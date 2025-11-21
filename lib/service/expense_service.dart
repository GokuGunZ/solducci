import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_split.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/group_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:async/async.dart';

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

      // FORCE context fields based on current context (not just if null)
      if (context.isGroup) {
        newExpense.groupId = context.groupId;  // Always set from context
      }
      if (context.isPersonal) {
        newExpense.userId = _supabase.auth.currentUser?.id;  // Always set from auth
        newExpense.groupId = null;  // Ensure no groupId for personal expenses
      }

      final dataToInsert = newExpense.toMap();

      // Insert expense and get the ID back
      final result = await _supabase
          .from('expenses')
          .insert(dataToInsert)
          .select()
          .single();

      final expenseId = result['id'] as int;

      // If group expense with splits, create expense_splits
      if (newExpense.groupId != null &&
          newExpense.splitType != null &&
          newExpense.splitType != SplitType.offer) {

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
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Read - Context-aware stream
  Stream<List<Expense>> get stream {
    final context = _contextManager.currentContext;
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value([]);
    }

    if (context.isPersonal) {
      // Personal context: show only user's personal expenses (no group)
      return _personalExpensesStream(userId);
    } else if (context.isView) {
      // View context: show expenses from multiple groups (+ optional personal)
      if (context.includesPersonal) {
        // Merge group expenses + personal expenses
        return _mergeStreams([
          _groupExpensesStream(context.groupIds),
          _personalExpensesStream(userId),
        ]);
      } else {
        // Only group expenses
        return _groupExpensesStream(context.groupIds);
      }
    } else {
      // Single group context
      return _groupExpensesStream([context.groupId!]);
    }
  }

  /// Stream for personal expenses only (no group_id)
  Stream<List<Expense>> _personalExpensesStream(String userId) {
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          // Filter out group expenses client-side
          final filtered = data.where((row) => row['group_id'] == null).toList();
          return _parseExpenses(filtered);
        });
  }

  /// Stream for expenses from one or more groups
  Stream<List<Expense>> _groupExpensesStream(List<String> groupIds) {
    if (groupIds.isEmpty) {
      return Stream.value([]);
    }

    // Supabase .inFilter() handles multiple IDs
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .inFilter('group_id', groupIds)
        .map((data) => _parseExpenses(data));
  }

  /// Merge multiple expense streams into one, removing duplicates and sorting
  Stream<List<Expense>> _mergeStreams(List<Stream<List<Expense>>> streams) {
    if (streams.isEmpty) {
      return Stream.value([]);
    }

    if (streams.length == 1) {
      return streams.first;
    }

    // Use StreamZip to combine streams
    return StreamZip(streams).map((results) {
      final merged = <Expense>[];

      // Flatten all lists
      for (final list in results) {
        merged.addAll(list);
      }

      // Remove duplicates by ID (shouldn't happen, but for safety)
      final uniqueById = <int, Expense>{};
      for (final expense in merged) {
        uniqueById[expense.id] = expense;
      }

      // Sort by date descending
      final sorted = uniqueById.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return sorted;
    });
  }

  // Helper to parse expense list
  List<Expense> _parseExpenses(List<Map<String, dynamic>> data) {
    return data.map<Expense>((row) => Expense.fromMap(row)).toList();
  }

  /// Check if splits need to be recalculated based on changed fields
  bool _needsSplitRecalculation(Expense original, Expense updated) {
    // Check if amount changed
    if ((original.amount - updated.amount).abs() > 0.001) {
      return true;
    }

    // Check if split type changed
    if (original.splitType != updated.splitType) {
      return true;
    }

    // Check if payer changed
    if (original.paidBy != updated.paidBy) {
      return true;
    }

    // Check if custom split data changed (for custom splits)
    if (updated.splitType == SplitType.custom) {
      final originalData = original.splitData ?? {};
      final updatedData = updated.splitData ?? {};

      // Check if keys are different
      if (originalData.keys.length != updatedData.keys.length ||
          !originalData.keys.every((key) => updatedData.containsKey(key))) {
        return true;
      }

      // Check if any amount changed
      for (final key in originalData.keys) {
        final originalAmount = originalData[key] ?? 0.0;
        final updatedAmount = updatedData[key] ?? 0.0;
        if ((originalAmount - updatedAmount).abs() > 0.001) {
          return true;
        }
      }
    }

    return false;
  }

  // Update
  Future updateExpense(Expense updatedExpense) async {
    try {
      // FIX: Fetch original expense to check if splits need recalculation
      final originalData = await _supabase
          .from('expenses')
          .select()
          .eq('id', updatedExpense.id)
          .single();

      final originalExpense = Expense.fromMap(originalData);

      // Check if split-relevant fields changed
      final needsRecalculation = _needsSplitRecalculation(originalExpense, updatedExpense);

      // Update expense record
      await _supabase
          .from('expenses')
          .update(updatedExpense.toMap())
          .eq('id', updatedExpense.id);

      // Handle splits based on the updated expense state
      if (updatedExpense.groupId != null) {
        // This is (or remains) a group expense

        if (updatedExpense.splitType == SplitType.offer) {
          // Offer type = no splits needed, delete any existing
          // ALWAYS delete when offer (regardless of needsRecalculation)
          await _supabase
              .from('expense_splits')
              .delete()
              .eq('expense_id', updatedExpense.id);

        } else if (needsRecalculation && updatedExpense.splitType != null) {
          // Need to recalculate splits (amount/type/payer changed)

          // Delete old splits
          await _supabase
              .from('expense_splits')
              .delete()
              .eq('expense_id', updatedExpense.id);

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
            await _supabase.from('expense_splits').insert(splits);
          }
        }

      } else if (originalExpense.groupId != null && updatedExpense.groupId == null) {
        // Changed from group to personal expense, delete all splits
        await _supabase
            .from('expense_splits')
            .delete()
            .eq('expense_id', updatedExpense.id);
      }
    } catch (e) {
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
    } catch (e) {
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

      final balances = <String, double>{};

      for (final splitData in response as List) {
        final split = ExpenseSplit.fromMap(splitData);
        final expense = splitData['expenses'] as Map<String, dynamic>;
        final paidBy = expense['paid_by'] as String;

        // Skip if already paid
        if (split.isPaid) continue;

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

      return balances;
    } catch (e) {
      return {};
    }
  }
}
