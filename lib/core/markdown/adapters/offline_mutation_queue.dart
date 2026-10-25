import 'package:solducci/core/logging/app_logger.dart';
import 'data_source_adapter.dart';

enum MutationAction {
  create,
  update,
  toggle,
  delete,
}

class QueuedMutation {
  final String id;
  final String entityType;
  final MutationAction action;
  final String? entityId;
  final String? documentId;
  final String? text;
  final bool? isCompleted;
  final String? idempotencyKey;
  final String? contextScope;
  final String? userId;
  final String? groupId;
  final DateTime queuedAt;
  int retryAttempts;

  QueuedMutation({
    required this.id,
    required this.entityType,
    required this.action,
    this.entityId,
    this.documentId,
    this.text,
    this.isCompleted,
    this.idempotencyKey,
    this.contextScope,
    this.userId,
    this.groupId,
    DateTime? queuedAt,
    this.retryAttempts = 0,
  }) : queuedAt = queuedAt ?? DateTime.now();
}

/// In-memory queue providing offline resilience and idempotent retry capabilities
/// for Markdown line data binding mutations.
class OfflineMutationQueue {
  final List<QueuedMutation> _queue = [];
  bool isOnline = true;

  int get pendingCount => _queue.length;
  List<QueuedMutation> get pendingMutations => List.unmodifiable(_queue);

  void enqueue(QueuedMutation mutation) {
    _queue.add(mutation);
    AppLogger.info('OfflineMutationQueue: Enqueued ${mutation.action.name} for ${mutation.entityType}');
  }

  /// Flushes all pending mutations through the appropriate adapter.
  /// Returns the number of successfully applied mutations.
  Future<int> flush(DataSourceAdapter adapter) async {
    if (!isOnline) {
      AppLogger.info('OfflineMutationQueue: Offline - flush deferred');
      return 0;
    }

    int applied = 0;
    final remaining = <QueuedMutation>[];

    for (var mutation in _queue) {
      if (mutation.entityType != adapter.entityType) {
        remaining.add(mutation);
        continue;
      }

      try {
        switch (mutation.action) {
          case MutationAction.create:
            if (mutation.documentId != null &&
                mutation.text != null &&
                mutation.idempotencyKey != null) {
              await adapter.createItem(
                documentId: mutation.documentId!,
                text: mutation.text!,
                isCompleted: mutation.isCompleted ?? false,
                contextScope: mutation.contextScope,
                userId: mutation.userId,
                groupId: mutation.groupId,
                idempotencyKey: mutation.idempotencyKey!,
              );
              applied++;
            }
            break;

          case MutationAction.update:
            if (mutation.entityId != null && mutation.text != null) {
              await adapter.updateItem(
                entityId: mutation.entityId!,
                text: mutation.text!,
                contextScope: mutation.contextScope,
              );
              applied++;
            }
            break;

          case MutationAction.toggle:
            if (mutation.entityId != null && mutation.isCompleted != null) {
              await adapter.toggleItem(
                entityId: mutation.entityId!,
                isCompleted: mutation.isCompleted!,
                contextScope: mutation.contextScope,
              );
              applied++;
            }
            break;

          case MutationAction.delete:
            if (mutation.entityId != null) {
              await adapter.deleteItem(
                entityId: mutation.entityId!,
                contextScope: mutation.contextScope,
              );
              applied++;
            }
            break;
        }
      } catch (e) {
        AppLogger.error('OfflineMutationQueue: Error executing ${mutation.action.name}: $e');
        mutation.retryAttempts++;
        remaining.add(mutation);
      }
    }

    _queue.clear();
    _queue.addAll(remaining);
    AppLogger.info('OfflineMutationQueue: Flushed $applied mutations. ${remaining.length} remaining');
    return applied;
  }

  void clear() {
    _queue.clear();
  }
}
