import 'package:hive/hive.dart';

part 'persistent_cache_entry.g.dart';

/// Metadata for cached items
///
/// Stores metadata separately from the actual cached data to avoid
/// Hive generic type issues. The data itself is stored in a separate box.
///
/// This approach allows us to:
/// - Track cache metadata (timestamps, dirty flags)
/// - Store strongly-typed model data separately
/// - Avoid Hive's limitations with generic type adapters
@HiveType(typeId: 0)
class PersistentCacheMetadata {
  /// When this entry was first cached
  @HiveField(0)
  final DateTime cachedAt;

  /// When this entry was last synced with server
  @HiveField(1)
  final DateTime lastSyncedAt;

  /// Whether this entry has local changes not yet synced to server
  @HiveField(2)
  final bool dirty;

  /// Version number for conflict resolution
  /// Incremented on each local modification
  @HiveField(3)
  final int version;

  PersistentCacheMetadata({
    required this.cachedAt,
    required this.lastSyncedAt,
    this.dirty = false,
    this.version = 1,
  });

  /// Create a copy with dirty flag set to true
  ///
  /// Call this when local changes are made that haven't been synced to server
  PersistentCacheMetadata markDirty() {
    return PersistentCacheMetadata(
      cachedAt: cachedAt,
      lastSyncedAt: lastSyncedAt,
      dirty: true,
      version: version + 1,
    );
  }

  /// Create a copy with dirty flag set to false and updated sync time
  ///
  /// Call this when local changes have been successfully synced to server
  PersistentCacheMetadata markSynced() {
    return PersistentCacheMetadata(
      cachedAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
      dirty: false,
      version: version,
    );
  }

  @override
  String toString() {
    return 'PersistentCacheMetadata(cachedAt: $cachedAt, dirty: $dirty, version: $version)';
  }
}
