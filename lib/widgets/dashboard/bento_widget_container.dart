import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_skeleton.dart';

/// Container base per ogni tile della Bento Dashboard con supporto nativo per:
/// - Skeleton Shimmer geometrico per taglia/tipo
/// - Stato Stale / Offline (badge discreto con retry)
/// - Error handling resiliente
/// - Transizione animata fluida tra skeleton e dati
class BentoWidgetContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final VoidCallback? onRetry;
  final bool isLoading;
  final bool isStale;
  final String? staleMessage;
  final bool hasError;
  final Widget? errorWidget;
  final String? heroTag;
  final BentoSkeletonType? skeletonType;
  final BentoWidgetSize? size;
  final Widget? skeletonWidget;

  const BentoWidgetContainer({
    super.key,
    required this.child,
    this.onTap,
    this.onExpand,
    this.onRetry,
    this.isLoading = false,
    this.isStale = false,
    this.staleMessage,
    this.hasError = false,
    this.errorWidget,
    this.heroTag,
    this.skeletonType,
    this.size,
    this.skeletonWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // AppTheme.surface (Dark OLED)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isStale
              ? const Color(0xFFF59E0B).withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildBody(context),
            ),
          ),
          // Specular highlight superiore
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    isStale ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Badge "Dati Offline/Stale" se la cache locale è attiva e la rete non risponde
          if (isStale && !isLoading)
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onRetry?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 10, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text(
                        staleMessage ?? 'Offline',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final effectiveTap = onTap ?? onExpand;

    if (effectiveTap != null) {
      content = GestureDetector(
        onTap: effectiveTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    if (heroTag != null) {
      content = Hero(
        tag: heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return KeyedSubtree(
        key: const ValueKey('skeleton'),
        child: _buildSkeleton(),
      );
    }

    if (hasError) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: errorWidget ?? _buildDefaultError(context),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('content'),
      child: child,
    );
  }

  Widget _buildSkeleton() {
    if (skeletonWidget != null) {
      return skeletonWidget!;
    }
    if (skeletonType != null) {
      return BentoSkeleton(type: skeletonType!);
    }
    if (size != null) {
      return BentoSkeleton.autoForSize(size!);
    }
    return const BentoSkeleton(type: BentoSkeletonType.generic);
  }

  Widget _buildDefaultError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 24, color: Colors.white.withOpacity(0.35)),
            const SizedBox(height: 6),
            Text(
              'Impossibile caricare',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onRetry!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Text(
                    'Riprova',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
