import 'package:flutter/material.dart';

/// Tipo di chip contesto
enum ContextChipType { personal, group, view, allGroups }

/// Widget Chip riutilizzabile per selezionare contesti (Personal, Group, View)
/// Ottimizzato con estetica Dark OLED, bagliori neon e contrasto perfetto.
class ContextChip extends StatelessWidget {
  final String id;
  final String label;
  final ContextChipType type;
  final bool isSelected;
  final bool isRelated; // Correlato (vista ↔ gruppi) - molto trasparente
  final bool isLightlySelected; // Selezione leggera (doppio tap) - meno trasparente
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
        ? Icons.person_rounded
        : type == ContextChipType.view
            ? Icons.view_list_rounded
            : type == ContextChipType.allGroups
                ? Icons.groups_rounded
                : Icons.group_rounded;

    // Colore primario del tipo
    final Color baseAccent = type == ContextChipType.personal
        ? const Color(0xFFA855F7) // Purple Neon
        : type == ContextChipType.view
            ? const Color(0xFF3B82F6) // Electric Blue
            : type == ContextChipType.allGroups
                ? const Color(0xFFF97316) // Sunset Orange
                : const Color(0xFF10B981); // Emerald Green

    final Color chipBgColor;
    final Color contentColor;
    final Color borderColor;

    if (isSelected) {
      chipBgColor = baseAccent;
      contentColor = Colors.white;
      borderColor = Colors.white.withOpacity(0.4);
    } else if (isLightlySelected) {
      chipBgColor = baseAccent.withOpacity(0.22);
      contentColor = baseAccent;
      borderColor = baseAccent.withOpacity(0.6);
    } else if (isRelated) {
      chipBgColor = baseAccent.withOpacity(0.12);
      contentColor = baseAccent.withOpacity(0.9);
      borderColor = baseAccent.withOpacity(0.35);
    } else {
      chipBgColor = const Color(0xFF1E1E24);
      contentColor = Colors.white60;
      borderColor = Colors.white.withOpacity(0.08);
    }

    final List<BoxShadow> shadows = isSelected
        ? [
            BoxShadow(
              color: baseAccent.withOpacity(0.45),
              blurRadius: 14,
              spreadRadius: 1.5,
            ),
          ]
        : isLightlySelected
            ? [
                BoxShadow(
                  color: baseAccent.withOpacity(0.25),
                  blurRadius: 10,
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
            // Main avatar circle
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: chipBgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2 : 1.2,
                ),
                boxShadow: shadows,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  splashColor: baseAccent.withOpacity(0.3),
                  highlightColor: baseAccent.withOpacity(0.15),
                  child: Center(
                    child: type == ContextChipType.group
                        ? Text(
                            label.substring(0, label.length >= 2 ? 2 : 1).toUpperCase(),
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          )
                        : Icon(icon, size: 24, color: contentColor),
                  ),
                ),
              ),
            ),

            // Bottone [+P] come badge in basso a destra
            if (onAddPersonalTap != null)
              Positioned(
                bottom: -3,
                right: -3,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAddPersonalTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: includesPersonal
                            ? const Color(0xFFA855F7)
                            : const Color(0xFF27272A),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF121215), width: 2),
                      ),
                      child: Icon(
                        includesPersonal ? Icons.person_rounded : Icons.person_add_rounded,
                        size: 13,
                        color: includesPersonal ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: 74,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11.5,
              height: 1.15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
