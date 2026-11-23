// Enums and value objects for the Life OS domain layer.
// These enums represent clean domain concepts independent of database constraints.

/// High-level semantic nature of an entity.
/// Default for new captures is [seed].
enum SemanticRole {
  seed,
  idea,
  project,
  practice,
  concept;

  static SemanticRole fromString(String? value) {
    if (value == null) return SemanticRole.seed;
    switch (value.toLowerCase().trim()) {
      case 'idea':
        return SemanticRole.idea;
      case 'project':
        return SemanticRole.project;
      case 'practice':
        return SemanticRole.practice;
      case 'concept':
        return SemanticRole.concept;
      case 'seed':
      default:
        return SemanticRole.seed;
    }
  }

  String get value => name;
}

/// Stage in the lifecycle of an entity.
enum LifecycleState {
  active,
  paused,
  completed,
  archived;

  static LifecycleState fromString(String? value) {
    if (value == null) return LifecycleState.active;
    switch (value.toLowerCase().trim()) {
      case 'paused':
        return LifecycleState.paused;
      case 'completed':
        return LifecycleState.completed;
      case 'archived':
        return LifecycleState.archived;
      case 'active':
      default:
        return LifecycleState.active;
    }
  }

  String get value => name;
}

/// Operational lens / mode currently applied to the entity.
/// Notice: Can be null. Absence of mode is valid domain structure (Amendment A).
enum OperationMode {
  exploration,
  execution,
  practice,
  reflection;

  static OperationMode? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase().trim()) {
      case 'exploration':
        return OperationMode.exploration;
      case 'execution':
        return OperationMode.execution;
      case 'practice':
        return OperationMode.practice;
      case 'reflection':
        return OperationMode.reflection;
      default:
        return null;
    }
  }

  String get value => name;
}

/// Supported polymorphic target types for entity_relations (Amendment C).
enum TargetType {
  entity,
  task,
  expense,
  timeScenario;

  static TargetType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'task':
        return TargetType.task;
      case 'expense':
        return TargetType.expense;
      case 'time_scenario':
      case 'timescenario':
        return TargetType.timeScenario;
      case 'entity':
      default:
        return TargetType.entity;
    }
  }

  String get value {
    switch (this) {
      case TargetType.timeScenario:
        return 'time_scenario';
      default:
        return name;
    }
  }
}

/// Semantic connection types between a LifeEntity and a target.
enum RelationType {
  requires,
  influences,
  partOf,
  contextFor,
  fundedBy,
  relatesTo;

  static RelationType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'requires':
        return RelationType.requires;
      case 'influences':
        return RelationType.influences;
      case 'part_of':
      case 'partof':
        return RelationType.partOf;
      case 'context_for':
      case 'contextfor':
        return RelationType.contextFor;
      case 'funded_by':
      case 'fundedby':
        return RelationType.fundedBy;
      case 'relates_to':
      case 'relatesto':
      default:
        return RelationType.relatesTo;
    }
  }

  String get value {
    switch (this) {
      case RelationType.partOf:
        return 'part_of';
      case RelationType.contextFor:
        return 'context_for';
      case RelationType.fundedBy:
        return 'funded_by';
      case RelationType.relatesTo:
        return 'relates_to';
      default:
        return name;
    }
  }
}

/// Contextual status of a relation edge (e.g. GDPR is a blocker for Solducci).
enum ContextStatus {
  blocker,
  active,
  resolved,
  reference;

  static ContextStatus? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase().trim()) {
      case 'blocker':
        return ContextStatus.blocker;
      case 'active':
        return ContextStatus.active;
      case 'resolved':
        return ContextStatus.resolved;
      case 'reference':
        return ContextStatus.reference;
      default:
        return null;
    }
  }

  String get value => name;
}

/// Level of user commitment for weekly planning.
enum CommitmentWeight {
  low,
  medium,
  high;

  static CommitmentWeight? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase().trim()) {
      case 'low':
        return CommitmentWeight.low;
      case 'medium':
        return CommitmentWeight.medium;
      case 'high':
        return CommitmentWeight.high;
      default:
        return null;
    }
  }

  String get value => name;
}
