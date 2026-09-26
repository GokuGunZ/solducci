import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/income_service.dart';
import 'package:solducci/service/wallet_service.dart';

class CashflowSummary {
  final double totalNetWorth;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlyCashflow;
  final double savingsRatePercent;

  CashflowSummary({
    required this.totalNetWorth,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlyCashflow,
    required this.savingsRatePercent,
  });
}

class CashflowService {
  static final CashflowService _instance = CashflowService._internal();
  factory CashflowService() => _instance;
  CashflowService._internal();

  /// Calcola il riepilogo del cashflow per il mese indicato
  CashflowSummary getSummaryForMonth(DateTime month) {
    final netWorth = WalletService().totalLiquidity;
    final income = IncomeService().getMonthlyTotal(month);

    final expensesList = ExpenseServiceCached().getAllCachedExpenses();
    final expenses = expensesList
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .fold(0.0, (sum, e) => sum + e.amount);

    final cashflow = income - expenses;
    final savingsRate = income > 0 ? (cashflow / income) * 100 : 0.0;

    return CashflowSummary(
      totalNetWorth: netWorth,
      monthlyIncome: income,
      monthlyExpenses: expenses,
      monthlyCashflow: cashflow,
      savingsRatePercent: savingsRate,
    );
  }
}
