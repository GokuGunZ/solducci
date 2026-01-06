import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/domain/repositories/task_tag_repository.dart';
import 'package:solducci/service/task/task_hierarchy_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// Service responsible for task-tag relationship operations
///
/// Handles tag assignment, removal, inheritance from parent tasks,
/// and tag-based queries. Focuses exclusively on the relationship
/// between tasks and tags, following the Single Responsibility Principle.
class TaskTagService {
  final TaskTagRepository _repository;
  final TaskHierarchyService _hierarchyService;
  final TaskStateManager _stateManager;

  TaskTagService(
    this._repository,
    this._hierarchyService,
    this._stateManager,
  );

  /// Get tags for a specific task (own tags only, no inheritance)
  Future<List<Tag>> getTaskTags(String taskId) async {
    try {
      final tagIds = await _repository.getTaskTagIds(taskId);
      final tags = await _repository.getTagsByIds(tagIds);
      return tags;
    } catch (e) {
      AppLogger.error('Error fetching task tags: $e');
      return [];
    }
  }

  /// Get effective tags for a task (own tags + inherited from parent)
  ///
  /// Requires taskFetcher to get task by ID.
  Future<List<Tag>> getEffectiveTags(
    String taskId, {
    required Future<Task?> Function(String) taskFetcher,
  }) async {
    final task = await taskFetcher(taskId);
    if (task == null) return [];

    final allTags = <String, Tag>{}; // Use map to avoid duplicates

    // Get task's own tags
    final ownTags = await getTaskTags(taskId);
    for (final tag in ownTags) {
      allTags[tag.id] = tag;
    }

    // Get inherited tags from parent (recursive)
    if (task.parentTaskId != null) {
      final parentTags = await getEffectiveTags(
        task.parentTaskId!,
        taskFetcher: taskFetcher,
      );
      for (final tag in parentTags) {
        allTags[tag.id] = tag;
      }
    }

    return allTags.values.toList();
  }

  /// Get effective tags for multiple tasks in batch (optimized)
  /// Returns a map of taskId to List of Tag
  Future<Map<String, List<Tag>>> getEffectiveTagsForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};

    final result = <String, List<Tag>>{};

    // Batch load all task-tag relationships
    final taskTagMap = await _repository.getTaskTagsForTasks(taskIds);

    // Get all unique tag IDs
    final allTagIds = taskTagMap.values.expand((ids) => ids).toSet();

    // Batch load all tags
    final tagMap = <String, Tag>{};
    if (allTagIds.isNotEmpty) {
      final tags = await _repository.getTagsByIds(allTagIds.toList());
      for (final tag in tags) {
        tagMap[tag.id] = tag;
      }
    }

    // Build result map
    for (final taskId in taskIds) {
      final tagIds = taskTagMap[taskId] ?? [];
      final tags = tagIds.map((id) => tagMap[id]).whereType<Tag>().toList();
      result[taskId] = tags;
    }

    return result;
  }

  /// Get effective tags for tasks including all subtasks (recursive)
  /// Returns a map of taskId to List of Tag for all tasks and their descendants
  Future<Map<String, List<Tag>>> getEffectiveTagsForTasksWithSubtasks(List<Task> tasks) async {
    // Collect all task IDs including subtasks recursively
    final allTaskIds = <String>{};

    void collectTaskIds(Task task) {
      allTaskIds.add(task.id);
      if (task.subtasks != null) {
        for (final subtask in task.subtasks!) {
          collectTaskIds(subtask);
        }
      }
    }

    for (final task in tasks) {
      collectTaskIds(task);
    }

    // Use the existing batch loading method
    return await getEffectiveTagsForTasks(allTaskIds.toList());
  }

  /// Assign tags to a task (replaces existing tags)
  ///
  /// Requires taskFetcher to trigger UI update after tag change.
  Future<void> assignTags(
    String taskId,
    List<String> tagIds, {
    required Future<Task?> Function(String) taskFetcher,
  }) async {
    try {
      await _repository.assignTags(taskId, tagIds);

      // CRITICAL: Tags changed, need to trigger UI rebuild
      // Refetch task and notify state manager
      final updatedTask = await taskFetcher(taskId);
      if (updatedTask != null) {
        _stateManager.updateTask(updatedTask);
      }
    } catch (e) {
      AppLogger.error('Error assigning tags: $e');
      rethrow;
    }
  }

  /// Add a single tag to a task
  ///
  /// Requires taskFetcher to trigger UI update after tag change.
  Future<void> addTag(
    String taskId,
    String tagId, {
    required Future<Task?> Function(String) taskFetcher,
  }) async {
    try {
      await _repository.addTag(taskId, tagId);

      // CRITICAL: Tag added, trigger UI rebuild
      final updatedTask = await taskFetcher(taskId);
      if (updatedTask != null) {
        _stateManager.updateTask(updatedTask);
      }
    } catch (e) {
      AppLogger.error('Error adding tag: $e');
      rethrow;
    }
  }

  /// Remove a single tag from a task
  ///
  /// Requires taskFetcher to trigger UI update after tag change.
  Future<void> removeTag(
    String taskId,
    String tagId, {
    required Future<Task?> Function(String) taskFetcher,
  }) async {
    try {
      await _repository.removeTag(taskId, tagId);

      // CRITICAL: Tag removed, trigger UI rebuild
      final updatedTask = await taskFetcher(taskId);
      if (updatedTask != null) {
        _stateManager.updateTask(updatedTask);
      }
    } catch (e) {
      AppLogger.error('Error removing tag: $e');
      rethrow;
    }
  }

  /// Get all tasks with a specific tag (with subtasks included in tree)
  ///
  /// Requires childrenFetcher for loading subtasks recursively.
  Future<List<Task>> getTasksByTag(
    String tagId, {
    bool includeCompleted = false,
    required Future<List<Task>> Function(String) childrenFetcher,
  }) async {
    try {
      // Get all tasks with this tag from repository
      final tasksWithTag = await _repository.getTasksByTag(
        tagId,
        includeCompleted: includeCompleted,
      );

      // For each task with tag, get all its descendants (subtasks)
      final allTasks = <Task>[];
      final processedIds = <String>{};

      for (final task in tasksWithTag) {
        if (!processedIds.contains(task.id)) {
          // Load the full task tree starting from this task
          final taskWithSubtasks = await _hierarchyService.loadTaskWithSubtasks(
            task.id,
            includeCompleted: includeCompleted,
            childrenFetcher: childrenFetcher,
          );
          if (taskWithSubtasks != null) {
            allTasks.add(taskWithSubtasks);
            processedIds.add(taskWithSubtasks.id);
            // Mark all descendants as processed
            _hierarchyService.markDescendantsAsProcessed(taskWithSubtasks, processedIds);
          }
        }
      }

      return allTasks;
    } catch (e) {
      AppLogger.error('Error fetching tasks by tag: $e');
      return [];
    }
  }
}
