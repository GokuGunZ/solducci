/// Base interface for models that support caching
///
/// Models implementing this interface can be cached in-memory
/// by their corresponding CacheableService.
///
/// Type parameter [K] represents the primary key type (int, String, UUID, etc.)
abstract class CacheableModel<K> {
  /// Unique identifier for this model instance
  /// Used as cache key in Map<K, Model>
  K get cacheKey;

  /// Timestamp of last modification (optional)
  /// Used for cache invalidation strategies
  DateTime? get lastModified => null;

  /// Whether this instance should be cached
  /// Override to implement conditional caching logic
  bool get shouldCache => true;

  /// Create a deep copy of this model
  /// Required for cache immutability guarantees
  CacheableModel<K> copyWith();

  /// Serialize to Map for persistence
  Map<String, dynamic> toMap();

  /// Hash code based on cache key for efficient Map lookups
  @override
  int get hashCode => cacheKey.hashCode;

  /// Equality based on cache key
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheableModel<K> && other.cacheKey == cacheKey;
  }
}
