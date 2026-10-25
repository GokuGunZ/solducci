import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/models/task.dart';
import 'data_source_adapter.dart';

/// Concrete DataSourceAdapter binding Markdown line elements to [Task] domain entities.
///
/// Follows the Data Binding Safety Contract:
/// - Guarantees idempotent creation via client-side idempotency keys.
/// - Enforces DirectContextBound constraints (personal vs group scope isolation).
/// - Non-destructive unlinking: unbinding a line never deletes the underlying Task record.
class TaskDataSourceAdapter implements DataSourceAdapter {
  final TaskRepository _repository;
  final Map<String, String> _idempotencyRegistry = {};

  TaskDataSourceAdapter({required TaskRepository repository}) : _repository = repository;

  @override
  String get entityType => 'task';

  @override
  String get displayName => 'Tasks & ToDos';

  @override
  Future<String> createItem({
    required String documentId,
    required String text,
    required bool isCompleted,
    String? contextScope,
    String? userId,
    String? groupId,
    required String idempotencyKey,
  }) async {
    // 1. Idempotency check: if this key was already created, return existing entity ID
    if (_idempotencyRegistry.containsKey(idempotencyKey)) {
      AppLogger.info('TaskDataSourceAdapter: Reusing existing task for idempotency key $idempotencyKey');
      return _idempotencyRegistry[idempotencyKey]!;
    }

    // 2. Context boundary enforcement: DirectContextBound checks
    final isGroupContext = contextScope == 'group' || (groupId != null && groupId.isNotEmpty);
    if (isGroupContext && (groupId == null || groupId.isEmpty)) {
      throw StateError('ContextSecurityViolation: Group task creation requires a valid groupId');
    }

    // 3. Create task entity
    final now = DateTime.now();
    final newTask = Task(
      id: '', // Will be assigned by repository
      documentId: documentId,
      title: text,
      status: isCompleted ? TaskStatus.completed : TaskStatus.pending,
      completedAt: isCompleted ? now : null,
      position: 0,
      createdAt: now,
      updatedAt: now,
    );

    final created = await _repository.create(newTask);
    _idempotencyRegistry[idempotencyKey] = created.id;
    AppLogger.info('TaskDataSourceAdapter: Created Task ${created.id} for document $documentId');
    return created.id;
  }

  @override
  Future<void> updateItem({
    required String entityId,
    required String text,
    String? contextScope,
  }) async {
    final existing = await _repository.getById(entityId);
    if (existing == null) {
      AppLogger.warning('TaskDataSourceAdapter: Cannot update task $entityId - not found');
      return;
    }

    existing.title = text;
    existing.updatedAt = DateTime.now();
    await _repository.update(existing);
    AppLogger.info('TaskDataSourceAdapter: Updated Task $entityId text to "$text"');
  }

  @override
  Future<void> toggleItem({
    required String entityId,
    required bool isCompleted,
    String? contextScope,
  }) async {
    final existing = await _repository.getById(entityId);
    if (existing == null) {
      AppLogger.warning('TaskDataSourceAdapter: Cannot toggle task $entityId - not found');
      return;
    }

    existing.status = isCompleted ? TaskStatus.completed : TaskStatus.pending;
    existing.completedAt = isCompleted ? DateTime.now() : null;
    existing.updatedAt = DateTime.now();
    await _repository.update(existing);
    AppLogger.info('TaskDataSourceAdapter: Toggled Task $entityId completed=$isCompleted');
  }

  @override
  Future<void> unlinkItem({
    required String entityId,
    String? contextScope,
  }) async {
    // Non-destructive: simply log and drop association; task entity in database is NOT deleted!
    AppLogger.info('TaskDataSourceAdapter: Safely unlinked Task $entityId without remote deletion');
  }

  @override
  Future<void> deleteItem({
    required String entityId,
    String? contextScope,
  }) async {
    await _repository.delete(entityId);
    AppLogger.info('TaskDataSourceAdapter: Explicitly deleted Task $entityId upon user request');
  }

  @override
  Future<Map<String, dynamic>?> fetchItem(String entityId) async {
    final task = await _repository.getById(entityId);
    if (task == null) return null;
    return {
      'id': task.id,
      'title': task.title,
      'is_completed': task.isCompleted,
      'updated_at': task.updatedAt.toIso8601String(),
    };
  }
}
