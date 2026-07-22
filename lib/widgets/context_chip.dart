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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Main avatar area
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: chipColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? chipColor
                      : (isRelated ? accentColor : Colors.grey[300]!),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: shadows,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: type == ContextChipType.group
                        ? Text(
                            label.substring(0, label.length >= 2 ? 2 : 1).toUpperCase(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Icon(icon, size: 24, color: textColor),
                  ),
                ),
              ),
            ),

            // Bottone [+P] come badge in basso a destra
            if (onAddPersonalTap != null)
              Positioned(
                bottom: -4,
                right: -4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAddPersonalTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: includesPersonal ? Colors.purple[600] : Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                      child: Icon(
                        includesPersonal ? Icons.person : Icons.person_add,
                        size: 14,
                        color: includesPersonal ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: isSelected ? textColor : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 11,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
