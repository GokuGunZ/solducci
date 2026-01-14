# 🧠 Smart Preloading - Analisi Tecnica e Architetturale

## 📋 Executive Summary

Lo **Smart Preloading** è un sistema intelligente che **anticipa le esigenze dell'utente** e precarica i dati **prima che vengano richiesti**, creando un'esperienza di **latenza percepita zero**.

**Key Insight**: Se l'utente sta guardando la lista spese, probabilmente aprirà i dettagli di una spesa. Precaricare i dati dei membri del gruppo PRIMA che clicchi!

---

## 🎯 Obiettivi

### Primary Goals
1. **Zero Perceived Latency**: Dati pronti PRIMA che l'utente naviga
2. **Context-Aware Preloading**: Preload basato su dove si trova l'utente
3. **Predictive Loading**: Imparare dai pattern di navigazione
4. **Resource Efficient**: Preload solo dati probabilmente necessari

### Secondary Goals
- Ridurre gli spinner di loading del 95%
- Migliorare perceived performance 10x
- Supportare navigazione rapida (no lag)
- Ottimizzare utilizzo rete (preload in background)

---

## 🏗️ Architettura Proposta

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      USER BEHAVIOR                          │
│  • User opens app                                           │
│  • User switches context (Personal → Group)                 │
│  • User views expense list                                  │
│  • User taps on expense                                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              SMART PRELOAD COORDINATOR                      │
│  • Observes navigation events                               │
│  • Predicts next navigation                                 │
│  • Triggers preload strategies                              │
└────────────────────────┬────────────────────────────────────┘
                         │
            ┌────────────┴────────────┐
            ▼                         ▼
┌──────────────────────┐    ┌──────────────────────┐
│  PRELOAD STRATEGIES  │    │  PRELOAD QUEUE       │
│  • Context-based     │    │  • Priority Queue    │
│  • Route-based       │    │  • Debouncing        │
│  • Pattern-based     │    │  • Cancellation      │
└──────────────────────┘    └──────────────────────┘
            │                         │
            └────────────┬────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   CACHED SERVICES                           │
│  • ExpenseServiceCached.preload(groupId)                    │
│  • GroupServiceCached.preload(groupId)                      │
│  • ProfileServiceCached.preload([userIds])                  │
└─────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. **SmartPreloadCoordinator** (New!)
- **Purpose**: Centrale di decisione per il preloading
- **Responsibilities**:
  - Osservare navigazione utente
  - Decidere COSA precaricare
  - Decidere QUANDO precaricare
  - Gestire priorità e cancellazioni

#### 2. **Preload Strategies** (New!)
- **Context-Based**: Preload basato su contesto corrente
- **Route-Based**: Preload basato su route/pagina
- **Pattern-Based**: Preload basato su comportamento storico

#### 3. **Preload Queue** (New!)
- **Priority Queue**: Task con priorità (high/medium/low)
- **Debouncing**: Evita preload multipli dello stesso dato
- **Cancellation**: Cancella preload se utente cambia direzione

---

## 🔧 Technical Implementation

### 1. SmartPreloadCoordinator

```dart
/// Central coordinator for smart preloading
///
/// Observes user behavior and triggers intelligent preloading
/// based on context, navigation patterns, and predictions.
class SmartPreloadCoordinator {
  // Singleton pattern
  static final SmartPreloadCoordinator _instance =
      SmartPreloadCoordinator._internal();
  factory SmartPreloadCoordinator() => _instance;
  SmartPreloadCoordinator._internal();

  // Services
  final _contextManager = ContextManager();
  final _expenseService = ExpenseServiceCached();
  final _groupService = GroupServiceCached();
  final _profileService = ProfileServiceCached();

  // Preload queue
  final _preloadQueue = PriorityQueue<PreloadTask>();

  // Pattern tracker
  final _patternTracker = NavigationPatternTracker();

  // Current preload tasks (for cancellation)
  final Map<String, CancelableOperation> _activeTasks = {};

  /// Initialize coordinator
  void initialize() {
    // Listen to context changes
    _contextManager.addListener(_onContextChanged);

    // Listen to route changes (if using navigator)
    // (Implementation depends on router setup)
  }

  // ====================================================================
  // CONTEXT-BASED PRELOADING
  // ====================================================================

  /// Triggered when user switches context
  Future<void> _onContextChanged() async {
    final context = _contextManager.currentContext;

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

    // Personal context is simple - just expenses
    await _queuePreload(
      PreloadTask(
        id: 'personal_expenses',
        priority: PreloadPriority.high,
        action: () => _expenseService.ensureInitialized(),
        description: 'Personal expenses',
      ),
    );
  }

  /// Preload data for Group context
  Future<void> _preloadGroupContext(String groupId) async {
    print('📦 Preloading Group context: $groupId');

    // 1. Group details + members (HIGH priority)
    await _queuePreload(
      PreloadTask(
        id: 'group_$groupId',
        priority: PreloadPriority.high,
        action: () async {
          final group = await _groupService.getCachedGroup(groupId);
          if (group != null) {
            // Preload member profiles
            await _profileService.preloadProfiles(
              group.members.map((m) => m.userId).toList(),
            );
          }
        },
        description: 'Group $groupId details + members',
      ),
    );

    // 2. Expenses for this group (HIGH priority)
    await _queuePreload(
      PreloadTask(
        id: 'group_${groupId}_expenses',
        priority: PreloadPriority.high,
        action: () => _expenseService.ensureInitialized(),
        description: 'Group $groupId expenses',
      ),
    );

    // 3. Balance calculations (MEDIUM priority)
    await _queuePreload(
      PreloadTask(
        id: 'group_${groupId}_balance',
        priority: PreloadPriority.medium,
        action: () => _expenseService.calculateGroupBalance(groupId),
        description: 'Group $groupId balance',
      ),
    );
  }

  /// Preload data for View context (multiple groups)
  Future<void> _preloadViewContext(List<String> groupIds) async {
    print('📦 Preloading View context: ${groupIds.length} groups');

    // Preload all groups in parallel
    await _queuePreload(
      PreloadTask(
        id: 'view_${groupIds.join('_')}',
        priority: PreloadPriority.high,
        action: () async {
          await Future.wait([
            // Groups
            Future.wait(
              groupIds.map((id) => _groupService.getCachedGroup(id)),
            ),
            // Expenses (filtered by context)
            _expenseService.ensureInitialized(),
          ]);
        },
        description: 'View with ${groupIds.length} groups',
      ),
    );
  }

  // ====================================================================
  // ROUTE-BASED PRELOADING
  // ====================================================================

  /// Preload for expense list view
  Future<void> preloadExpenseList() async {
    print('📦 Preloading Expense List view...');

    // Get current expenses from cache
    final expenses = _expenseService.getAllCachedExpenses();

    if (expenses.isEmpty) return;

    // 1. Preload profiles for all payer/payee (HIGH priority)
    final userIds = <String>{};
    for (final expense in expenses) {
      if (expense.payerId != null) userIds.add(expense.payerId!);
      if (expense.paidFor != null) userIds.addAll(expense.paidFor!);
    }

    await _queuePreload(
      PreloadTask(
        id: 'expense_list_profiles',
        priority: PreloadPriority.high,
        action: () => _profileService.preloadProfiles(userIds.toList()),
        description: 'Profiles for expense list',
      ),
    );

    // 2. Preload balance calculations (MEDIUM priority)
    await _queuePreload(
      PreloadTask(
        id: 'expense_list_balances',
        priority: PreloadPriority.medium,
        action: () => _expenseService.calculateBulkUserBalances(expenses),
        description: 'Balances for expense list',
      ),
    );

    // 3. Predict: User might tap first expense (LOW priority)
    if (expenses.isNotEmpty) {
      final firstExpense = expenses.first;
      await _preloadExpenseDetails(firstExpense.id);
    }
  }

  /// Preload for expense details view
  Future<void> _preloadExpenseDetails(int expenseId) async {
    final expense = await _expenseService.getCachedExpenseById(expenseId);
    if (expense == null) return;

    print('📦 Preloading Expense Details: $expenseId');

    // 1. Preload payer profile (HIGH priority)
    if (expense.payerId != null) {
      await _queuePreload(
        PreloadTask(
          id: 'expense_${expenseId}_payer',
          priority: PreloadPriority.high,
          action: () => _profileService.getCachedProfile(expense.payerId!),
          description: 'Payer profile for expense $expenseId',
        ),
      );
    }

    // 2. Preload all participant profiles (HIGH priority)
    if (expense.paidFor != null && expense.paidFor!.isNotEmpty) {
      await _queuePreload(
        PreloadTask(
          id: 'expense_${expenseId}_participants',
          priority: PreloadPriority.high,
          action: () =>
              _profileService.getCachedProfiles(expense.paidFor!),
          description: 'Participant profiles for expense $expenseId',
        ),
      );
    }

    // 3. Preload group details if group expense (MEDIUM priority)
    if (expense.isGroup && expense.groupId != null) {
      await _queuePreload(
        PreloadTask(
          id: 'expense_${expenseId}_group',
          priority: PreloadPriority.medium,
          action: () => _groupService.getCachedGroup(expense.groupId!),
          description: 'Group details for expense $expenseId',
        ),
      );
    }
  }

  /// Preload for group details view
  Future<void> preloadGroupDetails(String groupId) async {
    print('📦 Preloading Group Details: $groupId');

    // 1. Group members (already cached, but ensure profiles loaded)
    final group = await _groupService.getCachedGroup(groupId);
    if (group == null) return;

    await _queuePreload(
      PreloadTask(
        id: 'group_${groupId}_member_profiles',
        priority: PreloadPriority.high,
        action: () => _profileService.preloadProfiles(
          group.members.map((m) => m.userId).toList(),
        ),
        description: 'Member profiles for group $groupId',
      ),
    );

    // 2. Recent expenses for this group (MEDIUM priority)
    await _queuePreload(
      PreloadTask(
        id: 'group_${groupId}_recent_expenses',
        priority: PreloadPriority.medium,
        action: () async {
          // Fetch recent expenses (last 20)
          // Implementation depends on ExpenseService API
        },
        description: 'Recent expenses for group $groupId',
      ),
    );

    // 3. Balance breakdown (MEDIUM priority)
    await _queuePreload(
      PreloadTask(
        id: 'group_${groupId}_balance_breakdown',
        priority: PreloadPriority.medium,
        action: () => _expenseService.calculateGroupBalance(groupId),
        description: 'Balance breakdown for group $groupId',
      ),
    );
  }

  // ====================================================================
  // PATTERN-BASED PRELOADING
  // ====================================================================

  /// Preload based on navigation patterns
  ///
  /// Example: If user always goes Personal → Groups → Group Detail,
  /// preload group details when they open Groups page.
  Future<void> _preloadByPattern() async {
    final predictions = _patternTracker.predictNext();

    for (final prediction in predictions) {
      if (prediction.confidence > 0.7) {
        // High confidence - preload
        await _executePreloadForRoute(prediction.route);
      }
    }
  }

  /// Execute preload for predicted route
  Future<void> _executePreloadForRoute(String route) async {
    // Match route and execute corresponding preload
    if (route == '/expense_list') {
      await preloadExpenseList();
    } else if (route.startsWith('/group/')) {
      final groupId = route.split('/').last;
      await preloadGroupDetails(groupId);
    }
    // Add more routes as needed
  }

  // ====================================================================
  // QUEUE MANAGEMENT
  // ====================================================================

  /// Queue a preload task
  Future<void> _queuePreload(PreloadTask task) async {
    // Check if already queued or active
    if (_activeTasks.containsKey(task.id)) {
      print('⏭️  Skipping duplicate preload: ${task.id}');
      return;
    }

    // Add to queue
    _preloadQueue.add(task);

    // Process queue (debounced)
    await _processQueue();
  }

  /// Process preload queue
  Future<void> _processQueue() async {
    // Debounce: Wait 100ms for more tasks
    await Future.delayed(Duration(milliseconds: 100));

    while (_preloadQueue.isNotEmpty) {
      final task = _preloadQueue.removeFirst();

      // Check if already completed
      if (_activeTasks.containsKey(task.id)) continue;

      // Execute task
      print('▶️  Executing preload: ${task.description}');

      final operation = CancelableOperation.fromFuture(
        task.action(),
        onCancel: () => print('❌ Cancelled preload: ${task.id}'),
      );

      _activeTasks[task.id] = operation;

      try {
        await operation.value;
        print('✅ Completed preload: ${task.description}');
      } catch (e) {
        print('❌ Failed preload: ${task.description} - $e');
      } finally {
        _activeTasks.remove(task.id);
      }
    }
  }

  /// Cancel all active preloads
  void cancelAll() {
    for (final operation in _activeTasks.values) {
      operation.cancel();
    }
    _activeTasks.clear();
    _preloadQueue.clear();
  }

  /// Cancel specific preload
  void cancel(String taskId) {
    final operation = _activeTasks[taskId];
    operation?.cancel();
    _activeTasks.remove(taskId);
  }

  // ====================================================================
  // PUBLIC API
  // ====================================================================

  /// Manually trigger preload for specific context
  Future<void> preloadContext(String contextId) async {
    if (contextId == 'personal') {
      await _preloadPersonalContext();
    } else {
      // Assume it's a group ID
      await _preloadGroupContext(contextId);
    }
  }

  /// Get preload statistics
  PreloadStats getStats() {
    return PreloadStats(
      activeTasksCount: _activeTasks.length,
      queuedTasksCount: _preloadQueue.length,
      completedTasksCount: _patternTracker.completedCount,
    );
  }

  // ====================================================================
  // LIFECYCLE
  // ====================================================================

  void dispose() {
    cancelAll();
    _contextManager.removeListener(_onContextChanged);
  }
}
```

### 2. Supporting Classes

```dart
/// Preload task with priority
class PreloadTask implements Comparable<PreloadTask> {
  final String id;
  final PreloadPriority priority;
  final Future<void> Function() action;
  final String description;
  final DateTime createdAt;

  PreloadTask({
    required this.id,
    required this.priority,
    required this.action,
    required this.description,
  }) : createdAt = DateTime.now();

  @override
  int compareTo(PreloadTask other) {
    // Higher priority first
    return other.priority.value.compareTo(priority.value);
  }
}

/// Preload priority levels
enum PreloadPriority {
  high(3),
  medium(2),
  low(1);

  final int value;
  const PreloadPriority(this.value);
}

/// Priority queue implementation
class PriorityQueue<T extends Comparable<T>> {
  final List<T> _items = [];

  void add(T item) {
    _items.add(item);
    _items.sort();
  }

  T removeFirst() {
    return _items.removeAt(0);
  }

  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  void clear() {
    _items.clear();
  }
}

/// Cancelable operation wrapper
class CancelableOperation<T> {
  final Future<T> future;
  bool _cancelled = false;
  final void Function()? onCancel;

  CancelableOperation(this.future, {this.onCancel});

  static CancelableOperation<T> fromFuture<T>(
    Future<T> future, {
    void Function()? onCancel,
  }) {
    return CancelableOperation(future, onCancel: onCancel);
  }

  void cancel() {
    _cancelled = true;
    onCancel?.call();
  }

  Future<T> get value async {
    if (_cancelled) throw CancelledException();
    return await future;
  }
}

class CancelledException implements Exception {}

/// Navigation pattern tracker
class NavigationPatternTracker {
  final List<NavigationEvent> _history = [];
  final Map<String, int> _routeFrequency = {};
  int completedCount = 0;

  void trackNavigation(String route) {
    _history.add(NavigationEvent(route, DateTime.now()));
    _routeFrequency[route] = (_routeFrequency[route] ?? 0) + 1;

    // Keep last 100 events
    if (_history.length > 100) {
      _history.removeAt(0);
    }
  }

  List<NavigationPrediction> predictNext() {
    // Simple prediction: most frequent route after current
    // (More sophisticated ML-based prediction could be implemented)

    if (_history.isEmpty) return [];

    final currentRoute = _history.last.route;
    final predictions = <NavigationPrediction>[];

    // Find routes that frequently follow current route
    for (int i = 0; i < _history.length - 1; i++) {
      if (_history[i].route == currentRoute) {
        final nextRoute = _history[i + 1].route;
        predictions.add(
          NavigationPrediction(nextRoute, confidence: 0.8),
        );
      }
    }

    return predictions;
  }
}

class NavigationEvent {
  final String route;
  final DateTime timestamp;

  NavigationEvent(this.route, this.timestamp);
}

class NavigationPrediction {
  final String route;
  final double confidence; // 0.0 - 1.0

  NavigationPrediction(this.route, {required this.confidence});
}

/// Preload statistics
class PreloadStats {
  final int activeTasksCount;
  final int queuedTasksCount;
  final int completedTasksCount;

  PreloadStats({
    required this.activeTasksCount,
    required this.queuedTasksCount,
    required this.completedTasksCount,
  });

  @override
  String toString() {
    return 'PreloadStats(active: $activeTasksCount, queued: $queuedTasksCount, completed: $completedTasksCount)';
  }
}
```

### 3. Integration Points

```dart
// lib/service/context_manager.dart

class ContextManager extends ChangeNotifier {
  // Add preload coordinator
  final _preloadCoordinator = SmartPreloadCoordinator();

  Future<void> initialize() async {
    // ... existing initialization ...

    // Initialize preload coordinator
    _preloadCoordinator.initialize();
  }

  void switchToGroup(ExpenseGroup group) {
    _currentContext = ExpenseContext.group(group);
    notifyListeners(); // This triggers _onContextChanged in coordinator!

    // Manual trigger (optional, automatic via listener)
    _preloadCoordinator.preloadContext(group.id);
  }

  // ... rest of implementation ...
}
```

```dart
// lib/views/expense_list.dart

class ExpenseList extends StatefulWidget {
  // ...
}

class _ExpenseListState extends State<ExpenseList> {
  final _preloadCoordinator = SmartPreloadCoordinator();

  @override
  void initState() {
    super.initState();

    // Trigger preload for this view
    _preloadCoordinator.preloadExpenseList();
  }

  // ... rest of implementation ...
}
```

---

## 📊 Performance Impact

### Scenario 1: User opens Group Details

**Before (No Preloading):**
```
User taps "Group Detail" button
  ↓
1. Navigate to page (instant)
2. Show loading spinner
3. Fetch group details (300ms)
4. Fetch member profiles (500ms)
5. Fetch recent expenses (800ms)
6. Render (100ms)
  ↓
Total: 1.7s (perceived latency)
```

**After (With Smart Preloading):**
```
User views Groups page
  ↓ (Preload coordinator predicts user will tap)
Background preload:
  - Group details (300ms)
  - Member profiles (500ms)
  - Recent expenses (800ms)
  ↓ (All cached BEFORE user taps!)

User taps "Group Detail" button
  ↓
1. Navigate to page (instant)
2. Load from cache (10ms)
3. Render (100ms)
  ↓
Total: 110ms (15x faster!)
```

### Scenario 2: User switches context Personal → Group

**Before:**
```
User switches to Group X
  ↓
1. Show loading spinner
2. Fetch expenses for group (800ms)
3. Fetch group members (500ms)
4. Calculate balances (200ms)
5. Render (100ms)
  ↓
Total: 1.6s
```

**After:**
```
User clicks context switcher
  ↓ (Preload coordinator starts immediately)
Background preload (parallel):
  - Expenses (800ms)
  - Members (500ms)
  - Balances (200ms)
  ↓ (Max 800ms due to parallel)

User selects "Group X"
  ↓
1. Load from cache (10ms)
2. Render (100ms)
  ↓
Total: 110ms (14x faster!)
```

### Metrics
- **Perceived latency**: ~95% reduction (1.5s → 100ms)
- **Loading spinners**: ~95% elimination
- **User satisfaction**: Significant improvement
- **Network overhead**: Minimal (10-20% increase, preload only likely needed data)

---

## 🎯 Preloading Strategies

### 1. Aggressive Preloading
- **When**: User has fast connection, WiFi
- **What**: Preload everything user might need
- **Pros**: Zero perceived latency
- **Cons**: More network usage

### 2. Conservative Preloading
- **When**: User on mobile data, slow connection
- **What**: Preload only high-probability items
- **Pros**: Minimal network usage
- **Cons**: Some loading still visible

### 3. Adaptive Preloading (Recommended)
- **When**: Always
- **What**: Adjust based on connection quality
- **How**:
  ```dart
  final connectionQuality = await getConnectionQuality();

  if (connectionQuality == ConnectionQuality.excellent) {
    // Aggressive: preload everything
    await _preloadAll();
  } else if (connectionQuality == ConnectionQuality.good) {
    // Normal: preload high priority
    await _preloadHighPriority();
  } else {
    // Conservative: preload only critical
    await _preloadCritical();
  }
  ```

---

## 🧪 Testing Strategy

### Unit Tests
```dart
test('Preload coordinator triggers on context switch', () async {
  final coordinator = SmartPreloadCoordinator();
  coordinator.initialize();

  // Switch to group
  contextManager.switchToGroup(testGroup);

  // Wait for preload
  await Future.delayed(Duration(milliseconds: 500));

  // Verify data was preloaded
  expect(expenseService.cacheSize, greaterThan(0));
  expect(groupService.cacheSize, greaterThan(0));
});

test('Preload queue respects priority', () async {
  final coordinator = SmartPreloadCoordinator();

  // Queue low priority task
  await coordinator._queuePreload(PreloadTask(
    id: 'low',
    priority: PreloadPriority.low,
    action: () async => print('Low'),
  ));

  // Queue high priority task
  await coordinator._queuePreload(PreloadTask(
    id: 'high',
    priority: PreloadPriority.high,
    action: () async => print('High'),
  ));

  // High should execute first
  // (Verify through logs or task tracking)
});
```

### Integration Tests
- Test preload on navigation
- Test preload cancellation
- Test network failure handling
- Test memory usage

---

## 🔍 Debugging & Monitoring

### Preload Debug Panel

```dart
/// Debug panel showing preload activity
class PreloadDebugPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final coordinator = SmartPreloadCoordinator();
    final stats = coordinator.getStats();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Preload Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Active tasks: ${stats.activeTasksCount}'),
            Text('Queued tasks: ${stats.queuedTasksCount}'),
            Text('Completed: ${stats.completedTasksCount}'),
          ],
        ),
      ),
    );
  }
}
```

### Logging

```dart
// Enable debug logging
const debugPreload = true;

void _logPreload(String message) {
  if (debugPreload) {
    print('[PRELOAD] $message');
  }
}
```

---

## 📝 Migration Checklist

- [ ] Create SmartPreloadCoordinator class
- [ ] Create PreloadTask and priority queue
- [ ] Integrate with ContextManager
- [ ] Add preload triggers to key views
- [ ] Implement pattern tracking
- [ ] Test preload on context switch
- [ ] Test preload on navigation
- [ ] Add adaptive preloading
- [ ] Add debug panel
- [ ] Measure performance impact
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Update documentation

---

## 🎯 Success Criteria

### Must Have
- ✅ Loading spinners reduced by 90%+
- ✅ Navigation feels instant (< 200ms)
- ✅ Preload doesn't block UI
- ✅ Works with existing cache framework

### Nice to Have
- ✅ Pattern-based prediction
- ✅ Adaptive preloading based on connection
- ✅ Debug panel for monitoring
- ✅ Analytics for preload effectiveness

---

## 🚀 Future Enhancements

### Machine Learning Predictions
- Use ML model to predict navigation
- Train on user behavior data
- Achieve 95%+ prediction accuracy

### Prefetching on Idle
- Detect when app is idle
- Prefetch data for likely next actions
- Use device sensors (e.g., user looking at screen)

### Background Sync
- Sync data in background (when app in background)
- Keep cache fresh even when app closed
- Use WorkManager (Android) / Background Fetch (iOS)

---

## 📚 References

- [Flutter Navigation Best Practices](https://flutter.dev/docs/cookbook/navigation)
- [Predictive Prefetching](https://web.dev/predictive-prefetching/)
- [Resource Hints](https://www.w3.org/TR/resource-hints/)

---

_Documento creato: 2026-01-14_
_Versione: 1.0_
_Autore: Claude Sonnet 4.5 + Alessio_
