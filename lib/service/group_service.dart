import 'package:solducci/models/group.dart';
import 'package:solducci/models/group_invite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing expense groups
class GroupService {
  // Singleton pattern
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  final _supabase = Supabase.instance.client;

  // ========================================
  // GROUP CRUD
  // ========================================

  /// Get all groups the current user belongs to
  Future<List<ExpenseGroup>> getUserGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      // Step 1: Get group IDs for current user from group_members
      final membershipResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (membershipResponse as List)
          .map((m) => m['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) {
        return [];
      }

      // Step 2: Get groups by IDs with member count
      final groupsResponse = await _supabase
          .from('groups')
          .select('*, member_count:group_members(count)')
          .inFilter('id', groupIds)
          .order('created_at', ascending: false);

      return (groupsResponse as List).map((map) {
        // Extract member count from aggregation
        final memberCountData = map['member_count'] as List?;
        final count = memberCountData != null && memberCountData.isNotEmpty
            ? memberCountData[0]['count'] as int?
            : 0;

        return ExpenseGroup.fromMap({
          ...map,
          'member_count': count,
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get group by ID with members
  Future<ExpenseGroup?> getGroupById(String groupId) async {
    try {
      final response = await _supabase
          .from('groups')
          .select()
          .eq('id', groupId)
          .single();

      final group = ExpenseGroup.fromMap(response);

      // Load members
      group.members = await getGroupMembers(groupId);

      return group;
    } catch (e) {
      return null;
    }
  }

  /// Create a new group
  Future<ExpenseGroup?> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Insert group
      final groupResponse = await _supabase
          .from('groups')
          .insert({
            'name': name,
            'description': description,
            'created_by': userId,
          })
          .select()
          .single();

      final group = ExpenseGroup.fromMap(groupResponse);

      // Add creator as admin member
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
        'role': 'admin',
      });

      return group;
    } catch (e) {
      rethrow;
    }
  }

  /// Update group details
  Future<void> updateGroup(ExpenseGroup group) async {
    try {
      await _supabase
          .from('groups')
          .update(group.toUpdateMap())
          .eq('id', group.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete group (admin only)
  Future<void> deleteGroup(String groupId) async {
    try {
      await _supabase
          .from('groups')
          .delete()
          .eq('id', groupId);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // GROUP MEMBERS
  // ========================================

  /// Get all members of a group (with profile info)
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      // Get group members
      final membersResponse = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      final members = membersResponse as List;
      if (members.isEmpty) return [];

      // Get profile info for all members
      final userIds = members.map((m) => m['user_id'] as String).toList();

      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, nickname, email, avatar_url')
          .inFilter('id', userIds);

      // Create lookup map
      final profilesMap = {
        for (var p in profilesResponse as List)
          p['id'] as String: p
      };

      return members.map((map) {
        final profile = profilesMap[map['user_id']];
        return GroupMember.fromMap({
          ...map,
          'nickname': profile?['nickname'] ?? 'Unknown',
          'email': profile?['email'] ?? '',
          'avatar_url': profile?['avatar_url'],
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add member to group (for accepting invites)
  Future<void> addMemberToGroup({
    required String groupId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': role,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Remove member from group
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Leave group (current user)
  Future<void> leaveGroup(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      await removeMemberFromGroup(groupId: groupId, userId: userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if current user is admin of group
  Future<bool> isUserAdmin(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return false;
      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // GROUP INVITES
  // ========================================

  /// Send invite to user by email
  Future<GroupInvite?> sendInvite({
    required String groupId,
    required String inviteeEmail,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Check if user is already a member (by checking profiles with this email)
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', inviteeEmail.toLowerCase())
          .maybeSingle();

      if (profileResponse != null) {
        // User exists, check if already a member
        final inviteeUserId = profileResponse['id'] as String;
        final existingMember = await _supabase
            .from('group_members')
            .select('id')
            .eq('group_id', groupId)
            .eq('user_id', inviteeUserId)
            .maybeSingle();

        if (existingMember != null) {
          throw Exception('User is already a member of this group');
        }
      }

      // Check if there's already a pending invite
      final existingInvite = await _supabase
          .from('group_invites')
          .select('id')
          .eq('group_id', groupId)
          .eq('invitee_email', inviteeEmail.toLowerCase())
          .eq('status', 'pending')
          .maybeSingle();

      if (existingInvite != null) {
        throw Exception('An invite is already pending for this email');
      }

      // Create invite
      final response = await _supabase
          .from('group_invites')
          .insert({
            'group_id': groupId,
            'inviter_id': userId,
            'invitee_email': inviteeEmail.toLowerCase(),
          })
          .select()
          .single();

      return GroupInvite.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get pending invites for current user
  Future<List<GroupInvite>> getPendingInvites() async {
    try {
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail == null) return [];

      // Get invites
      final invitesResponse = await _supabase
          .from('group_invites')
          .select()
          .eq('invitee_email', userEmail.toLowerCase())
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final invites = invitesResponse as List;
      if (invites.isEmpty) return [];

      // Get group names and inviter nicknames separately
      final groupIds = invites.map((i) => i['group_id'] as String).toSet().toList();
      final inviterIds = invites.map((i) => i['inviter_id'] as String).toSet().toList();

      final groupsResponse = await _supabase
          .from('groups')
          .select('id, name')
          .inFilter('id', groupIds);

      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, nickname')
          .inFilter('id', inviterIds);

      // Create lookup maps
      final groupNames = {
        for (var g in groupsResponse as List)
          g['id'] as String: g['name'] as String
      };

      final inviterNicknames = {
        for (var p in profilesResponse as List)
          p['id'] as String: p['nickname'] as String
      };

      return invites.map((map) {
        return GroupInvite.fromMap({
          ...map,
          'group_name': groupNames[map['group_id']] ?? 'Unknown Group',
          'inviter_nickname': inviterNicknames[map['inviter_id']] ?? 'Unknown User',
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Accept invite
  Future<void> acceptInvite(String inviteId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Get invite details
      final invite = await _supabase
          .from('group_invites')
          .select('group_id')
          .eq('id', inviteId)
          .single();

      // Add user to group
      await addMemberToGroup(
        groupId: invite['group_id'],
        userId: userId,
      );

      // Update invite status
      await _supabase
          .from('group_invites')
          .update({
            'status': 'accepted',
            'invitee_id': userId,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', inviteId);
    } catch (e) {
      rethrow;
    }
  }

  /// Reject invite
  Future<void> rejectInvite(String inviteId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase
          .from('group_invites')
          .update({
            'status': 'rejected',
            'invitee_id': userId,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', inviteId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get count of pending invites for current user
  Future<int> getPendingInviteCount() async {
    try {
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail == null) return 0;

      final response = await _supabase
          .from('group_invites')
          .select()
          .eq('invitee_email', userEmail.toLowerCase())
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ========================================
  // STREAMS (Reactive)
  // ========================================

  /// Stream of user's groups (reactive)
  Stream<List<ExpenseGroup>> get groupsStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    // Note: Supabase streams don't support complex joins well
    // So we use a simple stream and fetch details separately if needed
    return _supabase
        .from('group_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((memberData) async {
          final groupIds = memberData
              .map((m) => m['group_id'] as String)
              .toList();

          if (groupIds.isEmpty) return <ExpenseGroup>[];

          final groupsData = await _supabase
              .from('groups')
              .select()
              .inFilter('id', groupIds);

          return (groupsData as List)
              .map((map) => ExpenseGroup.fromMap(map))
              .toList();
        });
  }
}
