/// Configuration for cache behavior
class CacheConfig {
  /// Maximum number of items to keep in cache
  /// When exceeded, oldest items (by lastAccessed) are evicted
  /// Set to null for unlimited cache size
  final int? maxSize;

  /// Time-to-live for cache entries
  /// Entries older than this duration are invalidated
  /// Set to null to disable TTL
  final Duration? ttl;

  /// Whether to enable cache statistics tracking
  /// Useful for debugging and performance monitoring
  final bool enableStats;

  /// Whether to preload all data on service initialization
  /// If true, service will fetch all data on first access
  final bool preloadOnInit;

  /// Strategy for cache eviction when maxSize is reached
  final EvictionStrategy evictionStrategy;

  const CacheConfig({
    this.maxSize,
    this.ttl,
    this.enableStats = false,
    this.preloadOnInit = false,
    this.evictionStrategy = EvictionStrategy.lru,
  });

  /// Default config: unlimited cache, no TTL, no preload
  static const CacheConfig defaultConfig = CacheConfig();

  /// Config for frequently accessed, stable data (groups, profiles)
  static const CacheConfig stable = CacheConfig(
    maxSize: 1000,
    ttl: Duration(hours: 1),
    enableStats: true,
    preloadOnInit: true,
  );

  /// Config for dynamic, frequently changing data (expenses)
  static const CacheConfig dynamic = CacheConfig(
    maxSize: 500,
    ttl: Duration(minutes: 30),
    enableStats: true,
    preloadOnInit: false,
  );

  /// Config for large datasets with aggressive eviction
  static const CacheConfig large = CacheConfig(
    maxSize: 200,
    ttl: Duration(minutes: 15),
    enableStats: true,
    evictionStrategy: EvictionStrategy.lfu,
  );
}

/// Strategy for evicting cache entries when maxSize is reached
enum EvictionStrategy {
  /// Least Recently Used - evict items accessed longest ago
  lru,

  /// Least Frequently Used - evict items accessed least often
  lfu,

  /// First In First Out - evict oldest items by insertion time
  fifo,
}

/// Metadata for a cached item
class CacheEntry<T> {
  final T data;
  final DateTime insertedAt;
  DateTime lastAccessedAt;
  int accessCount;

  CacheEntry(this.data)
      : insertedAt = DateTime.now(),
        lastAccessedAt = DateTime.now(),
        accessCount = 1;

  /// Mark this entry as accessed
  void markAccessed() {
    lastAccessedAt = DateTime.now();
    accessCount++;
  }

  /// Check if entry is expired based on TTL
  bool isExpired(Duration? ttl) {
    if (ttl == null) return false;
    return DateTime.now().difference(insertedAt) > ttl;
  }

  /// Get age of this entry
  Duration get age => DateTime.now().difference(insertedAt);

  /// Get time since last access
  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessedAt);
}

/// Statistics for cache performance monitoring
class CacheStats {
  int hits = 0;
  int misses = 0;
  int evictions = 0;
  int invalidations = 0;

  double get hitRate {
    final total = hits + misses;
    return total == 0 ? 0 : hits / total;
  }

  void reset() {
    hits = 0;
    misses = 0;
    evictions = 0;
    invalidations = 0;
  }

  @override
  String toString() {
    return 'CacheStats(hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, evictions: $evictions, invalidations: $invalidations)';
  }
}
