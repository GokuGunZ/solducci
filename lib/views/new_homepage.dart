import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/widgets/expense_list_item_optimized.dart';
import 'package:solducci/widgets/context_switcher.dart';
import 'package:solducci/utils/category_helpers.dart';

class NewHomepage extends StatefulWidget {
  const NewHomepage({super.key});

  @override
  State<NewHomepage> createState() => _NewHomepageState();
}

class _NewHomepageState extends State<NewHomepage> {
  final ExpenseServiceCached _expenseService = ExpenseServiceCached();
  final _contextManager = ContextManager();

  // Cache for pre-calculated balances
  Map<int, double> _balances = {};

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
        centerTitle: true,
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

                      // Debt balance section (for group and view contexts)
                      // Use ValueKey based on refresh counter to force rebuild
                      if (_contextManager.currentContext.isGroup)
                        _buildDebtBalanceSectionAsync(
                          key: ValueKey('debt_balance_$_debtBalanceRefreshKey'),
                        ),
                      if (_contextManager.currentContext.isGroup)
                        SizedBox(height: 16),

                      // View debt balance section (for multi-group views)
                      if (_contextManager.currentContext.isView)
                        _buildViewDebtBalanceSectionAsync(
                          key: ValueKey('view_debt_balance_$_debtBalanceRefreshKey'),
                        ),
                      if (_contextManager.currentContext.isView)
                        SizedBox(height: 16),

                      // Categories section with totals
                      _buildCategoriesSection(context, expenses),
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
  // OPTIMIZATION: Shows totals per category using cached expenses
  Widget _buildCategoriesSection(BuildContext context, List<Expense> expenses) {
    // Calculate totals per category
    final categoryTotals = _calculateCategoryTotals(expenses);

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
                final total = categoryTotals[category] ?? 0.0;
                return _buildCategoryItem(context, category, total);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Calculate totals per category from expenses list
  Map<Tipologia, double> _calculateCategoryTotals(List<Expense> expenses) {
    final totals = <Tipologia, double>{};

    for (final expense in expenses) {
      totals[expense.type] = (totals[expense.type] ?? 0.0) + expense.amount;
    }

    return totals;
  }

  // Build individual category item with circular icon, + button, and total
  // OPTIMIZATION: Shows total amount for this category
  Widget _buildCategoryItem(
    BuildContext context,
    Tipologia category,
    double total,
  ) {
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
            child: Column(
              children: [
                Text(
                  category.label,
                  style: TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Show total if > 0
                if (total > 0) ...[
                  SizedBox(height: 2),
                  Text(
                    '€${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
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

  // Build debt balance section for GROUP context (MULTI-PERSON SUPPORT)
  // Shows all pairwise balances between current user and other members
  Widget _buildDebtBalanceSectionAsync({Key? key}) {
    final groupId = _contextManager.currentContext.groupId;
    if (groupId == null) return SizedBox.shrink();

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      key: key,
      future: _expenseService.calculateGroupBalanceMultiPerson(groupId),
      builder: (context, snapshot) {
        // Loading state
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
          // No debts - show balanced state
          return Card(
            elevation: 3,
            color: Colors.green[50],
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                      SizedBox(width: 8),
                      Text(
                        'Tutti i saldi in pareggio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Multi-person balances - show all pairs
        final balances = snapshot.data!;
        return _buildMultiPersonDebtBalanceSection(balances);
      },
    );
  }

  // Build multi-person debt balance section (list of all pairwise balances)
  Widget _buildMultiPersonDebtBalanceSection(Map<String, Map<String, dynamic>> balances) {
    // Convert to PairwiseDebtBalance list
    final pairwiseBalances = balances.entries.map((entry) {
      final userId = entry.key;
      final data = entry.value;
      return PairwiseDebtBalance.fromBalanceEntry(
        userId: userId,
        userName: data['name'] as String,
        balance: data['balance'] as double,
      );
    }).toList();

    // Sort: you owe first, then they owe you
    pairwiseBalances.sort((a, b) {
      if (a.youOwe && !b.youOwe) return -1;
      if (!a.youOwe && b.youOwe) return 1;
      return b.amount.abs().compareTo(a.amount.abs());
    });

    return Card(
      elevation: 3,
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
            ...pairwiseBalances.map((balance) => _buildPairwiseBalanceRow(balance)),
          ],
        ),
      ),
    );
  }

  // Build single pairwise balance row (5-column layout)
  Widget _buildPairwiseBalanceRow(PairwiseDebtBalance balance) {
    final currentUserInitial = 'T'; // Tu
    final color = balance.youOwe ? Colors.orange : Colors.blue;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Position 1: Other user (if they owe you) or empty
          Expanded(
            flex: 2,
            child: balance.theyOwe
                ? Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[200],
                        radius: 16,
                        child: Text(
                          balance.userInitial,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        balance.userName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),

          // Position 2: Arrow + debt info (if other owes you)
          Expanded(
            flex: 2,
            child: balance.theyOwe
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        color: color[700],
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${balance.amountLabel} €',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Deve ricevere',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),

          // Position 3: Current user (always present)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange[200],
                  radius: 16,
                  child: Text(
                    currentUserInitial,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Position 4: Arrow + debt info (if you owe other)
          Expanded(
            flex: 2,
            child: balance.youOwe
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        color: color[700],
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${balance.amountLabel} €',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Deve a',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),

          // Position 5: Other user (if you owe them) or empty
          Expanded(
            flex: 2,
            child: balance.youOwe
                ? Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[200],
                        radius: 16,
                        child: Text(
                          balance.userInitial,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        balance.userName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Build debt balance section for VIEW context (GROUPED BY GROUPS)
  // Shows aggregated debts per group
  Widget _buildViewDebtBalanceSectionAsync({Key? key}) {
    final groupIds = _contextManager.currentContext.groupIds;
    if (groupIds.isEmpty) return SizedBox.shrink();

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      key: key,
      future: _expenseService.calculateViewBalanceGrouped(groupIds),
      builder: (context, snapshot) {
        // Loading state
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
          // No debts in any group
          return Card(
            elevation: 3,
            color: Colors.green[50],
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                      SizedBox(width: 8),
                      Text(
                        'Tutti i saldi in pareggio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Grouped balances
        final groupedBalances = snapshot.data!;
        return _buildGroupedDebtBalanceSection(groupedBalances);
      },
    );
  }

  // Build grouped debt balance section (list by groups)
  Widget _buildGroupedDebtBalanceSection(Map<String, Map<String, dynamic>> groupedBalances) {
    // Convert to GroupedDebtBalance list
    final groupBalances = groupedBalances.entries.map((entry) {
      final groupId = entry.key;
      final data = entry.value;
      return GroupedDebtBalance(
        groupId: groupId,
        groupName: data['groupName'] as String,
        peopleYouOwe: data['peopleYouOwe'] as int,
        peopleWhoOweYou: data['peopleWhoOweYou'] as int,
        totalYouOwe: data['totalYouOwe'] as double,
        totalTheyOweYou: data['totalTheyOweYou'] as double,
      );
    }).toList();

    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo Debiti per Gruppo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...groupBalances.map((balance) => _buildGroupedBalanceRow(balance)),
          ],
        ),
      ),
    );
  }

  // Build single grouped balance row - ONE row per group showing both debts and credits
  Widget _buildGroupedBalanceRow(GroupedDebtBalance balance) {
    final currentUserInitial = 'T'; // Tu

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group name header
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              balance.groupName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Single row with 5 columns showing BOTH sides
          Row(
            children: [
              // Position 1: Other people who owe you (if any)
              Expanded(
                flex: 2,
                child: balance.hasCredits
                    ? Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[200],
                            radius: 16,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${balance.peopleWhoOweYou}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.people, size: 10),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${balance.peopleWhoOweYou} ${balance.peopleWhoOweYou == 1 ? "persona" : "persone"}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : SizedBox.shrink(),
              ),

              // Position 2: Arrow + amount (credits - they owe you)
              Expanded(
                flex: 2,
                child: balance.hasCredits
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${balance.totalTheyOweYou.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Deve ricevere',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : SizedBox.shrink(),
              ),

              // Position 3: Current user (always present)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange[200],
                      radius: 16,
                      child: Text(
                        currentUserInitial,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tu',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Position 4: Arrow + amount (debts - you owe them)
              Expanded(
                flex: 2,
                child: balance.hasDebts
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${balance.totalYouOwe.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Deve a',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : SizedBox.shrink(),
              ),

              // Position 5: Other people you owe (if any)
              Expanded(
                flex: 2,
                child: balance.hasDebts
                    ? Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange[200],
                            radius: 16,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${balance.peopleYouOwe}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.people, size: 10),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${balance.peopleYouOwe} ${balance.peopleYouOwe == 1 ? "persona" : "persone"}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : SizedBox.shrink(),
              ),
            ],
          ),
        ],
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
        // OPTIMIZATION: Pre-calculate balances in bulk
        FutureBuilder<Map<int, double>>(
          future: _expenseService.calculateBulkUserBalances(recentExpenses),
          builder: (context, balanceSnapshot) {
            if (!balanceSnapshot.hasData) {
              _balances = {};
            } else {
              _balances = balanceSnapshot.data!;
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: recentExpenses.length,
              itemBuilder: (context, index) {
                final expense = recentExpenses[index];
                return ExpenseListItemOptimized(
                  expense: expense,
                  dismissible: true,
                  cachedBalance: _balances[expense.id],
                  onDeleted: _refreshDebtBalance,
                  onUpdated: _refreshDebtBalance,
                );
              },
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
    final expenseService = ExpenseServiceCached();

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

          // OPTIMIZATION: Pre-calculate balances in bulk
          return FutureBuilder<Map<int, double>>(
            future: expenseService.calculateBulkUserBalances(expenses),
            builder: (context, balanceSnapshot) {
              final balances = balanceSnapshot.data ?? {};

              return ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ExpenseListItemOptimized(
                    expense: expense,
                    dismissible: true,
                    cachedBalance: balances[expense.id],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
