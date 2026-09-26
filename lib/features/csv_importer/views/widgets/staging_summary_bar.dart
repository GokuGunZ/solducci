import 'package:flutter/material.dart';
import 'package:solducci/theme/app_theme.dart';

class StagingSummaryBar extends StatelessWidget {
  final int selectedCount;
  final int selectedExpensesCount;
  final int selectedIncomesCount;
  final double totalExpenses;
  final double totalIncomes;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback? onBatchContext;

  const StagingSummaryBar({
    super.key,
    required this.selectedCount,
    this.selectedExpensesCount = 0,
    this.selectedIncomesCount = 0,
    this.totalExpenses = 0.0,
    this.totalIncomes = 0.0,
    required this.isLoading,
    required this.onConfirm,
    this.onBatchContext,
  });

  @override
  Widget build(BuildContext context) {
    final net = totalIncomes - totalExpenses;
    final hasBoth = selectedExpensesCount > 0 && selectedIncomesCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Riepilogo a sinistra
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasBoth
                        ? '$selectedExpensesCount spese • $selectedIncomesCount entrate'
                        : (selectedIncomesCount > 0
                            ? '$selectedIncomesCount entrate selezionate'
                            : '$selectedExpensesCount spese selezionate'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        hasBoth
                            ? (net >= 0 ? '+€ ${net.toStringAsFixed(2)}' : '-€ ${(-net).toStringAsFixed(2)}')
                            : (selectedIncomesCount > 0
                                ? '+€ ${totalIncomes.toStringAsFixed(2)}'
                                : '-€ ${totalExpenses.toStringAsFixed(2)}'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: (hasBoth && net >= 0) || selectedIncomesCount > 0 && selectedExpensesCount == 0
                              ? AppTheme.success
                              : Colors.white,
                        ),
                      ),
                      if (hasBoth) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Netto',
                            style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Pulsante rapido Assegna Contesto Gruppo (se ci sono spese di gruppo selezionabili)
            if (onBatchContext != null && selectedExpensesCount > 0) ...[
              IconButton(
                onPressed: onBatchContext,
                tooltip: 'Assegna Contesto ($selectedExpensesCount spese)',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF27272A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.group_work_rounded, color: Color(0xFF818CF8), size: 22),
              ),
              const SizedBox(width: 8),
            ],

            // Pulsante Importa a destra
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (selectedCount > 0 && !isLoading) ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white30,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_done_rounded, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            selectedCount > 0 ? 'Importa ($selectedCount)' : 'Importa',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
