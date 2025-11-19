import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:intl/intl.dart';

/// Model for monthly expense grouping
class MonthlyGroup {
  final String monthLabel; // e.g., "Gennaio 2025"
  final DateTime month;
  final List<Expense> expenses;
  final double total;

  MonthlyGroup({
    required this.monthLabel,
    required this.month,
    required this.expenses,
    required this.total,
  });
}

/// Model for category breakdown
class CategoryBreakdown {
  final Tipologia category;
  final double total;
  final int count;
  final double percentage;

  CategoryBreakdown({
    required this.category,
    required this.total,
    required this.count,
    required this.percentage,
  });
}

/// Model for debt/credit calculation between two users
class DebtBalance {
  final double carlOwes; // How much current user owes to other (legacy naming)
  final double pitOwes; // How much other owes to current user (legacy naming)
  final double netBalance; // Positive = you owe other, Negative = other owes you
  final String balanceLabel; // User-friendly label

  DebtBalance({
    required this.carlOwes,
    required this.pitOwes,
    required this.netBalance,
    required this.balanceLabel,
  });

  /// Create DebtBalance from balance map (from ExpenseService.calculateGroupBalance)
  /// For 2-person groups only
  ///
  /// Convention:
  /// - balances[userId] > 0 = they owe you (you are owed)
  /// - balances[userId] < 0 = you owe them
  /// - netBalance > 0 = you owe (current user owes)
  /// - netBalance < 0 = you are owed (current user is owed)
  factory DebtBalance.fromBalanceMap(
    Map<String, double> balances,
    String currentUserName,
    String? otherUserName,
  ) {
    if (balances.isEmpty) {
      return DebtBalance(
        carlOwes: 0.0,
        pitOwes: 0.0,
        netBalance: 0.0,
        balanceLabel: "Saldo in pareggio",
      );
    }

    // For 2-person group, there should be only one entry
    final otherUserId = balances.keys.first;
    final balance = balances[otherUserId] ?? 0.0;
    // balance > 0 = they owe you
    // balance < 0 = you owe them

    final otherName = otherUserName ?? 'altro utente';

    double youOwe = 0.0;
    double theyOwe = 0.0;
    double netBalance;
    String label;

    if (balance > 0) {
      // Positive = they owe you (you are owed)
      theyOwe = balance;
      netBalance = -balance; // Negative netBalance = you are owed
      label = "$otherName ti deve ${balance.toStringAsFixed(2)} €";
    } else if (balance < 0) {
      // Negative = you owe them
      youOwe = -balance;
      netBalance = -balance; // Positive netBalance = you owe
      label = "Devi ${(-balance).toStringAsFixed(2)} € a $otherName";
    } else {
      netBalance = 0.0;
      label = "Saldo in pareggio";
    }

    return DebtBalance(
      carlOwes: youOwe,
      pitOwes: theyOwe,
      netBalance: netBalance,
      balanceLabel: label,
    );
  }

  @Deprecated('Use fromBalanceMap instead')
  factory DebtBalance.calculate(List<Expense> expenses) {
    // Legacy method - kept for backward compatibility
    // Use ExpenseService.calculateGroupBalance() + fromBalanceMap() instead
    return DebtBalance(
      carlOwes: 0.0,
      pitOwes: 0.0,
      netBalance: 0.0,
      balanceLabel: "Usa DebtBalance.fromBalanceMap",
    );
  }
}

/// Service for dashboard analytics
class DashboardService {
  /// Groups expenses by month, sorted newest to oldest
  static List<MonthlyGroup> groupByMonth(List<Expense> expenses) {
    if (expenses.isEmpty) return [];

    // Sort expenses by date descending (newest first)
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group by year-month
    final Map<String, List<Expense>> monthMap = {};
    for (var expense in sortedExpenses) {
      final key = DateFormat('yyyy-MM').format(expense.date);
      monthMap.putIfAbsent(key, () => []).add(expense);
    }

    // Convert to MonthlyGroup list
    final groups = <MonthlyGroup>[];
    for (var entry in monthMap.entries) {
      final monthDate = DateTime.parse('${entry.key}-01');
      final monthLabel = _getMonthLabelItalian(monthDate);
      final total = entry.value.fold<double>(0.0, (sum, e) => sum + e.amount);

      groups.add(MonthlyGroup(
        monthLabel: monthLabel,
        month: monthDate,
        expenses: entry.value,
        total: total,
      ));
    }

    // Sort groups by date descending
    groups.sort((a, b) => b.month.compareTo(a.month));

    return groups;
  }

  /// Calculates category breakdown with percentages
  static List<CategoryBreakdown> categoryBreakdown(List<Expense> expenses) {
    if (expenses.isEmpty) return [];

    final Map<Tipologia, double> totals = {};
    final Map<Tipologia, int> counts = {};

    // Calculate totals per category
    for (var expense in expenses) {
      totals[expense.type] = (totals[expense.type] ?? 0.0) + expense.amount;
      counts[expense.type] = (counts[expense.type] ?? 0) + 1;
    }

    final grandTotal = totals.values.fold<double>(0.0, (sum, v) => sum + v);

    // Create breakdown list
    final breakdowns = totals.entries.map((entry) {
      final percentage = grandTotal > 0 ? (entry.value / grandTotal * 100) : 0.0;
      return CategoryBreakdown(
        category: entry.key,
        total: entry.value,
        count: counts[entry.key]!,
        percentage: percentage,
      );
    }).toList();

    // Sort by total descending
    breakdowns.sort((a, b) => b.total.compareTo(a.total));

    return breakdowns;
  }

  /// Groups expenses by date sections for timeline view
  static Map<String, List<Expense>> groupByDateSections(List<Expense> expenses) {
    if (expenses.isEmpty) return {};

    // Sort by date descending
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, List<Expense>> sections = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var expense in sortedExpenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      String sectionLabel;
      if (expenseDate == today) {
        sectionLabel = "Oggi";
      } else if (expenseDate == yesterday) {
        sectionLabel = "Ieri";
      } else {
        sectionLabel = _formatDateItalian(expense.date);
      }

      sections.putIfAbsent(sectionLabel, () => []).add(expense);
    }

    return sections;
  }

  /// Helper function to format month names in Italian
  static String _getMonthLabelItalian(DateTime date) {
    const monthNames = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  /// Helper function to format date in Italian (e.g., "8 Gen 2025")
  static String _formatDateItalian(DateTime date) {
    const monthAbbr = [
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];
    return '${date.day} ${monthAbbr[date.month - 1]} ${date.year}';
  }
}
