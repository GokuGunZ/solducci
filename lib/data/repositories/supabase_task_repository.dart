import 'package:solducci/models/task.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of TaskRepository
///
/// Handles all database operations for tasks using Supabase.
/// Implements retry logic for transient failures and proper error handling.
class SupabaseTaskRepository implements TaskRepository {
  final SupabaseClient _supabase;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  SupabaseTaskRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<Task>> getAll({String? documentId}) async {
    try {
      PostgrestFilterBuilder query = _supabase.from('tasks').select();

      if (documentId != null) {
        query = query.eq('document_id', documentId);
      }

      final response = await _executeWithRetry(() => query.order('position'));

      final allTasks = _parseTasks(response);
      final rootTasks = await _buildTaskTree(allTasks);

      return rootTasks;
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Database error fetching tasks', e, stackTrace);
      throw NetworkException(
        'Failed to fetch tasks from database',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error fetching tasks', e, stackTrace);
      throw RepositoryException('Failed to fetch tasks', e, stackTrace);
    }
  }

  @override
  Future<Task?> getById(String id) async {
    try {
      _validateTaskId(id);

      final response = await _executeWithRetry(
        () => _supabase.from('tasks').select().eq('id', id).maybeSingle(),
      );

      if (response == null) {
        AppLogger.debug('Task not found: $id');
        return null;
      }

      final task = Task.fromMap(response);
      return task;
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Database error fetching task by ID', e, stackTrace);
      throw NetworkException(
        'Failed to fetch task from database',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is ValidationException) rethrow;
      AppLogger.error('Unexpected error fetching task by ID', e, stackTrace);
      throw RepositoryException('Failed to fetch task', e, stackTrace);
    }
  }

  @override
  Future<Task?> getWithSubtasks(String id) async {
    try {
      _validateTaskId(id);

      // First check if task exists
      final taskResponse = await _executeWithRetry(
        () => _supabase.from('tasks').select().eq('id', id).maybeSingle(),
      );

      if (taskResponse == null) {
        AppLogger.debug('Task not found: $id');
        return null;
      }

      // Get all tasks from the same document to build the tree
      final documentId = taskResponse['document_id'] as String;
      final allTasksResponse = await _executeWithRetry(
        () => _supabase
            .from('tasks')
            .select()
            .eq('document_id', documentId)
            .order('position'),
      );

      final allTasks = _parseTasks(allTasksResponse);
      final rootTasks = await _buildTaskTree(allTasks);

      // Find the specific task in the tree
      final foundTask = _findTaskInTree(rootTasks, id);

      if (foundTask == null) {
        throw NotFoundException('Task with ID $id not found in tree');
      }

      // Return a deep copy to avoid shared references
      final copy = _deepCopyTask(foundTask);
      return copy;
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error(
        'Database error fetching task with subtasks',
        e,
        stackTrace,
      );
      throw NetworkException(
        'Failed to fetch task with subtasks from database',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is RepositoryException) rethrow;
      AppLogger.error(
        'Unexpected error fetching task with subtasks',
        e,
        stackTrace,
      );
      throw RepositoryException(
        'Failed to fetch task with subtasks',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<Task> create(Task task) async {
    try {
      _validateTask(task);

      AppLogger.debug('Creating task: ${task.title}');

      // Verify document exists
      final documentExists = await _verifyDocumentExists(task.documentId);
      if (!documentExists) {
        throw ValidationException(
          'Document not found',
          fieldErrors: {'documentId': 'Document does not exist'},
        );
      }

      // Verify parent task exists if specified
      if (task.parentTaskId != null) {
        final parentExists = await _verifyTaskExists(task.parentTaskId!);
        if (!parentExists) {
          throw ValidationException(
            'Parent task not found',
            fieldErrors: {'parentTaskId': 'Parent task does not exist'},
          );
        }
      }

      final dataToInsert = task.toInsertMap();

      final response = await _executeWithRetry(
        () => _supabase.from('tasks').insert(dataToInsert).select().single(),
      );

      final createdTask = Task.fromMap(response);
      AppLogger.info(
        'Task created successfully: ${createdTask.id} - ${createdTask.title}',
      );
      return createdTask;
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Database error creating task', e, stackTrace);

      // Check for specific constraint violations
      if (e.code == '23503') {
        // Foreign key violation
        throw ValidationException(
          'Invalid reference: Document or parent task does not exist',
          error: e,
          stackTrace: stackTrace,
        );
      }

      throw NetworkException(
        'Failed to create task in database',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is RepositoryException) rethrow;
      AppLogger.error('Unexpected error creating task', e, stackTrace);
      throw RepositoryException('Failed to create task', e, stackTrace);
    }
  }

  @override
  Future<Task> update(Task task) async {
    try {
      _validateTaskId(task.id);
      _validateTask(task);

      AppLogger.debug('Updating task: ${task.id.substring(0, 8)}...');

      // Verify task exists
      final exists = await _verifyTaskExists(task.id);
      if (!exists) {
        throw NotFoundException('Task with ID ${task.id} not found');
      }

      // Prevent circular reference in hierarchy
      if (task.parentTaskId != null) {
        final descendants = await _getDescendantIds(task.id);
        if (descendants.contains(task.parentTaskId)) {
          throw ValidationException(
            'Cannot set parent to a descendant task (circular reference)',
            fieldErrors: {'parentTaskId': 'Would create circular reference'},
          );
        }
      }

      final dataToUpdate = task.toUpdateMap();

      final response = await _executeWithRetry(
        () => _supabase
            .from('tasks')
            .update(dataToUpdate)
            .eq('id', task.id)
            .select()
            .single(),
      );

      final updatedTask = Task.fromMap(response);
      AppLogger.info('Task updated successfully: ${updatedTask.id}');
      return updatedTask;
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Database error updating task', e, stackTrace);

      if (e.code == '23503') {
        throw ValidationException(
          'Invalid reference: Parent task does not exist',
          error: e,
          stackTrace: stackTrace,
        );
      }

      throw NetworkException(
        'Failed to update task in database',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is RepositoryException) rethrow;
      AppLogger.error('Unexpected error updating task', e, stackTrace);
      throw RepositoryException('Failed to update task', e, stackTrace);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      _validateTaskId(id);

      AppLogger.debug('Deleting task: ${id.substring(0, 8)}...');

      // Verify task exists before deleting
      final exists = await _verifyTaskExists(id);
      if (!exists) {
        throw NotFoundException('Task with ID $id not found');
      }

      // Database cascade will handle subtasks deletion
      await _executeWithRetry(
        () => _supabase.from('tasks').delete().eq('id', id),
      );

      AppLogger.info('Task deleted successfully: $id');
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Database error deleting task', e, stackTrace);
      throw NetworkException(
        'Failed to delete task from database',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is RepositoryException) rethrow;
      AppLogger.error('Unexpected error deleting task', e, stackTrace);
      throw RepositoryException('Failed to delete task', e, stackTrace);
    }
  }

  @override
  Future<List<Task>> getByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) {
        return [];
      }

      AppLogger.debug('Fetching ${ids.length} tasks by IDs');

      final response = await _executeWithRetry(
        () => _supabase
            .from('tasks')
            .select()
            .inFilter('id', ids)
            .order('position'),
      );

      final tasks = _parseTasks(response);

      // Sort to match the requested order
      final taskMap = {for (var task in tasks) task.id: task};
      final orderedTasks = ids
          .map((id) => taskMap[id])
          .whereType<Task>()
          .toList();

      AppLogger.debug(
        'Fetched ${orderedTasks.length} tasks out of ${ids.length} requested',
      );
      return orderedTasks;
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Database error fetching tasks by IDs', e, stackTrace);
      throw NetworkException(
        'Failed to fetch tasks from database',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error fetching tasks by IDs', e, stackTrace);
      throw RepositoryException('Failed to fetch tasks', e, stackTrace);
    }
  }

  @override
  Future<List<Task>> getByStatus(String documentId, TaskStatus status) async {
    try {
      AppLogger.debug(
        'Fetching tasks with status ${status.value} for document: $documentId',
      );

      final response = await _executeWithRetry(
        () => _supabase
            .from('tasks')
            .select()
            .eq('document_id', documentId)
            .eq('status', status.value)
            .order('position'),
      );

      final allTasks = _parseTasks(response);
      final rootTasks = await _buildTaskTree(allTasks);

      AppLogger.debug(
        'Fetched ${rootTasks.length} tasks with status ${status.value}',
      );
      return rootTasks;
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Database error fetching tasks by status', e, stackTrace);
      throw NetworkException(
        'Failed to fetch tasks from database',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Unexpected error fetching tasks by status',
        e,
        stackTrace,
      );
      throw RepositoryException('Failed to fetch tasks', e, stackTrace);
    }
  }

  @override
  Stream<List<Task>> watchAll({String? documentId}) {
    try {
      AppLogger.debug(
        'Setting up realtime stream${documentId != null ? " for document: $documentId" : ""}',
      );

      // Build the stream query - type changes after .eq() so we use dynamic
      dynamic streamQuery = _supabase.from('tasks').stream(primaryKey: ['id']);

      // Apply document filter if provided
      if (documentId != null) {
        streamQuery = streamQuery.eq('document_id', documentId);
      }

      // Apply ordering and map the data
      return (streamQuery.order('position')
              as Stream<List<Map<String, dynamic>>>)
          .asyncMap((data) async {
            try {
              final allTasks = _parseTasks(data);
              final rootTasks = await _buildTaskTree(allTasks);
              return rootTasks;
            } catch (e, stackTrace) {
              AppLogger.error('Error processing stream data', e, stackTrace);
              return <Task>[];
            }
          })
          .handleError((error, stackTrace) {
            AppLogger.error('Stream error', error, stackTrace);
            throw RepositoryException(
              'Stream error occurred',
              error,
              stackTrace,
            );
          });
    } catch (e, stackTrace) {
      AppLogger.error('Error setting up stream', e, stackTrace);
      throw RepositoryException(
        'Failed to setup realtime stream',
        e,
        stackTrace,
      );
    }
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  /// Execute a database operation with retry logic for transient failures
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        // Don't retry validation errors or not found errors
        if (e is ValidationException || e is NotFoundException) {
          rethrow;
        }

        // Check if we should retry
        final shouldRetry =
            attempts < _maxRetries &&
            (e is PostgrestException || e.toString().contains('network'));

        if (!shouldRetry) {
          rethrow;
        }

        AppLogger.warning(
          'Operation failed (attempt $attempts/$_maxRetries), retrying...',
          e,
        );
        await Future.delayed(_retryDelay * attempts);
      }
    }
  }

  /// Parse list of task maps to Task objects (flat, no hierarchy)
  List<Task> _parseTasks(List<Map<String, dynamic>> data) {
    final tasks = <Task>[];
    for (final map in data) {
      try {
        tasks.add(Task.fromMap(map));
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to parse task', e, stackTrace);
        // Skip tasks that fail to parse
      }
    }
    return tasks;
  }

  /// Build task tree structure from flat list
  /// Returns only root tasks with subtasks populated recursively
  Future<List<Task>> _buildTaskTree(List<Task> allTasks) async {
    if (allTasks.isEmpty) return [];

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
          AppLogger.warning(
            'Orphaned task found: ${task.id} (parent: ${task.parentTaskId})',
          );
          rootTasks.add(task);
        }
      }
    }

    // Deep copy the entire tree to avoid shared references
    return rootTasks.map((root) => _deepCopyTask(root)).toList();
  }

  /// Create a deep copy of a task with all its subtasks
  Task _deepCopyTask(Task task) {
    return Task(
      id: task.id,
      documentId: task.documentId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      completedAt: task.completedAt,
      position: task.position,
      parentTaskId: task.parentTaskId,
      tShirtSize: task.tShirtSize,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      subtasks: task.subtasks
          ?.map((subtask) => _deepCopyTask(subtask))
          .toList(),
    );
  }

  /// Find a task in a tree by ID (recursive)
  Task? _findTaskInTree(List<Task> tasks, String id) {
    for (final task in tasks) {
      if (task.id == id) return task;
      if (task.subtasks != null) {
        final found = _findTaskInTree(task.subtasks!, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Get all descendant task IDs for a given task
  Future<Set<String>> _getDescendantIds(String taskId) async {
    final descendants = <String>{};

    final children = await _executeWithRetry(
      () => _supabase.from('tasks').select('id').eq('parent_task_id', taskId),
    );

    for (final child in children) {
      final childId = child['id'] as String;
      descendants.add(childId);
      // Recursively get grandchildren
      final grandchildren = await _getDescendantIds(childId);
      descendants.addAll(grandchildren);
    }

    return descendants;
  }

  /// Verify if a document exists
  Future<bool> _verifyDocumentExists(String documentId) async {
    final response = await _executeWithRetry(
      () => _supabase
          .from('documents')
          .select('id')
          .eq('id', documentId)
          .maybeSingle(),
    );
    return response != null;
  }

  /// Verify if a task exists
  Future<bool> _verifyTaskExists(String taskId) async {
    final response = await _executeWithRetry(
      () => _supabase.from('tasks').select('id').eq('id', taskId).maybeSingle(),
    );
    return response != null;
  }

  /// Validate task ID is not empty
  void _validateTaskId(String id) {
    if (id.isEmpty) {
      throw ValidationException(
        'Task ID cannot be empty',
        fieldErrors: {'id': 'Required field'},
      );
    }
  }

  /// Validate task has required fields
  void _validateTask(Task task) {
    final errors = <String, String>{};

    if (task.title.trim().isEmpty) {
      errors['title'] = 'Title is required';
    }

    if (task.documentId.isEmpty) {
      errors['documentId'] = 'Document ID is required';
    }

    if (errors.isNotEmpty) {
      throw ValidationException('Task validation failed', fieldErrors: errors);
    }
  }
}
