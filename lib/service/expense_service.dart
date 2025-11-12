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
      if (context.isGroup && newExpense.groupId == null) {
        newExpense.groupId = context.groupId;
      }
      if (newExpense.userId == null && context.isPersonal) {
        newExpense.userId = _supabase.auth.currentUser?.id;
      }

      final dataToInsert = newExpense.toMap();
      if (kDebugMode) {
        print('📤 Data being sent to Supabase: $dataToInsert');
      }

      // Insert expense and get the ID back
      final result = await _supabase
          .from('expenses')
          .insert(dataToInsert)
          .select()
          .single();

      final expenseId = result['id'] as int;

      if (kDebugMode) {
        print('✅ Expense created successfully: ${newExpense.description} (ID: $expenseId)');
      }

      // If group expense with splits, create expense_splits
      if (newExpense.groupId != null &&
          newExpense.splitType != null &&
          newExpense.splitType != SplitType.full &&
          newExpense.splitType != SplitType.none) {

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

    if (userId == null) {
      if (kDebugMode) print('⚠️ No authenticated user');
      return Stream.value([]);
    }

    if (context.isPersonal) {
      // Personal context: show only user's personal expenses (no group)
      return _supabase
          .from('expenses')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((data) {
            // Filter out group expenses client-side
            final filtered = data.where((row) => row['group_id'] == null).toList();
            return _parseExpenses(filtered);
          });
    } else {
      // Group context: show expenses for this group
      return _supabase
          .from('expenses')
          .stream(primaryKey: ['id'])
          .eq('group_id', context.groupId!)
          .map(_parseExpenses);
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

  // Update
  Future updateExpense(Expense updatedExpense) async {
    try {
      await _supabase
          .from('expenses')
          .update(updatedExpense.toMap())
          .eq('id', updatedExpense.id);

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

      case SplitType.full:
      case SplitType.none:
        // No splits needed
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

    // Find current user's split
    final userSplit = splits.firstWhere(
      (split) => split.userId == currentUserId,
      orElse: () => ExpenseSplit(
        id: '',
        expenseId: expense.id.toString(),
        userId: currentUserId,
        amount: 0.0,
        isPaid: false,
        createdAt: DateTime.now(),
      ),
    );

    // If current user paid, they are owed (positive)
    // If someone else paid, current user owes (negative)
    if (expense.paidBy == currentUserId) {
      // User paid, so they're owed the total minus their share
      return expense.amount - userSplit.amount;
    } else {
      // User didn't pay, so they owe their share
      return -userSplit.amount;
    }
  }
}
