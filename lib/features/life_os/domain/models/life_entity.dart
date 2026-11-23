import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/entity_block.dart';
import 'package:solducci/features/life_os/domain/models/entity_property.dart';
import 'package:solducci/features/life_os/domain/models/enums.dart';

/// Pure Domain Model for an entity in Life OS.
/// Decoupled from any persistence framework or database representation.
class LifeEntity extends Equatable {
  final String id;
  final String? userId;
  final String? groupId;
  final String title;
  final String? description;

  /// Semantic role (seed, idea, project, practice, concept).
  /// Raw captures start with [SemanticRole.seed].
  final SemanticRole semanticRole;

  /// Lifecycle state (active, paused, completed, archived).
  /// Defaults to [LifecycleState.active].
  final LifecycleState lifecycleState;

  /// Current operational mode (exploration, execution, practice, reflection).
  /// Nullable by design (Amendment A: absence of structure is valid structure).
  final OperationMode? currentMode;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Derived/materialized cache of last meaningful activity.
  /// Computed from sessions and task completion (Amendment D).
  final DateTime? lastMeaningfulActivityAt;

  /// Progressive properties (INT-D016). Preserved across role changes.
  final List<EntityProperty> properties;

  /// Living, sequential content blocks added over time (INT-D015).
  final List<EntityBlock> blocks;

  /// Any extensible custom properties.
  final Map<String, dynamic> customMetadata;

  const LifeEntity({
    required this.id,
    this.userId,
    this.groupId,
    required this.title,
    this.description,
    this.semanticRole = SemanticRole.seed,
    this.lifecycleState = LifecycleState.active,
    this.currentMode,
    required this.createdAt,
    required this.updatedAt,
    this.lastMeaningfulActivityAt,
    this.properties = const [],
    this.blocks = const [],
    this.customMetadata = const {},
  });

  bool get isPersonal => groupId == null;
  bool get isGroupShared => groupId != null;

  bool get isSeed => semanticRole == SemanticRole.seed;
  bool get isIdea => semanticRole == SemanticRole.idea;
  bool get isProject => semanticRole == SemanticRole.project;
  bool get isPractice => semanticRole == SemanticRole.practice;
  bool get isConcept => semanticRole == SemanticRole.concept;

  bool get isArchived => lifecycleState == LifecycleState.archived;
  bool get isActive => lifecycleState == LifecycleState.active;
  bool get isPaused => lifecycleState == LifecycleState.paused;

  /// Upserts a property by its semantic key (INT-D016).
  /// Reuses and updates the existing property if key matches; appends if new.
  /// Guarantees: one entity + one semantic key → at most one active property.
  LifeEntity upsertProperty(EntityProperty property) {
    final cleanKey = property.key.trim();
    if (cleanKey.isEmpty) return this;

    final existingIndex = properties.indexWhere((p) => p.key == cleanKey);
    final List<EntityProperty> updated = List.from(properties);

    if (existingIndex >= 0) {
      updated[existingIndex] = property;
    } else {
      updated.add(property);
    }

    return copyWith(properties: updated, updatedAt: DateTime.now());
  }

  /// Removes a property by its semantic key.
  LifeEntity removeProperty(String key) {
    final cleanKey = key.trim();
    final updated = properties.where((p) => p.key != cleanKey).toList();
    return copyWith(properties: updated, updatedAt: DateTime.now());
  }

  LifeEntity copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? title,
    String? description,
    SemanticRole? semanticRole,
    LifecycleState? lifecycleState,
    OperationMode? Function()? currentMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? Function()? lastMeaningfulActivityAt,
    List<EntityProperty>? properties,
    List<EntityBlock>? blocks,
    Map<String, dynamic>? customMetadata,
  }) {
    return LifeEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      semanticRole: semanticRole ?? this.semanticRole,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      currentMode: currentMode != null ? currentMode() : this.currentMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMeaningfulActivityAt: lastMeaningfulActivityAt != null
          ? lastMeaningfulActivityAt()
          : this.lastMeaningfulActivityAt,
      properties: properties ?? this.properties,
      blocks: blocks ?? this.blocks,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        groupId,
        title,
        description,
        semanticRole,
        lifecycleState,
        currentMode,
        createdAt,
        updatedAt,
        lastMeaningfulActivityAt,
        properties,
        blocks,
        customMetadata,
      ];
}
