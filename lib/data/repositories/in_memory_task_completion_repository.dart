import 'package:solducci/domain/repositories/task_completion_repository.dart';
import 'package:solducci/models/task_completion.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// In-memory implementation of TaskCompletionRepository for testing
class InMemoryTaskCompletionRepository implements TaskCompletionRepository {
  final Map<String, List<TaskCompletion>> _completions = {};
  final Map<String, Task> _tasks = {};

  /// Register a task for this repository to track
  void registerTask(Task task) {
    _tasks[task.id] = task;
  }

  /// Get a task by ID (for verification in tests)
  Task? getTask(String taskId) => _tasks[taskId];

  @override
  Future<void> insertCompletion({
    required String taskId,
    required DateTime completedAt,
    String? notes,
  }) async {
    final completion = TaskCompletion(
      id: '${taskId}_${completedAt.millisecondsSinceEpoch}',
      taskId: taskId,
      completedAt: completedAt,
      notes: notes,
    );

    _completions.putIfAbsent(taskId, () => []).add(completion);
    AppLogger.debug('InMemory: Inserted completion for task: $taskId');
  }

  @override
  Future<void> markTaskCompleted({
    required String taskId,
    required DateTime completedAt,
  }) async {
    final task = _tasks[taskId];
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    _tasks[taskId] = task.copyWith(
      status: TaskStatus.completed,
      completedAt: completedAt,
    );
    AppLogger.debug('InMemory: Marked task completed: $taskId');
  }

  @override
  Future<void> markTaskPending({
    required String taskId,
  }) async {
    final task = _tasks[taskId];
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    // Create new Task with completedAt explicitly set to null
    _tasks[taskId] = Task(
      id: task.id,
      documentId: task.documentId,
      parentTaskId: task.parentTaskId,
      title: task.title,
      description: task.description,
      status: TaskStatus.pending,
      completedAt: null, // Explicitly null
      priority: task.priority,
      tShirtSize: task.tShirtSize,
      dueDate: task.dueDate,
      position: task.position,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      subtasks: task.subtasks,
    );
    AppLogger.debug('InMemory: Marked task pending: $taskId');
  }

  @override
  Future<void> resetRecurringTask({
    required String taskId,
    DateTime? nextDueDate,
  }) async {
    final task = _tasks[taskId];
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    // Create new Task with completedAt explicitly set to null
    _tasks[taskId] = Task(
      id: task.id,
      documentId: task.documentId,
      parentTaskId: task.parentTaskId,
      title: task.title,
      description: task.description,
      status: TaskStatus.pending,
      completedAt: null, // Explicitly null
      priority: task.priority,
      tShirtSize: task.tShirtSize,
      dueDate: nextDueDate ?? task.dueDate,
      position: task.position,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      subtasks: task.subtasks,
    );
    AppLogger.debug('InMemory: Reset recurring task: $taskId');
  }

  @override
  Future<List<TaskCompletion>> getCompletionHistory(String taskId) async {
    final history = _completions[taskId] ?? [];
    // Sort by completedAt descending (most recent first)
    history.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return List.from(history);
  }

  /// Clear all data (for test teardown)
  void clear() {
    _completions.clear();
    _tasks.clear();
  }
}
