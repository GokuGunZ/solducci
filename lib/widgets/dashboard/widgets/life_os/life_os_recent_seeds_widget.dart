import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

/// Bento Recent Seeds Widget (INT-D014)
/// Displays latest unpromoted seeds resting in the Living Core.
/// Tap opens the Entity Vitrine.
class LifeOsRecentSeedsWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const LifeOsRecentSeedsWidget({super.key, required this.def});

  @override
  State<LifeOsRecentSeedsWidget> createState() => _LifeOsRecentSeedsWidgetState();
}

class _LifeOsRecentSeedsWidgetState extends State<LifeOsRecentSeedsWidget> {
  List<LifeEntity> _seeds = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSeeds();
  }

  Future<void> _loadSeeds() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = getIt<LifeEntityRepository>();
      final all = await repository.getEntities();
      final seeds = all.where((e) => e.isSeed && !e.isArchived).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _seeds = seeds;
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

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final maxItems = size.crossAxisCellCount == 2 && size.mainAxisCellCount == 1
        ? 1
        : size.crossAxisCellCount >= 4
            ? 6
            : 3;

    final displaySeeds = _seeds.take(maxItems).toList();

    return BentoWidgetContainer(
      size: size,
      isLoading: _isLoading,
      hasError: _error != null,
      onRetry: _loadSeeds,
      onTap: () => context.push('/life_os'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco_rounded, size: 13, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.def.customProps?['title'] as String? ?? 'Semi Recenti',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_seeds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_seeds.length}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Content Body
            Expanded(
              child: displaySeeds.isEmpty
                  ? Center(
                      child: Text(
                        _isLoading ? 'Caricamento...' : 'Nessun seme a riposo',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displaySeeds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final seed = displaySeeds[index];
                        return InkWell(
                          onTap: () => context.push('/life_os/entity/${seed.id}', extra: seed),
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
                                const Icon(Icons.circle, size: 5, color: Color(0xFF10B981)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    seed.title,
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
