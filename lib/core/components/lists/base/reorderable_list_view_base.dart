import 'package:flutter/material.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

/// Configuration for reorderable list behavior
class ReorderableListConfig {
  /// Whether drag handles are built by default
  final bool buildDefaultDragHandles;

  /// Whether long press is required for dragging
  final bool longPressDraggable;

  /// Duration for insert animations
  final Duration insertDuration;

  /// Duration for remove animations
  final Duration removeDuration;

  /// Transitions for entering items
  final List<AnimationEffect<dynamic>> enterTransition;

  /// Transitions for exiting items
  final List<AnimationEffect<dynamic>> exitTransition;

  /// Whether reordering is enabled
  final bool enabled;

  /// Minimum drag distance to start reorder
  final double? dragStartDelay;

  const ReorderableListConfig({
    this.buildDefaultDragHandles = true,
    this.longPressDraggable = false,
    this.insertDuration = const Duration(milliseconds: 300),
    this.removeDuration = const Duration(milliseconds: 300),
    this.enterTransition = const [],
    this.exitTransition = const [],
    this.enabled = true,
    this.dragStartDelay,
  });

  /// Config for disabled reordering (static list)
  static const disabled = ReorderableListConfig(enabled: false);

  /// Config for smooth animations with immediate drag
  static const smoothImmediate = ReorderableListConfig(
    buildDefaultDragHandles: true,
    longPressDraggable: false,
    insertDuration: Duration(milliseconds: 0),
    removeDuration: Duration(milliseconds: 0),
    enterTransition: [],
    exitTransition: [],
  );
}

/// Abstract base for reorderable lists with animations
///
/// Provides a foundation for lists that support:
/// - Drag and drop reordering
/// - Smooth animations on position change
/// - Custom drag handles
/// - Persistence of custom order
///
/// Type Parameter:
/// - [T]: The item type being displayed
///
/// Usage:
/// ```dart
/// class TaskReorderableList extends ReorderableListViewBase<Task> {
///   @override
///   String getItemId(Task item) => item.id;
///
///   @override
///   Widget buildItem(BuildContext context, Task item, int index) {
///     return TaskListItem(task: item);
///   }
///
///   @override
///   void onReorderComplete(List<Task> reorderedItems) {
///     // Persist new order
///   }
/// }
/// ```
abstract class ReorderableListViewBase<T> extends StatefulWidget {
  /// The list of items to display
  final List<T> items;

  /// Reorderable list configuration
  final ReorderableListConfig config;

  /// Padding around the list
  final EdgeInsetsGeometry? padding;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Scroll controller
  final ScrollController? controller;

  /// Whether to shrink wrap the list
  final bool shrinkWrap;

  /// Primary scroll view
  final bool? primary;

  const ReorderableListViewBase({
    super.key,
    required this.items,
    this.config = const ReorderableListConfig(),
    this.padding,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
    this.primary,
  });

  /// Get unique ID for an item (required for animations)
  String getItemId(T item);

  /// Build the widget for an item
  Widget buildItem(BuildContext context, T item, int index);

  /// Called when reorder is complete
  /// Override to persist custom order
  void onReorderComplete(List<T> reorderedItems) {}

  /// Build proxy decorator (widget shown while dragging)
  /// Override to customize drag appearance
  Widget buildProxyDecorator(
    BuildContext context,
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(animation.value);
        final scale = 1.0 + (0.05 * t);

        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: 8 * t,
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  State<ReorderableListViewBase<T>> createState() =>
      _ReorderableListViewBaseState<T>();
}

class _ReorderableListViewBaseState<T>
    extends State<ReorderableListViewBase<T>> {
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(ReorderableListViewBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = List.from(widget.items);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (!widget.config.enabled) return;

    setState(() {
      // AnimatedReorderableListView doesn't need index adjustment
      // Standard ReorderableListView needs: if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    widget.onReorderComplete(_items);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.enabled) {
      // Static list (no reordering)
      return ListView.builder(
        padding: widget.padding,
        physics: widget.physics,
        controller: widget.controller,
        shrinkWrap: widget.shrinkWrap,
        primary: widget.primary,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return KeyedSubtree(
            key: ValueKey(widget.getItemId(item)),
            child: widget.buildItem(context, item, index),
          );
        },
      );
    }

    // Reorderable animated list
    return AnimatedReorderableListView<T>(
      items: _items,
      padding: widget.padding ?? EdgeInsets.zero,
      physics: widget.physics,
      controller: widget.controller,
      shrinkWrap: widget.shrinkWrap,
      primary: widget.primary ?? false,
      isSameItem: (a, b) => widget.getItemId(a) == widget.getItemId(b),
      insertDuration: widget.config.insertDuration,
      removeDuration: widget.config.removeDuration,
      enterTransition: widget.config.enterTransition,
      exitTransition: widget.config.exitTransition,
      buildDefaultDragHandles: widget.config.buildDefaultDragHandles,
      longPressDraggable: widget.config.longPressDraggable,
      proxyDecorator: (child, index, animation) {
        return widget.buildProxyDecorator(context, child, index, animation);
      },
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final item = _items[index];
        return KeyedSubtree(
          key: ValueKey(widget.getItemId(item)),
          child: widget.buildItem(context, item, index),
        );
      },
    );
  }
}
