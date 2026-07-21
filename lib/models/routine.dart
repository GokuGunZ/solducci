import 'package:flutter/material.dart';

class RoutineTemplate {
  final String id;
  final String userId;
  final String? groupId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoutineTemplate({
    required this.id,
    required this.userId,
    this.groupId,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoutineTemplate.fromMap(Map<String, dynamic> map) {
    return RoutineTemplate(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      groupId: map['group_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'group_id': groupId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class RoutineAlarm {
  final String id;
  final String routineTemplateId;
  final int offsetMinutes;
  final String label;
  final String alarmType; // 'push', 'native_aggressive'
  final DateTime createdAt;
  final DateTime updatedAt;

  RoutineAlarm({
    required this.id,
    required this.routineTemplateId,
    required this.offsetMinutes,
    required this.label,
    this.alarmType = 'push',
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoutineAlarm.fromMap(Map<String, dynamic> map) {
    return RoutineAlarm(
      id: map['id'] as String,
      routineTemplateId: map['routine_template_id'] as String,
      offsetMinutes: map['offset_minutes'] as int,
      label: map['label'] as String,
      alarmType: map['alarm_type'] as String? ?? 'push',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routine_template_id': routineTemplateId,
      'offset_minutes': offsetMinutes,
      'label': label,
      'alarm_type': alarmType,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class RoutineSchedule {
  final String id;
  final String routineTemplateId;
  final TimeOfDay targetTime;
  final int dayOfWeek; // 1-7
  final DateTime? isPausedForToday;
  final TimeOfDay? customTargetTimeOverride;
  final DateTime? overrideExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoutineSchedule({
    required this.id,
    required this.routineTemplateId,
    required this.targetTime,
    required this.dayOfWeek,
    this.isPausedForToday,
    this.customTargetTimeOverride,
    this.overrideExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoutineSchedule.fromMap(Map<String, dynamic> map) {
    // Parse time from Supabase format (HH:MM:SS)
    final timeStr = map['target_time'] as String;
    final timeParts = timeStr.split(':');
    final targetTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

    TimeOfDay? customTime;
    if (map['custom_target_time_override'] != null) {
      final overrideStr = map['custom_target_time_override'] as String;
      final overrideParts = overrideStr.split(':');
      customTime = TimeOfDay(hour: int.parse(overrideParts[0]), minute: int.parse(overrideParts[1]));
    }

    return RoutineSchedule(
      id: map['id'] as String,
      routineTemplateId: map['routine_template_id'] as String,
      targetTime: targetTime,
      dayOfWeek: map['day_of_week'] as int,
      isPausedForToday: map['is_paused_for_today'] != null ? DateTime.parse(map['is_paused_for_today'] as String) : null,
      customTargetTimeOverride: customTime,
      overrideExpiry: map['override_expiry'] != null ? DateTime.parse(map['override_expiry'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final formattedTarget = '${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}:00';
    String? formattedOverride;
    if (customTargetTimeOverride != null) {
      formattedOverride = '${customTargetTimeOverride!.hour.toString().padLeft(2, '0')}:${customTargetTimeOverride!.minute.toString().padLeft(2, '0')}:00';
    }

    return {
      'routine_template_id': routineTemplateId,
      'target_time': formattedTarget,
      'day_of_week': dayOfWeek,
      'is_paused_for_today': isPausedForToday?.toIso8601String().substring(0, 10), // only YYYY-MM-DD
      'custom_target_time_override': formattedOverride,
      'override_expiry': overrideExpiry?.toIso8601String().substring(0, 10),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
