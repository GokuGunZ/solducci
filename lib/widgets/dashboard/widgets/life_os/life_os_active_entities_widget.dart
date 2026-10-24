import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

/// Bento Active Entities Widget (INT-D014)
/// Displays currently active projects, practices, and concepts in LifeOS.
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

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

  Future<void> _loadEntities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = getIt<LifeEntityRepository>();
      final all = await repository.getEntities();
      final active = all.where((e) => !e.isSeed && !e.isArchived).toList()
        ..sort((a, b) {
          final aTime = a.lastMeaningfulActivityAt ?? a.createdAt;
          final bTime = b.lastMeaningfulActivityAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });

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
    final maxItems = size.crossAxisCellCount >= 4 ? 6 : 3;
    final displayEntities = _entities.take(maxItems).toList();

    return BentoWidgetContainer(
      size: size,
      isLoading: _isLoading,
      hasError: _error != null,
      onRetry: _loadEntities,
      onTap: () => context.push('/life_os'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF6366F1)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_entities.length}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: displayEntities.isEmpty
                  ? Center(
                      child: Text(
                        _isLoading ? 'Caricamento...' : 'Nessuna entità attiva',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayEntities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final entity = displayEntities[index];
                        final color = _colorForRole(entity.semanticRole);

                        return InkWell(
                          onTap: () => context.push('/life_os/entity/${entity.id}', extra: entity),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141418),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Row(
                              children: [
                                Icon(_iconForRole(entity.semanticRole), size: 14, color: color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entity.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white24),
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
    );
  }
}
