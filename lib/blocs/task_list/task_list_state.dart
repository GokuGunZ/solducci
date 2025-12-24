import 'package:equatable/equatable.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// States for TaskListBloc
///
/// Represents the current state of the task list UI.
/// Uses sealed class pattern for exhaustive pattern matching.
sealed class TaskListState extends Equatable {
  const TaskListState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class TaskListInitial extends TaskListState {
  const TaskListInitial();
}

/// Loading state while fetching tasks from repository
class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

/// Successfully loaded tasks
///
/// Contains the filtered/sorted task list and all UI state flags.
/// This is the primary state that the UI renders.
class TaskListLoaded extends TaskListState {
  /// Filtered and sorted tasks ready for display
  final List<Task> tasks;

  /// Current filter and sort configuration
  final FilterSortConfig filterConfig;

  /// Whether drag-and-drop reordering is enabled
  final bool isReorderMode;

  /// Whether the inline task creation row is visible
  final bool isCreatingTask;

  /// Original unfiltered tasks (for efficient re-filtering)
  final List<Task> rawTasks;

  const TaskListLoaded({
    required this.tasks,
    required this.rawTasks,
    this.filterConfig = const FilterSortConfig(),
    this.isReorderMode = false,
    this.isCreatingTask = false,
  });

  /// Create a copy with updated fields
  TaskListLoaded copyWith({
    List<Task>? tasks,
    List<Task>? rawTasks,
    FilterSortConfig? filterConfig,
    bool? isReorderMode,
    bool? isCreatingTask,
  }) {
    return TaskListLoaded(
      tasks: tasks ?? this.tasks,
      rawTasks: rawTasks ?? this.rawTasks,
      filterConfig: filterConfig ?? this.filterConfig,
      isReorderMode: isReorderMode ?? this.isReorderMode,
      isCreatingTask: isCreatingTask ?? this.isCreatingTask,
    );
  }

  @override
  List<Object?> get props => [
        tasks,
        rawTasks,
        filterConfig,
        isReorderMode,
        isCreatingTask,
      ];
}

/// Error state when task loading fails
class TaskListError extends TaskListState {
  final String message;
  final Object? error;

  const TaskListError(this.message, [this.error]);

  @override
  List<Object?> get props => [message, error];
}
