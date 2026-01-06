import 'package:solducci/models/task.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// Service responsible for complex task hierarchy operations
///
/// Handles recursive tree operations, subtask loading with filtering,
/// and hierarchy validation. Simple data queries (getChildTasks, getDescendantTasks)
/// remain in TaskService.
///
/// This service focuses exclusively on complex hierarchical business logic,
/// following the Single Responsibility Principle.
class TaskHierarchyService {
  final TaskRepository _repository;

  TaskHierarchyService(this._repository);

  /// Get a task by ID WITH all its subtasks properly loaded (recursive)
  /// This delegates to repository which handles the tree building
  Future<Task?> getTaskWithSubtasks(String taskId) async {
    try {
      return await _repository.getWithSubtasks(taskId);
    } catch (e) {
      AppLogger.error('❌ Error fetching task with subtasks: $e');
      return null;
    }
  }

  /// Helper to load a task with all its subtasks recursively
  ///
  /// Used by tag-based queries and other operations that need
  /// to filter tasks while maintaining the tree structure.
  ///
  /// Requires a childrenFetcher function to get immediate children,
  /// allowing this service to remain decoupled from data access.
  Future<Task?> loadTaskWithSubtasks(
    String taskId, {
    bool includeCompleted = false,
    required Future<List<Task>> Function(String) childrenFetcher,
  }) async {
    final task = await _repository.getById(taskId);
    if (task == null) return null;

    // Load subtasks using provided fetcher
    final subtasks = await childrenFetcher(taskId);

    if (subtasks.isNotEmpty) {
      final filteredSubtasks = <Task>[];
      for (final subtask in subtasks) {
        // Filter by completion status
        if (!includeCompleted && subtask.status == TaskStatus.completed) {
          continue;
        }

        // Recursively load subtask's children
        final subtaskWithChildren = await loadTaskWithSubtasks(
          subtask.id,
          includeCompleted: includeCompleted,
          childrenFetcher: childrenFetcher,
        );
        if (subtaskWithChildren != null) {
          filteredSubtasks.add(subtaskWithChildren);
        }
      }

      task.subtasks = filteredSubtasks.isEmpty ? null : filteredSubtasks;
    }

    return task;
  }

  /// Helper to mark all descendants as processed
  ///
  /// Used when processing task trees to avoid duplicate processing.
  /// Recursively adds all subtask IDs to the processed set.
  void markDescendantsAsProcessed(Task task, Set<String> processedIds) {
    if (task.subtasks != null) {
      for (final subtask in task.subtasks!) {
        processedIds.add(subtask.id);
        markDescendantsAsProcessed(subtask, processedIds);
      }
    }
  }

  /// Validate that setting a parent wouldn't create a circular reference
  ///
  /// Returns true if the proposed parent is valid, false if it would
  /// create a circular reference (e.g., setting a descendant as parent).
  ///
  /// Requires a descendantsFetcher function to get all descendants,
  /// allowing this service to remain decoupled from data access.
  Future<bool> validateParentChange(
    String taskId,
    String? newParentId, {
    required Future<List<Task>> Function(String) descendantsFetcher,
  }) async {
    if (newParentId == null) return true;

    // Check if the new parent is actually a descendant of this task
    final descendants = await descendantsFetcher(taskId);
    final descendantIds = descendants.map((t) => t.id).toSet();

    return !descendantIds.contains(newParentId);
  }
}
