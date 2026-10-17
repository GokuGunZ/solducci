import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_skeleton.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/data_source_switcher_header.dart';

class BaseListWidget<T> extends StatelessWidget {
  final bool isLoading;
  final bool isStale;
  final VoidCallback? onRetry;
  final VoidCallback? onExpand;
  final String currentSource;
  final Color color;
  final IconData icon;
  final VoidCallback onPreviousSource;
  final VoidCallback onNextSource;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String emptyMessage;
  final String? emptySubtitle;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final IconData? emptyIcon;
  final String? heroTag;
  final Widget? quickActionRow;
  final BentoSkeletonType? skeletonType;
  final Widget? bottomDock;
  final BentoWidgetSize? size;
  final int? currentSourceIndex;
  final int? totalSources;

  const BaseListWidget({
    super.key,
    this.isLoading = false,
    this.isStale = false,
    this.onRetry,
    this.onExpand,
    required this.currentSource,
    required this.color,
    required this.icon,
    required this.onPreviousSource,
    required this.onNextSource,
    required this.items,
    required this.itemBuilder,
    required this.emptyMessage,
    this.emptySubtitle,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.emptyIcon,
    this.heroTag,
    this.quickActionRow,
    this.skeletonType,
    this.size,
    this.bottomDock,
    this.currentSourceIndex,
    this.totalSources,
  });

  @override
  Widget build(BuildContext context) {
    final height = size?.mainAxisCellCount ?? 2;
    final isCompactHeight = height <= 1;

    return BentoWidgetContainer(
      isLoading: isLoading,
      isStale: isStale,
      onRetry: onRetry,
      heroTag: heroTag,
      size: size,
      onTap: isCompactHeight ? onExpand : null,
      onExpand: onExpand,
      skeletonType: skeletonType ?? BentoSkeletonType.list,
      child: Stack(
        children: [
          // Background Gradient subtle
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.09),
                    color.withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: isCompactHeight
                ? const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0)
                : (height == 2
                    ? const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0)
                    : const EdgeInsets.all(14.0)),
            child: isCompactHeight
                ? _buildCompactLayout(context)
                : _buildFullLayout(context, height: height),
          ),
        ],
      ),
    );
  }

  /// Layout per taglie con altezza limitata (es. 1x1, 2x1) per evitare RenderFlex overflow
  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentSource,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Text(
            emptyMessage.isNotEmpty ? emptyMessage : 'Nessun elemento',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tocca per aprire e gestire i dettagli',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 14, color: Colors.white30),
            ],
          ),
      ],
    );
  }

  /// Layout completo per taglie standard (2x2, 2x3, 2x4, 4x2)
  Widget _buildFullLayout(BuildContext context, {required int height}) {
    // In height 2 (~124px), vertical space is compact.
    // If the list has items, prioritize displaying items cleanly rather than squishing with the input field.
    // In height >= 3 (194px, 265px), both input row and items list fit with plenty of room.
    final showQuickAction = quickActionRow != null && (height >= 3 || items.isEmpty);
    double dragDx = 0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => dragDx = 0,
      onHorizontalDragUpdate: (details) => dragDx += details.primaryDelta ?? 0,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (dragDx < -40 || velocity < -200) {
          onNextSource();
        } else if (dragDx > 40 || velocity > 200) {
          onPreviousSource();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataSourceSwitcherHeader(
          title: currentSource,
          color: color,
          icon: icon,
          currentIndex: currentSourceIndex,
          totalSources: totalSources,
          onPrevious: onPreviousSource,
          onNext: onNextSource,
          onTitleTap: onExpand,
        ),
        if (showQuickAction) ...[
          const SizedBox(height: 6),
          quickActionRow!,
          const SizedBox(height: 6),
        ] else ...[
          SizedBox(height: height == 2 ? 6 : 10),
        ],
        Expanded(
          child: items.isEmpty
              ? BentoEmptyState(
                  icon: emptyIcon ?? icon,
                  title: emptyMessage.isNotEmpty ? emptyMessage : 'Nessun elemento',
                  subtitle: emptySubtitle,
                  color: color,
                  actionLabel: emptyActionLabel,
                  onAction: onEmptyAction,
                  isCompact: height <= 2,
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) => itemBuilder(context, items[index], index),
                ),
        ),
        if (bottomDock != null) bottomDock!,
      ],
    ),
  );
  }
}
