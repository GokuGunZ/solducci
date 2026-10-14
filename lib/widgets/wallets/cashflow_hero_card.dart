import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/service/cashflow_service.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/theme/app_theme.dart';

class CashflowHeroCard extends StatefulWidget {
  final bool isGroupContext;

  const CashflowHeroCard({
    super.key,
    this.isGroupContext = false,
  });

  @override
  State<CashflowHeroCard> createState() => _CashflowHeroCardState();
}

class _CashflowHeroCardState extends State<CashflowHeroCard> {
  DateTime _selectedMonth = DateTime.now();

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    // Genera gli ultimi 12 mesi
    final months = List.generate(12, (index) {
      return DateTime(now.year, now.month - index, 1);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141417),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Seleziona Mese',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    itemCount: months.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, i) {
                      final m = months[i];
                      final isCurrent = m.year == _selectedMonth.year && m.month == _selectedMonth.month;
                      final label = DateFormat('MMMM yyyy', 'it_IT').format(m);
                      final formattedLabel = label[0].toUpperCase() + label.substring(1);

                      return ListTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedMonth = m;
                          });
                        },
                        leading: Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: isCurrent ? const Color(0xFF10B981) : Colors.white38,
                        ),
                        title: Text(
                          formattedLabel,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white70,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 18)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: WalletService().stream,
      builder: (context, snapshot) {
        final summary = CashflowService().getSummaryForMonth(_selectedMonth);
        final monthName = DateFormat('MMMM yyyy', 'it_IT').format(_selectedMonth);
        final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);

        final isPositive = summary.monthlyCashflow >= 0;
        final savingsColor = isPositive ? AppTheme.success : AppTheme.error;

        // Se siamo in un gruppo, risaltiamo la card con contorno viola ametista e badge PERSONALE
        final borderColor = widget.isGroupContext
            ? const Color(0xFF8B5CF6).withOpacity(0.5)
            : Colors.white12;

        final cardGlow = widget.isGroupContext
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                )
              ]
            : null;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: widget.isGroupContext ? 1.4 : 1.0),
            boxShadow: cardGlow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= RIGA SUPERIORE: TITOLO & BADGE =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PATRIMONIO NETTO TOTALE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.isGroupContext)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_rounded, size: 12, color: Color(0xFF8B5CF6)),
                          SizedBox(width: 4),
                          Text(
                            'PERSONALE',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Totale Net Worth
              Text(
                '€ ${summary.totalNetWorth.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Suddivisione Patrimonio: Liquido vs Investito
              Row(
                children: [
                  // Liquido
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 13, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Liquido: €${summary.liquidNetWorth.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Investito
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, size: 13, color: Color(0xFF818CF8)),
                      const SizedBox(width: 4),
                      Text(
                        'Investito: €${summary.investedNetWorth.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ================= DIVISORE CON CHIP MESE SELEZIONABILE =================
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10, height: 1)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showMonthPicker(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 13, color: widget.isGroupContext ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            formattedMonth,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.white54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Divider(color: Colors.white10, height: 1)),
                ],
              ),

              const SizedBox(height: 14),

              // ================= PARTE INFERIORE: METRICHE DEL MESE =================
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
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),

                  // Consumi Mese
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Consumi', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '-€${summary.monthlyExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),

                  // Investiti Mese (se presenti)
                  if (summary.monthlyInvested > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Investiti', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          '€${summary.monthlyInvested.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),

                  // Delta (+/-) e Risparmio
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
                          size: 15,
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
                                '${summary.savingsRatePercent.toStringAsFixed(0)}% delta',
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
