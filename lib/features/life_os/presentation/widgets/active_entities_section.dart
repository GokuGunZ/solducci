import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/theme/app_theme.dart';

class ActiveEntitiesSection extends StatelessWidget {
  final List<LifeEntity> entities;

  const ActiveEntitiesSection({super.key, required this.entities});

  Color _roleColor(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return const Color(0xFF6366F1); // Indigo
      case SemanticRole.practice:
        return const Color(0xFF10B981); // Emerald
      case SemanticRole.concept:
        return const Color(0xFF3B82F6); // Blue
      case SemanticRole.idea:
        return const Color(0xFFF59E0B); // Amber
      case SemanticRole.seed:
        return Colors.white54;
    }
  }

  String _roleLabel(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return 'Progetto';
      case SemanticRole.practice:
        return 'Pratica';
      case SemanticRole.concept:
        return 'Conoscenza';
      case SemanticRole.idea:
        return 'Idea';
      case SemanticRole.seed:
        return 'Seme';
    }
  }

  String? _modeLabel(OperationMode? mode) {
    if (mode == null) return null;
    switch (mode) {
      case OperationMode.exploration:
        return 'Esplora';
      case OperationMode.execution:
        return 'Lavora';
      case OperationMode.practice:
        return 'Pratica';
      case OperationMode.reflection:
        return 'Rifletti';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.layers_outlined, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Entità Attive',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${entities.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entity = entities[index];
            final roleCol = _roleColor(entity.semanticRole);
            final modeStr = _modeLabel(entity.currentMode);

            return InkWell(
              onTap: () {
                context.push('/life_os/entity/${entity.id}', extra: entity);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleCol.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: roleCol.withOpacity(0.3)),
                      ),
                      child: Text(
                        _roleLabel(entity.semanticRole),
                        style: TextStyle(color: roleCol, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (modeStr != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          modeStr,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
