import 'package:solducci/features/life_os/domain/models/models.dart';

class LifeSessionMapper {
  static LifeSession fromMap(Map<String, dynamic> map) {
    final relatedRaw = map['related_entity_ids'];
    final List<String> relatedIds;
    if (relatedRaw is List) {
      relatedIds = relatedRaw.map((e) => e.toString()).toList();
    } else {
      relatedIds = [];
    }

    return LifeSession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      primaryEntityId: map['primary_entity_id'] as String,
      relatedEntityIds: relatedIds,
      startedAt: DateTime.parse(map['started_at'] as String),
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      activitySummary: map['activity_summary'] as String? ?? '',
      metrics: map['metrics'] != null
          ? Map<String, dynamic>.from(map['metrics'] as Map)
          : {},
      observations: map['observations'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(LifeSession session) {
    final map = <String, dynamic>{
      'user_id': session.userId,
      'primary_entity_id': session.primaryEntityId,
      'related_entity_ids': session.relatedEntityIds,
      'started_at': session.startedAt.toIso8601String(),
      'duration_minutes': session.durationMinutes,
      'activity_summary': session.activitySummary,
      'metrics': session.metrics,
      'observations': session.observations,
      'created_at': session.createdAt.toIso8601String(),
    };

    if (session.id.isNotEmpty && session.id != '00000000-0000-0000-0000-000000000000') {
      map['id'] = session.id;
    }

    return map;
  }
}
