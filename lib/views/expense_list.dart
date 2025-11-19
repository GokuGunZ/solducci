import 'package:flutter/material.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/widgets/expense_list_item.dart';
import 'package:solducci/widgets/context_switcher.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  ExpenseService expenseService = ExpenseService();
  final _contextManager = ContextManager();

  @override
  void initState() {
    super.initState();
    // Listen to context changes to rebuild stream
    _contextManager.addListener(_onContextChanged);
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    // Force rebuild to recreate stream with new context
    setState(() {});
  }

  // Unified method to open expense form for add/edit/duplicate
  void openExpenseForm({
    Expense? expense,
    required String title,
    bool isEdit = false,
  }) {
    final ExpenseForm form = expense != null
        ? ExpenseForm.fromExpense(expense, isEdit: isEdit)
        : ExpenseForm.empty();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: form.getExpenseView(context),
            ),
          ),
        ),
      ),
    );
  }

  void addExpense() {
    openExpenseForm(title: "Nuova Spesa");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ContextSwitcher(),
        elevation: 2,
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Nessuna spesa registrata',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Premi + per aggiungerne una',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          expenses.sort((a, b) {
            if (a.date.isAfter(b.date)) {
              return -1;
            } else {
              return 1;
            }
          });

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return ExpenseListItem(
                expense: expense,
                dismissible: true,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addExpense,
        tooltip: 'Aggiungi spesa',
        heroTag: 'expense_list_fab',
        child: Icon(Icons.add),
      ),
    );
  }
}
