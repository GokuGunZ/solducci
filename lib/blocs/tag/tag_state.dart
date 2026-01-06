import 'package:equatable/equatable.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// States for TagBloc
sealed class TagState extends Equatable {
  const TagState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TagInitial extends TagState {
  const TagInitial();
}

/// Loading state
class TagLoading extends TagState {
  const TagLoading();
}

/// Error state
class TagError extends TagState {
  final String message;
  final Object? error;

  const TagError(this.message, [this.error]);

  @override
  List<Object?> get props => [message, error];
}

/// Loaded state with tasks
class TagLoaded extends TagState {
  final List<Task> tasks;
  final List<Task> rawTasks; // Unfiltered tasks for re-filtering
  final FilterSortConfig filterConfig;
  final bool isCreatingTask; // True when inline task creation is active

  const TagLoaded({
    required this.tasks,
    required this.rawTasks,
    this.filterConfig = const FilterSortConfig(),
    this.isCreatingTask = false,
  });

  @override
  List<Object?> get props => [tasks, rawTasks, filterConfig, isCreatingTask];

  TagLoaded copyWith({
    List<Task>? tasks,
    List<Task>? rawTasks,
    FilterSortConfig? filterConfig,
    bool? isCreatingTask,
  }) {
    return TagLoaded(
      tasks: tasks ?? this.tasks,
      rawTasks: rawTasks ?? this.rawTasks,
      filterConfig: filterConfig ?? this.filterConfig,
      isCreatingTask: isCreatingTask ?? this.isCreatingTask,
    );
  }
}
