import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';

/// Handler for task completion logic and validation
///
/// Encapsulates the business logic for completing/uncompleting tasks,
/// including validation (e.g., checking for incomplete subtasks) and
/// user feedback (snackbars).
class TaskCompletionHandler {
  final TaskService taskService;

  TaskCompletionHandler({required this.taskService});

  /// Toggle task completion status with validation and feedback
  ///
  /// Returns true if the operation succeeded, false otherwise.
  /// Shows appropriate snackbar messages for success/error.
  Future<bool> toggleComplete({
    required BuildContext context,
    required Task task,
    required bool Function() isMounted,
  }) async {
    final wasCompleted = task.isCompleted;

    // Show immediate feedback
    if (isMounted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasCompleted ? 'Task ripristinata' : 'Task completata'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Update database
    try {
      if (wasCompleted) {
        await taskService.uncompleteTask(task.id);
      } else {
        await taskService.completeTask(task.id);
      }
      return true;
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
      return false;
    }
  }

  /// Delete a task with error handling and feedback
  Future<bool> deleteTask({
    required BuildContext context,
    required String taskId,
    required String taskTitle,
    required bool Function() isMounted,
  }) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina task'),
        content: Text('Vuoi davvero eliminare "$taskTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return false;
    }

    // Delete the task
    try {
      await taskService.deleteTask(taskId);
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task eliminata')),
        );
      }
      return true;
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
      return false;
    }
  }

  /// Duplicate a task with error handling and feedback
  Future<void> duplicateTask({
    required BuildContext context,
    required String taskId,
    required bool Function() isMounted,
  }) async {
    try {
      await taskService.duplicateTask(taskId);
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task duplicata')),
        );
      }
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }
}
