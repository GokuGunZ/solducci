import 'package:equatable/equatable.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// States for UnifiedTaskListBloc
sealed class UnifiedTaskListState extends Equatable {
  const UnifiedTaskListState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class TaskListInitial extends UnifiedTaskListState {
  const TaskListInitial();
}

/// Loading state while fetching tasks
class TaskListLoading extends UnifiedTaskListState {
  const TaskListLoading();
}

/// Successfully loaded tasks
class TaskListLoaded extends UnifiedTaskListState {
  /// Filtered and sorted tasks ready for display
  final List<Task> tasks;

  /// Original unfiltered tasks (for efficient re-filtering)
  final List<Task> rawTasks;

  /// Current filter and sort configuration
  final FilterSortConfig filterConfig;

  /// Whether the inline task creation row is visible
  final bool isCreatingTask;

  /// Whether drag-and-drop reordering is enabled
  final bool isReorderMode;

  /// Whether this data source supports custom ordering
  final bool supportsReordering;

  const TaskListLoaded({
    required this.tasks,
    required this.rawTasks,
    this.filterConfig = const FilterSortConfig(),
    this.isCreatingTask = false,
    this.isReorderMode = false,
    this.supportsReordering = false,
  });

  /// Create a copy with updated fields
  TaskListLoaded copyWith({
    List<Task>? tasks,
    List<Task>? rawTasks,
    FilterSortConfig? filterConfig,
    bool? isCreatingTask,
    bool? isReorderMode,
    bool? supportsReordering,
  }) {
    return TaskListLoaded(
      tasks: tasks ?? this.tasks,
      rawTasks: rawTasks ?? this.rawTasks,
      filterConfig: filterConfig ?? this.filterConfig,
      isCreatingTask: isCreatingTask ?? this.isCreatingTask,
      isReorderMode: isReorderMode ?? this.isReorderMode,
      supportsReordering: supportsReordering ?? this.supportsReordering,
    );
  }

  @override
  List<Object?> get props => [
        tasks,
        rawTasks,
        filterConfig,
        isCreatingTask,
        isReorderMode,
        supportsReordering,
      ];
}

/// Error state when task loading fails
class TaskListError extends UnifiedTaskListState {
  final String message;
  final Object? error;

  const TaskListError(this.message, [this.error]);

  @override
  List<Object?> get props => [message, error];
}
