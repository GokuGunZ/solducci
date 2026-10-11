import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/features/csv_importer/views/widgets/staging_card.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/investment_portfolio.dart';
import 'package:solducci/theme/app_theme.dart';

class MonthlyAccordionSection extends StatelessWidget {
  final DateTime monthDate;
  final List<StagingTransaction> transactions;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool> onSelectAllMonth;
  final List<ExpenseGroup> availableGroups;
  final List<InvestmentPortfolio> availablePortfolios;

  // Callbacks per le singole card
  final ValueChanged<StagingTransaction> onToggleCardSelection;
  final void Function(StagingTransaction, Tipologia) onCategoryChanged;
  final void Function(StagingTransaction, IncomeCategory)? onIncomeCategoryChanged;
  final void Function(StagingTransaction, String) onNameEdited;
  final ValueChanged<StagingTransaction> onAlignWithExisting;
  final ValueChanged<StagingTransaction> onOpenContextPicker;
  final ValueChanged<StagingTransaction>? onOpenVolumeSplit;
  final void Function(StagingTransaction, String?)? onPortfolioChanged;
  final ValueChanged<StagingTransaction>? onDismissTransaction;

  const MonthlyAccordionSection({
    super.key,
    required this.monthDate,
    required this.transactions,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSelectAllMonth,
    required this.availableGroups,
    required this.availablePortfolios,
    required this.onToggleCardSelection,
    required this.onCategoryChanged,
    this.onIncomeCategoryChanged,
    required this.onNameEdited,
    required this.onAlignWithExisting,
    required this.onOpenContextPicker,
    this.onOpenVolumeSplit,
    this.onPortfolioChanged,
    this.onDismissTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy', 'it_IT').format(monthDate);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final expenses = transactions.where((t) => !t.isIncome).toList();
    final incomes = transactions.where((t) => t.isIncome).toList();

    final expensesTotal = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final incomesTotal = incomes.fold(0.0, (sum, t) => sum + t.amount);

    final selectedCount = transactions.where((t) => t.isSelected).length;
    final totalCount = transactions.length;

    // Checkbox Tri-State: true (tutti), null (parziale), false (nessuno)
    final bool? triStateValue = totalCount == 0
        ? false
        : selectedCount == totalCount
            ? true
            : selectedCount > 0
                ? null
                : false;

    final groupCount = transactions.where((t) => t.groupId != null).length;
    final duplicateCount = transactions.where((t) => t.isDuplicate).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF10B981).withOpacity(0.3)
              : Colors.white.withOpacity(0.07),
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Accordion Mese
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Checkbox Tri-State Mese
                      Transform.scale(
                        scale: 1.15,
                        child: Checkbox(
                          value: triStateValue,
                          tristate: true,
                          activeColor: AppTheme.success,
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white38, width: 1.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (val) {
                            // Se era parziale o non selezionato -> seleziona tutto. Se era tutto -> deseleziona.
                            final shouldSelectAll = triStateValue != true;
                            onSelectAllMonth(shouldSelectAll);
                          },
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Titolo Mese
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  capitalizedMonth,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$totalCount voci',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Subtotali Spese / Entrate
                            Row(
                              children: [
                                if (expenses.isNotEmpty) ...[
                                  Text(
                                    '-€ ${expensesTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (incomes.isNotEmpty)
                                    const Text('  •  ', style: TextStyle(color: Colors.white24, fontSize: 12)),
                                ],
                                if (incomes.isNotEmpty) ...[
                                  Text(
                                    '+€ ${incomesTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Chevron animato
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 250),
                        turns: isExpanded ? 0.5 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Mini Badge Contestuali del Mese (se presenti)
                  if (groupCount > 0 || duplicateCount > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 44), // allineato con il testo
                        if (groupCount > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.group_rounded, color: Color(0xFFA78BFA), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '$groupCount in gruppo',
                                  style: const TextStyle(
                                    color: Color(0xFFA78BFA),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (duplicateCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '$duplicateCount duplicati',
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 2. Body Espanso con Lista Transazioni del Mese
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'Tutti i movimenti di questo mese sono stati importati! ✨',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final tx = transactions[index];
                    return Stack(
                      children: [
                        StagingCard(
                          transaction: tx,
                          availableGroups: availableGroups,
                          availablePortfolios: availablePortfolios,
                          onToggleSelection: (_) => onToggleCardSelection(tx),
                          onCategoryChanged: (cat) => onCategoryChanged(tx, cat),
                          onIncomeCategoryChanged: onIncomeCategoryChanged != null
                              ? (incCat) => onIncomeCategoryChanged!(tx, incCat)
                              : null,
                          onNameEdited: (name) => onNameEdited(tx, name),
                          onAlignWithExisting: () => onAlignWithExisting(tx),
                          onOpenContextPicker: () => onOpenContextPicker(tx),
                          onOpenVolumeSplit: onOpenVolumeSplit != null
                              ? () => onOpenVolumeSplit!(tx)
                              : null,
                          onPortfolioChanged: onPortfolioChanged != null
                              ? (pId) => onPortfolioChanged!(tx, pId)
                              : null,
                        ),
                        // Pulsante rapido Scarta singolo movimento in alto a destra
                        if (onDismissTransaction != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white30),
                              tooltip: 'Scarta dalla bozza',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => onDismissTransaction!(tx),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
