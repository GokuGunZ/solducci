import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stato di una risorsa caricata per un tile della Bento Dashboard
enum BentoResourceStatus {
  loading,
  success,
  stale,
  error,
}

/// Involucro contenente i dati, lo stato e i metadati di caching/freshness
class BentoResource<T> {
  final BentoResourceStatus status;
  final T? data;
  final Object? error;
  final DateTime? timestamp;
  final bool isFromCache;

  const BentoResource({
    required this.status,
    this.data,
    this.error,
    this.timestamp,
    this.isFromCache = false,
  });

  bool get isLoading => status == BentoResourceStatus.loading;
  bool get isSuccess => status == BentoResourceStatus.success;
  bool get isStale => status == BentoResourceStatus.stale;
  bool get hasError => status == BentoResourceStatus.error;
  bool get hasData => data != null;

  factory BentoResource.loading({T? cachedData, DateTime? timestamp}) => BentoResource(
        status: BentoResourceStatus.loading,
        data: cachedData,
        timestamp: timestamp,
        isFromCache: cachedData != null,
      );

  factory BentoResource.success(T data) => BentoResource(
        status: BentoResourceStatus.success,
        data: data,
        timestamp: DateTime.now(),
        isFromCache: false,
      );

  factory BentoResource.stale({required T data, Object? error, DateTime? timestamp}) => BentoResource(
        status: BentoResourceStatus.stale,
        data: data,
        error: error,
        timestamp: timestamp,
        isFromCache: true,
      );

  factory BentoResource.error(Object error, {T? cachedData, DateTime? timestamp}) => BentoResource(
        status: cachedData != null ? BentoResourceStatus.stale : BentoResourceStatus.error,
        data: cachedData,
        error: error,
        timestamp: timestamp,
        isFromCache: cachedData != null,
      );
}

/// Motore di persistenza locale per la Bento Dashboard (Pattern SWR: Stale-While-Revalidate)
///
/// Carica istantaneamente l'ultimo snapshot valido salvato (0 ms da RAM o disco)
/// ed esegue in background il fetch fresco con timeout di sicurezza a prova di lag.
class BentoDataCache {
  static final BentoDataCache _instance = BentoDataCache._internal();
  factory BentoDataCache() => _instance;
  BentoDataCache._internal();

  /// Memory cache L1 per accesso sincrono immediato
  static final Map<String, _MemoryCacheEntry> _memoryCache = {};

  static const String _keyPrefix = 'bento_cache_v1_';

  /// Recupera l'ultimo snapshot sincrono in memoria (0 ms)
  static Map<String, dynamic>? getFastMemorySnapshot(String cacheKey) {
    final entry = _memoryCache[cacheKey];
    return entry?.data;
  }

  /// Recupera lo snapshot salvato (prima cerca in RAM, poi su SharedPreferences)
  static Future<Map<String, dynamic>?> getSnapshot(String cacheKey) async {
    final mem = _memoryCache[cacheKey];
    if (mem != null) {
      return mem.data;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$cacheKey');
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>?;
        final tsStr = decoded['timestamp'] as String?;
        final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
        if (data != null) {
          _memoryCache[cacheKey] = _MemoryCacheEntry(data: data, timestamp: ts ?? DateTime.now());
          return data;
        }
      }
    } catch (e) {
      debugPrint('[BentoDataCache] Errore lettura cache ($cacheKey): $e');
    }
    return null;
  }

  /// Salva lo snapshot del widget sia in RAM che asincronamente su SharedPreferences
  static Future<void> saveSnapshot(String cacheKey, Map<String, dynamic> data) async {
    final now = DateTime.now();
    _memoryCache[cacheKey] = _MemoryCacheEntry(data: data, timestamp: now);

    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'data': data,
        'timestamp': now.toIso8601String(),
      });
      await prefs.setString('$_keyPrefix$cacheKey', payload);
    } catch (e) {
      debugPrint('[BentoDataCache] Errore scrittura cache ($cacheKey): $e');
    }
  }

  /// Esegue il flusso Stale-While-Revalidate completo con Stream:
  /// 1. Emette subito i dati in cache se disponibili (con status loading o stale)
  /// 2. Lancia il fetcher asincrono protetto da timeout
  /// 3. Se il fetcher va a buon fine, emette success e aggiorna la cache locale
  /// 4. Se va in timeout o errore e ci sono dati in cache, emette stale senza rompere la UI
  static Stream<BentoResource<T>> executeSWR<T>({
    required String cacheKey,
    required Future<T> Function() fetcher,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T data) toJson,
    Duration timeout = const Duration(seconds: 4),
  }) async* {
    // 1. Lettura immediata della cache
    T? cachedData;
    DateTime? cachedTimestamp;

    final memEntry = _memoryCache[cacheKey];
    if (memEntry != null) {
      try {
        cachedData = fromJson(memEntry.data);
        cachedTimestamp = memEntry.timestamp;
      } catch (_) {}
    }

    if (cachedData == null) {
      final diskSnapshot = await getSnapshot(cacheKey);
      if (diskSnapshot != null) {
        try {
          cachedData = fromJson(diskSnapshot);
          cachedTimestamp = _memoryCache[cacheKey]?.timestamp;
        } catch (_) {}
      }
    }

    // Se abbiamo dati cached, emettiamo subito lo stato con i dati precedenti
    if (cachedData != null) {
      yield BentoResource.loading(cachedData: cachedData, timestamp: cachedTimestamp);
    } else {
      yield BentoResource.loading();
    }

    // 2. Fetch fresco con timeout
    try {
      final fresh = await fetcher().timeout(timeout);
      // Salva in cache
      final jsonToStore = toJson(fresh);
      unawaited(saveSnapshot(cacheKey, jsonToStore));

      yield BentoResource.success(fresh);
    } catch (error) {
      debugPrint('[BentoDataCache] Fetch fallito o timeout per $cacheKey: $error');
      if (cachedData != null) {
        yield BentoResource.stale(
          data: cachedData,
          error: error,
          timestamp: cachedTimestamp,
        );
      } else {
        yield BentoResource.error(error);
      }
    }
  }

  /// Pulisce tutta la cache in memoria e su disco
  static Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('[BentoDataCache] Errore clearAll: $e');
    }
  }
}

class _MemoryCacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const _MemoryCacheEntry({required this.data, required this.timestamp});
}
