import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

/// Bento Active Entities Widget (INT-D014 / Step 3.2 Refactor)
/// Displays currently active projects, practices, and concepts in LifeOS.
/// Dimension-aware composition:
/// - 2x2 (H2 ~124px): Top 2 active entities with high legibility, role glyph & mode chip.
/// - 4x2 (H2 Wide): Asymmetric split (35% focus summary left + 65% rich entity stream right).
class LifeOsActiveEntitiesWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const LifeOsActiveEntitiesWidget({super.key, required this.def});

  @override
  State<LifeOsActiveEntitiesWidget> createState() => _LifeOsActiveEntitiesWidgetState();
}

class _LifeOsActiveEntitiesWidgetState extends State<LifeOsActiveEntitiesWidget> {
  List<LifeEntity> _entities = [];
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
        _loadEntities(currentContext);
      }
    } catch (_) {
      if (_lastContext == null) _loadEntities();
    }
  }

  Future<void> _loadEntities([ExpenseContext? ctx]) async {
    final effectiveContext = ctx ?? _lastContext;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = getIt<LifeEntityRepository>();
      final all = await repository.getEntities(
        groupId: effectiveContext?.isPersonal == true ? null : effectiveContext?.groupId,
        isPersonal: effectiveContext?.isPersonal ?? false,
      );

      final active = all
          .where((e) => !e.isSeed && !e.isArchived && e.lifecycleState == LifecycleState.active)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (mounted) {
        setState(() {
          _entities = active;
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

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final is4x2 = size.crossAxisCellCount == 4 && size.mainAxisCellCount == 2;

    return BentoWidgetContainer(
      size: size,
      isLoading: _isLoading,
      hasError: _error != null,
      onRetry: _loadEntities,
      onTap: () => context.push('/life_os'),
      child: is4x2 ? _build4x2AsymmetricSplit() : _build2x2CompactView(),
    );
  }

  /// 2x2 (H2 ~124px): Top 2 active entities with high legibility
  Widget _build2x2CompactView() {
    final displayEntities = _entities.take(2).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ∞ ambient signature
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.all_inclusive_rounded, size: 13, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 8),
              Text(
                widget.def.customProps?['title'] as String? ?? 'Entità Attive',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_entities.isNotEmpty)
                Text(
                  '${_entities.length}',
                  style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // High-legibility entity cards
          Expanded(
            child: displayEntities.isEmpty
                ? Center(
                    child: Text(
                      _isLoading ? 'Caricamento...' : 'Nessuna entità attiva',
                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  )
                : Column(
                    children: displayEntities.map((entity) {
                      final roleColor = _colorForRole(entity.semanticRole);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/life_os/entity/${entity.id}', extra: entity),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141418),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Row(
                              children: [
                                Icon(_iconForRole(entity.semanticRole), size: 14, color: roleColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entity.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (entity.currentMode != null) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entity.currentMode!.value,
                                      style: const TextStyle(color: Colors.white60, fontSize: 9),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  /// 4x2 (H2 Wide): Asymmetric split (35% focus summary left + 65% rich entity stream right)
  Widget _build4x2AsymmetricSplit() {
    final displayEntities = _entities.take(3).toList();
    final projectsCount = _entities.where((e) => e.semanticRole == SemanticRole.project).length;
    final practicesCount = _entities.where((e) => e.semanticRole == SemanticRole.practice).length;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (35%): Focus Summary Tile
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
                      const Icon(Icons.all_inclusive_rounded, size: 14, color: Color(0xFF6366F1)),
                      const SizedBox(width: 6),
                      const Text(
                        'ATTIVE',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_entities.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$projectsCount progetti • $practicesCount pratiche',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/life_os'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Apri LifeOS', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
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

          // Right Column (65%): Multi-entity cards stream
          Expanded(
            flex: 65,
            child: displayEntities.isEmpty
                ? const Center(
                    child: Text('Nessuna entità attiva', style: TextStyle(color: Colors.white30, fontSize: 12)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROGETTI & PRATICHE IN CORSO',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayEntities.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final entity = displayEntities[index];
                            final roleColor = _colorForRole(entity.semanticRole);
                            return GestureDetector(
                              onTap: () => context.push('/life_os/entity/${entity.id}', extra: entity),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141418),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_iconForRole(entity.semanticRole), size: 14, color: roleColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entity.title,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (entity.currentMode != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: roleColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          entity.currentMode!.value,
                                          style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.white24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
