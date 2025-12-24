import 'package:equatable/equatable.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// Events for TaskListBloc
///
/// Handles all user interactions and system events that affect the task list:
/// - Loading tasks from repository
/// - Applying filters and sorting
/// - Reordering tasks
/// - Task creation lifecycle
/// - Manual refresh requests
sealed class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

/// Request to load tasks for a specific document
class TaskListLoadRequested extends TaskListEvent {
  final String documentId;

  const TaskListLoadRequested(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Filter or sort configuration changed
///
/// Triggers re-filtering and re-sorting of the current task list.
/// Does NOT reload from repository - works with cached tasks for performance.
class TaskListFilterChanged extends TaskListEvent {
  final FilterSortConfig config;

  const TaskListFilterChanged(this.config);

  @override
  List<Object?> get props => [config];
}

/// Task reordered via drag-and-drop
///
/// Updates task positions and persists the new custom order.
/// Only applicable when sortBy == TaskSortOption.custom.
class TaskListTaskReordered extends TaskListEvent {
  final int oldIndex;
  final int newIndex;

  const TaskListTaskReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// User started inline task creation
///
/// Shows the task creation row and updates UI state.
class TaskListTaskCreationStarted extends TaskListEvent {
  const TaskListTaskCreationStarted();
}

/// Task creation completed (success or cancel)
///
/// Hides the task creation row and triggers list refresh.
class TaskListTaskCreationCompleted extends TaskListEvent {
  const TaskListTaskCreationCompleted();
}

/// Manual refresh requested
///
/// Forces reload from repository, bypassing cache.
/// Used after external changes (e.g., task added from detail page).
class TaskListRefreshRequested extends TaskListEvent {
  const TaskListRefreshRequested();
}

/// Enable/disable reorder mode
///
/// Toggles drag-and-drop reordering capability.
/// Auto-switches to custom sort when enabled.
class TaskListReorderModeToggled extends TaskListEvent {
  final bool enabled;

  const TaskListReorderModeToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
