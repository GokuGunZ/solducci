import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_skeleton.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MonthlyBurnRateWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const MonthlyBurnRateWidget({super.key, required this.def});

  @override
  State<MonthlyBurnRateWidget> createState() => _MonthlyBurnRateWidgetState();
}

class _MonthlyBurnRateWidgetState extends State<MonthlyBurnRateWidget> {
  @override
  Widget build(BuildContext context) {
    final currentContext = DashboardContextScope.of(context);

    return StreamBuilder<List<Expense>>(
      stream: ExpenseServiceCached().stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return BentoWidgetContainer(
            heroTag: widget.def.id,
            size: widget.def.size,
            skeletonType: BentoSkeletonType.chart,
            isLoading: true,
            onExpand: () {
              GoRouter.of(context).push('/economy/charts', extra: {'heroTag': widget.def.id});
            },
            child: const SizedBox.shrink(),
          );
        }

        final allExpenses = snapshot.data ?? [];
        final userId = Supabase.instance.client.auth.currentUser?.id;
        final targetCategory = widget.def.customProps?['category'] as String?;

        // Filter expenses by context and category
        final expenses = allExpenses.where((e) {
          if (currentContext.isGroup) {
            if (e.groupId != currentContext.groupId) return false;
              } else if (currentContext.isPersonal) {
                if (e.userId != userId || e.groupId != null) return false;
              }
              if (targetCategory != null && e.type.name.toLowerCase() != targetCategory.toLowerCase()) {
                return false;
              }
              return true;
            }).toList();

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

            final isWide = widget.def.size.crossAxisCellCount >= 3;
            final isHeight3 = widget.def.size.mainAxisCellCount >= 3;
            final hasNoExpenses = currentMonthTotal == 0.0 && avgLast3Months == 0.0;

            // Calcolo metriche per H3 e Panoramico
            final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
            final currentDay = now.day;
            final daysRemaining = (daysInMonth - currentDay) + 1;
            final remainingBudget = (avgLast3Months - currentMonthTotal).clamp(0.0, double.infinity);
            final dailyAllowance = daysRemaining > 0 ? (remainingBudget / daysRemaining) : 0.0;

            // Sparkline ultimi 7 giorni
            final List<double> last7DaysExpenses = List.filled(7, 0.0);
            final List<String> last7DaysLabels = [];
            const italianDays = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
            for (int i = 6; i >= 0; i--) {
              final targetDate = now.subtract(Duration(days: i));
              final dayTotal = expenses.where((e) =>
                e.date.year == targetDate.year &&
                e.date.month == targetDate.month &&
                e.date.day == targetDate.day
              ).fold(0.0, (sum, e) => sum + e.amount);
              last7DaysExpenses[6 - i] = dayTotal;
              last7DaysLabels.add(italianDays[targetDate.weekday - 1]);
            }
            final maxDayExpense = last7DaysExpenses.fold(0.0, (m, v) => v > m ? v : m);

            final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');

            return BentoWidgetContainer(
              heroTag: widget.def.id,
              size: widget.def.size,
              isLoading: false,
              onExpand: () {
                GoRouter.of(context).push('/economy/charts', extra: {'heroTag': widget.def.id});
              },
              child: hasNoExpenses
                  ? BentoEmptyState(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Nessuna spesa',
                      subtitle: 'Registra un\'uscita per calcolare il burn rate',
                      color: const Color(0xFFE068F1),
                      actionLabel: 'Aggiungi Spesa',
                      onAction: () => GoRouter.of(context).push('/expenses/add'),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFFE068F1).withOpacity(0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: isWide ? 14.0 : 12.0,
                          ),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Left column: Values & Ratio
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            targetCategory != null
                                                ? 'BURN RATE (${targetCategory.toUpperCase()})'
                                                : 'BURN RATE MENSILE',
                                            style: TextStyle(
                                              color: const Color(0xFFE068F1).withOpacity(0.85),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            formatter.format(currentMonthTotal),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Media 3 mesi: ${formatter.format(avgLast3Months)}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Right column: Daily allowance & Days remaining
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'BUDGET GIORNALIERO',
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                                Text(
                                                  '$daysRemaining gg restanti',
                                                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${formatter.format(dailyAllowance)}/gg',
                                              style: TextStyle(
                                                color: dailyAllowance > 0 ? const Color(0xFF10B981) : Colors.redAccent,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                              value: displayRatio,
                                              backgroundColor: Colors.white10,
                                              color: ratio > 1.0 ? Colors.redAccent : const Color(0xFFE068F1),
                                              borderRadius: BorderRadius.circular(4),
                                              minHeight: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : isHeight3
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Livello 1: Macroscopico (Burn rate e stato mese)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              targetCategory != null
                                                  ? 'BURN RATE (${targetCategory.toUpperCase()})'
                                                  : 'BURN RATE',
                                              style: TextStyle(
                                                color: const Color(0xFFE068F1).withOpacity(0.85),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (ratio > 1.0 ? Colors.redAccent : const Color(0xFF10B981)).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    ratio > 1.0 ? Icons.trending_up : Icons.trending_down,
                                                    color: ratio > 1.0 ? Colors.redAccent : const Color(0xFF10B981),
                                                    size: 11,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '${(displayRatio * 100).toInt()}%',
                                                    style: TextStyle(
                                                      color: ratio > 1.0 ? Colors.redAccent : const Color(0xFF10B981),
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatter.format(currentMonthTotal),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'Media 3 mesi: ${formatter.format(avgLast3Months)}',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: displayRatio,
                                          backgroundColor: Colors.white10,
                                          color: ratio > 1.0 ? Colors.redAccent : const Color(0xFFE068F1),
                                          borderRadius: BorderRadius.circular(3),
                                          minHeight: 4,
                                        ),
                                        const SizedBox(height: 8),
                                        // Divider discreto
                                        Container(height: 0.8, color: Colors.white.withOpacity(0.08)),
                                        const SizedBox(height: 6),

                                        // Livello 2: Microscopico (Budget Giornaliero & Sparkline 7 Giorni)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            const Text(
                                              'TARGET GIORNALIERO',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            Text(
                                              '${formatter.format(dailyAllowance)}/gg',
                                              style: TextStyle(
                                                color: dailyAllowance > 0 ? const Color(0xFF10B981) : Colors.redAccent,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // 7 barrette verticali sparkline
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: List.generate(7, (index) {
                                              final val = last7DaysExpenses[index];
                                              final label = last7DaysLabels[index];
                                              final isToday = index == 6;
                                              final double barHeightRatio = maxDayExpense > 0
                                                  ? (val / maxDayExpense).clamp(0.05, 1.0)
                                                  : 0.05;
                                              final isExceeding = dailyAllowance > 0 && val > dailyAllowance;

                                              return Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Expanded(
                                                    child: Align(
                                                      alignment: Alignment.bottomCenter,
                                                      child: Container(
                                                        width: 14,
                                                        height: barHeightRatio * 32,
                                                        decoration: BoxDecoration(
                                                          color: val == 0
                                                              ? Colors.white.withOpacity(0.05)
                                                              : isExceeding
                                                                  ? Colors.redAccent.withOpacity(0.85)
                                                                  : (isToday ? const Color(0xFFE068F1) : const Color(0xFFE068F1).withOpacity(0.4)),
                                                          borderRadius: BorderRadius.circular(3),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    label,
                                                    style: TextStyle(
                                                      color: isToday ? Colors.white : Colors.white38,
                                                      fontSize: 9,
                                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              targetCategory != null
                                                  ? 'BURN RATE (${targetCategory.toUpperCase()})'
                                                  : 'BURN RATE',
                                              style: TextStyle(
                                                color: const Color(0xFFE068F1).withOpacity(0.8),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            Icon(
                                              ratio > 1.0 ? Icons.trending_up : Icons.trending_down,
                                              color: ratio > 1.0 ? Colors.redAccent : const Color(0xFFE068F1),
                                              size: 15,
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              formatter.format(currentMonthTotal),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Media 3 mesi: ${formatter.format(avgLast3Months)}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${(displayRatio * 100).toInt()}% speso',
                                                  style: TextStyle(
                                                    color: ratio > 1.0 ? Colors.redAccent : const Color(0xFFE068F1),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '$daysRemaining gg rimasti',
                                                  style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            LinearProgressIndicator(
                                              value: displayRatio,
                                              backgroundColor: Colors.white10,
                                              color: ratio > 1.0 ? Colors.redAccent : const Color(0xFFE068F1),
                                              borderRadius: BorderRadius.circular(3),
                                              minHeight: 4,
                                            ),
                                          ],
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
