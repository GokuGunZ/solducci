import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

/// Bento Recent Seeds Widget (INT-D014 / Step 3.2 Refactor)
/// Displays resting raw seeds waiting to be matured or explored.
/// Dimension-aware composition:
/// - 2x1 (H1 ~54px): Glanceable mini-banner with latest seed & count badge.
/// - 2x2 (H2 ~124px): Compact list of 2-3 latest resting seeds with direct vitrine tap.
/// - 4x2 (H2 Wide): Asymmetric split (35% analytics/counter + 65% operational stream).
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
  ExpenseContext? _lastContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final currentContext = DashboardContextScope.of(context);
      if (_lastContext != currentContext) {
        _lastContext = currentContext;
        _loadSeeds(currentContext);
      }
    } catch (_) {
      if (_lastContext == null) _loadSeeds();
    }
  }

  Future<void> _loadSeeds([ExpenseContext? ctx]) async {
    final effectiveContext = ctx ?? _lastContext;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = getIt<LifeEntityRepository>();
      final entities = await repository.getEntities(
        groupId: effectiveContext?.isPersonal == true ? null : (effectiveContext?.isView == true ? null : effectiveContext?.groupId),
        groupIds: effectiveContext?.isView == true ? effectiveContext?.view?.groupIds : null,
        isPersonal: effectiveContext?.isPersonal ?? false,
      );

      final seeds = entities.where((e) => e.isSeed && !e.isArchived).toList()
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

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Adesso' : '${diff.inMinutes}m fa';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h fa';
    } else if (diff.inDays == 1) {
      return 'Ieri';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final is2x1 = size.crossAxisCellCount == 2 && size.mainAxisCellCount == 1;
    final is4x2 = size.crossAxisCellCount == 4 && size.mainAxisCellCount == 2;

    return BentoWidgetContainer(
      size: size,
      isLoading: _isLoading,
      hasError: _error != null,
      onRetry: _loadSeeds,
      onTap: () {
        if (_seeds.isNotEmpty && is2x1) {
          context.push('/life_os/entity/${_seeds.first.id}', extra: _seeds.first);
        } else {
          context.push('/life_os');
        }
      },
      child: is2x1
          ? _build2x1MiniBanner()
          : is4x2
              ? _build4x2AsymmetricSplit()
              : _build2x2CompactList(),
    );
  }

  /// 2x1 (H1 ~54px): Glanceable mini-banner
  Widget _build2x1MiniBanner() {
    final latestSeed = _seeds.isNotEmpty ? _seeds.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco_rounded, size: 14, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: latestSeed == null
                ? Text(
                    _isLoading ? 'Caricamento...' : 'Nessun seme a riposo',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    latestSeed.title,
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
          if (_seeds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_seeds.length}',
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.white30),
        ],
      ),
    );
  }

  /// 2x2 (H2 ~124px): Compact list of 2-3 seeds with direct tap
  Widget _build2x2CompactList() {
    final displaySeeds = _seeds.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count & ∞ brand signature
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
                Text(
                  '${_seeds.length}',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Body
          Expanded(
            child: displaySeeds.isEmpty
                ? Center(
                    child: Text(
                      _isLoading ? 'Caricamento...' : 'Nessun seme a riposo',
                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displaySeeds.length,
                    itemBuilder: (context, index) {
                      final seed = displaySeeds[index];
                      return GestureDetector(
                        onTap: () => context.push('/life_os/entity/${seed.id}', extra: seed),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  seed.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 4x2 (H2 Wide): Asymmetric split (35% summary left + 65% operational list right)
  Widget _build4x2AsymmetricSplit() {
    final displaySeeds = _seeds.take(4).toList();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (35%): Counter & Context Summary
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
                      const Icon(Icons.eco_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      const Text(
                        'SEMI',
                        style: TextStyle(
                          color: Color(0xFF10B981),
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
                        '${_seeds.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const Text(
                        'a riposo',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
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

          // Right Column (65%): Operational Seed Stream
          Expanded(
            flex: 65,
            child: displaySeeds.isEmpty
                ? const Center(
                    child: Text('Nessun seme a riposo', style: TextStyle(color: Colors.white30, fontSize: 12)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ULTIME CATTURE',
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
                          itemCount: displaySeeds.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final seed = displaySeeds[index];
                            return GestureDetector(
                              onTap: () => context.push('/life_os/entity/${seed.id}', extra: seed),
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
                                    Expanded(
                                      child: Text(
                                        seed.title,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatRelativeTime(seed.createdAt),
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                    const SizedBox(width: 4),
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
