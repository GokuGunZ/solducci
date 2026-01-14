import 'package:solducci/models/group.dart';
import 'package:solducci/models/group_invite.dart';
import 'package:solducci/core/cache/persistent/persistent_cacheable_service.dart';
import 'package:solducci/core/cache/persistent/persistent_cache_config.dart';
import 'package:solducci/core/cache/cache_config.dart';
import 'package:solducci/core/cache/cache_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cached version of GroupService with persistent caching
///
/// This service provides:
/// - Cached group data and members
/// - Persistent cache on disk (offline support)
/// - Reduced queries for group details
/// - Fast group name lookups for UI (e.g., expense list items)
/// - Automatic cache updates on CRUD operations
/// - Background sync with server
class GroupServiceCached extends PersistentCacheableService<ExpenseGroup, String> {
  // Singleton pattern
  static final GroupServiceCached _instance = GroupServiceCached._internal();
  factory GroupServiceCached() => _instance;

  GroupServiceCached._internal()
      : super(
          config: CacheConfig.stable,
          persistentConfig: PersistentCacheConfig.stable,
        ) {
    // Register with global cache manager
    CacheManager.instance.register('groups', this);
  }

  @override
  String get boxName => 'groups_cache';

  final _supabase = Supabase.instance.client;

  /// Cache for group members (group_id → List<GroupMember>)
  /// Heavily used for forms, balance calculations, etc.
  final Map<String, List<GroupMember>> _membersCache = {};

  /// Cache for group invites
  final Map<String, GroupInvite> _invitesCache = {};

  // ====================================================================
  // CacheableService Implementation
  // ====================================================================

  @override
  Future<ExpenseGroup?> fetchById(String id) async {
    try {
      final response = await _supabase
          .from('groups')
          .select()
          .eq('id', id)
          .single();

      final group = ExpenseGroup.fromMap(response);

      // Also load and cache members
      group.members = await getGroupMembers(id);

      return group;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ExpenseGroup>> fetchAll() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get group IDs for current user
      final membershipResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (membershipResponse as List)
          .map((m) => m['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) return [];

      // Get groups with member count
      final groupsResponse = await _supabase
          .from('groups')
          .select('*, member_count:group_members(count)')
          .inFilter('id', groupIds)
          .order('created_at', ascending: false);

      return (groupsResponse as List).map((map) {
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

  @override
  Future<ExpenseGroup> insert(ExpenseGroup item) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    // Insert group
    final groupResponse = await _supabase
        .from('groups')
        .insert({
          'name': item.name,
          'description': item.description,
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

    // Invalidate members cache for this group
    _membersCache.remove(group.id);

    return group;
  }

  @override
  Future<ExpenseGroup> update(ExpenseGroup item) async {
    await _supabase
        .from('groups')
        .update(item.toUpdateMap())
        .eq('id', item.id);

    return item;
  }

  @override
  Future<void> delete(String id) async {
    await _supabase
        .from('groups')
        .delete()
        .eq('id', id);

    // Clear related caches
    _membersCache.remove(id);
  }

  // ====================================================================
  // GROUP MEMBERS (Cached)
  // ====================================================================

  /// Get group members (cached)
  ///
  /// This is a CRITICAL optimization - getGroupMembers() is called frequently
  /// in forms, balance calculations, and list views. Caching eliminates
  /// hundreds of redundant queries.
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    // Check cache first
    if (_membersCache.containsKey(groupId)) {
      return _membersCache[groupId]!;
    }

    // Fetch from database
    try {
      final membersResponse = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      final members = membersResponse as List;
      if (members.isEmpty) {
        _membersCache[groupId] = [];
        return [];
      }

      // Get profile info
      final userIds = members.map((m) => m['user_id'] as String).toList();

      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, nickname, email, avatar_url')
          .inFilter('id', userIds);

      final profilesMap = {
        for (var p in profilesResponse as List)
          p['id'] as String: p
      };

      final membersList = members.map((map) {
        final profile = profilesMap[map['user_id']];
        return GroupMember.fromMap({
          ...map,
          'nickname': profile?['nickname'] ?? 'Unknown',
          'email': profile?['email'] ?? '',
          'avatar_url': profile?['avatar_url'],
        });
      }).toList();

      // Cache result
      _membersCache[groupId] = membersList;

      return membersList;
    } catch (e) {
      return [];
    }
  }

  /// Get members for multiple groups (bulk operation)
  ///
  /// Optimized batch loading for multi-group views
  Future<Map<String, List<GroupMember>>> getBulkGroupMembers(
    List<String> groupIds,
  ) async {
    final results = <String, List<GroupMember>>{};
    final missingIds = <String>[];

    // Check cache first
    for (final groupId in groupIds) {
      if (_membersCache.containsKey(groupId)) {
        results[groupId] = _membersCache[groupId]!;
      } else {
        missingIds.add(groupId);
      }
    }

    // Fetch missing groups
    if (missingIds.isNotEmpty) {
      for (final groupId in missingIds) {
        final members = await getGroupMembers(groupId);
        results[groupId] = members;
      }
    }

    return results;
  }

  /// Invalidate members cache for a group
  void invalidateMembersCache(String groupId) {
    _membersCache.remove(groupId);
  }

  /// Add member to group
  Future<void> addMemberToGroup({
    required String groupId,
    required String userId,
    String role = 'member',
  }) async {
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': role,
    });

    // Invalidate cache
    _membersCache.remove(groupId);

    // Trigger cache refresh for this group
    final group = await getById(groupId);
    if (group != null) {
      putInCache(group);
    }
  }

  /// Remove member from group
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    await _supabase
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);

    // Invalidate cache
    _membersCache.remove(groupId);
  }

  /// Leave group (current user)
  Future<void> leaveGroup(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    await removeMemberFromGroup(groupId: groupId, userId: userId);

    // Also remove from cache since user is no longer member
    invalidate(groupId);
  }

  /// Check if user is admin
  Future<bool> isUserAdmin(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // Check cached members first
    if (_membersCache.containsKey(groupId)) {
      final members = _membersCache[groupId]!;
      final userMember = members.firstWhere(
        (m) => m.userId == userId,
        orElse: () => GroupMember(
          id: '',
          groupId: groupId,
          userId: userId,
          role: GroupRole.member,
          joinedAt: DateTime.now(),
        ),
      );
      return userMember.isAdmin;
    }

    // Fallback to database
    try {
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

  // ====================================================================
  // CACHED OPERATIONS (Fast Path)
  // ====================================================================

  /// Get group name by ID (ultra-fast cache lookup)
  ///
  /// This is THE optimization for expense list items - instead of
  /// fetching group details every time, we use cached data
  String? getGroupName(String groupId) {
    final cached = getCached().firstWhere(
      (g) => g.id == groupId,
      orElse: () => ExpenseGroup(
        id: '',
        name: '',
        createdBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return cached.id.isNotEmpty ? cached.name : null;
  }

  /// Get group by ID from cache (fast path)
  Future<ExpenseGroup?> getCachedGroup(String id) => getById(id);

  /// Get all user's groups from cache
  List<ExpenseGroup> getAllCachedGroups() => getCached();

  // ====================================================================
  // GROUP INVITES
  // ====================================================================

  Future<GroupInvite?> sendInvite({
    required String groupId,
    required String inviteeEmail,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    // Check if user exists and is already a member
    final profileResponse = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', inviteeEmail.toLowerCase())
        .maybeSingle();

    if (profileResponse != null) {
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

    // Check for pending invite
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

    final invite = GroupInvite.fromMap(response);
    _invitesCache[invite.id] = invite;

    return invite;
  }

  Future<List<GroupInvite>> getPendingInvites() async {
    final userEmail = _supabase.auth.currentUser?.email;
    if (userEmail == null) return [];

    try {
      final invitesResponse = await _supabase
          .from('group_invites')
          .select()
          .eq('invitee_email', userEmail.toLowerCase())
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final invites = invitesResponse as List;
      if (invites.isEmpty) return [];

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

      final groupNames = {
        for (var g in groupsResponse as List)
          g['id'] as String: g['name'] as String
      };

      final inviterNicknames = {
        for (var p in profilesResponse as List)
          p['id'] as String: p['nickname'] as String
      };

      final invitesList = invites.map((map) {
        final invite = GroupInvite.fromMap({
          ...map,
          'group_name': groupNames[map['group_id']] ?? 'Unknown Group',
          'inviter_nickname': inviterNicknames[map['inviter_id']] ?? 'Unknown User',
        });
        _invitesCache[invite.id] = invite;
        return invite;
      }).toList();

      return invitesList;
    } catch (e) {
      return [];
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    final invite = await _supabase
        .from('group_invites')
        .select('group_id')
        .eq('id', inviteId)
        .single();

    await addMemberToGroup(
      groupId: invite['group_id'],
      userId: userId,
    );

    await _supabase
        .from('group_invites')
        .update({
          'status': 'accepted',
          'invitee_id': userId,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', inviteId);

    _invitesCache.remove(inviteId);

    // Refresh cache to include new group
    await refreshCache();
  }

  Future<void> rejectInvite(String inviteId) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('group_invites')
        .update({
          'status': 'rejected',
          'invitee_id': userId,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', inviteId);

    _invitesCache.remove(inviteId);
  }

  Future<int> getPendingInviteCount() async {
    final userEmail = _supabase.auth.currentUser?.email;
    if (userEmail == null) return 0;

    try {
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

  // ====================================================================
  // STREAMS (Backward Compatibility)
  // ====================================================================

  Stream<List<ExpenseGroup>> get groupsStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

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

          final groups = (groupsData as List)
              .map((map) => ExpenseGroup.fromMap(map))
              .toList();

          // Update cache with streamed data
          putManyInCache(groups);

          return groups;
        });
  }

  // ====================================================================
  // BACKWARD COMPATIBILITY (Legacy Methods)
  // ====================================================================

  Future<List<ExpenseGroup>> getUserGroups() => fetchAll();

  Future<ExpenseGroup?> getGroupById(String groupId) async {
    final group = await getById(groupId);
    if (group != null) {
      group.members = await getGroupMembers(groupId);
    }
    return group;
  }

  Future<ExpenseGroup?> createGroup({
    required String name,
    String? description,
  }) async {
    final newGroup = ExpenseGroup(
      id: '', // Will be generated by Supabase
      name: name,
      description: description,
      createdBy: _supabase.auth.currentUser?.id ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await create(newGroup);
  }

  Future<void> updateGroup(ExpenseGroup group) async {
    await updateItem(group);
  }

  Future<void> deleteGroup(String groupId) async {
    await deleteItem(groupId);
  }
}
