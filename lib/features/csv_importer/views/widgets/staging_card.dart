import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/features/csv_importer/views/widgets/category_picker_sheet.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/theme/app_theme.dart';

class StagingCard extends StatelessWidget {
  final StagingTransaction transaction;
  final ValueChanged<bool> onToggleSelection;
  final ValueChanged<Tipologia> onCategoryChanged;
  final ValueChanged<String> onNameEdited;
  final VoidCallback onAlignWithExisting;

  const StagingCard({
    super.key,
    required this.transaction,
    required this.onToggleSelection,
    required this.onCategoryChanged,
    required this.onNameEdited,
    required this.onAlignWithExisting,
  });

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: transaction.cleanDescription);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifica Nome Spesa', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Es. Conad, Bar Centrale...',
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

  @override
  Widget build(BuildContext context) {
    final isSelected = transaction.isSelected;
    final catColor = CategoryPickerSheet.getColor(transaction.category);
    final catIcon = CategoryPickerSheet.getIcon(transaction.category);
    final dateStr = DateFormat('dd MMM yyyy', 'it_IT').format(transaction.date);

    Color borderColor = Colors.white10;
    if (transaction.duplicateStatus == DuplicateStatus.exactMatch) {
      borderColor = AppTheme.error.withOpacity(0.3);
    } else if (transaction.duplicateStatus == DuplicateStatus.fuzzyMatch) {
      borderColor = AppTheme.warning.withOpacity(0.4);
    } else if (isSelected) {
      borderColor = AppTheme.success.withOpacity(0.25);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E1E22) : const Color(0xFF141417),
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
                // Riga superiore: Checkbox, Titolo, Importo
                Row(
                  children: [
                    // Checkbox circolare
                    GestureDetector(
                      onTap: () => onToggleSelection(!isSelected),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppTheme.success : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppTheme.success : Colors.white30,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.black)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Titolo modificabile
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEditNameDialog(context),
                        child: Row(
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
                      ),
                    ),

                    // Importo
                    Text(
                      '${transaction.isIncome ? '+' : '-'} €${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: transaction.isIncome
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

                // Riga inferiore: Chip Categoria + Badge Duplicati
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Chip Categoria interattivo
                      InkWell(
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
                      ),

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
