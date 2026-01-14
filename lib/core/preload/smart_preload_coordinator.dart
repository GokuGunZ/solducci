import 'dart:async';
import 'package:solducci/core/preload/preload_task.dart';
import 'package:solducci/core/preload/preload_priority.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/service/profile_service_cached.dart';

/// Simple priority queue implementation using sorted list
class _PriorityQueue<T extends Comparable<T>> {
  final List<T> _items = [];

  void add(T item) {
    _items.add(item);
    _items.sort();
  }

  T removeFirst() => _items.removeAt(0);

  bool get isNotEmpty => _items.isNotEmpty;

  int get length => _items.length;

  void clear() => _items.clear();
}

/// Central coordinator for smart preloading
///
/// Observes user behavior (context changes, navigation) and triggers
/// intelligent preloading to ensure data is ready before the user needs it.
///
/// Key Features:
/// - Context-aware preloading (Personal, Group, View)
/// - Priority-based queue (high/medium/low)
/// - Automatic deduplication (same task not queued twice)
/// - Background execution (non-blocking)
class SmartPreloadCoordinator {
  // Singleton pattern
  static final SmartPreloadCoordinator _instance =
      SmartPreloadCoordinator._internal();
  factory SmartPreloadCoordinator() => _instance;
  SmartPreloadCoordinator._internal();

  // Services (lazy-initialized to avoid circular dependency)
  ContextManager? _contextManager;
  ExpenseServiceCached? _expenseService;
  GroupServiceCached? _groupService;
  ProfileServiceCached? _profileService;

  // Priority queue for preload tasks (sorted by priority)
  final _PriorityQueue<PreloadTask> _queue = _PriorityQueue<PreloadTask>();

  // Track active tasks to avoid duplicates
  final Set<String> _activeTaskIds = {};

  // Track if currently processing queue
  bool _isProcessing = false;

  /// Initialize coordinator and start listening to events
  void initialize() {
    print('🧠 SmartPreloadCoordinator initialized');

    // Initialize services (lazy initialization to avoid circular dependency)
    _contextManager = ContextManager();
    _expenseService = ExpenseServiceCached();
    _groupService = GroupServiceCached();
    _profileService = ProfileServiceCached();

    // Listen to context changes for automatic preloading
    _contextManager!.addListener(_onContextChanged);
  }

  // ====================================================================
  // CONTEXT-BASED PRELOADING
  // ====================================================================

  /// Triggered automatically when user switches context
  Future<void> _onContextChanged() async {
    final context = _contextManager!.currentContext;

    print('🧠 Context changed: ${context.displayName}');

    if (context.isPersonal) {
      await _preloadPersonalContext();
    } else if (context.isGroup) {
      await _preloadGroupContext(context.groupId!);
    } else if (context.isView) {
      await _preloadViewContext(context.groupIds);
    }
  }

  /// Preload data for Personal context
  Future<void> _preloadPersonalContext() async {
    print('📦 Preloading Personal context...');

    // Personal context: just ensure expenses are loaded
    await _queuePreload(
      PreloadTask(
        id: 'personal_expenses',
        priority: PreloadPriority.high,
        action: () => _expenseService!.ensureInitialized(),
        description: 'Personal expenses',
      ),
    );
  }

  /// Preload data for Group context
  Future<void> _preloadGroupContext(String groupId) async {
    print('📦 Preloading Group context: $groupId');

    // 1. Group details (HIGH priority)
    await _queuePreload(
      PreloadTask(
        id: 'group_$groupId',
        priority: PreloadPriority.high,
        action: () async {
          await _groupService!.ensureInitialized();
        },
        description: 'Group $groupId details',
      ),
    );

    // 2. Expenses for this group (HIGH priority)
    await _queuePreload(
      PreloadTask(
        id: 'group_${groupId}_expenses',
        priority: PreloadPriority.high,
        action: () => _expenseService!.ensureInitialized(),
        description: 'Group $groupId expenses',
      ),
    );

    // 3. User profiles (MEDIUM priority)
    await _queuePreload(
      PreloadTask(
        id: 'profiles',
        priority: PreloadPriority.medium,
        action: () => _profileService!.ensureInitialized(),
        description: 'User profiles',
      ),
    );
  }

  /// Preload data for View context (multiple groups)
  Future<void> _preloadViewContext(List<String> groupIds) async {
    print('📦 Preloading View context: ${groupIds.length} groups');

    // Preload all groups and expenses (HIGH priority)
    await _queuePreload(
      PreloadTask(
        id: 'view_${groupIds.join('_')}',
        priority: PreloadPriority.high,
        action: () async {
          await Future.wait([
            _groupService!.ensureInitialized(),
            _expenseService!.ensureInitialized(),
            _profileService!.ensureInitialized(),
          ]);
        },
        description: 'View with ${groupIds.length} groups',
      ),
    );
  }

  // ====================================================================
  // MANUAL PRELOADING (for specific views)
  // ====================================================================

  /// Manually trigger preload for expense list view
  Future<void> preloadExpenseList() async {
    print('📦 Preloading Expense List view...');

    // Ensure all services are initialized
    await _queuePreload(
      PreloadTask(
        id: 'expense_list',
        priority: PreloadPriority.high,
        action: () async {
          await Future.wait([
            _expenseService!.ensureInitialized(),
            _groupService!.ensureInitialized(),
            _profileService!.ensureInitialized(),
          ]);
        },
        description: 'Expense List view',
      ),
    );
  }

  /// Manually trigger preload for group details view
  Future<void> preloadGroupDetails(String groupId) async {
    print('📦 Preloading Group Details view: $groupId');

    await _queuePreload(
      PreloadTask(
        id: 'group_details_$groupId',
        priority: PreloadPriority.high,
        action: () async {
          await Future.wait([
            _groupService!.ensureInitialized(),
            _expenseService!.ensureInitialized(),
            _profileService!.ensureInitialized(),
          ]);
        },
        description: 'Group Details $groupId',
      ),
    );
  }

  // ====================================================================
  // QUEUE MANAGEMENT
  // ====================================================================

  /// Add task to queue and start processing
  Future<void> _queuePreload(PreloadTask task) async {
    // Check if already active
    if (_activeTaskIds.contains(task.id)) {
      print('⏭️  Skipping duplicate task: ${task.id}');
      return;
    }

    // Add to queue
    _queue.add(task);
    _activeTaskIds.add(task.id);

    print('➕ Queued: ${task.description} (${task.priority.name})');

    // Start processing if not already running
    if (!_isProcessing) {
      _processQueue();
    }
  }

  /// Process queue in priority order
  Future<void> _processQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();

      print('▶️  Executing: ${task.description}');

      try {
        await task.action();
        print('✅ Completed: ${task.description}');
      } catch (e) {
        print('❌ Failed: ${task.description} - $e');
      } finally {
        _activeTaskIds.remove(task.id);
      }
    }

    _isProcessing = false;
    print('🏁 Queue empty');
  }

  // ====================================================================
  // DIAGNOSTICS
  // ====================================================================

  /// Get current queue size
  int get queueSize => _queue.length;

  /// Get active task count
  int get activeTaskCount => _activeTaskIds.length;

  /// Print diagnostics
  void printDiagnostics() {
    print('=== Smart Preload Diagnostics ===');
    print('Queue size: $queueSize');
    print('Active tasks: $activeTaskCount');
    print('Is processing: $_isProcessing');
    print('================================');
  }

  /// Dispose and cleanup
  void dispose() {
    _contextManager?.removeListener(_onContextChanged);
    _queue.clear();
    _activeTaskIds.clear();
  }
}
