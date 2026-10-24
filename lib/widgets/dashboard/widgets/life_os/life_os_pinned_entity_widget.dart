import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

/// Bento Pinned Entity Widget (INT-D014)
/// Highlights a specific LifeEntity on the feed with quick vitrine access.
class LifeOsPinnedEntityWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const LifeOsPinnedEntityWidget({super.key, required this.def});

  @override
  State<LifeOsPinnedEntityWidget> createState() => _LifeOsPinnedEntityWidgetState();
}

class _LifeOsPinnedEntityWidgetState extends State<LifeOsPinnedEntityWidget> {
  LifeEntity? _entity;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntity();
  }

  @override
  void didUpdateWidget(covariant LifeOsPinnedEntityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.def.customProps?['entity_id'] != widget.def.customProps?['entity_id']) {
      _loadEntity();
    }
  }

  Future<void> _loadEntity() async {
    final entityId = widget.def.customProps?['entity_id'] as String?;
    if (entityId == null || entityId.isEmpty) {
      setState(() {
        _isLoading = false;
        _entity = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = getIt<LifeEntityRepository>();
      final entity = await repository.getEntityById(entityId);
      if (mounted) {
        setState(() {
          _entity = entity;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Errore di caricamento';
        });
      }
    }
  }

  IconData _iconForRole(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return Icons.rocket_launch_rounded;
      case SemanticRole.practice:
        return Icons.repeat_rounded;
      case SemanticRole.concept:
        return Icons.menu_book_rounded;
      case SemanticRole.idea:
        return Icons.lightbulb_outline_rounded;
      case SemanticRole.seed:
        return Icons.eco_outlined;
    }
  }

  Color _colorForRole(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return const Color(0xFF6366F1);
      case SemanticRole.practice:
        return const Color(0xFF10B981);
      case SemanticRole.concept:
        return const Color(0xFF3B82F6);
      case SemanticRole.idea:
        return const Color(0xFFF59E0B);
      case SemanticRole.seed:
        return Colors.white54;
    }
  }

  String _labelForRole(SemanticRole role) {
    switch (role) {
      case SemanticRole.seed:
        return 'Seme';
      case SemanticRole.project:
        return 'Progetto';
      case SemanticRole.practice:
        return 'Pratica';
      case SemanticRole.concept:
        return 'Concetto';
      case SemanticRole.idea:
        return 'Idea';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entity = _entity;
    final size = widget.def.size;

    return BentoWidgetContainer(
      size: size,
      isLoading: _isLoading,
      hasError: _error != null,
      onRetry: _loadEntity,
      onTap: entity != null
          ? () => context.push('/life_os/entity/${entity.id}', extra: entity)
          : () => context.push('/life_os'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: entity == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.push_pin_outlined, size: 20, color: Colors.white30),
                    const SizedBox(height: 6),
                    Text(
                      _isLoading ? 'Caricamento...' : 'Nessuna entità fissata',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Pinned badge + Role Chip
                  Row(
                    children: [
                      const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        widget.def.customProps?['title'] as String? ?? 'In Evidenza',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _colorForRole(entity.semanticRole).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconForRole(entity.semanticRole),
                                size: 10, color: _colorForRole(entity.semanticRole)),
                            const SizedBox(width: 4),
                            Text(
                              _labelForRole(entity.semanticRole),
                              style: TextStyle(
                                color: _colorForRole(entity.semanticRole),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    entity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Snippet (last block or description)
                  Expanded(
                    child: Text(
                      entity.blocks.isNotEmpty
                          ? entity.blocks.last.content
                          : (entity.description != null && entity.description!.isNotEmpty
                              ? entity.description!
                              : 'Tocca per aprire la Vitrine e aggiungere pensieri.'),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        height: 1.35,
                      ),
                      maxLines: size.crossAxisCellCount == 2 && size.mainAxisCellCount == 1 ? 1 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
