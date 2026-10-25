import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/models/space_items.dart';
import 'data_source_adapter.dart';

/// Concrete DataSourceAdapter binding Markdown line elements to [ShoppingListItem] entities.
class ShoppingListDataSourceAdapter implements DataSourceAdapter {
  final Map<String, ShoppingListItem> _items = {};
  final Map<String, String> _idempotencyRegistry = {};

  @override
  String get entityType => 'shopping_list';

  @override
  String get displayName => 'Lista della Spesa';

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
    if (_idempotencyRegistry.containsKey(idempotencyKey)) {
      AppLogger.info('ShoppingListAdapter: Reusing existing item for idempotency key $idempotencyKey');
      return _idempotencyRegistry[idempotencyKey]!;
    }

    final id = 'shop-${DateTime.now().millisecondsSinceEpoch}-${_items.length}';
    final now = DateTime.now();
    final item = ShoppingListItem(
      id: id,
      documentId: documentId,
      name: text,
      quantity: 1.0,
      isBought: isCompleted,
      position: _items.length,
      createdAt: now,
      updatedAt: now,
    );

    _items[id] = item;
    _idempotencyRegistry[idempotencyKey] = id;
    AppLogger.info('ShoppingListAdapter: Created ShoppingListItem $id: "$text"');
    return id;
  }

  @override
  Future<void> updateItem({
    required String entityId,
    required String text,
    String? contextScope,
  }) async {
    final existing = _items[entityId];
    if (existing == null) {
      AppLogger.warning('ShoppingListAdapter: Item $entityId not found for update');
      return;
    }

    _items[entityId] = ShoppingListItem(
      id: existing.id,
      documentId: existing.documentId,
      pantryItemId: existing.pantryItemId,
      name: text,
      quantity: existing.quantity,
      unit: existing.unit,
      isBought: existing.isBought,
      position: existing.position,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    AppLogger.info('ShoppingListAdapter: Updated ShoppingListItem $entityId to "$text"');
  }

  @override
  Future<void> toggleItem({
    required String entityId,
    required bool isCompleted,
    String? contextScope,
  }) async {
    final existing = _items[entityId];
    if (existing == null) {
      AppLogger.warning('ShoppingListAdapter: Item $entityId not found for toggle');
      return;
    }

    _items[entityId] = ShoppingListItem(
      id: existing.id,
      documentId: existing.documentId,
      pantryItemId: existing.pantryItemId,
      name: existing.name,
      quantity: existing.quantity,
      unit: existing.unit,
      isBought: isCompleted,
      position: existing.position,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    AppLogger.info('ShoppingListAdapter: Toggled ShoppingListItem $entityId isBought=$isCompleted');
  }

  @override
  Future<void> unlinkItem({
    required String entityId,
    String? contextScope,
  }) async {
    AppLogger.info('ShoppingListAdapter: Safely unlinked ShoppingListItem $entityId without remote deletion');
  }

  @override
  Future<void> deleteItem({
    required String entityId,
    String? contextScope,
  }) async {
    _items.remove(entityId);
    AppLogger.info('ShoppingListAdapter: Explicitly deleted ShoppingListItem $entityId');
  }

  @override
  Future<Map<String, dynamic>?> fetchItem(String entityId) async {
    final item = _items[entityId];
    if (item == null) return null;
    return {
      'id': item.id,
      'title': item.name,
      'is_completed': item.isBought,
      'updated_at': item.updatedAt.toIso8601String(),
    };
  }
}
