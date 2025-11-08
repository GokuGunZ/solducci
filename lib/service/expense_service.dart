import 'package:flutter/foundation.dart';
import 'package:solducci/models/expense.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseService {
  final database = Supabase.instance.client.from('expenses');

  // Create
  Future<void> createExpense(Expense newExpense) async {
    try {
      await database.insert(newExpense.toMap());
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

  // Read
  final Stream<List<Expense>> stream = Supabase.instance.client
      .from('expenses')
      .stream(primaryKey: ['id'])
      .map(
        (data) {
          if (kDebugMode) {
            print('📊 Received ${data.length} expenses from stream');
          }
          return data
              .map<Expense>((Map<String, dynamic> row) {
                try {
                  return Expense.fromMap(row);
                } catch (e) {
                  if (kDebugMode) {
                    print('❌ ERROR parsing expense from row: $row');
                    print('   Error: $e');
                  }
                  rethrow;
                }
              })
              .toList();
        },
      );

  // Update
  Future updateExpense(Expense updatedExpense) async {
    try {
      await database.update(updatedExpense.toMap()).eq('id', updatedExpense.id);
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
      await database.delete().eq('id', expense.id);
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
}
