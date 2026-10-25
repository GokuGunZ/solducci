import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User-specific preferences service for customizing Role Property Pack templates.
/// Follows the canon:
/// - Remote user preference (`profiles.preferences['life_os']['role_packs']`) = SOURCE OF TRUTH (cross-device)
/// - Local preference / cache (`SharedPreferences`) = FAST LOCAL PROJECTION (offline / 0ms)
/// - In-memory cache isolated by `"$userId:$role"` (safe for multi-user / account switch)
class UserPropertyPackService {
  static const String _prefPrefix = 'life_os_role_packs_';
  final SupabaseClient? _supabase;
  final SharedPreferences? _prefs;

  // In-memory cache isolated by "$userId:$role"
  final Map<String, List<PropertyTemplate>> _memoryCache = {};

  UserPropertyPackService({
    SupabaseClient? supabase,
    SharedPreferences? prefs,
  })  : _supabase = supabase,
        _prefs = prefs;

  String _resolveUserId(String? explicitUserId) {
    if (explicitUserId != null && explicitUserId.isNotEmpty) return explicitUserId;
    try {
      final client = _supabase ?? (Supabase.instance.isInitialized ? Supabase.instance.client : null);
      final authId = client?.auth.currentUser?.id;
      if (authId != null && authId.isNotEmpty) return authId;
    } catch (_) {}
    return 'default';
  }

  String _cacheKey(String userId, SemanticRole role) => '$userId:${role.value}';

  /// Synchronous getter returning cached or default templates immediately.
  List<PropertyTemplate> getCachedTemplatesForRole(SemanticRole role, {String? userId}) {
    final uid = _resolveUserId(userId);
    final key = _cacheKey(uid, role);
    if (_memoryCache.containsKey(key)) {
      return List.unmodifiable(_memoryCache[key]!);
    }
    return RolePropertyPacks.getSuggestionsForRole(role);
  }

  /// Retrieves the customized or default property templates for a specific [role].
  /// Attempts:
  /// 1. In-memory cache (instant)
  /// 2. Local SharedPreferences projection (fast offline)
  /// 3. Remote profiles.preferences (cross-device source of truth)
  Future<List<PropertyTemplate>> getTemplatesForRole(
    SemanticRole role, {
    String? userId,
  }) async {
    final uid = _resolveUserId(userId);
    final key = _cacheKey(uid, role);

    if (_memoryCache.containsKey(key)) {
      return List.unmodifiable(_memoryCache[key]!);
    }

    // 1. Try local SharedPreferences projection
    List<PropertyTemplate>? localTemplates;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final storageKey = '$_prefPrefix${uid}_${role.value}';
      final rawJson = prefs.getString(storageKey);
      if (rawJson != null) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        localTemplates = decoded
            .map((item) => PropertyTemplate.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    if (localTemplates != null) {
      _memoryCache[key] = localTemplates;
    }

    // 2. Cross-device sync: If user is authenticated, query remote profiles.preferences
    if (uid != 'default') {
      try {
        final client = _supabase ?? Supabase.instance.client;
        final response = await client
            .from('profiles')
            .select('preferences')
            .eq('id', uid)
            .maybeSingle();

        if (response != null && response['preferences'] is Map) {
          final prefsMap = response['preferences'] as Map<String, dynamic>;
          final lifeOs = prefsMap['life_os'] as Map<String, dynamic>?;
          final rolePacks = lifeOs?['role_packs'] as Map<String, dynamic>?;
          if (rolePacks != null && rolePacks.containsKey(role.value)) {
            final rawList = rolePacks[role.value] as List<dynamic>;
            final remoteTemplates = rawList
                .map((item) => PropertyTemplate.fromJson(item as Map<String, dynamic>))
                .toList();

            _memoryCache[key] = remoteTemplates;

            // Update local projection cache
            try {
              final prefs = _prefs ?? await SharedPreferences.getInstance();
              final storageKey = '$_prefPrefix${uid}_${role.value}';
              final encoded = jsonEncode(remoteTemplates.map((t) => t.toJson()).toList());
              await prefs.setString(storageKey, encoded);
            } catch (_) {}

            return List.unmodifiable(remoteTemplates);
          }
        }
      } catch (_) {
        // Fallback gracefully to local projection on network/uninitialized error
      }
    }

    if (localTemplates != null) {
      return List.unmodifiable(localTemplates);
    }

    // 3. Fallback to domain defaults
    final defaults = RolePropertyPacks.getSuggestionsForRole(role);
    _memoryCache[key] = List.from(defaults);
    return List.unmodifiable(defaults);
  }

  /// Saves customized property templates for a given [role].
  /// Writes immediately to local cache (fast projection) and pushes to remote profiles.preferences.
  Future<void> saveTemplatesForRole(
    SemanticRole role,
    List<PropertyTemplate> templates, {
    String? userId,
  }) async {
    final uid = _resolveUserId(userId);
    final key = _cacheKey(uid, role);

    _memoryCache[key] = List.from(templates);

    // 1. Local projection persistence
    final encoded = jsonEncode(templates.map((t) => t.toJson()).toList());
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final storageKey = '$_prefPrefix${uid}_${role.value}';
      await prefs.setString(storageKey, encoded);
    } catch (_) {}

    // 2. Remote cross-device persistence
    if (uid != 'default') {
      try {
        final client = _supabase ?? Supabase.instance.client;
        final existing = await client
            .from('profiles')
            .select('preferences')
            .eq('id', uid)
            .maybeSingle();

        Map<String, dynamic> fullPrefs = {};
        if (existing != null && existing['preferences'] is Map) {
          fullPrefs = Map<String, dynamic>.from(existing['preferences'] as Map);
        }

        final lifeOs = Map<String, dynamic>.from(fullPrefs['life_os'] as Map? ?? {});
        final rolePacks = Map<String, dynamic>.from(lifeOs['role_packs'] as Map? ?? {});
        rolePacks[role.value] = templates.map((t) => t.toJson()).toList();
        lifeOs['role_packs'] = rolePacks;
        fullPrefs['life_os'] = lifeOs;

        await client
            .from('profiles')
            .update({'preferences': fullPrefs})
            .eq('id', uid);
      } catch (_) {}
    }
  }

  /// Resets a specific role pack to system defaults for [userId].
  Future<void> resetToDefaults(SemanticRole role, {String? userId}) async {
    final uid = _resolveUserId(userId);
    final key = _cacheKey(uid, role);

    _memoryCache.remove(key);

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final storageKey = '$_prefPrefix${uid}_${role.value}';
      await prefs.remove(storageKey);
    } catch (_) {}

    if (uid != 'default') {
      try {
        final client = _supabase ?? Supabase.instance.client;
        final existing = await client
            .from('profiles')
            .select('preferences')
            .eq('id', uid)
            .maybeSingle();

        if (existing != null && existing['preferences'] is Map) {
          final fullPrefs = Map<String, dynamic>.from(existing['preferences'] as Map);
          final lifeOs = Map<String, dynamic>.from(fullPrefs['life_os'] as Map? ?? {});
          final rolePacks = Map<String, dynamic>.from(lifeOs['role_packs'] as Map? ?? {});
          rolePacks.remove(role.value);
          lifeOs['role_packs'] = rolePacks;
          fullPrefs['life_os'] = lifeOs;

          await client
              .from('profiles')
              .update({'preferences': fullPrefs})
              .eq('id', uid);
        }
      } catch (_) {}
    }

    _memoryCache[key] = List.from(RolePropertyPacks.getSuggestionsForRole(role));
  }

  /// Clears in-memory caches. Call on logout or user switch.
  void clearMemoryCache() {
    _memoryCache.clear();
  }
}
