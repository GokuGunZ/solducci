import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:solducci/models/group.dart';
import 'package:solducci/service/group_service.dart';

/// Manages the current expense context (Personal or Group)
/// This is the core of the multi-user system - determines what expenses are shown
class ContextManager extends ChangeNotifier {
  // Singleton pattern
  static final ContextManager _instance = ContextManager._internal();
  factory ContextManager() => _instance;
  ContextManager._internal();

  final _groupService = GroupService();

  ExpenseContext _currentContext = ExpenseContext.personal();
  List<ExpenseGroup> _userGroups = [];
  bool _isLoading = false;

  // Getters
  ExpenseContext get currentContext => _currentContext;
  List<ExpenseGroup> get userGroups => _userGroups;
  bool get isLoading => _isLoading;

  // Quick checks
  bool get isPersonalContext => _currentContext.isPersonal;
  bool get isGroupContext => !_currentContext.isPersonal;
  String get contextDisplayName => _currentContext.displayName;
  String? get currentGroupId => _currentContext.groupId;

  /// Initialize context manager - load user's groups
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadUserGroups();
    } catch (e) {
      // Error handled silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load/refresh user's groups
  Future<void> loadUserGroups() async {
    try {
      _userGroups = await _groupService.getUserGroups();

      // If current context is a group that no longer exists, switch to personal
      if (_currentContext.isGroup) {
        final stillExists = _userGroups.any(
          (g) => g.id == _currentContext.groupId,
        );
        if (!stillExists) {
          switchToPersonal();
        }
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Switch to personal context
  void switchToPersonal() {
    _currentContext = ExpenseContext.personal();
    notifyListeners();
  }

  /// Switch to a group context
  void switchToGroup(ExpenseGroup group) {
    _currentContext = ExpenseContext.group(group);
    notifyListeners();
  }

  /// Switch to group by ID (useful for deep linking)
  Future<void> switchToGroupById(String groupId) async {
    try {
      final group = _userGroups.firstWhere((g) => g.id == groupId);
      switchToGroup(group);
    } catch (e) {
      // Try loading from database
      final group = await _groupService.getGroupById(groupId);
      if (group != null) {
        switchToGroup(group);
      } else {
        throw Exception('Group not found: $groupId');
      }
    }
  }

  /// Create a new group and switch to it
  Future<ExpenseGroup?> createAndSwitchToGroup({
    required String name,
    String? description,
  }) async {
    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
      );

      if (group != null) {
        await loadUserGroups(); // Refresh groups list
        switchToGroup(group);
      }

      return group;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete current group and switch to personal
  Future<void> deleteCurrentGroup() async {
    if (_currentContext.isPersonal) {
      throw Exception('Cannot delete personal context');
    }

    try {
      await _groupService.deleteGroup(_currentContext.groupId!);
      await loadUserGroups();
      switchToPersonal();
    } catch (e) {
      rethrow;
    }
  }

  /// Leave current group and switch to personal
  Future<void> leaveCurrentGroup() async {
    if (_currentContext.isPersonal) {
      throw Exception('Cannot leave personal context');
    }

    try {
      await _groupService.leaveGroup(_currentContext.groupId!);
      await loadUserGroups();
      switchToPersonal();
    } catch (e) {
      rethrow;
    }
  }

  /// Get group members for current context
  Future<List<GroupMember>> getCurrentGroupMembers() async {
    if (_currentContext.isPersonal) {
      return [];
    }

    return await _groupService.getGroupMembers(_currentContext.groupId!);
  }

  /// Clear context (on logout)
  void clear() {
    _currentContext = ExpenseContext.personal();
    _userGroups = [];
    notifyListeners();
  }
}

/// Represents the current expense context (Personal or Group)
class ExpenseContext {
  final bool isPersonal;
  final ExpenseGroup? group;

  ExpenseContext.personal()
      : isPersonal = true,
        group = null;

  ExpenseContext.group(this.group) : isPersonal = false {
    if (group == null) {
      throw Exception('Group cannot be null for group context');
    }
  }

  /// Check if context is a group
  bool get isGroup => !isPersonal;

  /// Display name for UI
  String get displayName => isPersonal ? 'Personale' : group!.name;

  /// Group ID (null if personal)
  String? get groupId => group?.id;

  /// Icon for context
  String get icon => isPersonal ? '👤' : '👥';

  @override
  String toString() {
    return isPersonal ? 'Personal Context' : 'Group Context: ${group!.name}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExpenseContext) return false;

    if (isPersonal && other.isPersonal) return true;
    if (isPersonal != other.isPersonal) return false;

    return groupId == other.groupId;
  }

  @override
  int get hashCode => isPersonal ? 0 : groupId.hashCode;
}
