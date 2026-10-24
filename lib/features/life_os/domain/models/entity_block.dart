import 'package:equatable/equatable.dart';

/// Pure domain representation of a sequential content block in an evolvable [LifeEntity].
class EntityBlock extends Equatable {
  final String id;
  final String content;
  final int position;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EntityBlock({
    required this.id,
    required this.content,
    this.position = 0,
    required this.createdAt,
    this.updatedAt,
  });

  EntityBlock copyWith({
    String? id,
    String? content,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EntityBlock(
      id: id ?? this.id,
      content: content ?? this.content,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'position': position,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory EntityBlock.fromJson(Map<String, dynamic> json) {
    return EntityBlock(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, content, position, createdAt, updatedAt];
}
