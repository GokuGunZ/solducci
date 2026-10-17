// Core interfaces enforcing contextual scoping across all entities in Solducci.
//
// Prevents accidental data leaks by providing compile-time type safety:
// 1. [DirectContextBound]: Models having direct contextual ownership (Personal or Group).
// 2. [DocumentBound]: Models belonging to a parent document that determines context.
// 3. [PortfolioBound]: Models belonging to a parent portfolio.
// 4. [UserBound]: Models strictly tied to a user account.

abstract mixin class DirectContextBound {
  /// The user ID if this entity was created in a personal context, or null/creator ID.
  String? get userId;

  /// The group ID if this entity belongs to an expense group, or null if personal.
  String? get groupId;

  /// Whether this entity belongs strictly to a personal context.
  bool get isPersonalContext => groupId == null && userId != null;

  /// Whether this entity belongs to a shared group.
  bool get isGroupContext => groupId != null;
}

abstract interface class DocumentBound {
  /// The parent document ID defining the context and permissions of this entity.
  String get documentId;
}

abstract interface class PortfolioBound {
  /// The parent portfolio ID defining the context and ownership of this asset.
  String get portfolioId;
}

abstract interface class UserBound {
  /// The user ID of the account owning this entity.
  String get userId;
}
