import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/models/task_completion.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing tasks with hierarchical structure and recurrence logic
/// Handles business logic for tasks including tag management, recurrence,
/// completion logic, and state management.
/// Uses TaskRepository for data access.
class TaskService {
  // Singleton pattern
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  final _supabase = Supabase.instance.client;
  late final TaskRepository _repository;
  final _tagService = TagService();
  final _recurrenceService = RecurrenceService();
  final _stateManager = TaskStateManager();

  /// Initialize the service with repository from service locator
  void initialize() {
    _repository = getIt<TaskRepository>();
    AppLogger.debug('TaskService initialized with repository');
  }

  /// Get real-time stream of tasks for a document with tree structure
  /// Uses repository's watchAll method which handles realtime updates
  Stream<List<Task>> getTasksForDocument(String documentId) {
    AppLogger.debug('Setting up stream for document: $documentId');
    return _repository.watchAll(documentId: documentId).asBroadcastStream();
  }

  /// Get flat list of tasks (without hierarchy structure)
  /// Note: This now returns tasks with hierarchy. If flat list is truly needed,
  /// consider adding a separate method to flatten the tree.
  Stream<List<Task>> getFlatTasksForDocument(String documentId) {
    return _repository.watchAll(documentId: documentId);
  }

  /// Get tasks as a Future (one-time fetch) - useful for manual refresh
  Future<List<Task>> fetchTasksForDocument(String documentId) async {
    try {
      final rootTasks = await _repository.getAll(documentId: documentId);

      AppLogger.debug('🌳 Fetched tree: ${rootTasks.length} root tasks');
      for (final root in rootTasks) {
        AppLogger.debug('   Root: ${root.id.substring(0, 8)} with ${root.subtasks?.length ?? 0} subtasks');
      }

      return rootTasks;
    } catch (e) {
      AppLogger.error('❌ Error fetching tasks: $e');
      return [];
    }
  }

  /// Get tasks filtered by status
  Future<List<Task>> getTasksByStatus(String documentId, TaskStatus status) async {
    try {
      return await _repository.getByStatus(documentId, status);
    } catch (e) {
      AppLogger.error('Error fetching tasks by status: $e');
      return [];
    }
  }

  /// Get a single task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      return await _repository.getById(taskId);
    } catch (e) {
      AppLogger.error('Error fetching task by ID: $e');
      return null;
    }
  }

  /// Get a task by ID WITH all its subtasks properly loaded (recursive)
  /// This is the correct method to use when you need the full task tree
  Future<Task?> getTaskWithSubtasks(String taskId) async {
    try {
      return await _repository.getWithSubtasks(taskId);
    } catch (e) {
      AppLogger.error('❌ Error fetching task with subtasks: $e');
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

  /// Get effective tags for multiple tasks in batch (optimized)
  /// Returns a map of taskId to List of Tag
  Future<Map<String, List<Tag>>> getEffectiveTagsForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};

    final result = <String, List<Tag>>{};

    // Batch load all task-tag relationships
    final taskTagsResponse = await _supabase
        .from('task_tags')
        .select('task_id, tag_id')
        .inFilter('task_id', taskIds);

    // Group by task_id
    final taskTagMap = <String, List<String>>{};
    for (final row in taskTagsResponse) {
      final taskId = row['task_id'] as String;
      final tagId = row['tag_id'] as String;
      taskTagMap.putIfAbsent(taskId, () => []).add(tagId);
    }

    // Get all unique tag IDs
    final allTagIds = taskTagMap.values.expand((ids) => ids).toSet();

    // Batch load all tags
    final tagMap = <String, Tag>{};
    for (final tagId in allTagIds) {
      final tag = await _tagService.getTagById(tagId);
      if (tag != null) tagMap[tagId] = tag;
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
      // Business logic: Verify parent task exists and handle completion status
      if (task.parentTaskId != null) {
        final parent = await getTaskById(task.parentTaskId!);
        if (parent == null) {
          throw Exception('Parent task not found');
        }

        // If parent is completed, uncomplete it (can't have incomplete subtasks)
        if (parent.status == TaskStatus.completed) {
          await uncompleteTask(parent.id);
        }
      }

      // Use repository for data access
      final createdTask = await _repository.create(task);

      AppLogger.info('✅ Task created: ${createdTask.id} - ${createdTask.title}');

      // Business logic: Assign tags if provided
      if (tagIds != null && tagIds.isNotEmpty) {
        await assignTags(createdTask.id, tagIds);
      }

      // Business logic: State management
      _stateManager.getOrCreateTaskNotifier(createdTask.id, createdTask);
      _stateManager.notifyListChange(createdTask.documentId);
      AppLogger.debug('🔔 State updated for task: ${createdTask.id}');

      return createdTask;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    try {
      // Business logic: Prevent circular reference in hierarchy
      if (task.parentTaskId != null) {
        final descendants = await getDescendantTasks(task.id);
        final descendantIds = descendants.map((t) => t.id).toSet();
        if (descendantIds.contains(task.parentTaskId)) {
          throw Exception('Cannot set parent to a descendant task (circular reference)');
        }
      }

      // Use repository for data access
      final updatedTask = await _repository.update(task);

      // Business logic: State management
      _stateManager.updateTask(updatedTask);

      // If this is a subtask, also update parent to refresh subtasks list
      if (updatedTask.parentTaskId != null) {
        final parentTask = await getTaskById(updatedTask.parentTaskId!);
        if (parentTask != null) {
          _stateManager.updateTask(parentTask);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a task (cascades to subtasks and task_tags via DB constraints)
  Future<void> deleteTask(String taskId) async {
    try {
      // Use repository for data access
      await _repository.delete(taskId);

      // No need to notify - Supabase stream will automatically emit DELETE
      // and the UI will update via StreamBuilder
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

      // Check if task has incomplete subtasks
      final subtasks = await getChildTasks(taskId);
      if (subtasks.isNotEmpty) {
        final hasIncompleteSubtasks = subtasks.any((t) => t.status != TaskStatus.completed);
        if (hasIncompleteSubtasks) {
          throw Exception('Non puoi completare una task con subtask incomplete');
        }
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

      // No notification needed - Supabase stream will emit UPDATE
      // Task will be filtered out from AllTasksView automatically
    } catch (e) {
      rethrow;
    }
  }

  /// Uncomplete a task (set back to pending)
  Future<void> uncompleteTask(String taskId) async {
    try {
      final task = await getTaskById(taskId);

      await _supabase.from('tasks').update({
        'status': TaskStatus.pending.value,
        'completed_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      // If this task has a completed parent, uncomplete it too
      if (task?.parentTaskId != null) {
        final parent = await getTaskById(task!.parentTaskId!);
        if (parent != null && parent.status == TaskStatus.completed) {
          await uncompleteTask(parent.id); // Recursive uncomplete
        }
      }

      // No notification needed - Supabase stream will emit UPDATE
      // Task will be filtered back into AllTasksView automatically
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

      // CRITICAL: Tags changed, need to trigger UI rebuild
      // Refetch task and notify state manager
      // The task itself doesn't change, but the UI needs to know tags changed
      final updatedTask = await getTaskById(taskId);
      if (updatedTask != null) {
        _stateManager.updateTask(updatedTask);
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

      // CRITICAL: Tag added, trigger UI rebuild
      final updatedTask = await getTaskById(taskId);
      if (updatedTask != null) {
        _stateManager.updateTask(updatedTask);
      }
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

      // CRITICAL: Tag removed, trigger UI rebuild
      final updatedTask = await getTaskById(taskId);
      if (updatedTask != null) {
        _stateManager.updateTask(updatedTask);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all tasks with a specific tag (with subtasks included in tree)
  Future<List<Task>> getTasksByTag(String tagId, {bool includeCompleted = false}) async {
    try {
      // Get all tasks with this tag
      var query = _supabase
          .from('tasks')
          .select('*, task_tags!inner(tag_id)')
          .eq('task_tags.tag_id', tagId);

      if (!includeCompleted) {
        query = query.neq('status', TaskStatus.completed.value);
      }

      final response = await query.order('position');
      final tasksWithTag = _parseTasks(response);

      // For each task with tag, get all its descendants (subtasks)
      final allTasks = <Task>[];
      final processedIds = <String>{};

      for (final task in tasksWithTag) {
        if (!processedIds.contains(task.id)) {
          // Load the full task tree starting from this task
          final taskWithSubtasks = await _loadTaskWithSubtasks(
            task.id,
            includeCompleted: includeCompleted,
          );
          if (taskWithSubtasks != null) {
            allTasks.add(taskWithSubtasks);
            processedIds.add(taskWithSubtasks.id);
            // Mark all descendants as processed
            _markDescendantsAsProcessed(taskWithSubtasks, processedIds);
          }
        }
      }

      return allTasks;
    } catch (e) {
      return [];
    }
  }

  /// Helper to load a task with all its subtasks
  Future<Task?> _loadTaskWithSubtasks(String taskId, {bool includeCompleted = false}) async {
    final task = await getTaskById(taskId);
    if (task == null) return null;

    // Load subtasks
    final subtasks = await getChildTasks(taskId);

    if (subtasks.isNotEmpty) {
      final filteredSubtasks = <Task>[];
      for (final subtask in subtasks) {
        // Filter by completion status
        if (!includeCompleted && subtask.status == TaskStatus.completed) {
          continue;
        }

        // Recursively load subtask's children
        final subtaskWithChildren = await _loadTaskWithSubtasks(
          subtask.id,
          includeCompleted: includeCompleted,
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
  void _markDescendantsAsProcessed(Task task, Set<String> processedIds) {
    if (task.subtasks != null) {
      for (final subtask in task.subtasks!) {
        processedIds.add(subtask.id);
        _markDescendantsAsProcessed(subtask, processedIds);
      }
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

  /// Parse list of task maps to Task objects (flat, no hierarchy)
  /// Still used by methods that directly query task_tags and other related tables
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
