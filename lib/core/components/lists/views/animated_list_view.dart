import 'package:flutter/material.dart';
import 'package:solducci/core/animations/app_animations.dart';
import 'package:solducci/core/components/lists/controllers/animated_list_controller.dart';
import 'package:solducci/core/components/lists/controllers/list_creation_controller.dart';

/// Generic animated list view with inline creation support
///
/// Features:
/// - Animated insert/remove operations
/// - Inline item creation (triggered by FAB or other widgets)
/// - Configurable item builder
/// - Integration with AnimatedListController
/// - Support for empty states
///
/// Usage:
/// ```dart
/// AnimatedListView<Task>(
///   controller: animatedListController,
///   creationController: listCreationController,
///   itemBuilder: (task, index) => TaskListItem(task),
///   emptyItemBuilder: () => EmptyTaskItem(
///     onSave: (task) => creationController.completeCreation(task),
///     onCancel: () => creationController.cancelCreation(),
///   ),
///   emptyStateBuilder: (context) => EmptyStateWidget(),
/// )
/// ```
class AnimatedListView<T> extends StatefulWidget {
  /// Controller for list animations
  final AnimatedListController<T>? controller;

  /// Controller for inline creation
  final ListCreationController<T>? creationController;

  /// Items to display (if not using controller)
  final List<T>? items;

  /// Builder for list items
  final Widget Function(T item, int index) itemBuilder;

  /// Builder for empty item during creation
  final Widget Function()? emptyItemBuilder;

  /// Builder for empty state when list is empty
  final Widget Function(BuildContext context)? emptyStateBuilder;

  /// Padding around list
  final EdgeInsetsGeometry? padding;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Scroll controller
  final ScrollController? scrollController;

  /// Whether list should shrink wrap
  final bool shrinkWrap;

  /// Primary scroll view
  final bool? primary;

  const AnimatedListView({
    super.key,
    this.controller,
    this.creationController,
    this.items,
    required this.itemBuilder,
    this.emptyItemBuilder,
    this.emptyStateBuilder,
    this.padding,
    this.physics,
    this.scrollController,
    this.shrinkWrap = false,
    this.primary,
  }) : assert(
          controller != null || items != null,
          'Either controller or items must be provided',
        );

  @override
  State<AnimatedListView<T>> createState() => _AnimatedListViewState<T>();
}

class _AnimatedListViewState<T> extends State<AnimatedListView<T>> {
  late AnimatedListController<T> _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      // Create internal controller
      _controller = AnimatedListController<T>(
        listKey: GlobalKey<AnimatedListState>(),
        itemBuilder: (item) => widget.itemBuilder(item, 0),
        initialItems: widget.items,
      );
      _ownsController = true;
    }

    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(AnimatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update items if not using controller
    if (widget.controller == null && widget.items != null) {
      _controller.replaceAll(
        widget.items!,
        getItemId: null, // Without diff for now
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _controller.items;

    // Empty state (no items and no creation)
    if (items.isEmpty &&
        (widget.creationController?.isCreating != true) &&
        widget.emptyStateBuilder != null) {
      return widget.emptyStateBuilder!(context);
    }

    return Column(
      children: [
        // Inline creation row (if active)
        if (widget.creationController != null)
          _buildInlineCreation(widget.creationController!),

        // Main list
        Expanded(
          child: AnimatedList(
            key: _controller.listKey,
            initialItemCount: items.length,
            padding: widget.padding,
            physics: widget.physics,
            controller: widget.scrollController,
            shrinkWrap: widget.shrinkWrap,
            primary: widget.primary,
            itemBuilder: (context, index, animation) {
              if (index >= items.length) {
                return const SizedBox.shrink();
              }

              final item = items[index];

              // Build item with animation
              return AppAnimations.buildInsertAnimation(
                context,
                animation,
                widget.itemBuilder(item, index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInlineCreation(ListCreationController<T> controller) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isCreating) {
          return const SizedBox.shrink();
        }

        if (widget.emptyItemBuilder == null) {
          return const SizedBox.shrink();
        }

        // Show empty item with slide animation
        return AnimatedInlineCreation(
          controller: controller,
          child: widget.emptyItemBuilder!(),
        );
      },
    );
  }
}

/// Simplified version without controllers for basic use cases
///
/// Usage:
/// ```dart
/// SimpleAnimatedListView<Task>(
///   items: tasks,
///   itemBuilder: (task, index) => TaskListItem(task),
///   onItemRemoved: (task) => removeTask(task),
/// )
/// ```
class SimpleAnimatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item, int index) itemBuilder;
  final void Function(T item)? onItemRemoved;
  final Widget Function(BuildContext context)? emptyStateBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const SimpleAnimatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onItemRemoved,
    this.emptyStateBuilder,
    this.padding,
    this.physics,
  });

  @override
  State<SimpleAnimatedListView<T>> createState() =>
      _SimpleAnimatedListViewState<T>();
}

class _SimpleAnimatedListViewState<T>
    extends State<SimpleAnimatedListView<T>> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(SimpleAnimatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Simple diff: detect additions and removals
    _updateItems(widget.items);
  }

  void _updateItems(List<T> newItems) {
    // Find removed items
    for (int i = _items.length - 1; i >= 0; i--) {
      if (!newItems.contains(_items[i])) {
        final removedItem = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) {
            return AppAnimations.buildRemoveAnimation(
              context,
              animation,
              widget.itemBuilder(removedItem, i),
            );
          },
          duration: AppAnimations.removeDuration,
        );
      }
    }

    // Find added items
    for (int i = 0; i < newItems.length; i++) {
      if (i >= _items.length || newItems[i] != _items[i]) {
        if (!_items.contains(newItems[i])) {
          _items.insert(i, newItems[i]);
          _listKey.currentState?.insertItem(
            i,
            duration: AppAnimations.insertDuration,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && widget.emptyStateBuilder != null) {
      return widget.emptyStateBuilder!(context);
    }

    return AnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      padding: widget.padding,
      physics: widget.physics,
      itemBuilder: (context, index, animation) {
        if (index >= _items.length) {
          return const SizedBox.shrink();
        }

        return AppAnimations.buildInsertAnimation(
          context,
          animation,
          widget.itemBuilder(_items[index], index),
        );
      },
    );
  }
}
