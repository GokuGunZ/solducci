import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/models/task_completion.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/service/task/task_hierarchy_service.dart';
import 'package:solducci/service/task/task_tag_service.dart';
import 'package:solducci/service/task/task_completion_service.dart';
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
  late final TaskHierarchyService _hierarchyService;
  late final TaskTagService _tagService;
  late final TaskCompletionService _completionService;
  final _recurrenceService = RecurrenceService();
  final _stateManager = TaskStateManager();

  /// Initialize the service with repository and specialized services from service locator
  void initialize() {
    _repository = getIt<TaskRepository>();
    _hierarchyService = getIt<TaskHierarchyService>();
    _tagService = getIt<TaskTagService>();
    _completionService = getIt<TaskCompletionService>();
    AppLogger.debug('TaskService initialized with repository and specialized services');
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
  /// Delegates to TaskHierarchyService
  Future<Task?> getTaskWithSubtasks(String taskId) async {
    return await _hierarchyService.getTaskWithSubtasks(taskId);
  }

  /// Get tags for a specific task - Delegates to TaskTagService
  Future<List<Tag>> getTaskTags(String taskId) async {
    return await _tagService.getTaskTags(taskId);
  }

  /// Get effective tags for a task (own tags + inherited from parent)
  /// Delegates to TaskTagService
  Future<List<Tag>> getEffectiveTags(String taskId) async {
    return await _tagService.getEffectiveTags(taskId, taskFetcher: getTaskById);
  }

  /// Get effective tags for multiple tasks in batch - Delegates to TaskTagService
  Future<Map<String, List<Tag>>> getEffectiveTagsForTasks(List<String> taskIds) async {
    return await _tagService.getEffectiveTagsForTasks(taskIds);
  }

  /// Get effective tags for tasks with subtasks - Delegates to TaskTagService
  Future<Map<String, List<Tag>>> getEffectiveTagsForTasksWithSubtasks(List<Task> tasks) async {
    return await _tagService.getEffectiveTagsForTasksWithSubtasks(tasks);
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
        final isValid = await _hierarchyService.validateParentChange(
          task.id,
          task.parentTaskId,
          descendantsFetcher: getDescendantTasks,
        );
        if (!isValid) {
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

  /// Complete a task - Delegates to TaskCompletionService
  Future<void> completeTask(String taskId, {String? notes}) async {
    await _completionService.completeTask(
      taskId,
      notes: notes,
      taskFetcher: getTaskById,
      childrenFetcher: getChildTasks,
      recurrenceFetcher: getEffectiveRecurrence,
      parentCompletionChecker: _checkParentCompletion,
    );
  }

  /// Uncomplete a task - Delegates to TaskCompletionService
  Future<void> uncompleteTask(String taskId) async {
    await _completionService.uncompleteTask(
      taskId,
      taskFetcher: getTaskById,
      uncompleteParent: uncompleteTask,
    );
  }

  /// Check if parent task should be auto-completed - Delegates to TaskCompletionService
  Future<void> _checkParentCompletion(String parentId) async {
    await _completionService.checkParentCompletion(
      parentId,
      taskFetcher: getTaskById,
      childrenFetcher: getChildTasks,
      completeParent: completeTask,
    );
  }

  /// Assign tags to a task - Delegates to TaskTagService
  Future<void> assignTags(String taskId, List<String> tagIds) async {
    await _tagService.assignTags(taskId, tagIds, taskFetcher: getTaskById);
  }

  /// Add a single tag to a task - Delegates to TaskTagService
  Future<void> addTag(String taskId, String tagId) async {
    await _tagService.addTag(taskId, tagId, taskFetcher: getTaskById);
  }

  /// Remove a single tag from a task - Delegates to TaskTagService
  Future<void> removeTag(String taskId, String tagId) async {
    await _tagService.removeTag(taskId, tagId, taskFetcher: getTaskById);
  }

  /// Get all tasks with a specific tag - Delegates to TaskTagService
  Future<List<Task>> getTasksByTag(String tagId, {bool includeCompleted = false}) async {
    return await _tagService.getTasksByTag(
      tagId,
      includeCompleted: includeCompleted,
      childrenFetcher: getChildTasks,
    );
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
      AppLogger.error('Error fetching child tasks: $e');
      return [];
    }
  }

  /// Get all descendant tasks (children, grandchildren, etc.) recursively
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

  /// Get completion history for a recurring task - Delegates to TaskCompletionService
  Future<List<TaskCompletion>> getCompletionHistory(String taskId) async {
    return await _completionService.getCompletionHistory(taskId);
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
