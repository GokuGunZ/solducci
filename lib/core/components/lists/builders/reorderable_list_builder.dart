import 'package:flutter/material.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

/// Configuration for reorderable list behavior
class ReorderableConfig {
  final bool enabled;
  final bool buildDefaultDragHandles;
  final bool longPressDraggable;
  final Duration insertDuration;
  final Duration removeDuration;

  const ReorderableConfig({
    this.enabled = true,
    this.buildDefaultDragHandles = true,
    this.longPressDraggable = false,
    this.insertDuration = const Duration(milliseconds: 300),
    this.removeDuration = const Duration(milliseconds: 300),
  });

  static const disabled = ReorderableConfig(enabled: false);
  static const smoothImmediate = ReorderableConfig(
    buildDefaultDragHandles: true,
    longPressDraggable: false,
    insertDuration: Duration(milliseconds: 0),
    removeDuration: Duration(milliseconds: 0),
  );
}

/// Builder-based reorderable list that works with ANY state management
///
/// This component is PURE UI - it doesn't manage state, filter, or persist anything.
/// All logic is injected via callbacks, making it compatible with:
/// - BLoC
/// - Provider
/// - Riverpod
/// - GetX
/// - setState
/// - Custom granular rebuild systems
///
/// Usage with BLoC:
/// ```dart
/// ReorderableListBuilder<Task>(
///   items: state.tasks,
///   getItemKey: (task) => task.id,
///   config: ReorderableConfig.smoothImmediate,
///   onReorder: (oldIndex, newIndex) {
///     bloc.add(TaskReorderedEvent(oldIndex, newIndex));
///   },
///   itemBuilder: (context, task, index) {
///     return TaskListItem(task: task);
///   },
/// )
/// ```
///
/// Usage with custom granular rebuild:
/// ```dart
/// ReorderableListBuilder<Task>(
///   items: displayedTasks,
///   getItemKey: (task) => task.id,
///   config: ReorderableConfig.smoothImmediate,
///   onReorder: (oldIndex, newIndex) {
///     setState(() {
///       final task = displayedTasks.removeAt(oldIndex);
///       displayedTasks.insert(newIndex, task);
///     });
///     _persistOrder(displayedTasks);
///   },
///   itemBuilder: (context, task, index) {
///     // Can use ValueListenableBuilder here for granular rebuilds
///     return ValueListenableBuilder(
///       valueListenable: taskNotifiers[task.id]!,
///       builder: (context, updatedTask, _) {
///         return TaskListItem(task: updatedTask);
///       },
///     );
///   },
/// )
/// ```
class ReorderableListBuilder<T extends Object> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) getItemKey;
  final ReorderableConfig config;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool shrinkWrap;
  final bool? primary;

  const ReorderableListBuilder({
    super.key,
    required this.items,
    required this.getItemKey,
    required this.itemBuilder,
    this.config = const ReorderableConfig(),
    this.onReorder,
    this.padding,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
    this.primary,
  });

  @override
  State<ReorderableListBuilder<T>> createState() =>
      _ReorderableListBuilderState<T>();
}

class _ReorderableListBuilderState<T extends Object>
    extends State<ReorderableListBuilder<T>> {
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
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return KeyedSubtree(
            key: ValueKey(widget.getItemKey(item)),
            child: widget.itemBuilder(context, item, index),
          );
        },
      );
    }

    // Reorderable animated list
    return AnimatedReorderableListView<T>(
      items: widget.items,
      padding: widget.padding ?? EdgeInsets.zero,
      physics: widget.physics,
      controller: widget.controller,
      shrinkWrap: widget.shrinkWrap,
      primary: widget.primary ?? false,
      isSameItem: (a, b) => widget.getItemKey(a) == widget.getItemKey(b),
      insertDuration: widget.config.insertDuration,
      removeDuration: widget.config.removeDuration,
      enterTransition: const [],
      exitTransition: const [],
      buildDefaultDragHandles: widget.config.buildDefaultDragHandles,
      longPressDraggable: widget.config.longPressDraggable,
      onReorder: (oldIndex, newIndex) {
        widget.onReorder?.call(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return KeyedSubtree(
          key: ValueKey(widget.getItemKey(item)),
          child: widget.itemBuilder(context, item, index),
        );
      },
    );
  }
}
