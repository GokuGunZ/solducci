import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

/// Bento Pinned Entity Widget (INT-D014 / Step 3.2 Refactor)
/// Highlights a specific LifeEntity on the feed with quick vitrine access.
/// Dimension-aware composition:
/// - 2x1 (H1 ~54px): Identity + single meaningful affordance (Pin, role glyph, title, pill).
/// - 2x2 (H2 ~124px): Prominent title + compact role badge + useful snippet.
/// - 4x2 (H2 Wide): Asymmetric split (35% identity & launcher + 65% rich content/properties stream).
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
  ExpenseContext? _lastContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final currentContext = DashboardContextScope.of(context);
      if (_lastContext != currentContext) {
        _lastContext = currentContext;
        _loadEntity(currentContext);
      }
    } catch (_) {
      if (_lastContext == null) _loadEntity();
    }
  }

  @override
  void didUpdateWidget(covariant LifeOsPinnedEntityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.def.customProps?['entity_id'] != widget.def.customProps?['entity_id']) {
      _loadEntity(_lastContext);
    }
  }

  bool _isEntityInContext(LifeEntity entity, ExpenseContext? ctx) {
    if (ctx == null) return true;
    if (ctx.isPersonal) {
      return entity.groupId == null;
    }
    if (ctx.isView && ctx.view != null) {
      return ctx.view!.groupIds.contains(entity.groupId);
    }
    if (ctx.groupId != null) {
      return entity.groupId == ctx.groupId;
    }
    return true;
  }

  Future<void> _loadEntity([ExpenseContext? ctx]) async {
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
    final is2x1 = size.crossAxisCellCount == 2 && size.mainAxisCellCount == 1;
    final is4x2 = size.crossAxisCellCount == 4 && size.mainAxisCellCount == 2;

    final isOutOfContext = entity != null && !_isEntityInContext(entity, _lastContext);

    return BentoWidgetContainer(
      size: size,
      isLoading: _isLoading,
      hasError: _error != null,
      onRetry: () => _loadEntity(_lastContext),
      onTap: entity != null && !isOutOfContext
          ? () => context.push('/life_os/entity/${entity.id}', extra: entity)
          : () => context.push('/life_os'),
      child: entity == null
          ? _buildEmptyState()
          : isOutOfContext
              ? _buildOutOfContextState()
              : is2x1
                  ? _build2x1MiniBanner(entity)
                  : is4x2
                      ? _build4x2AsymmetricSplit(entity)
                      : _build2x2Card(entity),
    );
  }

  Widget _buildOutOfContextState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.layers_clear_outlined, size: 18, color: Colors.white30),
          SizedBox(height: 6),
          Text(
            'Entità fuori dal contesto',
            style: TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin_outlined, size: 18, color: Colors.white30),
          const SizedBox(height: 6),
          Text(
            _isLoading ? 'Caricamento...' : 'Tocca per scegliere un\'entità',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 2x1 (H1 ~54px): Identity + single meaningful affordance
  Widget _build2x1MiniBanner(LifeEntity entity) {
    final roleColor = _colorForRole(entity.semanticRole);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.push_pin_rounded, size: 13, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Icon(_iconForRole(entity.semanticRole), size: 14, color: roleColor),
          const SizedBox(width: 8),
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
              color: roleColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _labelForRole(entity.semanticRole),
              style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white30),
        ],
      ),
    );
  }

  /// 2x2 (H2 ~124px): Prominent title + compact role badge + snippet
  Widget _build2x2Card(LifeEntity entity) {
    final roleColor = _colorForRole(entity.semanticRole);
    final snippet = entity.blocks.isNotEmpty
        ? entity.blocks.last.content
        : (entity.description != null && entity.description!.isNotEmpty
            ? entity.description!
            : (entity.properties.isNotEmpty
                ? '${entity.properties.first.label}: ${entity.properties.first.displayValue}'
                : 'Tocca per aprire la Vitrine.'));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Pin glyph + role pill
          Row(
            children: [
              const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFF59E0B)),
              const SizedBox(width: 5),
              const Text(
                'In Evidenza',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconForRole(entity.semanticRole), size: 10, color: roleColor),
                    const SizedBox(width: 4),
                    Text(
                      _labelForRole(entity.semanticRole),
                      style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
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

          // Snippet
          Expanded(
            child: Text(
              snippet,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 4x2 (H2 Wide): Asymmetric split (35% identity left + 65% content stream right)
  Widget _build4x2AsymmetricSplit(LifeEntity entity) {
    final roleColor = _colorForRole(entity.semanticRole);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (35%): Identity Card
          Expanded(
            flex: 35,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Icon(_iconForRole(entity.semanticRole), size: 13, color: roleColor),
                      const SizedBox(width: 5),
                      Text(
                        _labelForRole(entity.semanticRole).toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    entity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: () => context.push('/life_os/entity/${entity.id}', extra: entity),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Apri Vitrine', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Right Column (65%): Content & Properties Stream
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header for right section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CONTENUTI & PROPRIETÀ',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (entity.currentMode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entity.currentMode!.value,
                          style: const TextStyle(color: Colors.white70, fontSize: 9),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Properties pills or latest block
                Expanded(
                  child: entity.blocks.isNotEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141418),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ultima nota aggiunta:',
                                style: TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  entity.blocks.last.content,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      : (entity.properties.isNotEmpty
                          ? ListView.separated(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entity.properties.take(2).length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final prop = entity.properties[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141418),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        prop.label,
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                      const Spacer(),
                                      Text(
                                        prop.displayValue,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                entity.description != null && entity.description!.isNotEmpty
                                    ? entity.description!
                                    : 'Nessun blocco o proprietà ancora aggiunta.',
                                style: const TextStyle(color: Colors.white30, fontSize: 11),
                              ),
                            )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
