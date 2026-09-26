import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/features/csv_importer/views/widgets/category_picker_sheet.dart';
import 'package:solducci/features/csv_importer/views/widgets/income_category_picker_sheet.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/investment_portfolio.dart';
import 'package:solducci/theme/app_theme.dart';

class StagingCard extends StatelessWidget {
  final StagingTransaction transaction;
  final List<ExpenseGroup> availableGroups;
  final List<InvestmentPortfolio> availablePortfolios;
  final ValueChanged<bool> onToggleSelection;
  final ValueChanged<Tipologia> onCategoryChanged;
  final ValueChanged<IncomeCategory>? onIncomeCategoryChanged;
  final ValueChanged<String> onNameEdited;
  final VoidCallback onAlignWithExisting;
  final VoidCallback onOpenContextPicker;
  final VoidCallback? onOpenVolumeSplit;
  final ValueChanged<String?>? onPortfolioChanged;

  const StagingCard({
    super.key,
    required this.transaction,
    this.availableGroups = const [],
    this.availablePortfolios = const [],
    required this.onToggleSelection,
    required this.onCategoryChanged,
    this.onIncomeCategoryChanged,
    required this.onNameEdited,
    required this.onAlignWithExisting,
    required this.onOpenContextPicker,
    this.onOpenVolumeSplit,
    this.onPortfolioChanged,
  });

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: transaction.cleanDescription);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          transaction.isIncome ? 'Modifica Nome Entrata' : 'Modifica Nome Spesa',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: transaction.isIncome ? 'Es. Stipendio, Rimborso...' : 'Es. Conad, Bar Centrale...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF27272A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                onNameEdited(text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CategoryPickerSheet(
        currentCategory: transaction.category,
        onCategorySelected: onCategoryChanged,
      ),
    );
  }

  void _openIncomeCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => IncomeCategoryPickerSheet(
        currentCategory: transaction.incomeCategory,
        onCategorySelected: onIncomeCategoryChanged ?? (_) {},
      ),
    );
  }

  void _openPortfolioPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.isIncome ? 'Destinazione Rendita' : 'Destinazione Investimento',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Icon(Icons.trending_up_rounded, color: Color(0xFF818CF8)),
                ],
              ),
              const SizedBox(height: 16),
              if (availablePortfolios.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nessun portafoglio configurato in Solducci', style: TextStyle(color: Colors.white54, fontSize: 13)),
                )
              else
                ...availablePortfolios.map((p) {
                  final isSelected = p.id == transaction.portfolioId;
                  return InkWell(
                    onTap: () {
                      onPortfolioChanged?.call(p.id);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6366F1).withOpacity(0.18) : const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF818CF8) : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(p.iconData, size: 16, color: p.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                if (p.brokerName != null)
                                  Text(p.brokerName!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF818CF8), size: 18),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = transaction.isSelected;
    final isIncome = transaction.isIncome;
    final dateStr = DateFormat('dd MMM yyyy', 'it_IT').format(transaction.date);

    Color borderColor;
    if (transaction.duplicateStatus == DuplicateStatus.exactMatch) {
      borderColor = AppTheme.error.withOpacity(0.35);
    } else if (transaction.duplicateStatus == DuplicateStatus.fuzzyMatch) {
      borderColor = AppTheme.warning.withOpacity(0.4);
    } else if (isIncome) {
      borderColor = isSelected ? AppTheme.success.withOpacity(0.45) : AppTheme.success.withOpacity(0.18);
    } else if (isSelected) {
      borderColor = const Color(0xFF6366F1).withOpacity(0.35);
    } else {
      borderColor = Colors.white10;
    }

    final cardBgColor = isIncome
        ? (isSelected ? const Color(0xFF13221B) : const Color(0xFF141917))
        : (isSelected ? const Color(0xFF1E1E22) : const Color(0xFF141417));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => onToggleSelection(!isSelected),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Riga superiore: Checkbox, Titolo/Tag, Importo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Checkbox circolare
                    GestureDetector(
                      onTap: () => onToggleSelection(!isSelected),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? (isIncome ? AppTheme.success : const Color(0xFF6366F1))
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? (isIncome ? AppTheme.success : const Color(0xFF6366F1))
                                : Colors.white30,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Titolo modificabile con badge per Entrate
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEditNameDialog(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isIncome) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_downward_rounded, size: 10, color: AppTheme.success),
                                    SizedBox(width: 3),
                                    Text(
                                      'ENTRATA',
                                      style: TextStyle(
                                        color: AppTheme.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    transaction.cleanDescription,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.white54,
                                      decoration: !isSelected && transaction.duplicateStatus == DuplicateStatus.exactMatch
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_rounded, size: 14, color: Colors.white24),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Importo (+ in verde per entrate, - in bianco/rosso per spese)
                    Text(
                      '${isIncome ? '+' : '-'} €${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isIncome
                            ? AppTheme.success
                            : (isSelected ? Colors.white : Colors.white54),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Riga centrale: Data + Causale bancaria originale
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Row(
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.white24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.rawDescription,
                          style: const TextStyle(fontSize: 11, color: Colors.white30),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Riga inferiore: Chip Categoria + Contesto / Portafoglio + Badge Duplicati
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // SE ENTRATA: Chip Categoria Entrata (IncomeCategory)
                      if (isIncome) ...[
                        InkWell(
                          onTap: () => _openIncomeCategoryPicker(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: transaction.incomeCategory.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: transaction.incomeCategory.color.withOpacity(0.4), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(transaction.incomeCategory.icon, size: 14, color: transaction.incomeCategory.color),
                                const SizedBox(width: 6),
                                Text(
                                  transaction.incomeCategory.label,
                                  style: TextStyle(
                                    color: transaction.incomeCategory.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: transaction.incomeCategory.color),
                              ],
                            ),
                          ),
                        ),

                        // Se rendita/dividendo: Chip Portafoglio Rendita
                        if (transaction.incomeCategory == IncomeCategory.rendita) ...[
                          Builder(builder: (ctx) {
                            final portfolio = availablePortfolios
                                .where((p) => p.id == transaction.portfolioId)
                                .firstOrNull;
                            final pColor = transaction.incomeCategory.color;

                            return Container(
                              decoration: BoxDecoration(
                                color: pColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: pColor.withOpacity(0.4), width: 1),
                              ),
                              child: InkWell(
                                onTap: () => _openPortfolioPicker(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        portfolio?.iconData ?? Icons.trending_up_rounded,
                                        size: 13,
                                        color: pColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        portfolio?.name ?? 'Portafoglio Rendita',
                                        style: TextStyle(
                                          color: pColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: pColor),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ] else ...[
                        // SE SPESA: Chip Categoria Spesa (Tipologia)
                        Builder(builder: (ctx) {
                          final catColor = CategoryPickerSheet.getColor(transaction.category);
                          final catIcon = CategoryPickerSheet.getIcon(transaction.category);

                          return InkWell(
                            onTap: () => _openCategoryPicker(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: catColor.withOpacity(0.4), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(catIcon, size: 14, color: catColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    transaction.category.label,
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: catColor),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Chip Contesto Spesa (Personale vs Gruppo)
                        Builder(builder: (ctx) {
                          final isGroup = transaction.groupId != null;
                          final group = isGroup
                              ? availableGroups.where((g) => g.id == transaction.groupId).firstOrNull
                              : null;
                          final contextColor = isGroup ? const Color(0xFF818CF8) : const Color(0xFF10B981);
                          final hasCustomSplit = transaction.customSplitData != null;

                          return Container(
                            decoration: BoxDecoration(
                              color: contextColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: contextColor.withOpacity(0.35), width: 1),
                            ),
                            child: InkWell(
                              onTap: onOpenContextPicker,
                              onLongPress: isGroup ? onOpenVolumeSplit : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGroup ? Icons.group_rounded : Icons.person_rounded,
                                      size: 13,
                                      color: contextColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isGroup ? (group?.name ?? 'Gruppo') : 'Personale',
                                      style: TextStyle(
                                        color: contextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (isGroup) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        hasCustomSplit ? '• Custom' : '• Equa',
                                        style: TextStyle(
                                          color: contextColor.withOpacity(0.8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      GestureDetector(
                                        onTap: onOpenVolumeSplit,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: contextColor.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.tune_rounded, size: 11, color: contextColor),
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 2),
                                      Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: contextColor),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // Chip Portafoglio Investimento (se categoria == Investimento)
                        if (transaction.category == Tipologia.investimento) ...[
                          Builder(builder: (ctx) {
                            final portfolio = availablePortfolios
                                .where((p) => p.id == transaction.portfolioId)
                                .firstOrNull;
                            const pColor = Color(0xFF818CF8);

                            return Container(
                              decoration: BoxDecoration(
                                color: pColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: pColor.withOpacity(0.4), width: 1),
                              ),
                              child: InkWell(
                                onTap: () => _openPortfolioPicker(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        portfolio?.iconData ?? Icons.trending_up_rounded,
                                        size: 13,
                                        color: pColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        portfolio?.name ?? 'Scegli Portafoglio',
                                        style: const TextStyle(
                                          color: pColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: pColor),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],

                      // Badge Duplicato Esatto
                      if (transaction.duplicateStatus == DuplicateStatus.exactMatch)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 13, color: AppTheme.error),
                              SizedBox(width: 4),
                              Text(
                                'Già nel DB (esatta)',
                                style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                      // Badge Duplicato Fuzzy
                      if (transaction.duplicateStatus == DuplicateStatus.fuzzyMatch &&
                          transaction.matchedExistingExpense != null)
                        InkWell(
                          onTap: onAlignWithExisting,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sync_problem_rounded, size: 13, color: AppTheme.warning),
                                const SizedBox(width: 4),
                                Text(
                                  'Possibile duplicato (DB: €${transaction.matchedExistingExpense!.amount.toStringAsFixed(2)})',
                                  style: const TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
