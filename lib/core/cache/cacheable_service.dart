import 'dart:async';
import 'package:solducci/core/cache/cacheable_model.dart';
import 'package:solducci/core/cache/cache_config.dart';

/// Base abstract class for services that provide caching functionality
///
/// Implements a generic in-memory cache with:
/// - Configurable eviction strategies (LRU, LFU, FIFO)
/// - TTL support
/// - Cache statistics
/// - Bulk operations
/// - Reactive stream support
///
/// Type parameters:
/// - [M] - Model type (must implement CacheableModel)
/// - [K] - Cache key type (int, String, etc.)
abstract class CacheableService<M extends CacheableModel<K>, K> {
  /// Internal cache storage
  final Map<K, CacheEntry<M>> _cache = {};

  /// Cache configuration
  final CacheConfig config;

  /// Cache statistics
  final CacheStats stats = CacheStats();

  /// Stream controller for cache change notifications
  final StreamController<CacheChangeEvent<M, K>> _changeController =
      StreamController<CacheChangeEvent<M, K>>.broadcast();

  /// Whether the cache has been initialized (preloaded)
  bool _initialized = false;

  CacheableService({this.config = CacheConfig.defaultConfig});

  // ====================================================================
  // ABSTRACT METHODS - Must be implemented by subclasses
  // ====================================================================

  /// Fetch a single item from the data source by key
  /// Called on cache miss
  Future<M?> fetchById(K id);

  /// Fetch all items from the data source
  /// Called during cache preload or bulk refresh
  Future<List<M>> fetchAll();

  /// Persist a new item to the data source
  /// Cache is updated automatically after successful insert
  Future<M> insert(M item);

  /// Update an existing item in the data source
  /// Cache is updated automatically after successful update
  Future<M> update(M item);

  /// Delete an item from the data source
  /// Cache is invalidated automatically after successful delete
  Future<void> delete(K id);

  // ====================================================================
  // CACHE OPERATIONS
  // ====================================================================

  /// Get item by key - checks cache first, fetches on miss
  Future<M?> getById(K id) async {
    // Check cache first
    final cached = _getCached(id);
    if (cached != null) {
      if (config.enableStats) stats.hits++;
      return cached;
    }

    // Cache miss - fetch from source
    if (config.enableStats) stats.misses++;
    final item = await fetchById(id);

    if (item != null) {
      _putInCache(id, item);
    }

    return item;
  }

  /// Get multiple items by keys - optimized bulk operation
  Future<List<M>> getByIds(List<K> ids) async {
    final results = <M>[];
    final missingIds = <K>[];

    // Check cache for each ID
    for (final id in ids) {
      final cached = _getCached(id);
      if (cached != null) {
        results.add(cached);
        if (config.enableStats) stats.hits++;
      } else {
        missingIds.add(id);
        if (config.enableStats) stats.misses++;
      }
    }

    // Fetch missing items (subclass can optimize this with bulk query)
    if (missingIds.isNotEmpty) {
      final fetched = await fetchAll();
      for (final item in fetched) {
        if (missingIds.contains(item.cacheKey)) {
          _putInCache(item.cacheKey, item);
          results.add(item);
        }
      }
    }

    return results;
  }

  /// Get all cached items
  List<M> getCached() {
    return _cache.values.map((entry) {
      entry.markAccessed();
      return entry.data;
    }).toList();
  }

  /// Preload cache with all items from data source
  Future<void> preloadCache() async {
    if (_initialized) return;

    final items = await fetchAll();
    for (final item in items) {
      _putInCache(item.cacheKey, item);
    }

    _initialized = true;
  }

  /// Ensure cache is initialized (preload if needed)
  Future<void> ensureInitialized() async {
    if (config.preloadOnInit && !_initialized) {
      await preloadCache();
    }
  }

  /// Refresh cache by re-fetching all items
  Future<void> refreshCache() async {
    invalidateAll();
    await preloadCache();
  }

  /// Invalidate a single cache entry
  void invalidate(K id) {
    _cache.remove(id);
    if (config.enableStats) stats.invalidations++;
    _notifyChange(CacheChangeEvent.invalidated(id));
  }

  /// Invalidate multiple cache entries
  void invalidateMany(List<K> ids) {
    for (final id in ids) {
      invalidate(id);
    }
  }

  /// Invalidate all cache entries
  void invalidateAll() {
    _cache.clear();
    if (config.enableStats) {
      stats.invalidations += _cache.length;
    }
    _notifyChange(CacheChangeEvent.cleared());
  }

  /// Manually put item in cache (useful for optimistic updates)
  void putInCache(M item) {
    _putInCache(item.cacheKey, item);
  }

  /// Manually put multiple items in cache
  void putManyInCache(List<M> items) {
    for (final item in items) {
      _putInCache(item.cacheKey, item);
    }
  }

  // ====================================================================
  // CRUD OPERATIONS WITH CACHE INTEGRATION
  // ====================================================================

  /// Create a new item (calls insert + updates cache)
  Future<M> create(M item) async {
    final created = await insert(item);
    _putInCache(created.cacheKey, created);
    _notifyChange(CacheChangeEvent.created(created));
    return created;
  }

  /// Update an existing item (calls update + updates cache)
  Future<M> updateItem(M item) async {
    final updated = await update(item);
    _putInCache(updated.cacheKey, updated);
    _notifyChange(CacheChangeEvent.updated(updated));
    return updated;
  }

  /// Delete an item (calls delete + invalidates cache)
  Future<void> deleteItem(K id) async {
    await delete(id);
    invalidate(id);
    _notifyChange(CacheChangeEvent.deleted(id));
  }

  // ====================================================================
  // STREAM SUPPORT
  // ====================================================================

  /// Stream of cache change events
  Stream<CacheChangeEvent<M, K>> get cacheChanges => _changeController.stream;

  /// Stream of all cached items (reactive)
  Stream<List<M>> get cachedItemsStream {
    return _changeController.stream.map((_) => getCached());
  }

  // ====================================================================
  // INTERNAL CACHE MANAGEMENT
  // ====================================================================

  /// Get item from cache (internal, with TTL check)
  M? _getCached(K id) {
    final entry = _cache[id];
    if (entry == null) return null;

    // Check TTL
    if (entry.isExpired(config.ttl)) {
      _cache.remove(id);
      return null;
    }

    entry.markAccessed();
    return entry.data;
  }

  /// Put item in cache (internal, with eviction)
  void _putInCache(K id, M item) {
    if (!item.shouldCache) return;

    // Check size limit and evict if needed
    if (config.maxSize != null && _cache.length >= config.maxSize!) {
      _evictOne();
    }

    _cache[id] = CacheEntry(item);
  }

  /// Evict one entry based on eviction strategy
  void _evictOne() {
    if (_cache.isEmpty) return;

    K? keyToEvict;

    switch (config.evictionStrategy) {
      case EvictionStrategy.lru:
        // Evict least recently used
        DateTime oldestAccess = DateTime.now();
        for (final entry in _cache.entries) {
          if (entry.value.lastAccessedAt.isBefore(oldestAccess)) {
            oldestAccess = entry.value.lastAccessedAt;
            keyToEvict = entry.key;
          }
        }
        break;

      case EvictionStrategy.lfu:
        // Evict least frequently used
        int minAccessCount = double.maxFinite.toInt();
        for (final entry in _cache.entries) {
          if (entry.value.accessCount < minAccessCount) {
            minAccessCount = entry.value.accessCount;
            keyToEvict = entry.key;
          }
        }
        break;

      case EvictionStrategy.fifo:
        // Evict oldest by insertion
        DateTime oldestInsertion = DateTime.now();
        for (final entry in _cache.entries) {
          if (entry.value.insertedAt.isBefore(oldestInsertion)) {
            oldestInsertion = entry.value.insertedAt;
            keyToEvict = entry.key;
          }
        }
        break;
    }

    if (keyToEvict != null) {
      _cache.remove(keyToEvict);
      if (config.enableStats) stats.evictions++;
    }
  }

  /// Notify listeners of cache change
  void _notifyChange(CacheChangeEvent<M, K> event) {
    if (!_changeController.isClosed) {
      _changeController.add(event);
    }
  }

  // ====================================================================
  // DIAGNOSTICS
  // ====================================================================

  /// Get current cache size
  int get cacheSize => _cache.length;

  /// Get cache statistics
  CacheStats get cacheStats => stats;

  /// Check if an item is cached
  bool isCached(K id) => _cache.containsKey(id);

  /// Print cache diagnostics
  void printDiagnostics() {
    print('=== Cache Diagnostics: ${runtimeType} ===');
    print('Size: ${_cache.length}${config.maxSize != null ? ' / ${config.maxSize}' : ''}');
    print('Initialized: $_initialized');
    if (config.enableStats) {
      print('Stats: $stats');
    }
    print('=====================================');
  }

  // ====================================================================
  // LIFECYCLE
  // ====================================================================

  /// Dispose resources
  void dispose() {
    _changeController.close();
    _cache.clear();
  }
}

/// Event emitted when cache changes
class CacheChangeEvent<M, K> {
  final CacheChangeType type;
  final M? item;
  final K? key;

  const CacheChangeEvent._(this.type, {this.item, this.key});

  factory CacheChangeEvent.created(M item) =>
      CacheChangeEvent._(CacheChangeType.created, item: item);

  factory CacheChangeEvent.updated(M item) =>
      CacheChangeEvent._(CacheChangeType.updated, item: item);

  factory CacheChangeEvent.deleted(K key) =>
      CacheChangeEvent._(CacheChangeType.deleted, key: key);

  factory CacheChangeEvent.invalidated(K key) =>
      CacheChangeEvent._(CacheChangeType.invalidated, key: key);

  factory CacheChangeEvent.cleared() =>
      CacheChangeEvent._(CacheChangeType.cleared);
}

enum CacheChangeType {
  created,
  updated,
  deleted,
  invalidated,
  cleared,
}
