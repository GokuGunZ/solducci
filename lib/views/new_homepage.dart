import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/widgets/expense_list_item.dart';
import 'package:solducci/widgets/context_switcher.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/views/shell_with_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewHomepage extends StatefulWidget {
  const NewHomepage({super.key});

  @override
  State<NewHomepage> createState() => _NewHomepageState();
}

class _NewHomepageState extends State<NewHomepage> {
  final ExpenseService _expenseService = ExpenseService();
  final _contextManager = ContextManager();

  // Key to force rebuild of debt balance section
  int _debtBalanceRefreshKey = 0;

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
    setState(() {
      _debtBalanceRefreshKey++;
    });
  }

  // Force refresh of debt balance section
  void _refreshDebtBalance() {
    setState(() {
      _debtBalanceRefreshKey++;
    });
  }

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
        stream: _expenseService.stream,
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

                      // Debt balance section (only for group context)
                      // Use ValueKey based on refresh counter to force rebuild
                      if (_contextManager.currentContext.isGroup)
                        _buildDebtBalanceSectionAsync(
                          key: ValueKey('debt_balance_$_debtBalanceRefreshKey'),
                        ),
                      if (_contextManager.currentContext.isGroup)
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
      floatingActionButton: FloatingActionButton(
        onPressed: addExpense,
        tooltip: 'Aggiungi spesa',
        heroTag: 'homepage_fab',
        child: Icon(Icons.add),
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
    final categoryColor = CategoryHelpers.getCategoryColor(category);
    final categoryIcon = CategoryHelpers.getCategoryIcon(category);

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
    ).then((_) {
      // Refresh debt balance after form is closed
      _refreshDebtBalance();
    });
  }

  void addExpense() {
    _openExpenseForm(context, ExpenseForm.empty());
  }

  void _openExpenseForm(BuildContext context, ExpenseForm form) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Nuova Spesa"),
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
    ).then((_) {
      // Refresh debt balance after form is closed (expense may have been added)
      _refreshDebtBalance();
    });
  }

  // Build debt balance section (async version for group context)
  Widget _buildDebtBalanceSectionAsync({Key? key}) {
    final groupId = _contextManager.currentContext.groupId;
    if (groupId == null) return SizedBox.shrink();

    return FutureBuilder<Map<String, double>>(
      key: key,
      future: _expenseService.calculateGroupBalance(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // No debts = balanced - fetch names for UI
          return FutureBuilder<List<String>>(
            future: _getUserNames(groupId),
            builder: (context, nameSnapshot) {
              final names = nameSnapshot.data ?? ['Tu', 'Altro membro'];
              final debtBalance = DebtBalance(
                carlOwes: 0.0,
                pitOwes: 0.0,
                netBalance: 0.0,
                balanceLabel: "Saldo in pareggio",
              );
              return _buildDebtBalanceSection(debtBalance, names[0], names[1]);
            },
          );
        }

        final balances = snapshot.data!;

        // Get user names from GroupService
        return FutureBuilder<List<String>>(
          future: _getUserNames(groupId),
          builder: (context, nameSnapshot) {
            if (nameSnapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              );
            }

            final names = nameSnapshot.data ?? ['Tu', 'Altro membro'];
            final currentUserName = names[0];
            final otherUserName = names[1];

            final debtBalance = DebtBalance.fromBalanceMap(
              balances,
              currentUserName,
              otherUserName,
            );

            return _buildDebtBalanceSection(
              debtBalance,
              currentUserName,
              otherUserName,
            );
          },
        );
      },
    );
  }

  // Helper to get both user names in the group
  // Returns [currentUserName, otherUserName]
  Future<List<String>> _getUserNames(String groupId) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return ['Tu', 'Altro membro'];

      final members = await GroupService().getGroupMembers(groupId);
      if (members.isEmpty) return ['Tu', 'Altro membro'];

      // Find current user and other member
      final currentMember = members.firstWhere(
        (m) => m.userId == currentUserId,
        orElse: () => members.first,
      );

      final otherMember = members.firstWhere(
        (m) => m.userId != currentUserId,
        orElse: () => members.last,
      );

      return [
        currentMember.nickname ?? 'Tu',
        otherMember.nickname ?? 'Altro membro',
      ];
    } catch (e) {
      return ['Tu', 'Altro membro'];
    }
  }

  // Build debt balance section with dynamic user names
  Widget _buildDebtBalanceSection(
    DebtBalance balance,
    String currentUserName,
    String otherUserName,
  ) {
    // Use balance.netBalance convention from fromBalanceMap:
    // netBalance > 0 = current user owes
    // netBalance < 0 = current user is owed
    final currentUserOwes = balance.netBalance > 0;
    final balanced = balance.netBalance == 0;
    final amount = balance.netBalance.abs();

    // Get first letter for avatars
    final currentInitial = currentUserName.isNotEmpty
        ? currentUserName[0].toUpperCase()
        : 'T';
    final otherInitial = otherUserName.isNotEmpty
        ? otherUserName[0].toUpperCase()
        : 'A';

    return Card(
      elevation: 3,
      color: balanced
          ? Colors.green[50]
          : (currentUserOwes ? Colors.orange[50] : Colors.blue[50]),
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
                // Current user column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange[200],
                        child: Text(
                          currentInitial,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currentUserName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          currentUserOwes
                              ? Icons.arrow_forward
                              : Icons.arrow_back,
                          color: currentUserOwes
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
                              : (currentUserOwes
                                    ? Colors.orange[700]
                                    : Colors.blue[700]),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!balanced)
                        Text(
                          currentUserOwes ? 'Deve a' : 'Deve ricevere',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),

                // Other user column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[200],
                        child: Text(
                          otherInitial,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        otherUserName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  // Navigate to Spese tab (index 1) in ShellWithNav
                  context.push("/expense_list");
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
              onDeleted: _refreshDebtBalance,
              onUpdated: _refreshDebtBalance,
            );
          },
        ),
      ],
    );
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
