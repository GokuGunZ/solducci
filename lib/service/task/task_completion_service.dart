import 'package:solducci/models/task.dart';
import 'package:solducci/models/task_completion.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/domain/repositories/task_completion_repository.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// Service responsible for task completion operations
///
/// Handles task completion/uncompletion logic, recurrence handling,
/// completion history, parent auto-completion, and subtask validation.
/// Focuses exclusively on completion-related business logic,
/// following the Single Responsibility Principle.
///
/// Refactored to use dependency injection for testability.
class TaskCompletionService {
  final TaskCompletionRepository _repository;

  TaskCompletionService(this._repository);

  /// Complete a task with recurrence handling
  ///
  /// For recurring tasks: adds to history and resets
  /// For non-recurring tasks: marks as completed
  ///
  /// Requires functions to:
  /// - taskFetcher: Get task by ID
  /// - childrenFetcher: Get immediate children for validation
  /// - recurrenceFetcher: Get effective recurrence for the task
  /// - parentCompletionChecker: Check if parent should be auto-completed
  Future<void> completeTask(
    String taskId, {
    String? notes,
    required Future<Task?> Function(String) taskFetcher,
    required Future<List<Task>> Function(String) childrenFetcher,
    required Future<Recurrence?> Function(String) recurrenceFetcher,
    required Future<void> Function(String) parentCompletionChecker,
  }) async {
    try {
      final task = await taskFetcher(taskId);
      if (task == null) {
        throw Exception('Task not found');
      }

      // Check if task has incomplete subtasks
      final subtasks = await childrenFetcher(taskId);
      if (subtasks.isNotEmpty) {
        final hasIncompleteSubtasks = subtasks.any((t) => t.status != TaskStatus.completed);
        if (hasIncompleteSubtasks) {
          throw Exception('Non puoi completare una task con subtask incomplete');
        }
      }

      final recurrence = await recurrenceFetcher(taskId);
      final completedAt = DateTime.now();

      if (recurrence != null && recurrence.isActive) {
        // Recurring task: add to history and reset with next due date
        await _repository.insertCompletion(
          taskId: taskId,
          completedAt: completedAt,
          notes: notes,
        );

        // Calculate next occurrence
        final nextOccurrence = recurrence.getNextOccurrence(completedAt);

        // Reset task to pending with updated due date
        await _repository.resetRecurringTask(
          taskId: taskId,
          nextDueDate: nextOccurrence,
        );
      } else {
        // Non-recurring task: mark as completed
        await _repository.markTaskCompleted(
          taskId: taskId,
          completedAt: completedAt,
        );
      }

      // Check if parent should be auto-completed
      if (task.parentTaskId != null) {
        await parentCompletionChecker(task.parentTaskId!);
      }

      // No notification needed - Supabase stream will emit UPDATE
      // Task will be filtered out from AllTasksView automatically
    } catch (e) {
      AppLogger.error('Error completing task: $e');
      rethrow;
    }
  }

  /// Uncomplete a task (set back to pending)
  ///
  /// Requires functions to:
  /// - taskFetcher: Get task by ID
  /// - uncompleteParent: Recursively uncomplete parent if needed
  Future<void> uncompleteTask(
    String taskId, {
    required Future<Task?> Function(String) taskFetcher,
    required Future<void> Function(String) uncompleteParent,
  }) async {
    try {
      final task = await taskFetcher(taskId);

      await _repository.markTaskPending(taskId: taskId);

      // If this task has a completed parent, uncomplete it too
      if (task?.parentTaskId != null) {
        final parent = await taskFetcher(task!.parentTaskId!);
        if (parent != null && parent.status == TaskStatus.completed) {
          await uncompleteParent(parent.id); // Recursive uncomplete
        }
      }

      // No notification needed - Supabase stream will emit UPDATE
      // Task will be filtered back into AllTasksView automatically
    } catch (e) {
      AppLogger.error('Error uncompleting task: $e');
      rethrow;
    }
  }

  /// Check if parent task should be auto-completed
  ///
  /// If all subtasks are completed, complete the parent
  ///
  /// Requires functions to:
  /// - taskFetcher: Get task by ID
  /// - childrenFetcher: Get immediate children
  /// - completeParent: Complete the parent task
  Future<void> checkParentCompletion(
    String parentId, {
    required Future<Task?> Function(String) taskFetcher,
    required Future<List<Task>> Function(String) childrenFetcher,
    required Future<void> Function(String) completeParent,
  }) async {
    final parent = await taskFetcher(parentId);
    if (parent == null) return;

    final subtasks = await childrenFetcher(parentId);
    if (subtasks.isEmpty) return;

    final allCompleted = subtasks.every((t) => t.status == TaskStatus.completed);

    if (allCompleted && parent.status != TaskStatus.completed) {
      await completeParent(parentId);
    }
  }

  /// Get completion history for a recurring task
  Future<List<TaskCompletion>> getCompletionHistory(String taskId) async {
    try {
      return await _repository.getCompletionHistory(taskId);
    } catch (e) {
      AppLogger.error('Error fetching completion history: $e');
      return [];
    }
  }
}
