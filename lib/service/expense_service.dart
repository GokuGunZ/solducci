import 'package:solducci/models/expense.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseService {
  final database = Supabase.instance.client.from('expenses');

  // Create
  Future createExpense(Expense newExpense) async {
    await database.insert(newExpense.toMap());
  }

  // Read
  final stream = Supabase.instance.client.from('expenses').stream(primaryKey: ['id'],)
  .map((data) => data.map((expenseMap) => Expense.fromMap(expenseMap)).toList());

  // Update
  Future updateExpense(Expense updatedExpense) async {
    await database.update(updatedExpense.toMap()).eq('id', updatedExpense.id);
  }

  // Delete
  Future deleteExpense(Expense expense) async {
    await database.delete().eq('id', expense.id);
  }

}