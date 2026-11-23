import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/theme/app_theme.dart';

/// Floating suggestion list for '@' mentions in LifeOS capture bar.
class EntityMentionPicker extends StatelessWidget {
  final List<LifeEntity> entities;
  final String query;
  final ValueChanged<LifeEntity> onSelected;

  const EntityMentionPicker({
    super.key,
    required this.entities,
    required this.query,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cleanQuery = query.toLowerCase().trim();
    final filtered = entities.where((e) {
      if (cleanQuery.isEmpty) return true;
      return e.title.toLowerCase().contains(cleanQuery);
    }).take(6).toList();

    if (filtered.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F23),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Nessuna entità trovata per "@$query"',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          itemBuilder: (context, index) {
            final entity = filtered[index];
            final roleIcon = _getRoleIcon(entity.semanticRole);
            final roleColor = _getRoleColor(entity.semanticRole);

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(entity);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(roleIcon, color: roleColor, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entity.semanticRole.value.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getRoleIcon(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return Icons.folder_open_rounded;
      case SemanticRole.concept:
        return Icons.lightbulb_outline_rounded;
      case SemanticRole.practice:
        return Icons.repeat_rounded;
      case SemanticRole.idea:
        return Icons.auto_awesome_outlined;
      case SemanticRole.seed:
      default:
        return Icons.eco_outlined;
    }
  }

  Color _getRoleColor(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return AppTheme.primary;
      case SemanticRole.concept:
        return const Color(0xFFF59E0B);
      case SemanticRole.practice:
        return const Color(0xFF10B981);
      case SemanticRole.idea:
        return const Color(0xFF38BDF8);
      case SemanticRole.seed:
      default:
        return const Color(0xFFA1A1AA);
    }
  }
}
