import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/service/cashflow_service.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/theme/app_theme.dart';

class CashflowHeroCard extends StatelessWidget {
  const CashflowHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: WalletService().stream,
      builder: (context, snapshot) {
        final now = DateTime.now();
        final summary = CashflowService().getSummaryForMonth(now);
        final monthName = DateFormat('MMMM yyyy', 'it_IT').format(now);

        final isPositive = summary.monthlyCashflow >= 0;
        final savingsColor = isPositive ? AppTheme.success : AppTheme.error;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Riga Titolo & Mese
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PATRIMONIO NETTO',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      monthName[0].toUpperCase() + monthName.substring(1),
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Totale Liquidità
              Text(
                '€ ${summary.totalNetWorth.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 14),

              // Griglia Cashflow del Mese (Entrate vs Spese vs Risparmio)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Entrate Mese
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Entrate', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '+€${summary.monthlyIncome.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),

                  // Uscite Mese
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Uscite', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '-€${summary.monthlyExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),

                  // Risparmio Netto & Tasso
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: savingsColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: savingsColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 16,
                          color: savingsColor,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isPositive ? '+' : ''}€${summary.monthlyCashflow.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: savingsColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (summary.monthlyIncome > 0)
                              Text(
                                '${summary.savingsRatePercent.toStringAsFixed(0)}% risparmio',
                                style: TextStyle(
                                  color: savingsColor.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
