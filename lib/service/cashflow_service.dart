import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/income_service.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
import 'package:solducci/service/wallet_service.dart';

class CashflowSummary {
  final double totalNetWorth; // Liquidità + Investimenti
  final double liquidNetWorth; // Solo conti bancari e contanti
  final double investedNetWorth; // Solo controvalore asset
  final double monthlyIncome;
  final double monthlyExpenses; // Solo spese di consumo (escluse quelle di investimento)
  final double monthlyInvested; // Spese di investimento/accumulo del mese
  final double monthlyCashflow; // income - (expenses + invested)
  final double savingsRatePercent; // (income - expenses) / income * 100

  CashflowSummary({
    required this.totalNetWorth,
    required this.liquidNetWorth,
    required this.investedNetWorth,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlyInvested,
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
    final liquidNetWorth = WalletService().totalLiquidity;
    final investedNetWorth = InvestmentPortfolioService().getTotalCurrentValue();
    final totalNetWorth = liquidNetWorth + investedNetWorth;

    final income = IncomeService().getMonthlyTotal(month);

    final expensesList = ExpenseServiceCached().getAllCachedExpenses();
    final monthExpenses = expensesList
        .where((e) => e.date.year == month.year && e.date.month == month.month);

    // Distingue tra spese di consumo e investimenti
    final consumptionExpenses = monthExpenses
        .where((e) => e.type != Tipologia.investimento)
        .fold(0.0, (sum, e) => sum + e.amount);

    final investedExpenses = monthExpenses
        .where((e) => e.type == Tipologia.investimento)
        .fold(0.0, (sum, e) => sum + e.amount);

    final netCashflow = income - (consumptionExpenses + investedExpenses);
    // Tasso di risparmio: investire è risparmio, quindi (income - consumi) / income
    final savingsRate = income > 0
        ? ((income - consumptionExpenses) / income) * 100
        : 0.0;

    return CashflowSummary(
      totalNetWorth: totalNetWorth,
      liquidNetWorth: liquidNetWorth,
      investedNetWorth: investedNetWorth,
      monthlyIncome: income,
      monthlyExpenses: consumptionExpenses,
      monthlyInvested: investedExpenses,
      monthlyCashflow: netCashflow,
      savingsRatePercent: savingsRate,
    );
  }
}
