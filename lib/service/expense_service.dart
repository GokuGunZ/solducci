import 'package:flutter/foundation.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_split.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/group_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseService {
  // Singleton pattern
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  final _supabase = Supabase.instance.client;
  final _contextManager = ContextManager();

  // Create
  Future<void> createExpense(Expense newExpense) async {
    try {
      // Auto-set context fields if not set
      final context = _contextManager.currentContext;

      if (kDebugMode) {
        print('🔍 [CREATE] Context: ${context.isPersonal ? "Personal" : "Group (${context.groupId})"}');
        print('🔍 [CREATE] Expense before context set:');
        print('   - groupId: ${newExpense.groupId}');
        print('   - userId: ${newExpense.userId}');
        print('   - paidBy: ${newExpense.paidBy}');
        print('   - splitType: ${newExpense.splitType?.value}');
      }

      // FORCE context fields based on current context (not just if null)
      if (context.isGroup) {
        newExpense.groupId = context.groupId;  // Always set from context
        if (kDebugMode) {
          print('🔧 [CREATE] FORCED groupId from context: ${newExpense.groupId}');
        }
      }
      if (context.isPersonal) {
        newExpense.userId = _supabase.auth.currentUser?.id;  // Always set from auth
        newExpense.groupId = null;  // Ensure no groupId for personal expenses
        if (kDebugMode) {
          print('🔧 [CREATE] FORCED userId from auth: ${newExpense.userId}');
          print('🔧 [CREATE] FORCED groupId to null (personal context)');
        }
      }

      final dataToInsert = newExpense.toMap();
      if (kDebugMode) {
        print('📤 [CREATE] Data being sent to Supabase:');
        dataToInsert.forEach((key, value) {
          print('   $key: $value');
        });
      }

      // Insert expense and get the ID back
      final result = await _supabase
          .from('expenses')
          .insert(dataToInsert)
          .select()
          .single();

      final expenseId = result['id'] as int;

      if (kDebugMode) {
        print('✅ [CREATE] Expense created successfully: ${newExpense.description} (ID: $expenseId)');
        print('🔍 [CREATE] Result from DB:');
        result.forEach((key, value) {
          print('   $key: $value');
        });
        print('🔍 [CREATE] Verifying group_id in DB: ${result['group_id']}');
      }

      // If group expense with splits, create expense_splits
      if (newExpense.groupId != null &&
          newExpense.splitType != null &&
          newExpense.splitType != SplitType.offer) {

        if (kDebugMode) {
          print('💰 Creating splits for expense $expenseId (type: ${newExpense.splitType?.label})');
        }

        // Get group members to calculate splits
        final members = await GroupService().getGroupMembers(newExpense.groupId!);

        // Calculate splits based on type
        final splits = _calculateSplits(
          expenseId: expenseId,
          expense: newExpense,
          members: members,
        );

        // Insert splits
        if (splits.isNotEmpty) {
          await _supabase.from('expense_splits').insert(splits);

          if (kDebugMode) {
            print('✅ Created ${splits.length} expense splits');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR creating expense: $e');
      }
      rethrow;
    }
  }

  // Read - Context-aware stream
  Stream<List<Expense>> get stream {
    final context = _contextManager.currentContext;
    final userId = _supabase.auth.currentUser?.id;

    if (kDebugMode) {
      print('🔍 [STREAM] Creating stream for context: ${context.isPersonal ? "Personal" : "Group (${context.groupId})"}');
      print('🔍 [STREAM] Current user ID: $userId');
    }

    if (userId == null) {
      if (kDebugMode) print('⚠️ [STREAM] No authenticated user');
      return Stream.value([]);
    }

    if (context.isPersonal) {
      // Personal context: show only user's personal expenses (no group)
      if (kDebugMode) {
        print('🔍 [STREAM] Setting up PERSONAL stream: user_id=$userId, group_id=NULL');
      }
      return _supabase
          .from('expenses')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((data) {
            if (kDebugMode) {
              print('📊 [STREAM] Personal received ${data.length} rows from DB');
            }
            // Filter out group expenses client-side
            final filtered = data.where((row) => row['group_id'] == null).toList();
            if (kDebugMode) {
              print('📊 [STREAM] Personal after filter: ${filtered.length} expenses (removed ${data.length - filtered.length} group expenses)');
            }
            return _parseExpenses(filtered);
          });
    } else {
      // Group context: show expenses for this group
      if (kDebugMode) {
        print('🔍 [STREAM] Setting up GROUP stream: group_id=${context.groupId}');
      }
      return _supabase
          .from('expenses')
          .stream(primaryKey: ['id'])
          .eq('group_id', context.groupId!)
          .map((data) {
            if (kDebugMode) {
              print('📊 [STREAM] Group received ${data.length} rows from DB');
              if (data.isNotEmpty) {
                print('📊 [STREAM] Sample rows:');
                for (var i = 0; i < data.length && i < 3; i++) {
                  print('   [${i + 1}] id=${data[i]['id']}, desc="${data[i]['description']}", group_id=${data[i]['group_id']}');
                }
              }
            }
            return _parseExpenses(data);
          });
    }
  }

  // Helper to parse expense list
  List<Expense> _parseExpenses(List<Map<String, dynamic>> data) {
    if (kDebugMode) {
      print('📊 Received ${data.length} expenses from stream');
    }

    return data.map<Expense>((row) {
      try {
        return Expense.fromMap(row);
      } catch (e) {
        if (kDebugMode) {
          print('❌ ERROR parsing expense from row: $row');
          print('   Error: $e');
        }
        rethrow;
      }
    }).toList();
  }

  /// Check if splits need to be recalculated based on changed fields
  bool _needsSplitRecalculation(Expense original, Expense updated) {
    // Check if amount changed
    if ((original.amount - updated.amount).abs() > 0.001) {
      if (kDebugMode) {
        print('   → Amount changed: ${original.amount} → ${updated.amount}');
      }
      return true;
    }

    // Check if split type changed
    if (original.splitType != updated.splitType) {
      if (kDebugMode) {
        print('   → Split type changed: ${original.splitType?.value} → ${updated.splitType?.value}');
      }
      return true;
    }

    // Check if payer changed
    if (original.paidBy != updated.paidBy) {
      if (kDebugMode) {
        print('   → Payer changed: ${original.paidBy} → ${updated.paidBy}');
      }
      return true;
    }

    // Check if custom split data changed (for custom splits)
    if (updated.splitType == SplitType.custom) {
      final originalData = original.splitData ?? {};
      final updatedData = updated.splitData ?? {};

      // Check if keys are different
      if (originalData.keys.length != updatedData.keys.length ||
          !originalData.keys.every((key) => updatedData.containsKey(key))) {
        if (kDebugMode) {
          print('   → Custom split users changed');
        }
        return true;
      }

      // Check if any amount changed
      for (final key in originalData.keys) {
        final originalAmount = originalData[key] ?? 0.0;
        final updatedAmount = updatedData[key] ?? 0.0;
        if ((originalAmount - updatedAmount).abs() > 0.001) {
          if (kDebugMode) {
            print('   → Custom split amount changed for $key: $originalAmount → $updatedAmount');
          }
          return true;
        }
      }
    }

    if (kDebugMode) {
      print('   → No split-relevant changes detected');
    }
    return false;
  }

  // Update
  Future updateExpense(Expense updatedExpense) async {
    try {
      if (kDebugMode) {
        print('🔄 [UPDATE] Updating expense: ${updatedExpense.description} (ID: ${updatedExpense.id})');
        print('🔍 [UPDATE] New values:');
        print('   - amount: ${updatedExpense.amount}');
        print('   - splitType: ${updatedExpense.splitType?.value}');
        print('   - paidBy: ${updatedExpense.paidBy}');
        print('   - groupId: ${updatedExpense.groupId}');
      }

      // FIX: Fetch original expense to check if splits need recalculation
      final originalData = await _supabase
          .from('expenses')
          .select()
          .eq('id', updatedExpense.id)
          .single();

      final originalExpense = Expense.fromMap(originalData);

      // Check if split-relevant fields changed
      final needsRecalculation = _needsSplitRecalculation(originalExpense, updatedExpense);

      if (kDebugMode) {
        print('🔍 [UPDATE] Splits need recalculation: $needsRecalculation');
      }

      // Update expense record
      await _supabase
          .from('expenses')
          .update(updatedExpense.toMap())
          .eq('id', updatedExpense.id);

      if (kDebugMode) {
        print('✅ [UPDATE] Expense record updated');
      }

      // Handle splits based on the updated expense state
      if (updatedExpense.groupId != null) {
        // This is (or remains) a group expense

        if (updatedExpense.splitType == SplitType.offer) {
          // Offer type = no splits needed, delete any existing
          // ALWAYS delete when offer (regardless of needsRecalculation)
          if (kDebugMode) {
            print('🗑️ [UPDATE] Split type is "offer", deleting all splits for expense ${updatedExpense.id}');
          }

          try {
            // First, verify what splits exist before delete
            final existingSplits = await _supabase
                .from('expense_splits')
                .select()
                .eq('expense_id', updatedExpense.id);

            if (kDebugMode) {
              print('   Found ${existingSplits.length} existing splits before delete');
            }

            // Now delete them
            await _supabase
                .from('expense_splits')
                .delete()
                .eq('expense_id', updatedExpense.id);

            if (kDebugMode) {
              print('🗑️ [UPDATE] Delete command executed for ${existingSplits.length} splits');
            }

            // Verify deletion
            final remainingSplits = await _supabase
                .from('expense_splits')
                .select()
                .eq('expense_id', updatedExpense.id);

            if (kDebugMode) {
              print('   Remaining splits after delete: ${remainingSplits.length}');
              if (remainingSplits.isNotEmpty) {
                print('   ⚠️ WARNING: Splits were not deleted!');
                for (var split in remainingSplits) {
                  print('      - Split ID: ${split['id']}, user: ${split['user_id']}, amount: ${split['amount']}');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('   ❌ Error during delete: $e');
            }
            rethrow;
          }

        } else if (needsRecalculation && updatedExpense.splitType != null) {
          // Need to recalculate splits (amount/type/payer changed)
          if (kDebugMode) {
            print('💰 [UPDATE] Recalculating splits for expense ${updatedExpense.id}');
          }

          // Delete old splits with verification
          final deleteResult = await _supabase
              .from('expense_splits')
              .delete()
              .eq('expense_id', updatedExpense.id)
              .select();

          if (kDebugMode) {
            print('🗑️ [UPDATE] Deleted ${deleteResult.length} old splits');
          }

          // Small delay to ensure delete is committed
          await Future.delayed(Duration(milliseconds: 50));

          // Get group members to calculate new splits
          final members = await GroupService().getGroupMembers(updatedExpense.groupId!);

          // Calculate new splits based on type
          final splits = _calculateSplits(
            expenseId: updatedExpense.id,
            expense: updatedExpense,
            members: members,
          );

          // Insert new splits
          if (splits.isNotEmpty) {
            if (kDebugMode) {
              print('📝 [UPDATE] Inserting ${splits.length} new splits...');
            }

            await _supabase.from('expense_splits').insert(splits);

            if (kDebugMode) {
              print('✅ [UPDATE] Created ${splits.length} new expense splits');
              for (var split in splits) {
                print('   - userId: ${split['user_id']}, amount: ${split['amount']}, paid: ${split['is_paid']}');
              }
            }
          }
        } else {
          // No recalculation needed, splits remain unchanged
          if (kDebugMode) {
            print('ℹ️ [UPDATE] Splits unchanged, skipping recalculation');
          }
        }

      } else if (originalExpense.groupId != null && updatedExpense.groupId == null) {
        // Changed from group to personal expense, delete all splits
        if (kDebugMode) {
          print('🗑️ [UPDATE] Changed to personal expense, deleting all splits');
        }
        await _supabase
            .from('expense_splits')
            .delete()
            .eq('expense_id', updatedExpense.id);
      }

      if (kDebugMode) {
        print('✅ Expense updated successfully: ${updatedExpense.description}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR updating expense: $e');
      }
      rethrow;
    }
  }

  // Delete
  Future deleteExpense(Expense expense) async {
    try {
      await _supabase
          .from('expenses')
          .delete()
          .eq('id', expense.id);

      if (kDebugMode) {
        print('✅ Expense deleted successfully: ${expense.description}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR deleting expense: $e');
      }
      rethrow;
    }
  }

  // Get expenses for a specific group (utility method)
  Future<List<Expense>> getGroupExpenses(String groupId) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('group_id', groupId)
          .order('date', ascending: false);

      return _parseExpenses((response as List).cast<Map<String, dynamic>>());
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR getting group expenses: $e');
      }
      return [];
    }
  }

  // Get personal expenses (utility method)
  Future<List<Expense>> getPersonalExpenses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      // Filter out group expenses
      final filtered = (response as List).where((row) => row['group_id'] == null).toList();
      return _parseExpenses(filtered.cast<Map<String, dynamic>>());
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR getting personal expenses: $e');
      }
      return [];
    }
  }

  // ========================================
  // EXPENSE SPLITS
  // ========================================

  /// Calculate splits based on expense split type
  List<Map<String, dynamic>> _calculateSplits({
    required int expenseId,
    required Expense expense,
    required List<GroupMember> members,
  }) {
    final splits = <Map<String, dynamic>>[];

    switch (expense.splitType) {
      case SplitType.equal:
        // Split equally among all members
        final amountPerPerson = expense.amount / members.length;
        final roundedAmount = double.parse(amountPerPerson.toStringAsFixed(2));

        for (final member in members) {
          splits.add({
            'expense_id': expenseId,
            'user_id': member.userId,
            'amount': roundedAmount,
            'is_paid': member.userId == expense.paidBy,
          });
        }
        break;

      case SplitType.custom:
        // Use custom amounts from splitData
        if (expense.splitData != null) {
          for (final entry in expense.splitData!.entries) {
            final userId = entry.key;
            final amount = entry.value;

            // Only create split if amount > 0
            if (amount > 0) {
              splits.add({
                'expense_id': expenseId,
                'user_id': userId,
                'amount': amount,
                'is_paid': userId == expense.paidBy,
              });
            }
          }
        }
        break;

      case SplitType.lend:
        // Payer advances for all members - everyone else must reimburse
        // FIX: Divide total amount only among non-payers
        final nonPayerCount = members.where((m) => m.userId != expense.paidBy).length;

        if (nonPayerCount == 0) {
          // No one to split with, skip
          if (kDebugMode) {
            print('⚠️ [LEND] No other members to split with');
          }
          break;
        }

        final amountPerPerson = expense.amount / nonPayerCount;
        final roundedAmount = double.parse(amountPerPerson.toStringAsFixed(2));

        for (final member in members) {
          // Create splits for ALL members except the payer
          if (member.userId != expense.paidBy) {
            splits.add({
              'expense_id': expenseId,
              'user_id': member.userId,
              'amount': roundedAmount,
              'is_paid': false,  // All others must pay
            });
          }
        }
        break;

      case SplitType.offer:
        // Payer offers the expense - no splits, no reimbursement
        break;

      default:
        if (kDebugMode) {
          print('⚠️ Unknown split type: ${expense.splitType}');
        }
        break;
    }

    return splits;
  }

  /// Get splits for a specific expense
  Future<List<ExpenseSplit>> getExpenseSplits(int expenseId) async {
    try {
      final response = await _supabase
          .from('expense_splits')
          .select('''
            *,
            profiles:user_id (
              nickname,
              email,
              avatar_url
            )
          ''')
          .eq('expense_id', expenseId)
          .order('amount', ascending: false);

      return (response as List).map((map) {
        // Flatten joined profile data
        final profile = map['profiles'] as Map<String, dynamic>?;
        return ExpenseSplit.fromMap({
          ...map,
          'user_name': profile?['nickname'],
          'user_email': profile?['email'],
          'user_avatar_url': profile?['avatar_url'],
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR getting expense splits: $e');
      }
      return [];
    }
  }

  /// Calculate how much the current user owes or is owed for a group expense
  /// Returns positive if user is owed money, negative if user owes money
  Future<double> calculateUserBalance(Expense expense) async {
    if (expense.groupId == null) return 0.0;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 0.0;

    // Get splits for this expense
    final splits = await getExpenseSplits(expense.id);

    if (expense.paidBy == currentUserId) {
      // Current user paid - calculate how much they're owed
      // Sum all unpaid splits (what others owe to payer)
      double totalOwed = 0.0;
      for (final split in splits) {
        if (!split.isPaid) {
          totalOwed += split.amount;
        }
      }
      return totalOwed; // Positive = they owe you
    } else {
      // Someone else paid - check if current user has an unpaid split
      final userSplit = splits.firstWhere(
        (split) => split.userId == currentUserId,
        orElse: () => ExpenseSplit(
          id: '',
          expenseId: expense.id.toString(),
          userId: currentUserId,
          amount: 0.0,
          isPaid: true, // No split = nothing to pay
          createdAt: DateTime.now(),
        ),
      );

      // If user has unpaid split, they owe that amount
      if (!userSplit.isPaid) {
        return -userSplit.amount; // Negative = you owe
      } else {
        return 0.0; // Already paid or no split
      }
    }
  }

  /// Calculate total balance for current user in a group
  /// Returns map of {otherUserId: amount} where positive = they owe you, negative = you owe them
  Future<Map<String, double>> calculateGroupBalance(String groupId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return {};

    try {
      // Get all expense splits for this group
      final response = await _supabase
          .from('expense_splits')
          .select('''
            *,
            expenses!inner(group_id, paid_by)
          ''')
          .eq('expenses.group_id', groupId);

      if (kDebugMode) {
        print('💰 [BALANCE] Found ${response.length} total splits for group $groupId');
      }

      final balances = <String, double>{};

      for (final splitData in response as List) {
        final split = ExpenseSplit.fromMap(splitData);
        final expense = splitData['expenses'] as Map<String, dynamic>;
        final paidBy = expense['paid_by'] as String;

        // Skip if already paid
        if (split.isPaid) continue;

        if (kDebugMode) {
          print('   - Split: expenseId=${split.expenseId}, userId=${split.userId}, amount=${split.amount}, isPaid=${split.isPaid}');
        }

        if (paidBy == currentUserId) {
          // Current user paid, others owe them
          if (split.userId != currentUserId) {
            balances[split.userId] = (balances[split.userId] ?? 0.0) + split.amount;
          }
        } else if (split.userId == currentUserId) {
          // Someone else paid, current user owes them
          balances[paidBy] = (balances[paidBy] ?? 0.0) - split.amount;
        }
      }

      if (kDebugMode) {
        print('💰 [BALANCE] Final balances: $balances');
      }

      return balances;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR calculating group balance: $e');
      }
      return {};
    }
  }
}
