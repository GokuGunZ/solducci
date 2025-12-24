import 'package:solducci/models/task.dart';
import 'package:solducci/models/task_completion.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for task completion operations
///
/// Handles task completion/uncompletion logic, recurrence handling,
/// completion history, parent auto-completion, and subtask validation.
/// Focuses exclusively on completion-related business logic,
/// following the Single Responsibility Principle.
class TaskCompletionService {
  final _supabase = Supabase.instance.client;

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

      if (recurrence != null && recurrence.isActive) {
        // Recurring task: add to history and reset with next due date
        await _supabase.from('task_completions').insert({
          'task_id': taskId,
          'completed_at': DateTime.now().toIso8601String(),
          'notes': notes,
        });

        // Calculate next occurrence
        final nextOccurrence = recurrence.getNextOccurrence(DateTime.now());

        // Reset task to pending with updated due date
        final updateData = {
          'status': TaskStatus.pending.value,
          'completed_at': null,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Update due date if next occurrence is available
        if (nextOccurrence != null) {
          updateData['due_date'] = nextOccurrence.toIso8601String();
        }

        await _supabase.from('tasks').update(updateData).eq('id', taskId);
      } else {
        // Non-recurring task: mark as completed
        await _supabase.from('tasks').update({
          'status': TaskStatus.completed.value,
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', taskId);
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

      await _supabase.from('tasks').update({
        'status': TaskStatus.pending.value,
        'completed_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

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
      final response = await _supabase
          .from('task_completions')
          .select()
          .eq('task_id', taskId)
          .order('completed_at', ascending: false);

      return response.map((map) => TaskCompletion.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Error fetching completion history: $e');
      return [];
    }
  }
}
