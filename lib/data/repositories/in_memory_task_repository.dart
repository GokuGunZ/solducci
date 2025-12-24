import 'dart:async';
import 'package:solducci/models/task.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// In-memory implementation of TaskRepository for testing
///
/// Provides a fake implementation that stores tasks in memory.
/// Useful for unit tests and integration tests without database dependency.
/// Simulates realistic delays and supports realtime streams.
class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};
  final StreamController<Map<String, Task>> _streamController = StreamController.broadcast();
  final Duration _delay;
  final bool _enableDelays;

  /// Create an in-memory repository
  ///
  /// [delay] - Simulated network delay (default: 50ms)
  /// [enableDelays] - Enable/disable delays (default: true)
  InMemoryTaskRepository({
    Duration delay = const Duration(milliseconds: 50),
    bool enableDelays = true,
  })  : _delay = delay,
        _enableDelays = enableDelays;

  /// Simulate network delay
  Future<void> _simulateDelay() async {
    if (_enableDelays) {
      await Future.delayed(_delay);
    }
  }

  /// Notify stream listeners of changes
  void _notifyListeners() {
    _streamController.add(Map.from(_tasks));
  }

  /// Generate a unique ID for a task
  String _generateId() {
    return 'task-${DateTime.now().millisecondsSinceEpoch}-${_tasks.length}';
  }

  @override
  Future<List<Task>> getAll({String? documentId}) async {
    await _simulateDelay();

    AppLogger.debug('InMemory: Fetching all tasks${documentId != null ? " for document: $documentId" : ""}');

    var tasks = _tasks.values.toList();

    // Filter by document if specified
    if (documentId != null) {
      tasks = tasks.where((t) => t.documentId == documentId).toList();
    }

    // Build tree structure
    final rootTasks = await _buildTaskTree(tasks);

    AppLogger.debug('InMemory: Fetched ${rootTasks.length} root tasks');
    return rootTasks;
  }

  @override
  Future<Task?> getById(String id) async {
    await _simulateDelay();

    if (id.isEmpty) {
      throw ValidationException(
        'Task ID cannot be empty',
        fieldErrors: {'id': 'Required field'},
      );
    }

    AppLogger.debug('InMemory: Fetching task by ID: ${id.length > 8 ? id.substring(0, 8) : id}...');

    final task = _tasks[id];
    if (task != null) {
      AppLogger.debug('InMemory: Task fetched: ${task.title}');
    }
    return task != null ? _deepCopyTask(task) : null;
  }

  @override
  Future<Task?> getWithSubtasks(String id) async {
    await _simulateDelay();

    if (id.isEmpty) {
      throw ValidationException(
        'Task ID cannot be empty',
        fieldErrors: {'id': 'Required field'},
      );
    }

    AppLogger.debug('InMemory: Fetching task with subtasks: ${id.length > 8 ? id.substring(0, 8) : id}...');

    final task = _tasks[id];
    if (task == null) {
      AppLogger.debug('InMemory: Task not found: $id');
      return null;
    }

    // Get all tasks from the same document to build the tree
    final documentTasks = _tasks.values
        .where((t) => t.documentId == task.documentId)
        .toList();

    final rootTasks = await _buildTaskTree(documentTasks);

    // Find the specific task in the tree
    final foundTask = _findTaskInTree(rootTasks, id);

    if (foundTask == null) {
      throw NotFoundException('Task with ID $id not found in tree');
    }

    final copy = _deepCopyTask(foundTask);
    AppLogger.debug('InMemory: Task with subtasks fetched: ${copy.title} (${copy.subtasks?.length ?? 0} subtasks)');
    return copy;
  }

  @override
  Future<Task> create(Task task) async {
    await _simulateDelay();

    _validateTask(task);

    AppLogger.debug('InMemory: Creating task: ${task.title}');

    // Verify parent task exists if specified
    if (task.parentTaskId != null) {
      if (!_tasks.containsKey(task.parentTaskId)) {
        throw ValidationException(
          'Parent task not found',
          fieldErrors: {'parentTaskId': 'Parent task does not exist'},
        );
      }
    }

    // Generate ID if not provided
    final id = task.id.isEmpty ? _generateId() : task.id;
    final now = DateTime.now();

    final createdTask = Task(
      id: id,
      documentId: task.documentId,
      parentTaskId: task.parentTaskId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      tShirtSize: task.tShirtSize,
      dueDate: task.dueDate,
      completedAt: task.completedAt,
      position: task.position,
      createdAt: now,
      updatedAt: now,
    );

    _tasks[id] = createdTask;
    _notifyListeners();

    AppLogger.info('InMemory: Task created successfully: $id - ${createdTask.title}');
    return _deepCopyTask(createdTask);
  }

  @override
  Future<Task> update(Task task) async {
    await _simulateDelay();

    if (task.id.isEmpty) {
      throw ValidationException(
        'Task ID cannot be empty',
        fieldErrors: {'id': 'Required field'},
      );
    }

    _validateTask(task);

    AppLogger.debug('InMemory: Updating task: ${task.id.length > 8 ? task.id.substring(0, 8) : task.id}...');

    // Verify task exists
    if (!_tasks.containsKey(task.id)) {
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

    final updatedTask = Task(
      id: task.id,
      documentId: task.documentId,
      parentTaskId: task.parentTaskId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      tShirtSize: task.tShirtSize,
      dueDate: task.dueDate,
      completedAt: task.completedAt,
      position: task.position,
      createdAt: _tasks[task.id]!.createdAt,
      updatedAt: DateTime.now(),
    );

    _tasks[task.id] = updatedTask;
    _notifyListeners();

    AppLogger.info('InMemory: Task updated successfully: ${task.id}');
    return _deepCopyTask(updatedTask);
  }

  @override
  Future<void> delete(String id) async {
    await _simulateDelay();

    if (id.isEmpty) {
      throw ValidationException(
        'Task ID cannot be empty',
        fieldErrors: {'id': 'Required field'},
      );
    }

    AppLogger.debug('InMemory: Deleting task: ${id.length > 8 ? id.substring(0, 8) : id}...');

    // Verify task exists
    if (!_tasks.containsKey(id)) {
      throw NotFoundException('Task with ID $id not found');
    }

    // Get all descendants
    final descendants = await _getDescendantIds(id);

    // Delete task and all descendants
    _tasks.remove(id);
    for (final descendantId in descendants) {
      _tasks.remove(descendantId);
    }

    _notifyListeners();

    AppLogger.info('InMemory: Task deleted successfully: $id');
  }

  @override
  Future<List<Task>> getByIds(List<String> ids) async {
    await _simulateDelay();

    if (ids.isEmpty) {
      return [];
    }

    AppLogger.debug('InMemory: Fetching ${ids.length} tasks by IDs');

    final tasks = <Task>[];
    for (final id in ids) {
      final task = _tasks[id];
      if (task != null) {
        tasks.add(_deepCopyTask(task));
      }
    }

    AppLogger.debug('InMemory: Fetched ${tasks.length} tasks out of ${ids.length} requested');
    return tasks;
  }

  @override
  Future<List<Task>> getByStatus(String documentId, TaskStatus status) async {
    await _simulateDelay();

    AppLogger.debug('InMemory: Fetching tasks with status ${status.value} for document: $documentId');

    final tasks = _tasks.values
        .where((t) => t.documentId == documentId && t.status == status)
        .toList();

    final rootTasks = await _buildTaskTree(tasks);

    AppLogger.debug('InMemory: Fetched ${rootTasks.length} tasks with status ${status.value}');
    return rootTasks;
  }

  @override
  Stream<List<Task>> watchAll({String? documentId}) {
    AppLogger.debug('InMemory: Setting up stream${documentId != null ? " for document: $documentId" : ""}');

    // Return stream that emits on every change
    return _streamController.stream
        .map((allTasks) {
          var tasks = allTasks.values.toList();
          if (documentId != null) {
            tasks = tasks.where((t) => t.documentId == documentId).toList();
          }
          return tasks;
        })
        .asyncMap((tasks) => _buildTaskTree(tasks))
        .handleError((error, stackTrace) {
          AppLogger.error('InMemory: Stream error', error, stackTrace);
          throw RepositoryException('Stream error occurred', error, stackTrace);
        });
  }

  // ============================================================================
  // Additional Helper Methods for Testing
  // ============================================================================

  /// Clear all tasks (useful for test cleanup)
  void clear() {
    _tasks.clear();
    _notifyListeners();
    AppLogger.debug('InMemory: All tasks cleared');
  }

  /// Get current task count
  int get taskCount => _tasks.length;

  /// Check if a task exists
  bool containsTask(String id) => _tasks.containsKey(id);

  /// Seed with initial tasks (useful for tests)
  void seed(List<Task> tasks) {
    for (final task in tasks) {
      _tasks[task.id] = task;
    }
    _notifyListeners();
    AppLogger.debug('InMemory: Seeded with ${tasks.length} tasks');
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  /// Build task tree structure from flat list
  Future<List<Task>> _buildTaskTree(List<Task> allTasks) async {
    if (allTasks.isEmpty) return [];

    // Create a map for quick lookup
    final taskMap = <String, Task>{};
    for (final task in allTasks) {
      taskMap[task.id] = _deepCopyTask(task);
    }

    // Build tree by assigning children to parents
    final rootTasks = <Task>[];

    for (final task in taskMap.values) {
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
          AppLogger.warning('InMemory: Orphaned task found: ${task.id} (parent: ${task.parentTaskId})');
          rootTasks.add(task);
        }
      }
    }

    return rootTasks;
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
      subtasks: task.subtasks?.map((subtask) => _deepCopyTask(subtask)).toList(),
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
    final children = _tasks.values.where((t) => t.parentTaskId == taskId).toList();

    for (final child in children) {
      descendants.add(child.id);
      // Recursively get grandchildren
      final grandchildren = await _getDescendantIds(child.id);
      descendants.addAll(grandchildren);
    }

    return descendants;
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
      throw ValidationException(
        'Task validation failed',
        fieldErrors: errors,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _streamController.close();
    AppLogger.debug('InMemory: Repository disposed');
  }
}
