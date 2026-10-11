import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/theme/app_theme.dart';

class StagingBatchToolbar extends StatelessWidget {
  final int selectedCount;
  final double selectedTotal;
  final bool isCommitting;
  final VoidCallback onDeselectAll;
  final VoidCallback onContextPressed;
  final VoidCallback onCategoryPressed;
  final VoidCallback onWalletPressed;
  final VoidCallback onDiscardPressed;
  final VoidCallback onCommitPressed;

  const StagingBatchToolbar({
    super.key,
    required this.selectedCount,
    required this.selectedTotal,
    this.isCommitting = false,
    required this.onDeselectAll,
    required this.onContextPressed,
    required this.onCategoryPressed,
    required this.onWalletPressed,
    required this.onDiscardPressed,
    required this.onCommitPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22).withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Riga Superiore: Contatore Selezionati & Deseleziona
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$selectedCount selezionati • € ${selectedTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDeselectAll,
                        child: const Text(
                          'Deseleziona',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Riga Azioni Batch Ortogonali
                  Row(
                    children: [
                      // Azione Contesto
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.group_rounded,
                          label: 'Contesto',
                          color: const Color(0xFF8B5CF6),
                          onTap: onContextPressed,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Azione Categoria
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.category_rounded,
                          label: 'Categoria',
                          color: const Color(0xFF3B82F6),
                          onTap: onCategoryPressed,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Azione Conto / Wallet
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Conto',
                          color: const Color(0xFFF59E0B),
                          onTap: onWalletPressed,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Azione Scarta
                      IconButton(
                        onPressed: onDiscardPressed,
                        tooltip: 'Scarta selezionati',
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444).withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Bottone Primario: Importa Selezionati
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isCommitting ? null : onCommitPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isCommitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.rocket_launch_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Importa $selectedCount Movimenti',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
