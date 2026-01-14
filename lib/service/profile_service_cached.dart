import 'package:solducci/core/cache/cacheable_service.dart';
import 'package:solducci/core/cache/cache_config.dart';
import 'package:solducci/core/cache/cache_manager.dart';
import 'package:solducci/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cached version of ProfileService with performance optimizations
///
/// Features:
/// - Cache-first profile lookups (O(1) instead of query)
/// - Bulk profile fetching for group members
/// - Automatic cache invalidation on updates
/// - Stream integration with cache auto-population
///
/// Usage:
/// ```dart
/// final service = ProfileServiceCached();
/// final profile = await service.getCachedProfile(userId); // Fast!
/// final profiles = await service.getCachedProfiles([id1, id2]); // Bulk!
/// ```
class ProfileServiceCached extends CacheableService<UserProfile, String> {
  // Singleton pattern
  static final ProfileServiceCached _instance = ProfileServiceCached._internal();
  factory ProfileServiceCached() => _instance;

  ProfileServiceCached._internal()
      : super(config: CacheConfig.stable) {
    // Register with global cache manager
    CacheManager.instance.register('profiles', this);
  }

  final _supabase = Supabase.instance.client;

  // ====================================================================
  // CacheableService Abstract Methods Implementation
  // ====================================================================

  @override
  Future<UserProfile?> fetchById(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return UserProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<UserProfile>> fetchAll() async {
    try {
      final response = await _supabase.from('profiles').select();

      return (response as List)
          .map((map) => UserProfile.fromMap(map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<UserProfile> insert(UserProfile item) async {
    try {
      await _supabase.from('profiles').insert({
        'id': item.id,
        'email': item.email,
        'nickname': item.nickname,
        'avatar_url': item.avatarUrl,
      });

      // Cache the new profile
      putInCache(item);

      return item;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserProfile> update(UserProfile item) async {
    try {
      await _supabase
          .from('profiles')
          .update(item.toUpdateMap())
          .eq('id', item.id);

      // Update cache
      putInCache(item);

      return item;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _supabase.from('profiles').delete().eq('id', id);

      // Remove from cache
      invalidate(id);
    } catch (e) {
      rethrow;
    }
  }

  // ====================================================================
  // ProfileService-Specific Methods (Cached)
  // ====================================================================

  /// Get current user's profile (cached)
  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return await getById(userId);
  }

  /// Get profile by user ID (cached)
  Future<UserProfile?> getCachedProfile(String userId) async {
    return await getById(userId);
  }

  /// Get multiple profiles by IDs (bulk operation - OPTIMIZED!)
  /// Uses cache first, then fetches missing profiles in one query
  Future<List<UserProfile>> getCachedProfiles(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    return await getByIds(userIds);
  }

  /// Get profile by user ID synchronously from cache only
  /// Returns null if not cached
  /// Note: This checks if the ID is in cache, then returns via getById which is fast
  Future<UserProfile?> getProfileFromCacheOnly(String userId) async {
    if (!isCached(userId)) return null;
    return await getById(userId); // Will hit cache
  }

  /// Bulk fetch profiles by IDs (fetches missing ones from DB)
  Future<List<UserProfile>> fetchByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];

      final response = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', ids);

      return (response as List)
          .map((map) => UserProfile.fromMap(map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update current user's profile
  Future<void> updateProfile(UserProfile profile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    if (userId != profile.id) {
      throw Exception('Cannot update another user\'s profile');
    }

    await update(profile);
  }

  /// Update current user's nickname
  Future<void> updateNickname(String nickname) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Get current profile from cache or DB
      final profile = await getById(userId);
      if (profile == null) {
        throw Exception('Profile not found');
      }

      // Update nickname
      final updated = profile.copyWith(nickname: nickname);
      await update(updated);
    } catch (e) {
      rethrow;
    }
  }

  /// Update current user's avatar URL
  Future<void> updateAvatarUrl(String? avatarUrl) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Get current profile from cache or DB
      final profile = await getById(userId);
      if (profile == null) {
        throw Exception('Profile not found');
      }

      // Update avatar
      final updated = profile.copyWith(avatarUrl: avatarUrl);
      await update(updated);
    } catch (e) {
      rethrow;
    }
  }

  /// Search profiles by email (for inviting users)
  Future<UserProfile?> searchByEmail(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('email', email.toLowerCase())
          .maybeSingle();

      if (response == null) return null;

      final profile = UserProfile.fromMap(response);

      // Cache the found profile
      putInCache(profile);

      return profile;
    } catch (e) {
      return null;
    }
  }

  /// Stream current user's profile (reactive with cache auto-population)
  Stream<UserProfile?> get profileStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(null);
    }

    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) return null;

          final profile = UserProfile.fromMap(data.first);

          // Auto-populate cache from stream
          putInCache(profile);

          return profile;
        });
  }

  /// Check if profile exists for current user
  Future<bool> profileExists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check cache first
      if (isCached(userId)) return true;

      // Check DB
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Create profile manually (if trigger didn't work)
  Future<void> createProfile({
    required String userId,
    required String email,
    String nickname = 'Utente',
  }) async {
    final profile = UserProfile(
      id: userId,
      email: email,
      nickname: nickname,
      avatarUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await insert(profile);
  }

  // ====================================================================
  // Utility Methods
  // ====================================================================

  /// Get nickname for a user ID (checks cache, returns null if not found)
  /// For guaranteed result, use getCachedProfile() instead
  String? getNickname(String userId) {
    if (!isCached(userId)) return null;
    // Quick lookup from cached list
    final cached = getCached();
    final profile = cached.firstWhere((p) => p.id == userId, orElse: () => UserProfile(
      id: '',
      email: '',
      nickname: '',
      avatarUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return profile.id.isNotEmpty ? profile.nickname : null;
  }

  /// Get avatar URL for a user ID (checks cache, returns null if not found)
  /// For guaranteed result, use getCachedProfile() instead
  String? getAvatarUrl(String userId) {
    if (!isCached(userId)) return null;
    // Quick lookup from cached list
    final cached = getCached();
    final profile = cached.firstWhere((p) => p.id == userId, orElse: () => UserProfile(
      id: '',
      email: '',
      nickname: '',
      avatarUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return profile.id.isNotEmpty ? profile.avatarUrl : null;
  }

  /// Preload profiles for a list of user IDs
  /// Useful before showing a list of users
  Future<void> preloadProfiles(List<String> userIds) async {
    await getCachedProfiles(userIds);
  }
}
