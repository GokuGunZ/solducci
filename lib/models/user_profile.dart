import 'package:hive/hive.dart';
import 'package:solducci/core/cache/cacheable_model.dart';

part 'user_profile.g.dart';

/// User profile model with nickname and avatar
/// Corresponds to 'profiles' table in Supabase
@HiveType(typeId: 5)
class UserProfile implements CacheableModel<String> {
  @HiveField(0)
  final String id; // UUID from auth.users

  @HiveField(1)
  final String email;

  @HiveField(2)
  String nickname;

  @HiveField(3)
  String? avatarUrl;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
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
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      nickname: map['nickname'] as String? ?? 'Utente',
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
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

  // ====================================================================
  // CacheableModel Implementation
  // ====================================================================

  @override
  String get cacheKey => id;

  @override
  DateTime? get lastModified => updatedAt;

  @override
  bool get shouldCache => true;

  /// Create a copy with modified fields
  @override
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
