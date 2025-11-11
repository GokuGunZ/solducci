import 'package:flutter/foundation.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/context_manager.dart';
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

      await _supabase.from('expenses').insert(dataToInsert);

      if (kDebugMode) {
        print('✅ Expense created successfully: ${newExpense.description}');
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
}
