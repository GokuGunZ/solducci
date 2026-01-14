import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_split.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/core/cache/cacheable_service.dart';
import 'package:solducci/core/cache/cache_config.dart';
import 'package:solducci/core/cache/cache_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:async/async.dart';

/// Cached version of ExpenseService with in-memory caching
///
/// This service extends CacheableService to provide:
/// - In-memory cache of expenses by ID
/// - Reduced database queries for repeated access
/// - Bulk balance calculation using cached data
/// - Automatic cache invalidation on CRUD operations
///
/// The service maintains backward compatibility with existing stream-based API
/// while adding new cached getter methods for improved performance.
class ExpenseServiceCached extends CacheableService<Expense, int> {
  // Singleton pattern
  static final ExpenseServiceCached _instance = ExpenseServiceCached._internal();
  factory ExpenseServiceCached() => _instance;

  ExpenseServiceCached._internal()
      : super(config: CacheConfig.dynamic) {
    // Register with global cache manager
    CacheManager.instance.register('expenses', this);

    // Setup invalidation rules: when expenses change, invalidate groups
    CacheManager.instance.registerInvalidationRule('expenses', ['groups']);
  }

  final _supabase = Supabase.instance.client;
  final _contextManager = ContextManager();

  /// Cache for expense splits (expense_id → List<ExpenseSplit>)
  /// Reduces queries for split calculations
  final Map<int, List<ExpenseSplit>> _splitsCache = {};

  /// Cache for user balances (expense_id → user_balance)
  /// Eliminates repetitive balance calculations in list views
  final Map<int, double> _userBalanceCache = {};

  // ====================================================================
  // CacheableService Implementation (Abstract Methods)
  // ====================================================================

  @override
  Future<Expense?> fetchById(int id) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('id', id)
          .single();

      return Expense.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Expense>> fetchAll() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Fetch all expenses for current user (personal + groups they belong to)
      final response = await _supabase
          .from('expenses')
          .select()
          .or('user_id.eq.$userId,group_id.not.is.null')
          .order('date', ascending: false);

      return _parseExpenses((response as List).cast<Map<String, dynamic>>());
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Expense> insert(Expense item) async {
    // Auto-set context fields
    final context = _contextManager.currentContext;

    if (context.isGroup) {
      item.groupId = context.groupId;
    }
    if (context.isPersonal) {
      item.userId = _supabase.auth.currentUser?.id;
      item.groupId = null;
    }

    final dataToInsert = item.toMap();

    // Insert expense and get the ID back
    final result = await _supabase
        .from('expenses')
        .insert(dataToInsert)
        .select()
        .single();

    final expenseId = result['id'] as int;
    final createdExpense = Expense.fromMap(result);

    // If group expense with splits, create expense_splits
    if (createdExpense.groupId != null &&
        createdExpense.splitType != null &&
        createdExpense.splitType != SplitType.offer) {
      await _createExpenseSplits(expenseId, createdExpense);
    }

    // Invalidate balance cache
    _invalidateBalanceCache();

    return createdExpense;
  }

  @override
  Future<Expense> update(Expense item) async {
    // Fetch original expense to check if splits need recalculation
    final originalData = await _supabase
        .from('expenses')
        .select()
        .eq('id', item.id)
        .single();

    final originalExpense = Expense.fromMap(originalData);

    // Check if split-relevant fields changed
    final needsRecalculation = _needsSplitRecalculation(originalExpense, item);

    // Update expense record
    await _supabase
        .from('expenses')
        .update(item.toMap())
        .eq('id', item.id);

    // Handle splits based on the updated expense state
    if (item.groupId != null) {
      if (item.splitType == SplitType.offer) {
        // Delete splits for offer type
        await _supabase
            .from('expense_splits')
            .delete()
            .eq('expense_id', item.id);
      } else if (needsRecalculation && item.splitType != null) {
        // Recalculate splits
        await _supabase
            .from('expense_splits')
            .delete()
            .eq('expense_id', item.id);

        await Future.delayed(Duration(milliseconds: 50));
        await _createExpenseSplits(item.id, item);
      }
    } else if (originalExpense.groupId != null && item.groupId == null) {
      // Changed from group to personal, delete splits
      await _supabase
          .from('expense_splits')
          .delete()
          .eq('expense_id', item.id);
    }

    // Invalidate caches
    _splitsCache.remove(item.id);
    _invalidateBalanceCache();

    return item;
  }

  @override
  Future<void> delete(int id) async {
    await _supabase
        .from('expenses')
        .delete()
        .eq('id', id);

    // Invalidate caches
    _splitsCache.remove(id);
    _invalidateBalanceCache();
  }

  // ====================================================================
  // STREAM API (Backward Compatibility)
  // ====================================================================

  /// Context-aware stream of expenses
  /// Maintains backward compatibility with existing code
  Stream<List<Expense>> get stream {
    final context = _contextManager.currentContext;
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value([]);
    }

    if (context.isPersonal) {
      return _personalExpensesStream(userId);
    } else if (context.isView) {
      if (context.includesPersonal) {
        return _mergeStreams([
          _groupExpensesStream(context.groupIds),
          _personalExpensesStream(userId),
        ]);
      } else {
        return _groupExpensesStream(context.groupIds);
      }
    } else {
      if (context.includesPersonal) {
        return _mergeStreams([
          _groupExpensesStream([context.groupId!]),
          _personalExpensesStream(userId),
        ]);
      } else {
        return _groupExpensesStream([context.groupId!]);
      }
    }
  }

  Stream<List<Expense>> _personalExpensesStream(String userId) {
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          final filtered = data.where((row) => row['group_id'] == null).toList();
          final expenses = _parseExpenses(filtered);

          // Update cache with streamed data
          putManyInCache(expenses);

          return expenses;
        });
  }

  Stream<List<Expense>> _groupExpensesStream(List<String> groupIds) {
    if (groupIds.isEmpty) {
      return Stream.value([]);
    }

    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .inFilter('group_id', groupIds)
        .map((data) {
          final expenses = _parseExpenses(data);

          // Update cache with streamed data
          putManyInCache(expenses);

          return expenses;
        });
  }

  Stream<List<Expense>> _mergeStreams(List<Stream<List<Expense>>> streams) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first;

    return StreamZip(streams).map((results) {
      final merged = <Expense>[];
      for (final list in results) {
        merged.addAll(list);
      }

      final uniqueById = <int, Expense>{};
      for (final expense in merged) {
        uniqueById[expense.id] = expense;
      }

      final sorted = uniqueById.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      // Update cache with merged data
      putManyInCache(sorted);

      return sorted;
    });
  }

  List<Expense> _parseExpenses(List<Map<String, dynamic>> data) {
    return data.map<Expense>((row) => Expense.fromMap(row)).toList();
  }

  // ====================================================================
  // CACHED OPERATIONS (New High-Performance API)
  // ====================================================================

  /// Get expense by ID from cache (fast path)
  /// Falls back to database if not cached
  Future<Expense?> getCachedExpense(int id) => getById(id);

  /// Get multiple expenses from cache
  Future<List<Expense>> getCachedExpenses(List<int> ids) => getByIds(ids);

  /// Get all cached expenses for current context
  List<Expense> getAllCachedExpenses() {
    final context = _contextManager.currentContext;
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return [];

    final allCached = getCached();

    if (context.isPersonal) {
      return allCached
          .where((e) => e.userId == userId && e.groupId == null)
          .toList();
    } else if (context.isGroup) {
      return allCached
          .where((e) => e.groupId == context.groupId)
          .toList();
    } else if (context.isView) {
      return allCached
          .where((e) =>
              context.groupIds.contains(e.groupId) ||
              (context.includesPersonal && e.userId == userId && e.groupId == null))
          .toList();
    }

    return [];
  }

  // ====================================================================
  // EXPENSE SPLITS (With Caching)
  // ====================================================================

  /// Get splits for expense (cached)
  Future<List<ExpenseSplit>> getExpenseSplits(int expenseId) async {
    // Check cache first
    if (_splitsCache.containsKey(expenseId)) {
      return _splitsCache[expenseId]!;
    }

    // Fetch from database
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

      final splits = (response as List).map((map) {
        final profile = map['profiles'] as Map<String, dynamic>?;
        return ExpenseSplit.fromMap({
          ...map,
          'user_name': profile?['nickname'],
          'user_email': profile?['email'],
          'user_avatar_url': profile?['avatar_url'],
        });
      }).toList();

      // Cache result
      _splitsCache[expenseId] = splits;

      return splits;
    } catch (e) {
      return [];
    }
  }

  /// Calculate user balance for expense (cached)
  ///
  /// This method is HEAVILY optimized compared to original implementation:
  /// - Uses cached splits instead of fetching every time
  /// - Caches calculation result
  /// - Reduces O(n) queries in list views to O(1) cache lookups
  Future<double> calculateUserBalance(Expense expense) async {
    if (expense.groupId == null) return 0.0;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 0.0;

    // Check balance cache
    final cacheKey = expense.id;
    if (_userBalanceCache.containsKey(cacheKey)) {
      return _userBalanceCache[cacheKey]!;
    }

    // Calculate balance using cached splits
    final splits = await getExpenseSplits(expense.id);
    double balance = 0.0;

    if (expense.paidBy == currentUserId) {
      // Current user paid - sum unpaid splits
      for (final split in splits) {
        if (!split.isPaid) {
          balance += split.amount;
        }
      }
    } else {
      // Someone else paid - check if user has unpaid split
      final userSplit = splits.firstWhere(
        (split) => split.userId == currentUserId,
        orElse: () => ExpenseSplit(
          id: '',
          expenseId: expense.id.toString(),
          userId: currentUserId,
          amount: 0.0,
          isPaid: true,
          createdAt: DateTime.now(),
        ),
      );

      if (!userSplit.isPaid) {
        balance = -userSplit.amount;
      }
    }

    // Cache result
    _userBalanceCache[cacheKey] = balance;

    return balance;
  }

  /// Bulk calculate balances for multiple expenses
  ///
  /// MASSIVE optimization: instead of n separate queries, this batches
  /// split fetching and calculates all balances in one pass
  Future<Map<int, double>> calculateBulkUserBalances(List<Expense> expenses) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return {};

    final balances = <int, double>{};
    final expenseIds = expenses
        .where((e) => e.groupId != null)
        .map((e) => e.id)
        .toList();

    if (expenseIds.isEmpty) return {};

    // Fetch all splits in one query
    final response = await _supabase
        .from('expense_splits')
        .select()
        .inFilter('expense_id', expenseIds);

    // Group splits by expense_id
    final splitsByExpense = <int, List<ExpenseSplit>>{};
    for (final splitData in response as List) {
      final split = ExpenseSplit.fromMap(splitData);
      final expenseId = int.parse(split.expenseId);
      splitsByExpense.putIfAbsent(expenseId, () => []).add(split);
    }

    // Cache splits
    _splitsCache.addAll(splitsByExpense);

    // Calculate balance for each expense
    for (final expense in expenses) {
      if (expense.groupId == null) continue;

      final splits = splitsByExpense[expense.id] ?? [];
      double balance = 0.0;

      if (expense.paidBy == currentUserId) {
        for (final split in splits) {
          if (!split.isPaid) {
            balance += split.amount;
          }
        }
      } else {
        final userSplit = splits.firstWhere(
          (split) => split.userId == currentUserId,
          orElse: () => ExpenseSplit(
            id: '',
            expenseId: expense.id.toString(),
            userId: currentUserId,
            amount: 0.0,
            isPaid: true,
            createdAt: DateTime.now(),
          ),
        );

        if (!userSplit.isPaid) {
          balance = -userSplit.amount;
        }
      }

      balances[expense.id] = balance;
      _userBalanceCache[expense.id] = balance;
    }

    return balances;
  }

  /// Calculate total balance for group
  Future<Map<String, double>> calculateGroupBalance(String groupId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return {};

    try {
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

        if (split.isPaid) continue;

        if (paidBy == currentUserId) {
          if (split.userId != currentUserId) {
            balances[split.userId] = (balances[split.userId] ?? 0.0) + split.amount;
          }
        } else if (split.userId == currentUserId) {
          balances[paidBy] = (balances[paidBy] ?? 0.0) - split.amount;
        }
      }

      return balances;
    } catch (e) {
      return {};
    }
  }

  // ====================================================================
  // UTILITY METHODS
  // ====================================================================

  Future<void> _createExpenseSplits(int expenseId, Expense expense) async {
    final members = await GroupService().getGroupMembers(expense.groupId!);
    final splits = _calculateSplits(
      expenseId: expenseId,
      expense: expense,
      members: members,
    );

    if (splits.isNotEmpty) {
      await _supabase.from('expense_splits').insert(splits);
    }
  }

  List<Map<String, dynamic>> _calculateSplits({
    required int expenseId,
    required Expense expense,
    required List<GroupMember> members,
  }) {
    final splits = <Map<String, dynamic>>[];

    switch (expense.splitType) {
      case SplitType.equal:
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
        if (expense.splitData != null) {
          for (final entry in expense.splitData!.entries) {
            if (entry.value > 0) {
              splits.add({
                'expense_id': expenseId,
                'user_id': entry.key,
                'amount': entry.value,
                'is_paid': entry.key == expense.paidBy,
              });
            }
          }
        }
        break;

      case SplitType.lend:
        final nonPayerCount = members.where((m) => m.userId != expense.paidBy).length;
        if (nonPayerCount > 0) {
          final amountPerPerson = expense.amount / nonPayerCount;
          final roundedAmount = double.parse(amountPerPerson.toStringAsFixed(2));

          for (final member in members) {
            if (member.userId != expense.paidBy) {
              splits.add({
                'expense_id': expenseId,
                'user_id': member.userId,
                'amount': roundedAmount,
                'is_paid': false,
              });
            }
          }
        }
        break;

      case SplitType.offer:
        break;

      default:
        break;
    }

    return splits;
  }

  bool _needsSplitRecalculation(Expense original, Expense updated) {
    if ((original.amount - updated.amount).abs() > 0.001) return true;
    if (original.splitType != updated.splitType) return true;
    if (original.paidBy != updated.paidBy) return true;

    if (updated.splitType == SplitType.custom) {
      final originalData = original.splitData ?? {};
      final updatedData = updated.splitData ?? {};

      if (originalData.keys.length != updatedData.keys.length ||
          !originalData.keys.every((key) => updatedData.containsKey(key))) {
        return true;
      }

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

  void _invalidateBalanceCache() {
    _userBalanceCache.clear();
  }

  // ====================================================================
  // BACKWARD COMPATIBILITY (Legacy Methods)
  // ====================================================================

  Future<void> createExpense(Expense newExpense) async {
    await create(newExpense);
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    await updateItem(updatedExpense);
  }

  Future<void> deleteExpense(Expense expense) async {
    await deleteItem(expense.id);
  }

  Future<List<Expense>> getGroupExpenses(String groupId) async {
    final allExpenses = await fetchAll();
    return allExpenses.where((e) => e.groupId == groupId).toList();
  }

  Future<List<Expense>> getPersonalExpenses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final allExpenses = await fetchAll();
    return allExpenses
        .where((e) => e.userId == userId && e.groupId == null)
        .toList();
  }
}
