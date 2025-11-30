import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:solducci/models/group.dart';
import 'package:solducci/models/expense_view.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/service/view_storage_service.dart';
import 'package:solducci/service/group_storage_service.dart';

/// Manages the current expense context (Personal or Group)
/// This is the core of the multi-user system - determines what expenses are shown
class ContextManager extends ChangeNotifier {
  // Singleton pattern
  static final ContextManager _instance = ContextManager._internal();
  factory ContextManager() => _instance;
  ContextManager._internal();

  final _groupService = GroupService();
  final _viewStorage = ViewStorageService();
  final _groupStorage = GroupStorageService();

  ExpenseContext _currentContext = ExpenseContext.personal();
  List<ExpenseGroup> _userGroups = [];
  List<ExpenseView> _userViews = [];
  Map<String, bool> _groupPreferences = {}; // Cache per preferenze gruppi
  bool _isLoading = false;

  // Getters
  ExpenseContext get currentContext => _currentContext;
  List<ExpenseGroup> get userGroups => _userGroups;
  List<ExpenseView> get userViews => _userViews;
  bool get isLoading => _isLoading;

  // Quick checks
  bool get isPersonalContext => _currentContext.isPersonal;
  bool get isGroupContext => !_currentContext.isPersonal;
  String get contextDisplayName => _currentContext.displayName;
  String? get currentGroupId => _currentContext.groupId;

  /// Initialize context manager - load user's groups, views, and preferences
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadUserGroups();
      await loadUserViews();
      await loadGroupPreferences(); // Carica preferenze gruppi
      await _cleanupInvalidViews();
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

  /// Load/refresh user's views from local storage
  Future<void> loadUserViews() async {
    try {
      _userViews = await _viewStorage.loadViews();

      // Populate denormalized groups for each view
      for (final view in _userViews) {
        view.groups = _userGroups.where((g) => view.groupIds.contains(g.id)).toList();
      }

      // If current context is a view that no longer exists, switch to personal
      if (_currentContext.isView) {
        final stillExists = _userViews.any(
          (v) => v.id == _currentContext.viewId,
        );
        if (!stillExists) {
          switchToPersonal();
        }
      }

      notifyListeners();
    } catch (e) {
      // If error loading views, just set empty list
      _userViews = [];
      notifyListeners();
    }
  }

  /// Load/refresh group preferences from local storage
  Future<void> loadGroupPreferences() async {
    try {
      _groupPreferences = await _groupStorage.loadPreferences();
      notifyListeners();
    } catch (e) {
      // If error loading preferences, just set empty map
      _groupPreferences = {};
      notifyListeners();
    }
  }

  /// Get "include personal" preference for a specific group
  bool getGroupIncludesPersonal(String groupId) {
    return _groupPreferences[groupId] ?? false;
  }

  /// Toggle "include personal" preference for a specific group
  Future<void> toggleIncludePersonalForGroup(String groupId) async {
    final currentValue = _groupPreferences[groupId] ?? false;
    await _groupStorage.setIncludePersonal(groupId, !currentValue);
    await loadGroupPreferences();

    // If it's the current group context, re-switch to apply the preference
    if (_currentContext.isGroup && _currentContext.group!.id == groupId) {
      switchToGroup(_currentContext.group!);
    }
  }

  /// Clean up views that contain groups that no longer exist
  Future<void> _cleanupInvalidViews() async {
    final validGroupIds = _userGroups.map((g) => g.id).toSet();
    final viewsToRemove = <String>[];

    for (final view in _userViews) {
      // If view contains any groups that don't exist anymore, remove the view
      final hasInvalidGroups = !view.groupIds.every((id) => validGroupIds.contains(id));
      if (hasInvalidGroups) {
        viewsToRemove.add(view.id);
      }
    }

    for (final viewId in viewsToRemove) {
      await _viewStorage.deleteView(viewId);
    }

    if (viewsToRemove.isNotEmpty) {
      await loadUserViews();
    }
  }

  /// Switch to personal context
  void switchToPersonal() {
    _currentContext = ExpenseContext.personal();
    notifyListeners();
  }

  /// Switch to a group context
  void switchToGroup(ExpenseGroup group) {
    final includePersonal = _groupPreferences[group.id] ?? false;
    _currentContext = ExpenseContext.group(group, includePersonalForGroup: includePersonal);
    notifyListeners();
  }

  /// Switch to a view context
  void switchToView(ExpenseView view) {
    _currentContext = ExpenseContext.view(view);
    notifyListeners();
  }

  /// Switch to a temporary (unsaved) view with given group IDs
  /// Used for multi-select preview without creating a permanent view
  void switchToTemporaryView(List<String> groupIds, {bool includePersonal = false}) {
    // Get the actual group objects for the given IDs
    final groups = _userGroups.where((g) => groupIds.contains(g.id)).toList();

    // Create a temporary view (not saved to storage)
    final tempView = ExpenseView(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
      name: 'Vista Temporanea',
      groupIds: groupIds,
      includePersonal: includePersonal,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      groups: groups,
    );

    _currentContext = ExpenseContext.view(tempView);
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

  /// Create a new view and switch to it
  Future<ExpenseView> createAndSwitchToView({
    required String name,
    String? description,
    required List<String> groupIds,
    bool includePersonal = false,
  }) async {
    try {
      final view = ExpenseView.create(
        name: name,
        description: description,
        groupIds: groupIds,
        includePersonal: includePersonal,
      );

      await _viewStorage.addView(view);
      await loadUserViews(); // Refresh views list (populates groups)

      // Get the view from the loaded list (with groups populated)
      final loadedView = _userViews.firstWhere((v) => v.id == view.id);
      switchToView(loadedView);

      return loadedView;
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

  /// Delete current view and switch to personal
  Future<void> deleteCurrentView() async {
    if (!_currentContext.isView) {
      throw Exception('Current context is not a view');
    }

    try {
      await _viewStorage.deleteView(_currentContext.viewId!);
      await loadUserViews();
      switchToPersonal();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle "include personal" preference for current view
  Future<void> toggleIncludePersonalForCurrentView() async {
    if (!_currentContext.isView) return;

    final view = _currentContext.view!;
    final newValue = !view.includePersonal;

    await _viewStorage.setIncludePersonal(view.id, newValue);
    await loadUserViews();

    // Re-switch to refresh UI with updated view
    final updatedView = _userViews.firstWhere((v) => v.id == view.id);
    switchToView(updatedView);
  }

  /// Toggle "include personal" preference for a specific view (by ID)
  Future<void> toggleIncludePersonalForView(String viewId) async {
    final view = _userViews.firstWhere((v) => v.id == viewId);
    final newValue = !view.includePersonal;

    await _viewStorage.setIncludePersonal(viewId, newValue);
    await loadUserViews();
  }

  /// Toggle "include personal" preference for current group
  Future<void> toggleIncludePersonalForCurrentGroup() async {
    if (!_currentContext.isGroup) return;

    final groupId = _currentContext.group!.id;
    final newValue = !_currentContext.includePersonalForGroup;

    await _groupStorage.setIncludePersonal(groupId, newValue);
    await loadGroupPreferences();

    // Re-switch to apply the preference
    switchToGroup(_currentContext.group!);
  }

  /// Find existing view with the same group composition (ignoring order and includePersonal)
  ExpenseView? findViewWithSameGroups(List<String> groupIds) {
    final sortedInputIds = groupIds.toList()..sort();

    for (final view in _userViews) {
      final sortedViewIds = view.groupIds.toList()..sort();

      // Check if lists are equal (same groups, ignoring order)
      if (sortedInputIds.length == sortedViewIds.length &&
          sortedInputIds.every((id) => sortedViewIds.contains(id))) {
        return view;
      }
    }

    return null;
  }

  /// Get group members for current context
  Future<List<GroupMember>> getCurrentGroupMembers() async {
    if (_currentContext.isPersonal) {
      return [];
    }

    return await _groupService.getGroupMembers(_currentContext.groupId!);
  }

  /// Update a group and refresh
  Future<void> updateGroup(ExpenseGroup group) async {
    await _groupService.updateGroup(group);
    await loadUserGroups();

    // If it's the current group, update context
    if (_currentContext.isGroup && _currentContext.groupId == group.id) {
      final updatedGroup = _userGroups.firstWhere((g) => g.id == group.id);
      switchToGroup(updatedGroup);
    }
  }

  /// Update a view and refresh
  Future<void> updateView(ExpenseView view) async {
    await _viewStorage.updateView(view);
    await loadUserViews();

    // If it's the current view, update context
    if (_currentContext.isView && _currentContext.viewId == view.id) {
      final updatedView = _userViews.firstWhere((v) => v.id == view.id);
      switchToView(updatedView);
    }
  }

  /// Clear context (on logout)
  /// Note: Views remain in local storage and will be reloaded on next login
  void clear() {
    _currentContext = ExpenseContext.personal();
    _userGroups = [];
    _userViews = [];
    notifyListeners();
  }
}

/// Represents the current expense context (Personal, Group, or View)
class ExpenseContext {
  final bool isPersonal;
  final bool isView;
  final ExpenseGroup? group;
  final ExpenseView? view;
  final bool includePersonalForGroup;

  ExpenseContext.personal()
      : isPersonal = true,
        isView = false,
        group = null,
        view = null,
        includePersonalForGroup = false;

  ExpenseContext.group(this.group, {this.includePersonalForGroup = false})
      : isPersonal = false,
        isView = false,
        view = null {
    if (group == null) {
      throw Exception('Group cannot be null for group context');
    }
  }

  ExpenseContext.view(this.view)
      : isPersonal = false,
        isView = true,
        group = null,
        includePersonalForGroup = false {
    if (view == null) {
      throw Exception('View cannot be null for view context');
    }
  }

  /// Check if context is a group (single group, not a view)
  bool get isGroup => !isPersonal && !isView;

  /// Display name for UI
  String get displayName {
    if (isPersonal) return 'Personale';
    if (isView) {
      return view!.includePersonal ? '${view!.name} 👤' : view!.name;
    }
    // Single group with optional personal icon
    return includePersonalForGroup ? '${group!.name} 👤' : group!.name;
  }

  /// Group ID (null if personal or view)
  String? get groupId => group?.id;

  /// View ID (null if personal or group)
  String? get viewId => view?.id;

  /// Get all group IDs (for views, returns all groups in the view)
  List<String> get groupIds {
    if (isPersonal) return [];
    if (isView) return view!.groupIds;
    return [group!.id];
  }

  /// Check if context includes personal expenses (for views and groups with toggle enabled)
  bool get includesPersonal =>
      (isView && view!.includePersonal) ||
      (!isPersonal && !isView && includePersonalForGroup);

  /// Icon for context
  String get icon {
    if (isPersonal) return '👤';
    if (isView) return '📊';
    return '👥';
  }

  @override
  String toString() {
    if (isPersonal) return 'Personal Context';
    if (isView) return 'View Context: ${view!.name}';
    return 'Group Context: ${group!.name}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExpenseContext) return false;

    if (isPersonal && other.isPersonal) return true;
    if (isPersonal != other.isPersonal) return false;
    if (isView != other.isView) return false;

    if (isView) return viewId == other.viewId;
    return groupId == other.groupId;
  }

  @override
  int get hashCode {
    if (isPersonal) return 0;
    if (isView) return viewId.hashCode;
    return groupId.hashCode;
  }
}
