import 'package:solducci/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user profiles
class ProfileService {
  // Singleton pattern
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final _supabase = Supabase.instance.client;

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Get profile by user ID
  Future<UserProfile?> getProfileById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Get multiple profiles by IDs
  Future<List<UserProfile>> getProfilesByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final response = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', userIds);

      return (response as List)
          .map((map) => UserProfile.fromMap(map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update current user's profile
  Future<void> updateProfile(UserProfile profile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      if (userId != profile.id) {
        throw Exception('Cannot update another user\'s profile');
      }

      await _supabase
          .from('profiles')
          .update(profile.toUpdateMap())
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update current user's nickname
  Future<void> updateNickname(String nickname) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      await _supabase
          .from('profiles')
          .update({
            'nickname': nickname,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
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

      await _supabase
          .from('profiles')
          .update({
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
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

      return UserProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Stream current user's profile (reactive)
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
          return UserProfile.fromMap(data.first);
        });
  }

  /// Check if profile exists for current user
  Future<bool> profileExists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

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
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'nickname': nickname,
      });
    } catch (e) {
      rethrow;
    }
  }
}
