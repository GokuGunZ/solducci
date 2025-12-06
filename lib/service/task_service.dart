import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/models/task_completion.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing tasks with hierarchical structure and recurrence logic
/// Handles CRUD operations, tree building, task completion, and inheritance
class TaskService {
  // Singleton pattern
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  final _supabase = Supabase.instance.client;
  final _tagService = TagService();
  final _recurrenceService = RecurrenceService();

  /// Get real-time stream of tasks for a document with tree structure
  Stream<List<Task>> getTasksForDocument(String documentId) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('document_id', documentId)
        .order('position')
        .asyncMap((data) async => await _buildTaskTree(data));
  }

  /// Get flat list of tasks (without hierarchy structure)
  Stream<List<Task>> getFlatTasksForDocument(String documentId) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('document_id', documentId)
        .order('position')
        .map((data) => _parseTasks(data));
  }

  /// Get tasks filtered by status
  Future<List<Task>> getTasksByStatus(String documentId, TaskStatus status) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('document_id', documentId)
          .eq('status', status.value)
          .order('position');

      return await _buildTaskTree(response);
    } catch (e) {
      return [];
    }
  }

  /// Get a single task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('id', taskId)
          .maybeSingle();

      if (response == null) return null;

      return Task.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Get tags for a specific task
  Future<List<Tag>> getTaskTags(String taskId) async {
    try {
      final response = await _supabase
          .from('task_tags')
          .select('tag_id')
          .eq('task_id', taskId);

      final tagIds = response.map((row) => row['tag_id'] as String).toList();

      final tags = <Tag>[];
      for (final tagId in tagIds) {
        final tag = await _tagService.getTagById(tagId);
        if (tag != null) tags.add(tag);
      }

      return tags;
    } catch (e) {
      return [];
    }
  }

  /// Get effective tags for a task (own tags + inherited from parent)
  Future<List<Tag>> getEffectiveTags(String taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) return [];

    final allTags = <String, Tag>{}; // Use map to avoid duplicates

    // Get task's own tags
    final ownTags = await getTaskTags(taskId);
    for (final tag in ownTags) {
      allTags[tag.id] = tag;
    }

    // Get inherited tags from parent
    if (task.parentTaskId != null) {
      final parentTags = await getEffectiveTags(task.parentTaskId!);
      for (final tag in parentTags) {
        allTags[tag.id] = tag;
      }
    }

    return allTags.values.toList();
  }

  /// Get effective recurrence for a task (own recurrence > parent recurrence > tag recurrence)
  Future<Recurrence?> getEffectiveRecurrence(String taskId) async {
    // Priority 1: Task's own recurrence
    final taskRecurrence = await _recurrenceService.getRecurrenceForTask(taskId);
    if (taskRecurrence != null) return taskRecurrence;

    final task = await getTaskById(taskId);
    if (task == null) return null;

    // Priority 2: Parent task's effective recurrence
    if (task.parentTaskId != null) {
      final parentRecurrence = await getEffectiveRecurrence(task.parentTaskId!);
      if (parentRecurrence != null) return parentRecurrence;
    }

    // Priority 3: Tag recurrence (check all effective tags)
    final tags = await getEffectiveTags(taskId);
    for (final tag in tags) {
      final tagRecurrence = await _recurrenceService.getRecurrenceForTag(tag.id);
      if (tagRecurrence != null) return tagRecurrence;
    }

    return null;
  }

  /// Create a new task
  Future<Task> createTask(Task task, {List<String>? tagIds}) async {
    try {
      // Verify document exists
      final documentCheck = await _supabase
          .from('documents')
          .select('id')
          .eq('id', task.documentId)
          .maybeSingle();

      if (documentCheck == null) {
        throw Exception('Document not found');
      }

      // Verify parent task exists if specified
      if (task.parentTaskId != null) {
        final parent = await getTaskById(task.parentTaskId!);
        if (parent == null) {
          throw Exception('Parent task not found');
        }
      }

      final dataToInsert = task.toInsertMap();

      final response = await _supabase
          .from('tasks')
          .insert(dataToInsert)
          .select()
          .single();

      final createdTask = Task.fromMap(response);

      // Assign tags if provided
      if (tagIds != null && tagIds.isNotEmpty) {
        await assignTags(createdTask.id, tagIds);
      }

      return createdTask;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    try {
      // Prevent circular reference in hierarchy
      if (task.parentTaskId != null) {
        final descendants = await getDescendantTasks(task.id);
        final descendantIds = descendants.map((t) => t.id).toSet();
        if (descendantIds.contains(task.parentTaskId)) {
          throw Exception('Cannot set parent to a descendant task (circular reference)');
        }
      }

      final dataToUpdate = task.toUpdateMap();

      await _supabase
          .from('tasks')
          .update(dataToUpdate)
          .eq('id', task.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a task (cascades to subtasks and task_tags via DB constraints)
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId);
    } catch (e) {
      rethrow;
    }
  }

  /// Complete a task with recurrence handling
  /// For recurring tasks: adds to history and resets
  /// For non-recurring tasks: marks as completed
  Future<void> completeTask(String taskId, {String? notes}) async {
    try {
      final task = await getTaskById(taskId);
      if (task == null) {
        throw Exception('Task not found');
      }

      final recurrence = await getEffectiveRecurrence(taskId);

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
        await _checkParentCompletion(task.parentTaskId!);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Uncomplete a task (set back to pending)
  Future<void> uncompleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'status': TaskStatus.pending.value,
        'completed_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if parent task should be auto-completed
  /// If all subtasks are completed, complete the parent
  Future<void> _checkParentCompletion(String parentId) async {
    final parent = await getTaskById(parentId);
    if (parent == null) return;

    final subtasks = await getChildTasks(parentId);
    if (subtasks.isEmpty) return;

    final allCompleted = subtasks.every((t) => t.status == TaskStatus.completed);

    if (allCompleted && parent.status != TaskStatus.completed) {
      await completeTask(parentId);
    }
  }

  /// Assign tags to a task
  Future<void> assignTags(String taskId, List<String> tagIds) async {
    try {
      // Remove existing tags
      await _supabase
          .from('task_tags')
          .delete()
          .eq('task_id', taskId);

      // Add new tags
      if (tagIds.isNotEmpty) {
        final entries = tagIds.map((tagId) => {
          'task_id': taskId,
          'tag_id': tagId,
        }).toList();

        await _supabase.from('task_tags').insert(entries);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add a single tag to a task
  Future<void> addTag(String taskId, String tagId) async {
    try {
      await _supabase.from('task_tags').insert({
        'task_id': taskId,
        'tag_id': tagId,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a single tag from a task
  Future<void> removeTag(String taskId, String tagId) async {
    try {
      await _supabase
          .from('task_tags')
          .delete()
          .eq('task_id', taskId)
          .eq('tag_id', tagId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all tasks with a specific tag
  Future<List<Task>> getTasksByTag(String tagId, {bool includeCompleted = false}) async {
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
      return [];
    }
  }

  /// Get child tasks (immediate children only)
  Future<List<Task>> getChildTasks(String parentTaskId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('parent_task_id', parentTaskId)
          .order('position');

      return _parseTasks(response);
    } catch (e) {
      return [];
    }
  }

  /// Get all descendant tasks (children, grandchildren, etc.)
  Future<List<Task>> getDescendantTasks(String taskId) async {
    final descendants = <Task>[];
    final children = await getChildTasks(taskId);

    for (final child in children) {
      descendants.add(child);
      final grandchildren = await getDescendantTasks(child.id);
      descendants.addAll(grandchildren);
    }

    return descendants;
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
      return [];
    }
  }

  /// Duplicate a task (with option to duplicate subtasks)
  Future<Task> duplicateTask(String taskId, {bool includeSubtasks = false}) async {
    try {
      final original = await getTaskById(taskId);
      if (original == null) {
        throw Exception('Task not found');
      }

      // Create copy without id and with reset status
      final copy = Task.create(
        documentId: original.documentId,
        parentTaskId: original.parentTaskId,
        title: '${original.title} (Copy)',
        description: original.description,
        priority: original.priority,
        dueDate: original.dueDate,
        position: original.position + 1,
      );

      // Get original tags
      final tags = await getTaskTags(taskId);
      final tagIds = tags.map((t) => t.id).toList();

      final created = await createTask(copy, tagIds: tagIds);

      // Duplicate subtasks if requested
      if (includeSubtasks) {
        final subtasks = await getChildTasks(taskId);
        for (final subtask in subtasks) {
          final subtaskCopy = Task.create(
            documentId: subtask.documentId,
            parentTaskId: created.id, // Link to new parent
            title: subtask.title,
            description: subtask.description,
            priority: subtask.priority,
            dueDate: subtask.dueDate,
            position: subtask.position,
          );

          final subtaskTags = await getTaskTags(subtask.id);
          final subtaskTagIds = subtaskTags.map((t) => t.id).toList();

          await createTask(subtaskCopy, tagIds: subtaskTagIds);
        }
      }

      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Reorder tasks within a document or parent
  Future<void> reorderTasks(List<String> taskIds) async {
    try {
      for (int i = 0; i < taskIds.length; i++) {
        await _supabase
            .from('tasks')
            .update({'position': i, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', taskIds[i]);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Search tasks by title
  Future<List<Task>> searchTasks(String documentId, String query) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('document_id', documentId)
          .ilike('title', '%$query%')
          .order('position');

      return _parseTasks(response);
    } catch (e) {
      return [];
    }
  }

  /// Get overdue tasks for a document
  Future<List<Task>> getOverdueTasks(String documentId) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('document_id', documentId)
          .neq('status', TaskStatus.completed.value)
          .lt('due_date', now)
          .order('due_date');

      return _parseTasks(response);
    } catch (e) {
      return [];
    }
  }

  /// Get task statistics for a document
  Future<Map<String, int>> getTaskStatistics(String documentId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('status')
          .eq('document_id', documentId);

      final stats = <String, int>{
        'total': response.length,
        'pending': 0,
        'completed': 0,
        'in_progress': 0,
        'assigned': 0,
      };

      for (final row in response) {
        final status = row['status'] as String;
        if (status == 'pending') stats['pending'] = stats['pending']! + 1;
        if (status == 'completed') stats['completed'] = stats['completed']! + 1;
        if (status == 'in_progress') stats['in_progress'] = stats['in_progress']! + 1;
        if (status == 'assigned') stats['assigned'] = stats['assigned']! + 1;
      }

      return stats;
    } catch (e) {
      return {'total': 0, 'pending': 0, 'completed': 0, 'in_progress': 0, 'assigned': 0};
    }
  }

  /// Build task tree structure from flat list
  /// Returns only root tasks with subtasks populated recursively
  Future<List<Task>> _buildTaskTree(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return [];

    // Parse all tasks
    final allTasks = _parseTasks(data);

    // Create a map for quick lookup
    final taskMap = <String, Task>{};
    for (final task in allTasks) {
      taskMap[task.id] = task;
    }

    // Build tree by assigning children to parents
    final rootTasks = <Task>[];

    for (final task in allTasks) {
      if (task.parentTaskId == null) {
        // Root task
        rootTasks.add(task);
      } else {
        // Child task - add to parent's subtasks
        final parent = taskMap[task.parentTaskId];
        if (parent != null) {
          parent.subtasks ??= [];
          parent.subtasks!.add(task);
        } else {
          // Parent not found, treat as root (orphaned)
          rootTasks.add(task);
        }
      }
    }

    return rootTasks;
  }

  /// Parse list of task maps to Task objects (flat, no hierarchy)
  List<Task> _parseTasks(List<Map<String, dynamic>> data) {
    final tasks = <Task>[];
    for (final map in data) {
      try {
        tasks.add(Task.fromMap(map));
      } catch (e) {
        // Skip tasks that fail to parse
      }
    }
    return tasks;
  }
}
