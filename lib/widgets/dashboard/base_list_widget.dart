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
  final BentoWidgetSize? size;
  final Widget? bottomDock;

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
  });

  @override
  Widget build(BuildContext context) {
    final isCompactHeight = size != null && size!.mainAxisCellCount <= 1;

    return BentoWidgetContainer(
      isLoading: isLoading,
      isStale: isStale,
      onRetry: onRetry,
      heroTag: heroTag,
      size: size,
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
            padding: EdgeInsets.all(isCompactHeight ? 12.0 : 16.0),
            child: isCompactHeight
                ? _buildCompactLayout(context)
                : _buildFullLayout(context),
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

  /// Layout completo per taglie standard (2x2, 2x3, 4x2)
  Widget _buildFullLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataSourceSwitcherHeader(
          title: currentSource,
          color: color,
          icon: icon,
          onPrevious: onPreviousSource,
          onNext: onNextSource,
          onTitleTap: onExpand,
        ),
        if (quickActionRow != null) ...[
          const SizedBox(height: 8),
          quickActionRow!,
          const SizedBox(height: 8),
        ] else ...[
          const SizedBox(height: 12),
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
                  isCompact: false,
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) => itemBuilder(context, items[index], index),
                ),
        ),
        if (bottomDock != null) bottomDock!,
      ],
    );
  }
}
