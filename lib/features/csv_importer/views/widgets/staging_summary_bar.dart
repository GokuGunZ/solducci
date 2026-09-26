import 'package:flutter/material.dart';
import 'package:solducci/theme/app_theme.dart';

class StagingSummaryBar extends StatelessWidget {
  final int selectedCount;
  final double selectedTotal;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback? onBatchContext;

  const StagingSummaryBar({
    super.key,
    required this.selectedCount,
    required this.selectedTotal,
    required this.isLoading,
    required this.onConfirm,
    this.onBatchContext,
  });

  @override
  Widget build(BuildContext context) {
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
                    '$selectedCount spese selezionate',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '€ ${selectedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Pulsante rapido Assegna Contesto (se ci sono spese selezionate)
            if (onBatchContext != null && selectedCount > 0) ...[
              IconButton(
                onPressed: onBatchContext,
                tooltip: 'Assegna Contesto ($selectedCount selezionate)',
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
                  padding: const EdgeInsets.symmetric(horizontal: 22),
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
                        children: const [
                          Icon(Icons.download_done_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Importa Spese',
                            style: TextStyle(
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
