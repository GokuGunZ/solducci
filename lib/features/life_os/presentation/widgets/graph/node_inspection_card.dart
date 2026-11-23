import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/theme/app_theme.dart';

/// Bottom preview card displayed on single tap on an ego-graph node.
/// Allows inspecting properties and sub-items, with explicit actions
/// to drill down (descend level) or open the full entity vitrine.
class NodeInspectionCard extends StatelessWidget {
  final LifeEntity entity;
  final int childCount;
  final VoidCallback onDescend;
  final VoidCallback onClose;

  const NodeInspectionCard({
    super.key,
    required this.entity,
    required this.childCount,
    required this.onDescend,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hub_outlined, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${entity.semanticRole.name.toUpperCase()} · $childCount ${childCount == 1 ? "sotto-elemento" : "sotto-elementi"}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (childCount > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.subdirectory_arrow_right_rounded, size: 16),
                    label: const Text('Entra nel Livello'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: onDescend,
                  ),
                ),
              if (childCount > 0) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Dettaglio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27272A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    context.push('/life_os/entity/${entity.id}');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
