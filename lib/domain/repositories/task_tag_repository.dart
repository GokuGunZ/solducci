import 'package:solducci/models/tag.dart';
import 'package:solducci/models/task.dart';

/// Repository interface for task-tag relationship operations
///
/// Abstracts database operations for task-tag relationships and tag loading,
/// enabling testability and separation of concerns.
abstract class TaskTagRepository {
  /// Get tag IDs for a specific task
  Future<List<String>> getTaskTagIds(String taskId);

  /// Get tag objects by their IDs
  Future<List<Tag>> getTagsByIds(List<String> tagIds);

  /// Get tasks that have a specific tag
  Future<List<Task>> getTasksByTag(String tagId, {bool includeCompleted = false});

  /// Assign tags to a task (replaces existing tags)
  Future<void> assignTags(String taskId, List<String> tagIds);

  /// Add a single tag to a task
  Future<void> addTag(String taskId, String tagId);

  /// Remove a single tag from a task
  Future<void> removeTag(String taskId, String tagId);

  /// Batch load task-tag relationships for multiple tasks
  /// Returns a map of taskId to list of tagIds
  Future<Map<String, List<String>>> getTaskTagsForTasks(List<String> taskIds);
}
