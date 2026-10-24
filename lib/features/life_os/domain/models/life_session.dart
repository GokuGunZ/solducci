import 'package:equatable/equatable.dart';

/// Pure Domain Model for a lived activity sampling session.
/// Has one primary focal context and optional secondary related contexts.
class LifeSession extends Equatable {
  final String id;
  final String userId;
  final String primaryEntityId;
  final List<String> relatedEntityIds;
  final DateTime startedAt;
  final int durationMinutes;
  final String activitySummary;
  final Map<String, dynamic> metrics;
  final String? observations;
  final DateTime createdAt;

  const LifeSession({
    required this.id,
    required this.userId,
    required this.primaryEntityId,
    this.relatedEntityIds = const [],
    required this.startedAt,
    required this.durationMinutes,
    required this.activitySummary,
    this.metrics = const {},
    this.observations,
    required this.createdAt,
  });

  bool touchesEntity(String entityId) {
    return primaryEntityId == entityId || relatedEntityIds.contains(entityId);
  }

  LifeSession copyWith({
    String? id,
    String? userId,
    String? primaryEntityId,
    List<String>? relatedEntityIds,
    DateTime? startedAt,
    int? durationMinutes,
    String? activitySummary,
    Map<String, dynamic>? metrics,
    String? Function()? observations,
    DateTime? createdAt,
  }) {
    return LifeSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      primaryEntityId: primaryEntityId ?? this.primaryEntityId,
      relatedEntityIds: relatedEntityIds ?? this.relatedEntityIds,
      startedAt: startedAt ?? this.startedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      activitySummary: activitySummary ?? this.activitySummary,
      metrics: metrics ?? this.metrics,
      observations: observations != null ? observations() : this.observations,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        primaryEntityId,
        relatedEntityIds,
        startedAt,
        durationMinutes,
        activitySummary,
        metrics,
        observations,
        createdAt,
      ];
}
