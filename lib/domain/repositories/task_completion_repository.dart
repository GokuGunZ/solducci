import 'package:solducci/models/task_completion.dart';

/// Repository interface for task completion operations
///
/// Abstracts database operations for task completions,
/// enabling testability and separation of concerns.
abstract class TaskCompletionRepository {
  /// Insert a new completion record for a recurring task
  Future<void> insertCompletion({
    required String taskId,
    required DateTime completedAt,
    String? notes,
  });

  /// Update task status to completed
  Future<void> markTaskCompleted({
    required String taskId,
    required DateTime completedAt,
  });

  /// Update task status to pending (uncomplete)
  Future<void> markTaskPending({
    required String taskId,
  });

  /// Reset recurring task with new due date
  Future<void> resetRecurringTask({
    required String taskId,
    DateTime? nextDueDate,
  });

  /// Get completion history for a task
  Future<List<TaskCompletion>> getCompletionHistory(String taskId);
}
