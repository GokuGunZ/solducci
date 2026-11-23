import 'package:solducci/features/life_os/domain/models/models.dart';

class UserEntityOverlayMapper {
  static UserEntityOverlay fromMap(Map<String, dynamic> map) {
    return UserEntityOverlay(
      userId: map['user_id'] as String,
      entityId: map['entity_id'] as String,
      isInWeeklyRail: map['is_in_weekly_rail'] as bool? ?? false,
      commitmentWeight: CommitmentWeight.fromString(map['commitment_weight'] as String?),
      snoozedSignals: map['snoozed_signals'] != null
          ? Map<String, dynamic>.from(map['snoozed_signals'] as Map)
          : {},
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(UserEntityOverlay overlay) {
    return {
      'user_id': overlay.userId,
      'entity_id': overlay.entityId,
      'is_in_weekly_rail': overlay.isInWeeklyRail,
      'commitment_weight': overlay.commitmentWeight?.value,
      'snoozed_signals': overlay.snoozedSignals,
      'updated_at': overlay.updatedAt.toIso8601String(),
    };
  }
}
