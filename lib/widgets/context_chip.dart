import 'package:flutter/material.dart';

/// Tipo di chip contesto
enum ContextChipType { personal, group, view, allGroups }

/// Widget Chip riutilizzabile per selezionare contesti (Personal, Group, View)
class ContextChip extends StatelessWidget {
  final String id;
  final String label;
  final ContextChipType type;
  final bool isSelected;
  final bool isRelated; // Correlato (vista ↔ gruppi) - molto trasparente
  final bool
  isLightlySelected; // Selezione leggera (doppio tap) - meno trasparente
  final bool includesPersonal;
  final VoidCallback onTap;
  final VoidCallback? onAddPersonalTap;

  const ContextChip({
    required this.id,
    required this.label,
    required this.type,
    required this.isSelected,
    this.isRelated = false,
    this.isLightlySelected = false,
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
        ? Icons.view_list_rounded
        : type == ContextChipType.allGroups
        ? Icons.groups
        : Icons.group;

    // Colore in base al tipo e selezione
    final Color chipColor;
    final Color textColor;
    final Color accentColor;

    if (isSelected) {
      chipColor = type == ContextChipType.personal
          ? Colors.purple[700]!
          : type == ContextChipType.view
          ? Colors.blue[700]!
          : type == ContextChipType.allGroups
          ? Colors.orange[700]!
          : Colors.green[700]!;
      textColor = Colors.white;
      accentColor = chipColor;
    } else if (isLightlySelected) {
      // Stato "lightly selected" (doppio tap): meno trasparente di related
      chipColor = type == ContextChipType.view
          ? Colors.blue[100]!
          : type == ContextChipType.allGroups
          ? Colors.orange[100]!
          : Colors.green[100]!;
      textColor = type == ContextChipType.view
          ? Colors.blue[700]!
          : type == ContextChipType.allGroups
          ? Colors.orange[700]!
          : Colors.green[700]!;
      accentColor = type == ContextChipType.view
          ? Colors.blue[400]!
          : type == ContextChipType.allGroups
          ? Colors.orange[400]!
          : Colors.green[400]!;
    } else if (isRelated) {
      // Stato "correlato" (tap singolo): molto trasparente
      chipColor = type == ContextChipType.view
          ? Colors.blue[50]!
          : type == ContextChipType.allGroups
          ? Colors.orange[50]!
          : Colors.green[50]!;
      textColor = type == ContextChipType.view
          ? Colors.blue[700]!
          : type == ContextChipType.allGroups
          ? Colors.orange[700]!
          : Colors.green[700]!;
      accentColor = type == ContextChipType.view
          ? Colors.blue[300]!
          : type == ContextChipType.allGroups
          ? Colors.orange[300]!
          : Colors.green[300]!;
    } else {
      chipColor = Colors.grey[100]!;
      textColor = Colors.grey[800]!;
      accentColor = Colors.grey[300]!;
    }

    // BoxShadow per glow effect
    final List<BoxShadow> shadows = isSelected
        ? [
            // Glow più forte per selezionati
            BoxShadow(
              color: accentColor.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ]
        : isLightlySelected
        ? [
            // Glow medio per lightly selected (doppio tap)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1.5,
            ),
          ]
        : isRelated
        ? [
            // Glow leggero per correlati (tap singolo)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ]
        : [];

    return Container(
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? chipColor
              : (isRelated ? accentColor : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: shadows,
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey[300],
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
                  size: includesPersonal ? 20 : 16, // Più grande quando attivo
                  color: includesPersonal
                      ? Colors.purple[600] // Viola quando attivo
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
