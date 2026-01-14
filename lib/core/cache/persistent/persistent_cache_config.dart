/// Configuration for persistent cache behavior
///
/// Controls how the persistent cache operates, including:
/// - TTL (Time To Live) for cached entries
/// - Automatic background sync settings
/// - Data encryption options
class PersistentCacheConfig {
  /// TTL for persistent cache entries
  ///
  /// Entries older than this are deleted on load.
  /// Set to null to never expire cached data.
  final Duration? ttl;

  /// Whether to enable automatic background sync with server
  final bool enableSync;

  /// Interval between background sync operations
  ///
  /// Only applies if [enableSync] is true.
  final Duration syncInterval;

  /// Whether to encrypt data on disk
  ///
  /// Requires additional setup with Hive encryption.
  /// Recommended for sensitive data (financial, personal).
  final bool encrypt;

  const PersistentCacheConfig({
    this.ttl,
    this.enableSync = true,
    this.syncInterval = const Duration(minutes: 5),
    this.encrypt = false,
  });

  /// Default configuration
  ///
  /// - TTL: 7 days
  /// - Sync: enabled every 5 minutes
  /// - Encryption: disabled
  static const PersistentCacheConfig defaultConfig = PersistentCacheConfig(
    ttl: Duration(days: 7),
    enableSync: true,
  );

  /// Configuration for stable data (profiles, groups)
  ///
  /// - TTL: 30 days (data rarely changes)
  /// - Sync: enabled every 10 minutes (less frequent)
  /// - Encryption: disabled
  static const PersistentCacheConfig stable = PersistentCacheConfig(
    ttl: Duration(days: 30),
    enableSync: true,
    syncInterval: Duration(minutes: 10),
  );

  /// Configuration for dynamic data (expenses, transactions)
  ///
  /// - TTL: 7 days
  /// - Sync: enabled every 1 minute (frequent updates)
  /// - Encryption: disabled
  static const PersistentCacheConfig dynamic = PersistentCacheConfig(
    ttl: Duration(days: 7),
    enableSync: true,
    syncInterval: Duration(minutes: 1),
  );

  /// Configuration for sensitive data
  ///
  /// - TTL: 7 days
  /// - Sync: enabled
  /// - Encryption: enabled
  static const PersistentCacheConfig secure = PersistentCacheConfig(
    ttl: Duration(days: 7),
    enableSync: true,
    encrypt: true,
  );

  @override
  String toString() {
    return 'PersistentCacheConfig(ttl: $ttl, enableSync: $enableSync, syncInterval: $syncInterval, encrypt: $encrypt)';
  }
}
