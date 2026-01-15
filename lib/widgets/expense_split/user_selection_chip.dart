import 'package:flutter/material.dart';
import 'package:solducci/models/group.dart';

/// Chip per selezionare un utente (usato nella sezione "Chi paga")
///
/// Design:
/// - Compact chip con avatar circolare
/// - Nickname utente
/// - Selectable con border highlight quando selezionato
/// - Badge "Admin" se applicabile
///
/// Stati:
/// - Non selezionato: Background grigio chiaro, border grigio
/// - Selezionato: Background verde chiaro, border verde bold
class UserSelectionChip extends StatelessWidget {
  final GroupMember member;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showAdminBadge;

  const UserSelectionChip({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onTap,
    this.showAdminBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? Colors.green.shade50
        : Colors.grey.shade100;

    final borderColor = isSelected
        ? Colors.green.shade600
        : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 14,
              backgroundColor: isSelected
                  ? Colors.green.shade200
                  : Colors.blue.shade200,
              child: Text(
                member.initials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.green.shade900
                      : Colors.blue.shade900,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Nickname
            Flexible(
              child: Text(
                member.nickname ?? member.email ?? 'Unknown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.green.shade900
                      : Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Admin badge
            if (showAdminBadge && member.role == GroupRole.admin) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
