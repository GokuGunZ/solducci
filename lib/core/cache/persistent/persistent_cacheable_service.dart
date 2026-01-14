import 'package:hive/hive.dart';
import 'package:solducci/core/cache/cacheable_service.dart';
import 'package:solducci/core/cache/cacheable_model.dart';
import 'package:solducci/core/cache/cache_config.dart';
import 'package:solducci/core/cache/persistent/persistent_cache_config.dart';
import 'package:solducci/core/cache/persistent/persistent_cache_entry.dart';

/// Extended version of CacheableService with persistent cache support
///
/// Adds disk-based persistence using Hive for:
/// - Offline functionality (app works without network)
/// - Instant cold start (data loads from disk, not network)
/// - Background sync (auto-sync with server when online)
/// - Dirty flag tracking (local changes not yet synced)
///
/// Type parameters:
/// - [M] - Model type (must implement CacheableModel)
/// - [K] - Cache key type (int, String, etc.)
abstract class PersistentCacheableService<M extends CacheableModel<K>, K>
    extends CacheableService<M, K> {
  /// Hive box for persistent storage (stores actual model data)
  Box<M>? _persistentBox;

  /// Hive box for metadata (timestamps, dirty flags, etc.)
  Box<PersistentCacheMetadata>? _metadataBox;

  /// Name of the Hive box (must be unique per service)
  String get boxName;

  /// Metadata box name (derived from boxName)
  String get _metadataBoxName => '${boxName}_metadata';

  /// Persistent cache configuration
  final PersistentCacheConfig persistentConfig;

  PersistentCacheableService({
    required CacheConfig config,
    this.persistentConfig = PersistentCacheConfig.defaultConfig,
  }) : super(config: config);

  // ====================================================================
  // INITIALIZATION
  // ====================================================================

  /// Initialize persistent cache (open Hive boxes)
  ///
  /// This must be called before using the service.
  /// Typically called during app initialization.
  Future<void> initPersistentCache() async {
    if (_persistentBox != null) return; // Already initialized

    try {
      // Open Hive boxes (data and metadata)
      _persistentBox = await Hive.openBox<M>(boxName);
      _metadataBox = await Hive.openBox<PersistentCacheMetadata>(_metadataBoxName);
      print('📦 Opened Hive boxes: $boxName (${_persistentBox!.length} items)');

      // Load all data from persistent cache into in-memory cache
      await _loadFromPersistentCache();
    } catch (e) {
      print('❌ Failed to initialize persistent cache for $boxName: $e');
      rethrow;
    }
  }

  /// Load data from persistent cache to in-memory cache
  Future<void> _loadFromPersistentCache() async {
    final box = _persistentBox;
    final metaBox = _metadataBox;
    if (box == null || metaBox == null) return;

    print('📦 Loading ${box.length} items from persistent cache: $boxName');

    int loaded = 0;
    int expired = 0;

    // Iterate all entries in Hive box
    for (final key in box.keys) {
      final item = box.get(key);
      final metadata = metaBox.get(key);

      if (item == null) continue;

      // Check if expired
      if (metadata != null && _isExpired(metadata)) {
        await box.delete(key); // Clean up expired entry
        await metaBox.delete(key);
        expired++;
        continue;
      }

      // Load into in-memory cache
      putInCache(item);
      loaded++;
    }

    print('✅ Loaded $loaded items from persistent cache ($expired expired)');
  }

  /// Check if persistent entry is expired
  bool _isExpired(PersistentCacheMetadata metadata) {
    final ttl = persistentConfig.ttl;
    if (ttl == null) return false;
    return DateTime.now().difference(metadata.cachedAt) > ttl;
  }

  // ====================================================================
  // PERSISTENT CACHE OPERATIONS
  // ====================================================================

  /// Save item to persistent cache
  Future<void> _saveToPersistentCache(K key, M item,
      {bool dirty = false}) async {
    final box = _persistentBox;
    final metaBox = _metadataBox;
    if (box == null || metaBox == null) return;

    // Save the actual data
    await box.put(key, item);

    // Save/update metadata
    final existingMeta = metaBox.get(key);
    final metadata = PersistentCacheMetadata(
      cachedAt: DateTime.now(),
      lastSyncedAt: dirty
          ? (existingMeta?.lastSyncedAt ?? DateTime.now())
          : DateTime.now(),
      dirty: dirty,
      version: (existingMeta?.version ?? 0) + (dirty ? 1 : 0),
    );

    await metaBox.put(key, metadata);
  }

  /// Delete item from persistent cache
  Future<void> _deleteFromPersistentCache(K key) async {
    final box = _persistentBox;
    final metaBox = _metadataBox;
    if (box == null || metaBox == null) return;

    await box.delete(key);
    await metaBox.delete(key);
  }

  /// Mark item as dirty (local change not synced)
  Future<void> _markDirty(K key) async {
    final metaBox = _metadataBox;
    if (metaBox == null) return;

    final metadata = metaBox.get(key);
    if (metadata != null) {
      await metaBox.put(key, metadata.markDirty());
    }
  }

  /// Mark item as synced (clean)
  Future<void> _markSynced(K key) async {
    final metaBox = _metadataBox;
    if (metaBox == null) return;

    final metadata = metaBox.get(key);
    if (metadata != null) {
      await metaBox.put(key, metadata.markSynced());
    }
  }

  /// Get all dirty items (local changes not synced)
  List<M> getDirtyItems() {
    final box = _persistentBox;
    final metaBox = _metadataBox;
    if (box == null || metaBox == null) return [];

    final dirty = <M>[];
    for (final key in metaBox.keys) {
      final metadata = metaBox.get(key);
      if (metadata != null && metadata.dirty) {
        final item = box.get(key);
        if (item != null) {
          dirty.add(item);
        }
      }
    }
    return dirty;
  }

  // ====================================================================
  // OVERRIDDEN CRUD WITH PERSISTENCE
  // ====================================================================

  @override
  Future<M> create(M item) async {
    // 1. Create in database
    final created = await super.create(item);

    // 2. Save to persistent cache (not dirty since it came from server)
    await _saveToPersistentCache(created.cacheKey, created, dirty: false);

    return created;
  }

  @override
  Future<M> updateItem(M item) async {
    // 1. Update in database
    final updated = await super.updateItem(item);

    // 2. Update persistent cache
    await _saveToPersistentCache(updated.cacheKey, updated, dirty: false);

    return updated;
  }

  @override
  Future<void> deleteItem(K id) async {
    // 1. Delete from database
    await super.deleteItem(id);

    // 2. Delete from persistent cache
    await _deleteFromPersistentCache(id);
  }

  @override
  Future<void> preloadCache() async {
    // If persistent cache exists, use it (instant load)
    if (_persistentBox != null && _persistentBox!.isNotEmpty) {
      await _loadFromPersistentCache();

      // Then sync in background (fire and forget)
      if (persistentConfig.enableSync) {
        _syncInBackground(); // Intentionally not awaited
      }
      return;
    }

    // Otherwise, fetch from server and populate both caches
    await super.preloadCache();

    // Save to persistent cache
    final items = getCached();
    for (final item in items) {
      await _saveToPersistentCache(item.cacheKey, item);
    }
  }

  // ====================================================================
  // SYNC LOGIC
  // ====================================================================

  /// Sync with server in background
  ///
  /// This is called automatically after loading from persistent cache.
  /// Can also be called manually to force a sync.
  Future<void> _syncInBackground() async {
    if (!persistentConfig.enableSync) return;

    // Note: Network connectivity check could be added here using connectivity_plus
    // For now, we rely on graceful error handling when network is unavailable

    try {
      print('🔄 Starting background sync for $boxName...');

      // 1. Fetch latest from server
      final serverItems = await fetchAll();

      // 2. Update persistent cache with server data
      for (final item in serverItems) {
        await _saveToPersistentCache(item.cacheKey, item);
        putInCache(item); // Update in-memory too
      }

      // 3. Push dirty items to server
      await _pushDirtyItems();

      print('✅ Background sync completed: $boxName');
    } catch (e) {
      print('❌ Background sync failed for $boxName: $e');
      // Fail silently - app still works offline
    }
  }

  /// Push dirty items to server
  Future<void> _pushDirtyItems() async {
    final dirty = getDirtyItems();
    if (dirty.isEmpty) return;

    print('📤 Pushing ${dirty.length} dirty items to server...');

    for (final item in dirty) {
      try {
        // Try to update on server
        await update(item);

        // Mark as synced on success
        await _markSynced(item.cacheKey);
      } catch (e) {
        print('❌ Failed to sync item ${item.cacheKey}: $e');
        // Keep as dirty, will retry next sync
      }
    }
  }

  /// Force a sync with the server
  ///
  /// This can be called manually by the user or app logic.
  Future<void> forceSync() async {
    await _syncInBackground();
  }

  // ====================================================================
  // DIAGNOSTICS
  // ====================================================================

  /// Get persistent cache size
  int get persistentCacheSize => _persistentBox?.length ?? 0;

  /// Get number of dirty items
  int get dirtyItemsCount => getDirtyItems().length;

  /// Print persistent cache diagnostics
  void printPersistentDiagnostics() {
    print('=== Persistent Cache Diagnostics: $boxName ===');
    print('Box size: $persistentCacheSize items');
    print('Dirty items: $dirtyItemsCount');
    print('In-memory cache: $cacheSize items');
    print('TTL: ${persistentConfig.ttl}');
    print('Sync enabled: ${persistentConfig.enableSync}');
    print('=========================================');
  }

  // ====================================================================
  // LIFECYCLE
  // ====================================================================

  @override
  void dispose() {
    _persistentBox?.close();
    _metadataBox?.close();
    super.dispose();
  }

  /// Clear persistent cache (for testing or reset)
  Future<void> clearPersistentCache() async {
    await _persistentBox?.clear();
    await _metadataBox?.clear();
    print('🗑️ Cleared persistent cache: $boxName');
  }

  /// Delete the entire boxes from disk
  ///
  /// Use with caution - this permanently deletes all cached data.
  Future<void> deletePersistentCache() async {
    await _persistentBox?.close();
    await _metadataBox?.close();
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.deleteBoxFromDisk(_metadataBoxName);
    _persistentBox = null;
    _metadataBox = null;
    print('🗑️ Deleted persistent cache boxes: $boxName');
  }
}
