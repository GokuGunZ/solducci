import 'package:solducci/models/task.dart';

/// Repository interface for Task data operations
///
/// This interface defines the contract for task data access.
/// Implementations can use Supabase, local storage, or in-memory storage.
///
/// Following the Repository Pattern to:
/// - Abstract data source details
/// - Enable easy testing with mock implementations
/// - Support multiple data sources (remote, local, cache)
/// - Centralize data access logic
abstract class TaskRepository {
  /// Get all tasks for a document
  ///
  /// Returns a list of root-level tasks (no parent).
  /// Subtasks are nested in the `subtasks` property.
  ///
  /// Throws [RepositoryException] if operation fails.
  Future<List<Task>> getAll({String? documentId});

  /// Get a single task by ID
  ///
  /// Returns null if task not found.
  /// Does not load subtasks - use [getWithSubtasks] for that.
  Future<Task?> getById(String id);

  /// Get a task with all subtasks loaded (full tree)
  ///
  /// Recursively loads all descendant tasks.
  /// Returns null if task not found.
  Future<Task?> getWithSubtasks(String id);

  /// Create a new task
  ///
  /// The task ID will be generated if not provided.
  /// Returns the created task with server-generated fields.
  ///
  /// Throws [ValidationException] if task data is invalid.
  /// Throws [NetworkException] if network operation fails.
  Future<Task> create(Task task);

  /// Update an existing task
  ///
  /// Only updates the task itself, not subtasks.
  /// Returns the updated task.
  ///
  /// Throws [NotFoundException] if task doesn't exist.
  /// Throws [ValidationException] if task data is invalid.
  Future<Task> update(Task task);

  /// Delete a task
  ///
  /// Also deletes all subtasks recursively.
  /// This operation cannot be undone.
  ///
  /// Throws [NotFoundException] if task doesn't exist.
  Future<void> delete(String id);

  /// Batch get tasks by IDs
  ///
  /// More efficient than multiple [getById] calls.
  /// Returns tasks in the same order as requested IDs.
  /// Missing tasks are omitted from the result.
  Future<List<Task>> getByIds(List<String> ids);

  /// Get tasks filtered by status
  ///
  /// Useful for getting completed/pending tasks separately.
  Future<List<Task>> getByStatus(String documentId, TaskStatus status);

  /// Stream of task changes for a document
  ///
  /// Emits whenever tasks are created, updated, or deleted.
  /// The stream provides the complete list of tasks each time.
  ///
  /// Note: This may use polling or realtime subscriptions depending
  /// on the implementation.
  Stream<List<Task>> watchAll({String? documentId});
}

/// Base exception for repository operations
class RepositoryException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  RepositoryException(
    this.message, [
    this.originalError,
    this.stackTrace,
  ]);

  @override
  String toString() => 'RepositoryException: $message';
}

/// Thrown when a requested resource is not found
class NotFoundException extends RepositoryException {
  NotFoundException(String message, [dynamic error, StackTrace? stackTrace])
      : super(message, error, stackTrace);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Thrown when validation fails
class ValidationException extends RepositoryException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    String message, {
    this.fieldErrors,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return 'ValidationException: $message\nField errors: $fieldErrors';
    }
    return 'ValidationException: $message';
  }
}

/// Thrown when a network operation fails
class NetworkException extends RepositoryException {
  final int? statusCode;

  NetworkException(
    String message, {
    this.statusCode,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);

  @override
  String toString() {
    if (statusCode != null) {
      return 'NetworkException: $message (HTTP $statusCode)';
    }
    return 'NetworkException: $message';
  }
}
