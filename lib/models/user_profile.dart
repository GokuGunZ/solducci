import 'package:flutter/foundation.dart';

/// User profile model with nickname and avatar
/// Corresponds to 'profiles' table in Supabase
class UserProfile {
  final String id; // UUID from auth.users
  final String email;
  String nickname;
  String? avatarUrl;
  final DateTime createdAt;
  DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserProfile from Supabase map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    try {
      return UserProfile(
        id: map['id'] as String,
        email: map['email'] as String,
        nickname: map['nickname'] as String? ?? 'Utente',
        avatarUrl: map['avatar_url'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR parsing UserProfile: $e');
        print('   Data: $map');
      }
      rethrow;
    }
  }

  /// Convert UserProfile to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert to map for update (without id and created_at)
  Map<String, dynamic> toUpdateMap() {
    return {
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  UserProfile copyWith({
    String? nickname,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Get initials from nickname (for avatar placeholder)
  String get initials {
    final parts = nickname.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, nickname: $nickname)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
