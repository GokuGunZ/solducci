import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/models/expense.dart';
import 'package:intl/intl.dart';

class MonthlyBurnRateWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const MonthlyBurnRateWidget({super.key, required this.def});

  @override
  State<MonthlyBurnRateWidget> createState() => _MonthlyBurnRateWidgetState();
}

class _MonthlyBurnRateWidgetState extends State<MonthlyBurnRateWidget> {
  late Stream<List<Expense>> _expenseStream;

  @override
  void initState() {
    super.initState();
    _expenseStream = ExpenseServiceCached().stream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Expense>>(
      stream: _expenseStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return BentoWidgetContainer(
            heroTag: widget.def.id,
            isLoading: true,
            onExpand: () {
              GoRouter.of(context).push('/economy/charts', extra: {'heroTag': widget.def.id});
            },
            child: const Center(child: CircularProgressIndicator(color: Color(0xFFE068F1))),
          );
        }

          final expenses = snapshot.data ?? [];
          
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          
          double currentMonthTotal = 0;
          double last3MonthsTotal = 0;

          for (final e in expenses) {
            if (e.date.year == currentMonth.year && e.date.month == currentMonth.month) {
              currentMonthTotal += e.amount;
            } else if (e.date.isAfter(DateTime(now.year, now.month - 3)) && e.date.isBefore(currentMonth)) {
              last3MonthsTotal += e.amount;
            }
          }

          final avgLast3Months = last3MonthsTotal / 3.0;
          final ratio = avgLast3Months > 0 ? (currentMonthTotal / avgLast3Months) : (currentMonthTotal > 0 ? 1.0 : 0.0);
          final displayRatio = ratio > 1.0 ? 1.0 : ratio;

          final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');

          return BentoWidgetContainer(
            heroTag: widget.def.id,
            isLoading: false,
            onExpand: () {
              GoRouter.of(context).push('/economy/charts', extra: {'heroTag': widget.def.id});
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFE068F1).withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BURN RATE',
                            style: TextStyle(
                              color: const Color(0xFFE068F1).withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Icon(
                            ratio > 1.0 ? Icons.trending_up : Icons.trending_down, 
                            color: ratio > 1.0 ? Colors.redAccent : const Color(0xFFE068F1), 
                            size: 16
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        formatter.format(currentMonthTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Media ultimi 3 mesi: ${formatter.format(avgLast3Months)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: displayRatio,
                        backgroundColor: Colors.white10,
                        color: ratio > 1.0 ? Colors.redAccent : const Color(0xFFE068F1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
      },
    );
  }
}
