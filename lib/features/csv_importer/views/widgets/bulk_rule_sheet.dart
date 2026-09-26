import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/views/widgets/category_picker_sheet.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/theme/app_theme.dart';

class BulkRuleSheet extends StatelessWidget {
  final String detectedPattern;
  final String proposedName;
  final Tipologia proposedCategory;
  final int similarCount;
  final VoidCallback onApplyToAllAndSaveRule;
  final VoidCallback onApplyOnlyToCurrent;

  const BulkRuleSheet({
    super.key,
    required this.detectedPattern,
    required this.proposedName,
    required this.proposedCategory,
    required this.similarCount,
    required this.onApplyToAllAndSaveRule,
    required this.onApplyOnlyToCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryPickerSheet.getColor(proposedCategory);
    final catIcon = CategoryPickerSheet.getIcon(proposedCategory);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: AppTheme.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Regola Intelligente Trovata',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Trovate altre $similarCount transazioni simili nel file',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF27272A).withOpacity(0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pattern causale:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      Flexible(
                        child: Text(
                          '"$detectedPattern"',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nuovo nome:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      Text(
                        proposedName,
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Categoria:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      Row(
                        children: [
                          Icon(catIcon, size: 16, color: catColor),
                          const SizedBox(width: 6),
                          Text(
                            proposedCategory.label,
                            style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onApplyToAllAndSaveRule();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Applica a tutte ($similarCount) e ricorda regola',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onApplyOnlyToCurrent();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Modifica solo questa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
