/// Abstract base class for all document types (polymorphic design)
/// This enables extensibility for future document types like shopping lists,
/// pantry inventories, generic lists, etc.
///
/// Each document type should extend this class and implement its own
/// specific fields and behavior while maintaining common document properties.
abstract class Document {
  final String id;
  final String? userId; // For personal documents
  final String? groupId; // For shared group documents (future)
  final String documentType; // 'todo', 'shopping_list', 'dispensa', etc.
  String title;
  String? description;
  final DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic> metadata; // Extensible JSONB field

  Document({
    required this.id,
    this.userId,
    this.groupId,
    required this.documentType,
    required this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  /// Check if document is personal (not in a group)
  bool get isPersonal => groupId == null;

  /// Check if document is for a group
  bool get isGroup => groupId != null;

  /// Convert document to map for Supabase
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'document_type': documentType,
      'title': title,
      'description': description,
      'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Always include user_id and group_id (can be null)
    map['user_id'] = userId;
    map['group_id'] = groupId;

    // Only include id for updates
    if (id.isNotEmpty && id != '00000000-0000-0000-0000-000000000000') {
      map['id'] = id;
    }

    return map;
  }

  /// Convert to map for insert (without id)
  Map<String, dynamic> toInsertMap() {
    return toMap()..remove('id');
  }

  /// Convert to map for update (only mutable fields)
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Factory method for polymorphic deserialization
  /// Determines which concrete document class to instantiate based on document_type
  static Document fromMap(Map<String, dynamic> map) {
    final type = map['document_type'] as String;

    switch (type) {
      case 'todo':
        return TodoDocument.fromMap(map);
      case 'shopping_list':
        // Future implementation
        throw UnimplementedError('ShoppingListDocument not yet implemented');
      case 'dispensa':
        // Future implementation
        throw UnimplementedError('DispensaDocument not yet implemented');
      case 'generic_list':
        // Future implementation
        throw UnimplementedError('GenericListDocument not yet implemented');
      default:
        throw ArgumentError('Unknown document type: $type');
    }
  }

  @override
  String toString() {
    return '$runtimeType(id: $id, title: $title, type: $documentType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// ToDo document - contains a list of tasks with tags and recurrence
/// This is the first concrete implementation of Document
class TodoDocument extends Document {
  // Note: tasks are loaded separately via TaskService to avoid
  // circular dependencies and enable lazy loading

  TodoDocument({
    required super.id,
    super.userId,
    super.groupId,
    required super.title,
    super.description,
    required super.createdAt,
    required super.updatedAt,
    super.metadata,
  }) : super(documentType: 'todo');

  /// Create TodoDocument from Supabase map
  factory TodoDocument.fromMap(Map<String, dynamic> map) {
    return TodoDocument(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      groupId: map['group_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
    );
  }

  /// Create a copy with modified fields
  TodoDocument copyWith({
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return TodoDocument(
      id: id,
      userId: userId,
      groupId: groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create a new empty TodoDocument for the current user
  factory TodoDocument.create({
    required String userId,
    required String title,
    String? description,
  }) {
    return TodoDocument(
      id: '', // Will be generated by Supabase
      userId: userId,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
