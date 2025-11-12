import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/widgets/expense_list_item.dart';
import 'package:solducci/widgets/context_switcher.dart';

class NewHomepage extends StatelessWidget {
  const NewHomepage({super.key});

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Vuoi uscire dall\'applicazione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await authService.signOut();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante logout'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(
        title: const ContextSwitcher(),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
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
                ],
              ),
            );
          }

          // Calculate statistics
          final totalExpenses = _calculateTotal(expenses);
          final currentMonthTotal = _calculateCurrentMonthTotal(expenses);
          final debtBalance = DebtBalance.calculate(expenses);
          final recentExpenses = _getRecentExpenses(expenses, 15);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Compact summary section - half viewport
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Totals section
                      _buildTotalsSection(totalExpenses, currentMonthTotal),
                      SizedBox(height: 16),

                      // Debt balance section
                      _buildDebtBalanceSection(debtBalance),
                      SizedBox(height: 16),

                      // Categories section
                      _buildCategoriesSection(context),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 2),

                // Recent expenses section
                _buildRecentExpensesSection(context, recentExpenses),
              ],
            ),
          );
        },
      ),
    );
  }

  // Calculate total of all expenses
  double _calculateTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Calculate total for current month
  double _calculateCurrentMonthTotal(List<Expense> expenses) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return expenses
        .where((expense) {
          final expenseMonth = DateTime(expense.date.year, expense.date.month);
          return expenseMonth == currentMonth;
        })
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get recent expenses (sorted by date, limited to count)
  List<Expense> _getRecentExpenses(List<Expense> expenses, int count) {
    final sorted = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(count).toList();
  }

  // Build totals section
  Widget _buildTotalsSection(double total, double monthTotal) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 3,
            color: Colors.purple[150],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Totale',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${total.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 3,
            color: Colors.green[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Questo mese',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${monthTotal.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build categories section with circular icons and + buttons
  Widget _buildCategoriesSection(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Categorie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: Tipologia.values.map((category) {
                return _buildCategoryItem(context, category);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Build individual category item with circular icon and + button
  Widget _buildCategoryItem(BuildContext context, Tipologia category) {
    final categoryColor = _getCategoryColor(category);
    final categoryIcon = _getCategoryIcon(category);

    return Padding(
      padding: EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category icon - navigate to filtered list
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FilteredExpenseList(category: category),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: categoryColor,
                  radius: 18,
                  child: Icon(categoryIcon, color: Colors.white, size: 18),
                ),
              ),
              SizedBox(width: 4),
              // + button - create new expense with this category
              InkWell(
                onTap: () {
                  _openExpenseFormWithCategory(context, category);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: categoryColor, width: 1.5),
                  ),
                  child: Icon(Icons.add, size: 14, color: categoryColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              category.label,
              style: TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Open expense form with pre-selected category
  void _openExpenseFormWithCategory(BuildContext context, Tipologia category) {
    final form = ExpenseForm.empty();
    form.typeField.setValue(category);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Nuova Spesa - ${category.label}"),
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

  // Build debt balance section
  Widget _buildDebtBalanceSection(DebtBalance balance) {
    final carlOwes = balance.netBalance > 0;
    final balanced = balance.netBalance == 0;
    final amount = balance.netBalance.abs();

    return Card(
      elevation: 3,
      color: balanced
          ? Colors.green[50]
          : (carlOwes ? Colors.orange[50] : Colors.blue[50]),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo Debiti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                // Carl column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange[200],
                        child: Text(
                          'C',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Carl',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount/Arrow column
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (balanced)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
                          size: 24,
                        )
                      else
                        Icon(
                          carlOwes ? Icons.arrow_forward : Icons.arrow_back,
                          color: carlOwes
                              ? Colors.orange[700]
                              : Colors.blue[700],
                          size: 24,
                        ),
                      SizedBox(height: 4),
                      Text(
                        balanced ? 'Pari' : '${amount.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: balanced
                              ? Colors.green[700]
                              : (carlOwes
                                    ? Colors.orange[700]
                                    : Colors.blue[700]),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!balanced)
                        Text(
                          carlOwes ? 'Deve a' : 'Deve ricevere',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),

                // Pit column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[200],
                        child: Text(
                          'P',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build recent expenses section
  Widget _buildRecentExpensesSection(
    BuildContext context,
    List<Expense> recentExpenses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ultime Spese',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  context.go('/expenses');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Vedi Tutte'),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: recentExpenses.length,
          itemBuilder: (context, index) {
            final expense = recentExpenses[index];
            return ExpenseListItem(
              expense: expense,
              dismissible: true,
            );
          },
        ),
      ],
    );
  }

  // Helper methods for colors and icons (used by category items)
  Color _getCategoryColor(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Colors.purple;
      case Tipologia.cibo:
        return Colors.green;
      case Tipologia.utenze:
        return Colors.blue;
      case Tipologia.prodottiCasa:
        return Colors.orange;
      case Tipologia.ristorante:
        return Colors.red;
      case Tipologia.tempoLibero:
        return Colors.pink;
      case Tipologia.altro:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Icons.home;
      case Tipologia.cibo:
        return Icons.shopping_cart;
      case Tipologia.utenze:
        return Icons.bolt;
      case Tipologia.prodottiCasa:
        return Icons.cleaning_services;
      case Tipologia.ristorante:
        return Icons.restaurant;
      case Tipologia.tempoLibero:
        return Icons.sports_esports;
      case Tipologia.altro:
        return Icons.more_horiz;
    }
  }
}

// Filtered expense list by category
class FilteredExpenseList extends StatelessWidget {
  final Tipologia category;

  const FilteredExpenseList({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(title: Text('Spese - ${category.label}')),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses =
              snapshot.data!
                  .where((expense) => expense.type == category)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Nessuna spesa per ${category.label}',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return ExpenseListItem(
                expense: expense,
                dismissible: true, // Allow swipe gestures
              );
            },
          );
        },
      ),
    );
  }
}
