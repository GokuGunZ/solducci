import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/enums.dart';

/// Pure Domain Model for a semantic relation edge.
/// Connects a LifeEntity (source) to any supported target (TargetType).
class EntityRelation extends Equatable {
  final String id;
  final String userId;
  final String sourceId;
  final TargetType sourceType;
  final TargetType targetType;
  final String targetId;
  final RelationType relationType;
  final ContextStatus? contextStatus;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const EntityRelation({
    required this.id,
    required this.userId,
    required this.sourceId,
    this.sourceType = TargetType.entity,
    required this.targetType,
    required this.targetId,
    required this.relationType,
    this.contextStatus,
    this.metadata = const {},
    required this.createdAt,
  });

  bool get isBlocker => contextStatus == ContextStatus.blocker;
  bool get isActive => contextStatus == ContextStatus.active;
  bool get isResolved => contextStatus == ContextStatus.resolved;

  EntityRelation copyWith({
    String? id,
    String? userId,
    String? sourceId,
    TargetType? sourceType,
    TargetType? targetType,
    String? targetId,
    RelationType? relationType,
    ContextStatus? Function()? contextStatus,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return EntityRelation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      relationType: relationType ?? this.relationType,
      contextStatus: contextStatus != null ? contextStatus() : this.contextStatus,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        sourceId,
        sourceType,
        targetType,
        targetId,
        relationType,
        contextStatus,
        metadata,
        createdAt,
      ];
}
