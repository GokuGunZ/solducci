import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';

/// Dedicated widget for managing subtask list with AnimatedList
/// Mirrors the architecture of AllTasksView's _AnimatedTaskListBuilder
///
/// Key Features:
/// - Independent state management
/// - Granular diff-based updates
/// - AnimatedList with smooth insert/remove animations
/// - Listens to parent task notifier for updates
class SubtaskAnimatedList extends StatefulWidget {
  final String parentTaskId;
  final AlwaysNotifyValueNotifier<Task> parentNotifier;
  final TodoDocument document;
  final int depth;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final Map<String, List<Tag>>? taskTagsMap;
  final bool isExpanded;
  final bool isCreatingSubtask;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onSubtaskCreated;

  const SubtaskAnimatedList({
    super.key,
    required this.parentTaskId,
    required this.parentNotifier,
    required this.document,
    required this.depth,
    this.showAllPropertiesNotifier,
    this.taskTagsMap,
    required this.isExpanded,
    required this.isCreatingSubtask,
    required this.onCancelCreation,
    required this.onSubtaskCreated,
  });

  @override
  State<SubtaskAnimatedList> createState() => _SubtaskAnimatedListState();
}

class _SubtaskAnimatedListState extends State<SubtaskAnimatedList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Task> _displayedSubtasks = [];
  bool _isFirstLoad = true;
  StreamSubscription? _listenerSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize from parent's current subtasks
    _displayedSubtasks = List<Task>.from(widget.parentNotifier.value.subtasks ?? []);

    // If already has subtasks, mark as loaded to enable animations
    if (_displayedSubtasks.isNotEmpty) {
      _isFirstLoad = false;
    }

    // Listen to parent task changes
    widget.parentNotifier.addListener(_onParentTaskUpdated);
  }

  @override
  void dispose() {
    widget.parentNotifier.removeListener(_onParentTaskUpdated);
    _listenerSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(SubtaskAnimatedList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If parent notifier changed, update listener
    if (oldWidget.parentNotifier != widget.parentNotifier) {
      oldWidget.parentNotifier.removeListener(_onParentTaskUpdated);
      widget.parentNotifier.addListener(_onParentTaskUpdated);

      // Sync with new notifier's subtasks
      final newSubtasks = widget.parentNotifier.value.subtasks ?? [];
      _updateDisplayedSubtasks(newSubtasks);
    }
  }

  void _onParentTaskUpdated() {
    if (!mounted) return;

    final newSubtasks = widget.parentNotifier.value.subtasks ?? [];
    _updateDisplayedSubtasks(newSubtasks);
  }

  void _updateDisplayedSubtasks(List<Task> newSubtasks) {
    if (_isFirstLoad) {
      setState(() {
        _displayedSubtasks = newSubtasks;
        _isFirstLoad = false;
      });
      return;
    }

    // Granular diff - find exact changes (same logic as main task list)
    final newSubtaskIds = newSubtasks.map((t) => t.id).toList();
    final oldSubtaskIds = _displayedSubtasks.map((t) => t.id).toList();

    // Find insertions
    for (int i = 0; i < newSubtasks.length; i++) {
      if (i >= _displayedSubtasks.length || newSubtasks[i].id != _displayedSubtasks[i].id) {
        final subtaskId = newSubtasks[i].id;
        if (!oldSubtaskIds.contains(subtaskId)) {
          // New subtask - insert with animation
          setState(() {
            _displayedSubtasks.insert(i, newSubtasks[i]);
          });

          // Trigger animation if AnimatedList is ready
          _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 400));
          return; // Handle one change at a time
        }
      }
    }

    // Find deletions
    for (int i = _displayedSubtasks.length - 1; i >= 0; i--) {
      final subtaskId = _displayedSubtasks[i].id;
      if (!newSubtaskIds.contains(subtaskId)) {
        final removedTask = _displayedSubtasks[i];
        setState(() {
          _displayedSubtasks.removeAt(i);
        });

        _listKey.currentState?.removeItem(
          i,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: TaskListItem(
                key: ValueKey('removing_${removedTask.id}'),
                task: removedTask,
                document: widget.document,
                depth: widget.depth + 1,
                showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                preloadedTags: widget.taskTagsMap?[removedTask.id],
                taskTagsMap: widget.taskTagsMap,
              ),
            ),
          ),
          duration: const Duration(milliseconds: 300),
        );
        return; // Handle one change at a time
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only render if expanded
    if (!widget.isExpanded) {
      return const SizedBox.shrink();
    }

    // Return empty if no subtasks and not creating
    if (_displayedSubtasks.isEmpty && !widget.isCreatingSubtask) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: null, // Let content determine height
      child: AnimatedList(
        key: _listKey,
        shrinkWrap: true, // CRITICAL: Allow nested list to size itself
        physics: const NeverScrollableScrollPhysics(), // Parent handles scroll
        initialItemCount: _displayedSubtasks.length + (widget.isCreatingSubtask ? 1 : 0),
        itemBuilder: (context, index, animation) {
          // Show creation row as first item if creating subtask
          if (widget.isCreatingSubtask && index == 0) {
            return TaskCreationRow(
              key: ValueKey('subtask_creation_${widget.parentTaskId}'),
              document: widget.document,
              showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
              parentTaskId: widget.parentTaskId,
              onCancel: widget.onCancelCreation,
              onTaskCreated: widget.onSubtaskCreated,
            );
          }

          final subtaskIndex = widget.isCreatingSubtask ? index - 1 : index;
          if (subtaskIndex < 0 || subtaskIndex >= _displayedSubtasks.length) {
            return const SizedBox.shrink();
          }

          final subtask = _displayedSubtasks[subtaskIndex];

          // Animate new items with granular rebuilds
          return SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: _GranularSubtaskListItem(
                key: ValueKey('subtask_${subtask.id}'),
                subtask: subtask,
                document: widget.document,
                depth: widget.depth + 1,
                showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                taskTagsMap: widget.taskTagsMap,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Granular subtask item wrapper - mirrors _GranularTaskListItem from AllTasksView
/// Enables individual subtask rebuilds without affecting siblings
class _GranularSubtaskListItem extends StatefulWidget {
  final Task subtask;
  final TodoDocument document;
  final int depth;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final Map<String, List<Tag>>? taskTagsMap;

  const _GranularSubtaskListItem({
    super.key,
    required this.subtask,
    required this.document,
    required this.depth,
    this.showAllPropertiesNotifier,
    this.taskTagsMap,
  });

  @override
  State<_GranularSubtaskListItem> createState() => _GranularSubtaskListItemState();
}

class _GranularSubtaskListItemState extends State<_GranularSubtaskListItem> {
  late final AlwaysNotifyValueNotifier<Task> _subtaskNotifier;

  @override
  void initState() {
    super.initState();
    // Initialize notifier ONCE - this is the key to granular rebuilds
    final stateManager = TaskStateManager();
    _subtaskNotifier = stateManager.getOrCreateTaskNotifier(widget.subtask.id, widget.subtask);
  }

  @override
  Widget build(BuildContext context) {
    // Only this widget rebuilds when the subtask changes!
    return ValueListenableBuilder<Task>(
      valueListenable: _subtaskNotifier,
      builder: (context, updatedSubtask, _) {
        return TaskListItem(
          task: updatedSubtask,
          document: widget.document,
          depth: widget.depth,
          onTap: null, // Subtasks don't have tap handler
          showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
          preloadedTags: widget.taskTagsMap?[updatedSubtask.id],
          taskTagsMap: widget.taskTagsMap,
        );
      },
    );
  }
}
