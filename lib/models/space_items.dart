import 'package:solducci/models/tag.dart';

/// Item in a Note document
class NoteItem {
  final String id;
  final String documentId;
  final String content;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteItem({
    required this.id,
    required this.documentId,
    required this.content,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      content: map['content'] as String,
      position: map['position'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'content': content,
      'position': position,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Item in an Asterisk document
class AsteriskItem {
  final String id;
  final String documentId;
  final String content;
  final bool isResolved;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  AsteriskItem({
    required this.id,
    required this.documentId,
    required this.content,
    required this.isResolved,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AsteriskItem.fromMap(Map<String, dynamic> map) {
    return AsteriskItem(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      content: map['content'] as String,
      isResolved: map['is_resolved'] as bool? ?? false,
      position: map['position'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'content': content,
      'is_resolved': isResolved,
      'position': position,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Item in a Resource List document
class ResourceItem {
  final String id;
  final String documentId;
  final String title;
  final String? url;
  final String? description;
  final String? thumbnailUrl;
  final String? mediaType;
  final Map<String, dynamic> metadata;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relationships
  final List<Tag>? tags;
  final bool isRead;

  ResourceItem({
    required this.id,
    required this.documentId,
    required this.title,
    this.url,
    this.description,
    this.thumbnailUrl,
    this.mediaType,
    this.metadata = const {},
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
    this.isRead = false,
  });

  factory ResourceItem.fromMap(Map<String, dynamic> map, {List<Tag>? tags, bool isRead = false}) {
    return ResourceItem(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      title: map['title'] as String,
      url: map['url'] as String?,
      description: map['description'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      mediaType: map['media_type'] as String?,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : {},
      position: map['position'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      tags: tags,
      isRead: isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'title': title,
      'url': url,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'media_type': mediaType,
      'metadata': metadata,
      'position': position,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Item in a Pantry (Dispensa) document
class PantryItem {
  final String id;
  final String documentId;
  final String name;
  final String? category;
  final double? thresholdLow;
  final String unit;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relationships
  final List<PantryQuantity>? quantities;

  PantryItem({
    required this.id,
    required this.documentId,
    required this.name,
    this.category,
    this.thresholdLow,
    this.unit = 'pcs',
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.quantities,
  });

  double get totalQuantity => quantities?.fold(0.0, (sum, q) => sum! + q.quantity) ?? 0.0;
  bool get isBelowThreshold => thresholdLow != null && totalQuantity <= thresholdLow!;

  factory PantryItem.fromMap(Map<String, dynamic> map, {List<PantryQuantity>? quantities}) {
    return PantryItem(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      thresholdLow: (map['threshold_low'] as num?)?.toDouble(),
      unit: map['unit'] as String? ?? 'pcs',
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      quantities: quantities,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'name': name,
      'category': category,
      'threshold_low': thresholdLow,
      'unit': unit,
      'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Specific quantity of a Pantry item (e.g. one lot with an expiration date)
class PantryQuantity {
  final String id;
  final String pantryItemId;
  final double quantity;
  final DateTime? expirationDate;
  final String? lotNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  PantryQuantity({
    required this.id,
    required this.pantryItemId,
    required this.quantity,
    this.expirationDate,
    this.lotNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PantryQuantity.fromMap(Map<String, dynamic> map) {
    return PantryQuantity(
      id: map['id'] as String,
      pantryItemId: map['pantry_item_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      expirationDate: map['expiration_date'] != null ? DateTime.parse(map['expiration_date'] as String) : null,
      lotNumber: map['lot_number'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pantry_item_id': pantryItemId,
      'quantity': quantity,
      'expiration_date': expirationDate?.toIso8601String(),
      'lot_number': lotNumber,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Item in a Shopping List document
class ShoppingListItem {
  final String id;
  final String documentId;
  final String? pantryItemId;
  final String name;
  final double quantity;
  final String? unit;
  final bool isBought;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingListItem({
    required this.id,
    required this.documentId,
    this.pantryItemId,
    required this.name,
    required this.quantity,
    this.unit,
    required this.isBought,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      pantryItemId: map['pantry_item_id'] as String?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num? ?? 1).toDouble(),
      unit: map['unit'] as String?,
      isBought: map['is_bought'] as bool? ?? false,
      position: map['position'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'pantry_item_id': pantryItemId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'is_bought': isBought,
      'position': position,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
