/// Contract for domain data source adapters connecting Markdown line elements
/// to real domain entities (e.g. Tasks, Shopping List items).
abstract class DataSourceAdapter {
  /// Unique identifier of the entity type handled by this adapter (e.g. 'task', 'shopping_list').
  String get entityType;

  /// Human-readable label for UI displays.
  String get displayName;

  /// Idempotently creates an entity linked to a Markdown line element.
  ///
  /// [idempotencyKey] ensures that retries or re-parses do not create duplicate records.
  Future<String> createItem({
    required String documentId,
    required String text,
    required bool isCompleted,
    String? contextScope,
    String? userId,
    String? groupId,
    required String idempotencyKey,
  });

  /// Updates the text/title of an existing bound entity.
  Future<void> updateItem({
    required String entityId,
    required String text,
    String? contextScope,
  });

  /// Toggles the completion state of an existing bound entity.
  Future<void> toggleItem({
    required String entityId,
    required bool isCompleted,
    String? contextScope,
  });

  /// Safely unlinks a line element from the entity without deleting the remote entity.
  Future<void> unlinkItem({
    required String entityId,
    String? contextScope,
  });

  /// Explicitly deletes the remote entity (only when the user expressly requests deletion).
  Future<void> deleteItem({
    required String entityId,
    String? contextScope,
  });

  /// Fetches current state of the remote entity for conflict detection and verification.
  Future<Map<String, dynamic>?> fetchItem(String entityId);
}
