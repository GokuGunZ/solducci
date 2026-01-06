import 'package:solducci/domain/repositories/task_tag_repository.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// In-memory implementation of TaskTagRepository for testing
class InMemoryTaskTagRepository implements TaskTagRepository {
  // Storage: taskId -> List of tagIds
  final Map<String, List<String>> _taskTags = {};

  // Storage: tagId -> Tag object
  final Map<String, Tag> _tags = {};

  // Storage: taskId -> Task object (for getTasksByTag)
  final Map<String, Task> _tasks = {};

  /// Register a tag for this repository to use
  void registerTag(Tag tag) {
    _tags[tag.id] = tag;
  }

  /// Register a task for this repository to use
  void registerTask(Task task) {
    _tasks[task.id] = task;
  }

  @override
  Future<List<String>> getTaskTagIds(String taskId) async {
    return List.from(_taskTags[taskId] ?? []);
  }

  @override
  Future<List<Tag>> getTagsByIds(List<String> tagIds) async {
    final tags = <Tag>[];
    for (final tagId in tagIds) {
      final tag = _tags[tagId];
      if (tag != null) tags.add(tag);
    }
    return tags;
  }

  @override
  Future<List<Task>> getTasksByTag(
    String tagId, {
    bool includeCompleted = false,
  }) async {
    final tasksWithTag = <Task>[];

    for (final entry in _taskTags.entries) {
      final taskId = entry.key;
      final tagIds = entry.value;

      if (tagIds.contains(tagId)) {
        final task = _tasks[taskId];
        if (task != null) {
          // Filter by completion status
          if (includeCompleted || task.status != TaskStatus.completed) {
            tasksWithTag.add(task);
          }
        }
      }
    }

    // Sort by position (like Supabase)
    tasksWithTag.sort((a, b) => a.position.compareTo(b.position));
    return tasksWithTag;
  }

  @override
  Future<void> assignTags(String taskId, List<String> tagIds) async {
    // Replace existing tags
    _taskTags[taskId] = List.from(tagIds);
    AppLogger.debug('InMemory: Assigned ${tagIds.length} tags to task: $taskId');
  }

  @override
  Future<void> addTag(String taskId, String tagId) async {
    _taskTags.putIfAbsent(taskId, () => []).add(tagId);
    AppLogger.debug('InMemory: Added tag $tagId to task: $taskId');
  }

  @override
  Future<void> removeTag(String taskId, String tagId) async {
    _taskTags[taskId]?.remove(tagId);
    AppLogger.debug('InMemory: Removed tag $tagId from task: $taskId');
  }

  @override
  Future<Map<String, List<String>>> getTaskTagsForTasks(
    List<String> taskIds,
  ) async {
    final result = <String, List<String>>{};

    for (final taskId in taskIds) {
      final tagIds = _taskTags[taskId];
      if (tagIds != null && tagIds.isNotEmpty) {
        result[taskId] = List.from(tagIds);
      }
    }

    return result;
  }

  /// Clear all data (for test teardown)
  void clear() {
    _taskTags.clear();
    _tags.clear();
    _tasks.clear();
  }
}
