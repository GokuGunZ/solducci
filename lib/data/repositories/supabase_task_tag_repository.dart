import 'package:solducci/domain/repositories/task_tag_repository.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of TaskTagRepository
class SupabaseTaskTagRepository implements TaskTagRepository {
  final SupabaseClient _supabase;
  final TagService _tagService;

  SupabaseTaskTagRepository([
    SupabaseClient? supabase,
    TagService? tagService,
  ])  : _supabase = supabase ?? Supabase.instance.client,
        _tagService = tagService ?? TagService();

  @override
  Future<List<String>> getTaskTagIds(String taskId) async {
    try {
      final response = await _supabase
          .from('task_tags')
          .select('tag_id')
          .eq('task_id', taskId);

      return response.map((row) => row['tag_id'] as String).toList();
    } catch (e) {
      AppLogger.error('Error fetching task tag IDs: $e');
      return [];
    }
  }

  @override
  Future<List<Tag>> getTagsByIds(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    try {
      final tags = <Tag>[];
      for (final tagId in tagIds) {
        final tag = await _tagService.getTagById(tagId);
        if (tag != null) tags.add(tag);
      }
      return tags;
    } catch (e) {
      AppLogger.error('Error fetching tags by IDs: $e');
      return [];
    }
  }

  @override
  Future<List<Task>> getTasksByTag(
    String tagId, {
    bool includeCompleted = false,
  }) async {
    try {
      var query = _supabase
          .from('tasks')
          .select('*, task_tags!inner(tag_id)')
          .eq('task_tags.tag_id', tagId);

      if (!includeCompleted) {
        query = query.neq('status', TaskStatus.completed.value);
      }

      final response = await query.order('position');
      return _parseTasks(response);
    } catch (e) {
      AppLogger.error('Error fetching tasks by tag: $e');
      return [];
    }
  }

  @override
  Future<void> assignTags(String taskId, List<String> tagIds) async {
    try {
      // Remove existing tags
      await _supabase.from('task_tags').delete().eq('task_id', taskId);

      // Add new tags
      if (tagIds.isNotEmpty) {
        final entries = tagIds
            .map((tagId) => {
                  'task_id': taskId,
                  'tag_id': tagId,
                })
            .toList();

        await _supabase.from('task_tags').insert(entries);
      }

      AppLogger.debug('Assigned ${tagIds.length} tags to task: $taskId');
    } catch (e) {
      AppLogger.error('Error assigning tags: $e');
      rethrow;
    }
  }

  @override
  Future<void> addTag(String taskId, String tagId) async {
    try {
      await _supabase.from('task_tags').insert({
        'task_id': taskId,
        'tag_id': tagId,
      });

      AppLogger.debug('Added tag $tagId to task: $taskId');
    } catch (e) {
      AppLogger.error('Error adding tag: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeTag(String taskId, String tagId) async {
    try {
      await _supabase
          .from('task_tags')
          .delete()
          .eq('task_id', taskId)
          .eq('tag_id', tagId);

      AppLogger.debug('Removed tag $tagId from task: $taskId');
    } catch (e) {
      AppLogger.error('Error removing tag: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, List<String>>> getTaskTagsForTasks(
    List<String> taskIds,
  ) async {
    if (taskIds.isEmpty) return {};

    try {
      final response = await _supabase
          .from('task_tags')
          .select('task_id, tag_id')
          .inFilter('task_id', taskIds);

      // Group by task_id
      final result = <String, List<String>>{};
      for (final row in response) {
        final taskId = row['task_id'] as String;
        final tagId = row['tag_id'] as String;
        result.putIfAbsent(taskId, () => []).add(tagId);
      }

      return result;
    } catch (e) {
      AppLogger.error('Error batch loading task tags: $e');
      return {};
    }
  }

  /// Parse list of task maps to Task objects (flat, no hierarchy)
  List<Task> _parseTasks(List<Map<String, dynamic>> data) {
    final tasks = <Task>[];
    for (final map in data) {
      try {
        tasks.add(Task.fromMap(map));
      } catch (e) {
        AppLogger.warning('Failed to parse task', e);
        // Skip tasks that fail to parse
      }
    }
    return tasks;
  }
}
