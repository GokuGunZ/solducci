import 'package:flutter/material.dart';

/// Tipo di chip contesto
enum ContextChipType { personal, group, view }

/// Widget Chip riutilizzabile per selezionare contesti (Personal, Group, View)
class ContextChip extends StatelessWidget {
  final String id;
  final String label;
  final ContextChipType type;
  final bool isSelected;
  final bool includesPersonal;
  final VoidCallback onTap;
  final VoidCallback? onAddPersonalTap;

  const ContextChip({
    required this.id,
    required this.label,
    required this.type,
    required this.isSelected,
    this.includesPersonal = false,
    required this.onTap,
    this.onAddPersonalTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Icona in base al tipo
    final icon = type == ContextChipType.personal
        ? Icons.person
        : type == ContextChipType.view
            ? Icons.dashboard
            : Icons.group;

    // Colore in base al tipo e selezione
    final Color chipColor;
    final Color textColor;

    if (isSelected) {
      chipColor = type == ContextChipType.personal
          ? Colors.purple[700]!
          : type == ContextChipType.view
              ? Colors.blue[700]!
              : Colors.green[700]!;
      textColor = Colors.white;
    } else {
      chipColor = Colors.grey[100]!;
      textColor = Colors.grey[800]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? chipColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main chip area (tappable)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              topRight: onAddPersonalTap != null
                  ? Radius.zero
                  : Radius.circular(12),
              bottomRight: onAddPersonalTap != null
                  ? Radius.zero
                  : Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: textColor),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottone [+P] per gruppi e viste (non per Personale)
          if (onAddPersonalTap != null) ...[
            Container(
              width: 1,
              height: 24,
              color:
                  isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.grey[300],
            ),
            InkWell(
              onTap: onAddPersonalTap,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Icon(
                  includesPersonal ? Icons.person_remove : Icons.person_add,
                  size: 16,
                  color: includesPersonal
                      ? (isSelected ? Colors.white : Colors.green[700])
                      : (isSelected ? Colors.white70 : Colors.grey[600]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
