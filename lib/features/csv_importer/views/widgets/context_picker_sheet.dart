import 'package:flutter/material.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/theme/app_theme.dart';

class ContextPickerSheet extends StatelessWidget {
  final List<ExpenseGroup> groups;
  final String? currentGroupId;
  final int count; // Quante spese si stanno modificando (1 o N)
  final ValueChanged<String?> onContextSelected; // null = Personale

  const ContextPickerSheet({
    super.key,
    required this.groups,
    required this.currentGroupId,
    this.count = 1,
    required this.onContextSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Handle bar
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
            const SizedBox(height: 18),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.hub_rounded, color: Color(0xFF6366F1), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count > 1 ? 'Contesto ($count spese)' : 'Contesto Spesa',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Personale o condivisa con un gruppo',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Opzione 1: Personale (default)
            _buildOptionTile(
              context: context,
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Personale',
              subtitle: 'Spesa tua individuale (nessuna divisione)',
              isSelected: currentGroupId == null,
              onTap: () {
                Navigator.pop(context);
                onContextSelected(null);
              },
            ),

            const SizedBox(height: 10),

            // Separatore o header gruppi
            if (groups.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  'I TUOI GRUPPI',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                  ),
                ),
              ),

              // Lista gruppi
              ...groups.map((group) {
                final isSelected = currentGroupId == group.id;
                final membersCount = group.memberCount ?? group.members?.length ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildOptionTile(
                    context: context,
                    icon: Icons.group_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: group.name,
                    subtitle: membersCount > 0 ? '$membersCount membri • Divisa di default' : 'Gruppo di spesa',
                    isSelected: isSelected,
                    initials: group.initials,
                    onTap: () {
                      Navigator.pop(context);
                      onContextSelected(group.id);
                    },
                  ),
                );
              }),
            ] else ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white38, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nessun gruppo trovato. Crea un gruppo in Solducci per condividere le spese.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    String? initials,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.12) : const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor.withOpacity(0.4) : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: initials != null && initials.isNotEmpty
                  ? Text(
                      initials,
                      style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14),
                    )
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: iconColor, size: 22)
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
