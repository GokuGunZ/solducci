import 'package:solducci/core/cache/cacheable_service.dart';

/// Centralized cache manager for coordinating multiple service caches
///
/// Responsibilities:
/// - Register and track all CacheableServices
/// - Provide global cache operations (invalidate all, refresh all)
/// - Cross-service cache invalidation
/// - Global cache statistics
/// - Memory management
///
/// Usage:
/// ```dart
/// // Register services
/// CacheManager.instance.register('expenses', expenseService);
/// CacheManager.instance.register('groups', groupService);
///
/// // Global operations
/// await CacheManager.instance.preloadAll();
/// CacheManager.instance.invalidateAll();
/// ```
class CacheManager {
  // Singleton pattern
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  static CacheManager get instance => _instance;
  CacheManager._internal();

  /// Registry of all cacheable services
  final Map<String, CacheableService> _services = {};

  /// Cross-service invalidation rules
  /// When a change occurs in service A, invalidate cache in services B, C
  final Map<String, List<String>> _invalidationRules = {};

  // ====================================================================
  // SERVICE REGISTRATION
  // ====================================================================

  /// Register a cacheable service
  void register(String name, CacheableService service) {
    _services[name] = service;
  }

  /// Unregister a service
  void unregister(String name) {
    _services.remove(name);
  }

  /// Get a registered service by name
  CacheableService? getService(String name) {
    return _services[name];
  }

  /// Check if a service is registered
  bool isRegistered(String name) {
    return _services.containsKey(name);
  }

  // ====================================================================
  // CROSS-SERVICE INVALIDATION
  // ====================================================================

  /// Register an invalidation rule
  ///
  /// When [sourceService] changes, invalidate cache in [targetServices]
  ///
  /// Example:
  /// ```dart
  /// // When expenses change, invalidate group balance cache
  /// CacheManager.instance.registerInvalidationRule(
  ///   'expenses',
  ///   ['groups', 'balance']
  /// );
  /// ```
  void registerInvalidationRule(String sourceService, List<String> targetServices) {
    _invalidationRules[sourceService] = targetServices;
  }

  /// Trigger invalidation cascade
  ///
  /// When a service changes, invalidate related caches
  void triggerInvalidationCascade(String sourceService) {
    final targets = _invalidationRules[sourceService];
    if (targets != null) {
      for (final target in targets) {
        final service = _services[target];
        service?.invalidateAll();
      }
    }
  }

  // ====================================================================
  // GLOBAL CACHE OPERATIONS
  // ====================================================================

  /// Preload all registered services
  Future<void> preloadAll() async {
    final futures = _services.values.map((s) => s.preloadCache());
    await Future.wait(futures);
  }

  /// Ensure all services are initialized
  Future<void> ensureAllInitialized() async {
    final futures = _services.values.map((s) => s.ensureInitialized());
    await Future.wait(futures);
  }

  /// Refresh all caches
  Future<void> refreshAll() async {
    final futures = _services.values.map((s) => s.refreshCache());
    await Future.wait(futures);
  }

  /// Invalidate all caches
  void invalidateAll() {
    for (final service in _services.values) {
      service.invalidateAll();
    }
  }

  /// Invalidate specific service cache
  void invalidateService(String name) {
    _services[name]?.invalidateAll();
  }

  // ====================================================================
  // DIAGNOSTICS & MONITORING
  // ====================================================================

  /// Get global cache statistics
  GlobalCacheStats getGlobalStats() {
    final stats = GlobalCacheStats();

    for (final entry in _services.entries) {
      final serviceStats = entry.value.cacheStats;
      stats.totalHits += serviceStats.hits;
      stats.totalMisses += serviceStats.misses;
      stats.totalEvictions += serviceStats.evictions;
      stats.totalInvalidations += serviceStats.invalidations;
      stats.totalSize += entry.value.cacheSize;

      stats.serviceStats[entry.key] = ServiceCacheStats(
        name: entry.key,
        size: entry.value.cacheSize,
        stats: serviceStats,
      );
    }

    return stats;
  }

  /// Print global cache diagnostics
  void printGlobalDiagnostics() {
    print('\n========================================');
    print('    GLOBAL CACHE DIAGNOSTICS');
    print('========================================');

    final globalStats = getGlobalStats();

    print('\n📊 GLOBAL STATISTICS');
    print('Total Cache Size: ${globalStats.totalSize} items');
    print('Total Hits: ${globalStats.totalHits}');
    print('Total Misses: ${globalStats.totalMisses}');
    print('Global Hit Rate: ${(globalStats.hitRate * 100).toStringAsFixed(1)}%');
    print('Total Evictions: ${globalStats.totalEvictions}');
    print('Total Invalidations: ${globalStats.totalInvalidations}');

    print('\n📦 SERVICE BREAKDOWN');
    for (final entry in globalStats.serviceStats.entries) {
      final service = entry.value;
      print('\n  ${entry.key}:');
      print('    Size: ${service.size} items');
      print('    Hits: ${service.stats.hits}');
      print('    Misses: ${service.stats.misses}');
      print('    Hit Rate: ${(service.stats.hitRate * 100).toStringAsFixed(1)}%');
    }

    if (_invalidationRules.isNotEmpty) {
      print('\n🔗 INVALIDATION RULES');
      for (final entry in _invalidationRules.entries) {
        print('  ${entry.key} → ${entry.value.join(', ')}');
      }
    }

    print('\n========================================\n');
  }

  /// Get total memory usage estimate (rough calculation)
  int estimateMemoryUsage() {
    // Rough estimate: assume average 500 bytes per cached item
    const avgBytesPerItem = 500;
    return getGlobalStats().totalSize * avgBytesPerItem;
  }

  /// Clear all caches and reset (for testing or memory pressure)
  void clearAll() {
    invalidateAll();
    for (final service in _services.values) {
      service.stats.reset();
    }
  }

  // ====================================================================
  // LIFECYCLE
  // ====================================================================

  /// Dispose all services
  void dispose() {
    for (final service in _services.values) {
      service.dispose();
    }
    _services.clear();
    _invalidationRules.clear();
  }
}

/// Global cache statistics across all services
class GlobalCacheStats {
  int totalHits = 0;
  int totalMisses = 0;
  int totalEvictions = 0;
  int totalInvalidations = 0;
  int totalSize = 0;

  final Map<String, ServiceCacheStats> serviceStats = {};

  double get hitRate {
    final total = totalHits + totalMisses;
    return total == 0 ? 0 : totalHits / total;
  }
}

/// Statistics for a single service cache
class ServiceCacheStats {
  final String name;
  final int size;
  final dynamic stats; // CacheStats from service

  ServiceCacheStats({
    required this.name,
    required this.size,
    required this.stats,
  });
}
