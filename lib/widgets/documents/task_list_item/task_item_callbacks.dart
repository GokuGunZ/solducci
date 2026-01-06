import 'package:solducci/models/task.dart';

/// Callbacks for TaskListItem user interactions.
///
/// Groups all event handlers into a single object to reduce constructor
/// parameters and improve code organization. All callbacks are optional.
class TaskItemCallbacks {
  /// Called when the task item is tapped
  final VoidCallback? onTap;

  /// Called when the task is modified (status, properties, etc.)
  ///
  /// Note: This is now deprecated in favor of reactive state management
  /// via TaskStateManager. Left for backward compatibility.
  @Deprecated('Use TaskStateManager for reactive updates')
  final VoidCallback? onChanged;

  /// Called when a delete operation is requested
  ///
  /// Return a Future that completes when the delete is done.
  /// If the Future completes with an error, the delete will be cancelled.
  final Future<void> Function(Task task)? onDelete;

  /// Called when a duplicate operation is requested
  ///
  /// Return a Future that completes when the duplicate is done.
  final Future<void> Function(Task task)? onDuplicate;

  /// Called when task completion status changes
  ///
  /// Receives the new completion status (true = completed, false = pending).
  final Future<void> Function(Task task, bool completed)? onCompletionChanged;

  /// Called when subtasks expand/collapse state changes
  final void Function(bool isExpanded)? onExpansionChanged;

  const TaskItemCallbacks({
    this.onTap,
    this.onChanged,
    this.onDelete,
    this.onDuplicate,
    this.onCompletionChanged,
    this.onExpansionChanged,
  });

  /// Create an empty callbacks object (all callbacks are null)
  const TaskItemCallbacks.empty()
      : onTap = null,
        onChanged = null,
        onDelete = null,
        onDuplicate = null,
        onCompletionChanged = null,
        onExpansionChanged = null;

  /// Create a copy with some callbacks replaced
  TaskItemCallbacks copyWith({
    VoidCallback? onTap,
    VoidCallback? onChanged,
    Future<void> Function(Task task)? onDelete,
    Future<void> Function(Task task)? onDuplicate,
    Future<void> Function(Task task, bool completed)? onCompletionChanged,
    void Function(bool isExpanded)? onExpansionChanged,
  }) {
    return TaskItemCallbacks(
      onTap: onTap ?? this.onTap,
      onChanged: onChanged ?? this.onChanged,
      onDelete: onDelete ?? this.onDelete,
      onDuplicate: onDuplicate ?? this.onDuplicate,
      onCompletionChanged: onCompletionChanged ?? this.onCompletionChanged,
      onExpansionChanged: onExpansionChanged ?? this.onExpansionChanged,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskItemCallbacks &&
        other.onTap == onTap &&
        other.onChanged == onChanged &&
        other.onDelete == onDelete &&
        other.onDuplicate == onDuplicate &&
        other.onCompletionChanged == onCompletionChanged &&
        other.onExpansionChanged == onExpansionChanged;
  }

  @override
  int get hashCode {
    return Object.hash(
      onTap,
      onChanged,
      onDelete,
      onDuplicate,
      onCompletionChanged,
      onExpansionChanged,
    );
  }

  @override
  String toString() {
    return 'TaskItemCallbacks('
        'onTap: ${onTap != null}, '
        'onDelete: ${onDelete != null}, '
        'onDuplicate: ${onDuplicate != null}, '
        'onCompletionChanged: ${onCompletionChanged != null}'
        ')';
  }
}

/// Type alias for void callback (used for backward compatibility)
typedef VoidCallback = void Function();
