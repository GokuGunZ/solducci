import 'package:flutter/material.dart';
import 'package:solducci/core/components/lists/base/reorderable_list_view_base.dart';
import 'package:solducci/core/components/animations/highlight_animation_mixin.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// Task-specific implementation of ReorderableListViewBase
///
/// Provides Task domain logic on top of the generic ReorderableListViewBase:
/// - Uses task.id as the unique key
/// - Persists reorder to TaskOrderPersistenceService
/// - Integrates with highlight animation for visual feedback
/// - Supports custom reorder callbacks
///
/// Usage:
/// ```dart
/// TaskReorderableListView(
///   documentId: document.id,
///   items: allTasks,
///   config: ReorderableListConfig.smoothImmediate,
///   itemBuilder: (context, task, index) {
///     return TaskListItem(task: task);
///   },
///   onReorderComplete: (reorderedTasks) {
///     // Optional: additional handling after reorder
///   },
/// )
/// ```
class TaskReorderableListView extends StatelessWidget {
  final String documentId;
  final List<Task> items;
  final ReorderableListConfig config;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool shrinkWrap;
  final bool? primary;

  /// Builder for individual task items
  final Widget Function(BuildContext context, Task task, int index) itemBuilder;

  /// Optional callback when reorder completes (after persistence)
  final void Function(List<Task> reorderedTasks)? onReorderComplete;

  /// Whether to enable highlight animation on reorder
  final bool enableHighlightAnimation;

  const TaskReorderableListView({
    super.key,
    required this.documentId,
    required this.items,
    required this.itemBuilder,
    this.config = const ReorderableListConfig(),
    this.padding,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
    this.primary,
    this.onReorderComplete,
    this.enableHighlightAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return _TaskReorderableListViewImpl(
      documentId: documentId,
      items: items,
      config: config,
      padding: padding,
      physics: physics,
      controller: controller,
      shrinkWrap: shrinkWrap,
      primary: primary,
      itemBuilder: itemBuilder,
      onReorderCompleteCallback: onReorderComplete,
      enableHighlightAnimation: enableHighlightAnimation,
    );
  }
}

/// Private implementation that extends ReorderableListViewBase
class _TaskReorderableListViewImpl extends ReorderableListViewBase<Task> {
  final String documentId;
  final Widget Function(BuildContext context, Task task, int index) itemBuilder;
  final void Function(List<Task> reorderedTasks)? onReorderCompleteCallback;
  final bool enableHighlightAnimation;

  final _orderPersistenceService = TaskOrderPersistenceService();

  _TaskReorderableListViewImpl({
    required this.documentId,
    required super.items,
    required this.itemBuilder,
    required super.config,
    super.padding,
    super.physics,
    super.controller,
    super.shrinkWrap,
    super.primary,
    this.onReorderCompleteCallback,
    required this.enableHighlightAnimation,
  });

  @override
  String getItemId(Task item) => item.id;

  @override
  Widget buildItem(BuildContext context, Task item, int index) {
    final child = itemBuilder(context, item, index);

    // Wrap with highlight animation if enabled
    if (enableHighlightAnimation) {
      return HighlightContainer(
        key: ValueKey('highlight_${item.id}'),
        autoStart: false, // Don't auto-start, trigger manually on reorder
        child: child,
      );
    }

    return child;
  }

  @override
  void onReorderComplete(List<Task> reorderedItems) {
    AppLogger.debug('🔄 Task reorder detected for document: $documentId');

    // Persist new order to local storage
    final taskIds = reorderedItems.map((task) => task.id).toList();
    _orderPersistenceService.saveCustomOrder(
      documentId: documentId,
      taskIds: taskIds,
    );

    AppLogger.debug(
      '💾 Persisted custom order: ${taskIds.take(3).join(", ")}... '
      '(${taskIds.length} tasks)',
    );

    // Call optional callback
    onReorderCompleteCallback?.call(reorderedItems);
  }

  @override
  Widget buildProxyDecorator(
    BuildContext context,
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    // Enhanced drag appearance with more pronounced lift effect
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(animation.value);
        final scale = 1.0 + (0.08 * t); // Slightly larger scale than default
        final elevation = 12.0 * t; // Higher elevation during drag

        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: elevation,
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: 0.9 + (0.1 * (1 - t)), // Slight fade during drag
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
