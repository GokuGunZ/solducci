import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/recurring_transaction.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/service/recurring_transaction_service.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/service/app_navigation_coordinator.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class CashflowForecastWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const CashflowForecastWidget({super.key, required this.def});

  @override
  State<CashflowForecastWidget> createState() => _CashflowForecastWidgetState();
}

class _CashflowForecastWidgetState extends State<CashflowForecastWidget> {
  final _walletService = WalletService();
  final _recurringService = RecurringTransactionService();

  StreamSubscription? _walletSub;
  StreamSubscription? _recurringSub;

  List<Wallet> _wallets = [];
  List<RecurringTransaction> _recurringItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _walletSub = _walletService.stream.listen((w) {
      if (mounted) setState(() => _wallets = w);
    });
    _recurringSub = _recurringService.stream.listen((r) {
      if (mounted) setState(() => _recurringItems = r);
    });
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _recurringSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final wallets = await _walletService.fetchWallets();
    final items = await _recurringService.fetchRecurringTransactions();
    if (mounted) {
      setState(() {
        _wallets = wallets;
        _recurringItems = items;
        _isLoading = false;
      });
    }
  }

  double get _currentBalance {
    return _wallets.fold(0.0, (sum, w) => sum + w.currentBalance);
  }

  // Previsioni per i prossimi 7 giorni (da oggi a oggi+6)
  List<_DailyForecast> _compute7DaysForecast() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeItems = _recurringItems.where((i) => i.isActive).toList();

    List<_DailyForecast> forecast = [];
    double runningBalance = _currentBalance;

    for (int i = 0; i < 7; i++) {
      final day = today.add(Duration(days: i));
      double income = 0.0;
      double expense = 0.0;
      List<RecurringTransaction> dayItems = [];

      for (final item in activeItems) {
        final due = DateTime(item.nextDueDate.year, item.nextDueDate.month, item.nextDueDate.day);
        if (due.isAtSameMomentAs(day)) {
          dayItems.add(item);
          if (item.isIncome) {
            income += item.amount;
          } else {
            expense += item.amount;
          }
        }
      }

      runningBalance = runningBalance + income - expense;

      forecast.add(_DailyForecast(
        date: day,
        income: income,
        expense: expense,
        projectedBalance: runningBalance,
        items: dayItems,
      ));
    }

    return forecast;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final forecast = _compute7DaysForecast();
    final endBalance = forecast.isNotEmpty ? forecast.last.projectedBalance : _currentBalance;
    final delta = endBalance - _currentBalance;
    final totalIncomes = forecast.fold(0.0, (s, f) => s + f.income);
    final totalExpenses = forecast.fold(0.0, (s, f) => s + f.expense);

    final isPanoramic = size.crossAxisCellCount >= 3;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: size,
      isLoading: _isLoading,
      onTap: () => AppNavigationCoordinator().navigateToEconomy(context, section: 'recurring'),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isPanoramic
            ? _buildPanoramicView(forecast, endBalance, delta, totalIncomes, totalExpenses)
            : _buildExpandedView(forecast, endBalance, delta, totalIncomes, totalExpenses),
      ),
    );
  }

  // Taglia 2x3 (Altezza 3, Due Livelli a Confronto)
  Widget _buildExpandedView(
    List<_DailyForecast> forecast,
    double endBalance,
    double delta,
    double totalIncomes,
    double totalExpenses,
  ) {
    Color safetyColor;
    String safetyLabel;

    if (endBalance < 0) {
      safetyColor = AppTheme.error;
      safetyLabel = 'Rischio scoperto';
    } else if (delta < -300) {
      safetyColor = const Color(0xFFF59E0B);
      safetyLabel = 'Uscite pesanti';
    } else if (delta >= 0) {
      safetyColor = const Color(0xFF10B981);
      safetyLabel = 'In crescita';
    } else {
      safetyColor = const Color(0xFF38BDF8);
      safetyLabel = 'Stabile';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Cashflow 7 Giorni',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: safetyColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: safetyColor.withOpacity(0.4)),
              ),
              child: Text(
                safetyLabel,
                style: TextStyle(color: safetyColor, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Livello 1: Saldo a +7 giorni e Delta
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A).withOpacity(0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STIMA A +7 GG', style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(
                    '€ ${endBalance.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: endBalance >= 0 ? Colors.white : AppTheme.error,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('VARIAZIONE', style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(
                    '${delta >= 0 ? '+' : ''}€ ${delta.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: delta >= 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Livello 2: Timeline a 7 tacche (Oggi -> +6gg)
        const Text(
          'TIMELINE SCADENZE DELLA SETTIMANA',
          style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.6),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: forecast.map((f) {
            final isToday = f.date.day == DateTime.now().day;
            final dayLetter = DateFormat('E', 'it').format(f.date).substring(0, 1).toUpperCase();
            final hasIncome = f.income > 0;
            final hasExpense = f.expense > 0;

            Color dotColor = Colors.white12;
            if (hasIncome && hasExpense) {
              dotColor = const Color(0xFF8B5CF6);
            } else if (hasIncome) {
              dotColor = const Color(0xFF10B981);
            } else if (hasExpense) {
              dotColor = const Color(0xFFEF4444);
            }

            return Column(
              children: [
                Text(
                  dayLetter,
                  style: TextStyle(
                    color: isToday ? const Color(0xFF38BDF8) : Colors.white60,
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(dotColor == Colors.white12 ? 0.2 : 0.8),
                    shape: BoxShape.circle,
                    border: isToday ? Border.all(color: const Color(0xFF38BDF8), width: 1.5) : null,
                  ),
                  alignment: Alignment.center,
                  child: (hasIncome || hasExpense)
                      ? Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        )
                      : null,
                ),
                const SizedBox(height: 3),
                Text(
                  '${f.date.day}',
                  style: const TextStyle(color: Colors.white38, fontSize: 8.5),
                ),
              ],
            );
          }).toList(),
        ),

        const Spacer(),

        // Summary bar Entrate vs Uscite
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('+€ ${totalIncomes.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
            Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('-€ ${totalExpenses.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Taglia 4x2 (Panoramico Orizzontale a Due Colonne)
  Widget _buildPanoramicView(
    List<_DailyForecast> forecast,
    double endBalance,
    double delta,
    double totalIncomes,
    double totalExpenses,
  ) {
    final upcomingItems = forecast
        .expand((f) => f.items)
        .take(2)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Colonna Sinistra: Saldo Oggi vs +7gg e Variazione
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'CASHFLOW A 7 GIORNI',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo Oggi', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
                      Text('€ ${_currentBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF38BDF8)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Stima +7gg', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
                      Text('€ ${endBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (delta >= 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Variazione netta: ${delta >= 0 ? '+' : ''}€ ${delta.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: delta >= 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),
        Container(width: 1, color: Colors.white.withOpacity(0.08)),
        const SizedBox(width: 12),

        // Colonna Destra: Prossimi movimenti
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROSSIMI MOVIMENTI',
                style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
              ),
              if (upcomingItems.isEmpty)
                const Center(
                  child: Text('Nessuna scadenza nei 7gg', style: TextStyle(color: Colors.white38, fontSize: 11)),
                )
              else
                ...upcomingItems.map((item) {
                  return Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.isIncome ? '+' : '-'}€ ${item.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: item.isIncome ? const Color(0xFF10B981) : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entrate: +€${totalIncomes.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w600)),
                  Text('Uscite: -€${totalExpenses.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyForecast {
  final DateTime date;
  final double income;
  final double expense;
  final double projectedBalance;
  final List<RecurringTransaction> items;

  _DailyForecast({
    required this.date,
    required this.income,
    required this.expense,
    required this.projectedBalance,
    required this.items,
  });
}
