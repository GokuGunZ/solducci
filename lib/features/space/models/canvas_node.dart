import 'package:equatable/equatable.dart';

class CanvasNode extends Equatable {
  final String id;
  final String? parentId;
  final String type; // 'folder', 'markdown', 'url'
  final String lexorank;
  final String title;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> payload;
  final String? userId;
  final String? groupId;
  final DateTime lastAccessedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanvasNode({
    required this.id,
    this.parentId,
    required this.type,
    required this.lexorank,
    required this.title,
    this.metadata = const {},
    this.payload = const {},
    this.userId,
    this.groupId,
    required this.lastAccessedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  CanvasNode copyWith({
    String? id,
    String? parentId,
    bool clearParentId = false,
    String? type,
    String? lexorank,
    String? title,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? payload,
    String? userId,
    String? groupId,
    bool clearGroupId = false,
    DateTime? lastAccessedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CanvasNode(
      id: id ?? this.id,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      type: type ?? this.type,
      lexorank: lexorank ?? this.lexorank,
      title: title ?? this.title,
      metadata: metadata ?? this.metadata,
      payload: payload ?? this.payload,
      userId: userId ?? this.userId,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CanvasNode.fromMap(Map<String, dynamic> map) {
    return CanvasNode(
      id: map['id'],
      parentId: map['parent_id'],
      type: map['type'],
      lexorank: map['lexorank'],
      title: map['title'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      userId: map['user_id'],
      groupId: map['group_id'],
      lastAccessedAt: DateTime.parse(map['last_accessed_at']).toLocal(),
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      updatedAt: DateTime.parse(map['updated_at']).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'type': type,
      'lexorank': lexorank,
      'title': title,
      'metadata': metadata,
      'payload': payload,
      'user_id': userId,
      'group_id': groupId,
      'last_accessed_at': lastAccessedAt.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        parentId,
        type,
        lexorank,
        title,
        metadata,
        payload,
        userId,
        groupId,
        lastAccessedAt,
        createdAt,
        updatedAt,
      ];
}
