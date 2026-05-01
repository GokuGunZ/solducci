import 'dart:async';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for managing space items (Notes, Asterisks, Resources, Pantry)
class SpaceService {
  // Singleton pattern
  static final SpaceService _instance = SpaceService._internal();
  factory SpaceService() => _instance;
  SpaceService._internal();

  final _supabase = Supabase.instance.client;

  // --- NOTES ---

  Stream<List<NoteItem>> watchNotes(String documentId) {
    return _supabase
        .from('note_items')
        .stream(primaryKey: ['id'])
        .eq('document_id', documentId)
        .order('position', ascending: true)
        .map((data) => data.map((map) => NoteItem.fromMap(map)).toList());
  }

  Future<NoteItem> createNoteItem(NoteItem item) async {
    final response = await _supabase
        .from('note_items')
        .insert(item.toMap())
        .select()
        .single();
    return NoteItem.fromMap(response);
  }

  Future<void> updateNoteItem(NoteItem item) async {
    await _supabase
        .from('note_items')
        .update(item.toMap())
        .eq('id', item.id);
  }

  Future<void> deleteNoteItem(String id) async {
    await _supabase.from('note_items').delete().eq('id', id);
  }

  // --- ASTERISKS ---

  Stream<List<AsteriskItem>> watchAsterisks(String documentId, {bool? isResolved}) {
    var query = _supabase
        .from('asterisk_items')
        .stream(primaryKey: ['id'])
        .eq('document_id', documentId);
    
    return query.map((data) {
      var items = data.map((map) => AsteriskItem.fromMap(map)).toList();
      if (isResolved != null) {
        items = items.where((item) => item.isResolved == isResolved).toList();
      }
      return items..sort((a, b) => a.position.compareTo(b.position));
    });
  }

  Future<AsteriskItem> createAsteriskItem(AsteriskItem item) async {
    final response = await _supabase
        .from('asterisk_items')
        .insert(item.toMap())
        .select()
        .single();
    return AsteriskItem.fromMap(response);
  }

  Future<void> updateAsteriskItem(AsteriskItem item) async {
    await _supabase
        .from('asterisk_items')
        .update(item.toMap())
        .eq('id', item.id);
  }

  Future<void> deleteAsteriskItem(String id) async {
    await _supabase.from('asterisk_items').delete().eq('id', id);
  }

  // --- RESOURCES ---

  Stream<List<ResourceItem>> watchResources(String documentId) {
    return _supabase
        .from('resource_items')
        .stream(primaryKey: ['id'])
        .eq('document_id', documentId)
        .order('position', ascending: true)
        .map((data) => data.map((map) => ResourceItem.fromMap(map)).toList());
  }

  Future<ResourceItem> createResourceItem(ResourceItem item, List<String> tagIds) async {
    final response = await _supabase
        .from('resource_items')
        .insert(item.toMap())
        .select()
        .single();
    
    final createdItem = ResourceItem.fromMap(response);

    if (tagIds.isNotEmpty) {
      final tagInserts = tagIds.map((tagId) => {
        'resource_item_id': createdItem.id,
        'tag_id': tagId,
      }).toList();
      await _supabase.from('resource_item_tags').insert(tagInserts);
    }

    return createdItem;
  }

  Future<void> updateResourceItem(ResourceItem item, List<String> tagIds) async {
    await _supabase
        .from('resource_items')
        .update(item.toMap())
        .eq('id', item.id);

    await _supabase.from('resource_item_tags').delete().eq('resource_item_id', item.id);
    if (tagIds.isNotEmpty) {
      final tagInserts = tagIds.map((tagId) => {
        'resource_item_id': item.id,
        'tag_id': tagId,
      }).toList();
      await _supabase.from('resource_item_tags').insert(tagInserts);
    }
  }

  Future<void> deleteResourceItem(String id) async {
    await _supabase.from('resource_items').delete().eq('id', id);
  }

  Future<void> markResourceAsRead(String resourceItemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('resource_item_reads').upsert({
      'resource_item_id': resourceItemId,
      'user_id': userId,
      'read_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<String>> getReadResourceIds(String documentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('resource_item_reads')
        .select('resource_item_id')
        .eq('user_id', userId);
    
    return (response as List).map((r) => r['resource_item_id'] as String).toList();
  }

  Future<Map<String, List<String>>> getResourceTags(String documentId) async {
    final response = await _supabase
        .from('resource_item_tags')
        .select('resource_item_id, tag_id');
    
    final result = <String, List<String>>{};
    for (var row in (response as List)) {
      final itemId = row['resource_item_id'] as String;
      final tagId = row['tag_id'] as String;
      result.putIfAbsent(itemId, () => []).add(tagId);
    }
    return result;
  }

  // --- PANTRY ---

  Stream<List<PantryItem>> watchPantryItems(String documentId) {
    return _supabase
        .from('pantry_items')
        .stream(primaryKey: ['id'])
        .eq('document_id', documentId)
        .order('name', ascending: true)
        .map((data) => data.map((map) => PantryItem.fromMap(map)).toList());
  }

  Future<List<PantryQuantity>> getPantryQuantities(String pantryItemId) async {
    final response = await _supabase
        .from('pantry_quantities')
        .select()
        .eq('pantry_item_id', pantryItemId)
        .order('expiration_date', ascending: true);
    
    return (response as List).map((map) => PantryQuantity.fromMap(map)).toList();
  }

  Future<PantryItem> createPantryItem(PantryItem item) async {
    final response = await _supabase
        .from('pantry_items')
        .insert(item.toMap())
        .select()
        .single();
    return PantryItem.fromMap(response);
  }

  Future<void> updatePantryItem(PantryItem item) async {
    await _supabase
        .from('pantry_items')
        .update(item.toMap())
        .eq('id', item.id);
  }

  Future<void> deletePantryItem(String id) async {
    await _supabase.from('pantry_items').delete().eq('id', id);
  }

  Future<PantryItem?> getPantryItem(String id) async {
    try {
      final response = await _supabase
          .from('pantry_items')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return null;
      return PantryItem.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<PantryQuantity> addPantryQuantity(PantryQuantity quantity) async {
    final response = await _supabase
        .from('pantry_quantities')
        .insert(quantity.toMap())
        .select()
        .single();
    return PantryQuantity.fromMap(response);
  }

  Future<void> updatePantryQuantity(PantryQuantity quantity) async {
    await _supabase
        .from('pantry_quantities')
        .update(quantity.toMap())
        .eq('id', quantity.id);
  }

  Future<void> deletePantryQuantity(String id) async {
    await _supabase.from('pantry_quantities').delete().eq('id', id);
  }

  // --- SHOPPING LIST ---

  Stream<List<ShoppingListItem>> watchShoppingListItems(String documentId) {
    return _supabase
        .from('shopping_list_items')
        .stream(primaryKey: ['id'])
        .eq('document_id', documentId)
        .order('position', ascending: true)
        .map((data) => data.map((map) => ShoppingListItem.fromMap(map)).toList());
  }

  Future<ShoppingListItem> createShoppingListItem(ShoppingListItem item) async {
    final response = await _supabase
        .from('shopping_list_items')
        .insert(item.toMap())
        .select()
        .single();
    return ShoppingListItem.fromMap(response);
  }

  Future<void> updateShoppingListItem(ShoppingListItem item) async {
    await _supabase
        .from('shopping_list_items')
        .update(item.toMap())
        .eq('id', item.id);
  }

  Future<void> deleteShoppingListItem(String id) async {
    await _supabase.from('shopping_list_items').delete().eq('id', id);
  }

  Future<void> confirmShoppingPurchase(String documentId) async {
    final response = await _supabase
        .from('shopping_list_items')
        .select()
        .eq('document_id', documentId)
        .eq('is_bought', true);

    final items = (response as List).map((map) => ShoppingListItem.fromMap(map)).toList();

    for (var item in items) {
      if (item.pantryItemId != null) {
        await addPantryQuantity(PantryQuantity(
          id: '',
          pantryItemId: item.pantryItemId!,
          sizePerUnit: item.quantity, // We assume quantity in shopping list is the size
          unitsCount: 1, // Default to 1 unit of that size
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
      await deleteShoppingListItem(item.id);
    }
  }
}
