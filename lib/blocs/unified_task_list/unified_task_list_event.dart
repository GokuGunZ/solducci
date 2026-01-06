import 'package:equatable/equatable.dart';
import 'package:solducci/blocs/unified_task_list/task_list_data_source.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// Events for UnifiedTaskListBloc
sealed class UnifiedTaskListEvent extends Equatable {
  const UnifiedTaskListEvent();

  @override
  List<Object?> get props => [];
}

/// Load tasks from a specific data source
class TaskListLoadRequested extends UnifiedTaskListEvent {
  final TaskListDataSource dataSource;

  const TaskListLoadRequested(this.dataSource);

  @override
  List<Object?> get props => [dataSource];
}

/// Change filter/sort configuration
class TaskListFilterChanged extends UnifiedTaskListEvent {
  final FilterSortConfig config;

  const TaskListFilterChanged(this.config);

  @override
  List<Object?> get props => [config];
}

/// Reorder tasks (drag-and-drop)
class TaskListTaskReordered extends UnifiedTaskListEvent {
  final int oldIndex;
  final int newIndex;

  const TaskListTaskReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Start inline task creation
class TaskListTaskCreationStarted extends UnifiedTaskListEvent {
  const TaskListTaskCreationStarted();
}

/// Complete inline task creation
class TaskListTaskCreationCompleted extends UnifiedTaskListEvent {
  const TaskListTaskCreationCompleted();
}

/// Manual refresh request
class TaskListRefreshRequested extends UnifiedTaskListEvent {
  const TaskListRefreshRequested();
}

/// Toggle reorder mode (for custom ordering)
class TaskListReorderModeToggled extends UnifiedTaskListEvent {
  final bool enabled;

  const TaskListReorderModeToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
