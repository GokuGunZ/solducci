import 'package:solducci/features/life_os/domain/models/models.dart';

class EntityRelationMapper {
  static EntityRelation fromMap(Map<String, dynamic> map) {
    return EntityRelation(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      sourceId: map['source_id'] as String,
      sourceType: TargetType.fromString(map['source_type'] as String? ?? 'entity'),
      targetType: TargetType.fromString(map['target_type'] as String),
      targetId: map['target_id'] as String,
      relationType: RelationType.fromString(map['relation_type'] as String),
      contextStatus: ContextStatus.fromString(map['context_status'] as String?),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(EntityRelation relation) {
    final map = <String, dynamic>{
      'user_id': relation.userId,
      'source_id': relation.sourceId,
      'source_type': relation.sourceType.value,
      'target_type': relation.targetType.value,
      'target_id': relation.targetId,
      'relation_type': relation.relationType.value,
      'context_status': relation.contextStatus?.value,
      'metadata': relation.metadata,
      'created_at': relation.createdAt.toIso8601String(),
    };

    if (relation.id.isNotEmpty && relation.id != '00000000-0000-0000-0000-000000000000') {
      map['id'] = relation.id;
    }

    return map;
  }
}
