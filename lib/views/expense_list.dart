import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/widgets/expense_list_item_optimized.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:solducci/widgets/quick_add/unified_transaction_modal.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final ExpenseServiceCached _expenseService = ExpenseServiceCached();
  final _contextManager = ContextManager();

  // Cache for pre-calculated balances
  Map<int, double> _balances = {};

  @override
  void initState() {
    super.initState();
    // Listen to context changes to rebuild list
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

  // Unified method to open expense form / details
  void openExpenseForm({
    Expense? expense,
    required String title,
    bool isEdit = false,
  }) {
    if (expense != null) {
      GoRouter.of(context).push('/expense/${expense.id}', extra: expense);
    } else {
      UnifiedTransactionModal.show(context);
    }
  }

  void addExpense() {
    UnifiedTransactionModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SolducciAppBar(
        titleText: 'Lista Spese',
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.stream,
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

          // Sort expenses by date (newest first)
          expenses.sort((a, b) => b.date.compareTo(a.date));

          // OPTIMIZATION: Pre-calculate all balances in one bulk operation
          // This replaces N individual queries with 1 bulk query
          return FutureBuilder<Map<int, double>>(
            future: _expenseService.calculateBulkUserBalances(expenses),
            builder: (context, balanceSnapshot) {
              // Show list with loading indicator for balances
              if (!balanceSnapshot.hasData) {
                _balances = {}; // Clear old balances
              } else {
                _balances = balanceSnapshot.data!;
              }

              return ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ExpenseListItemOptimized(
                    expense: expense,
                    dismissible: true,
                    cachedBalance: _balances[expense.id],
                  );
                },
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
