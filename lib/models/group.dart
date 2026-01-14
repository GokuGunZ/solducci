import 'package:hive/hive.dart';
import 'package:solducci/core/cache/cacheable_model.dart';

part 'group.g.dart';

/// Expense group model (couple, roommates, etc.)
/// Corresponds to 'groups' table in Supabase
@HiveType(typeId: 6)
class ExpenseGroup implements CacheableModel<String> {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  final String createdBy; // User ID

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  // Denormalized data for UI (not stored in DB)
  @HiveField(6)
  List<GroupMember>? members;

  @HiveField(7)
  int? memberCount;

  ExpenseGroup({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.members,
    this.memberCount,
  });

  /// Create ExpenseGroup from Supabase map
  factory ExpenseGroup.fromMap(Map<String, dynamic> map) {
    return ExpenseGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      memberCount: map['member_count'] as int?,
    );
  }

  /// Convert ExpenseGroup to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert to map for insert (without id)
  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'description': description,
      'created_by': createdBy,
    };
  }

  /// Convert to map for update
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
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
  ExpenseGroup copyWith({
    String? name,
    String? description,
    List<GroupMember>? members,
    int? memberCount,
  }) {
    return ExpenseGroup(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      members: members ?? this.members,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  String toString() {
    return 'ExpenseGroup(id: $id, name: $name, members: ${memberCount ?? members?.length ?? 0})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Member of an expense group
/// Corresponds to 'group_members' table in Supabase
@HiveType(typeId: 7)
class GroupMember {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  final String groupId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final GroupRole role;

  @HiveField(4)
  final DateTime joinedAt;

  // Denormalized data for UI (from profiles table)
  @HiveField(5)
  String? nickname;

  @HiveField(6)
  String? email;

  @HiveField(7)
  String? avatarUrl;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.nickname,
    this.email,
    this.avatarUrl,
  });

  /// Create GroupMember from Supabase map
  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String,
      role: GroupRole.fromString(map['role'] as String? ?? 'member'),
      joinedAt: DateTime.parse(map['joined_at'] as String),
      // Denormalized fields (from JOIN with profiles)
      nickname: map['nickname'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  /// Convert GroupMember to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'role': role.value,
    };
  }

  /// Get initials from nickname
  String get initials {
    if (nickname == null || nickname!.isEmpty) return '?';
    final parts = nickname!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  bool get isAdmin => role == GroupRole.admin;
  bool get isMember => role == GroupRole.member;

  @override
  String toString() {
    return 'GroupMember(userId: $userId, nickname: $nickname, role: ${role.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Role of a member in a group
@HiveType(typeId: 8)
enum GroupRole {
  @HiveField(0)
  admin('admin'),

  @HiveField(1)
  member('member');

  final String value;
  const GroupRole(this.value);

  static GroupRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return GroupRole.admin;
      case 'member':
        return GroupRole.member;
      default:
        return GroupRole.member;
    }
  }

  String get label {
    switch (this) {
      case GroupRole.admin:
        return 'Admin';
      case GroupRole.member:
        return 'Membro';
    }
  }
}
