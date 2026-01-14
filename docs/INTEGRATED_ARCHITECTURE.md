# 🏛️ Integrated Architecture - Persistent Cache + Smart Preloading

## 📋 Overview

Questo documento descrive l'**architettura integrata** del sistema completo di caching avanzato, combinando:
- ✅ **In-Memory Cache** (esistente)
- ✅ **Persistent Cache** (nuova feature)
- ✅ **Smart Preloading** (nuova feature)

---

## 🎯 Sistema Completo: Le Tre Layers

```
╔══════════════════════════════════════════════════════════════════╗
║                         APPLICATION LAYER                        ║
║  (Views, Widgets, Blocs)                                         ║
╚══════════════════════════════════════════════════════════════════╝
                                ▲
                                │ Read/Write
                                ▼
╔══════════════════════════════════════════════════════════════════╗
║                    SMART PRELOADING LAYER                        ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ SmartPreloadCoordinator                                    │ ║
║  │  • Context-aware preloading                                │ ║
║  │  • Route-based preloading                                  │ ║
║  │  • Pattern-based prediction                                │ ║
║  │  • Priority queue management                               │ ║
║  └────────────────────────────────────────────────────────────┘ ║
╚══════════════════════════════════════════════════════════════════╝
                                ▲
                                │ Trigger preload
                                ▼
╔══════════════════════════════════════════════════════════════════╗
║                      CACHED SERVICES LAYER                       ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ PersistentCacheableService<M, K>                           │ ║
║  │  extends CacheableService<M, K>                            │ ║
║  │                                                             │ ║
║  │  Services:                                                  │ ║
║  │  • ExpenseServiceCached                                    │ ║
║  │  • GroupServiceCached                                      │ ║
║  │  • ProfileServiceCached                                    │ ║
║  └────────────────────────────────────────────────────────────┘ ║
╚══════════════════════════════════════════════════════════════════╝
                                ▲
                 ┌──────────────┴──────────────┐
                 │                             │
                 ▼                             ▼
  ┌──────────────────────────┐   ┌──────────────────────────┐
  │   IN-MEMORY CACHE        │   │   PERSISTENT CACHE       │
  │  (Map<K, Entry<M>>)      │◄──┤    (Hive Boxes)          │
  │                          │   │                          │
  │  • Ultra-fast (O(1))     │   │  • Offline support       │
  │  • Volatile (RAM)        │   │  • Survives restarts     │
  │  • Current session       │   │  • Disk storage          │
  └──────────────────────────┘   └──────────────────────────┘
                 │                             │
                 └──────────────┬──────────────┘
                                ▼
                  ┌──────────────────────────┐
                  │   SYNC COORDINATOR       │
                  │  • Background sync       │
                  │  • Conflict resolution   │
                  │  • Network awareness     │
                  └──────────────────────────┘
                                │
                                ▼
                  ┌──────────────────────────┐
                  │   SUPABASE DATABASE      │
                  │  • PostgreSQL            │
                  │  • Realtime streams      │
                  └──────────────────────────┘
```

---

## 🔄 Data Flow: Complete Journey

### Scenario 1: App Cold Start (First Time)

```
User opens app for first time
  ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Initialize Persistent Cache                        │
└─────────────────────────────────────────────────────────────┘
  • Open Hive boxes (empty - first time)
  • In-memory cache: empty
  ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Fetch from Supabase                                │
└─────────────────────────────────────────────────────────────┘
  • Query expenses (800ms)
  • Query groups (500ms)
  • Query profiles (600ms)
  ↓ (Total: ~2s)
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Populate Both Caches                               │
└─────────────────────────────────────────────────────────────┘
  • Write to in-memory cache (instant)
  • Write to persistent cache (50ms)
  ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: Render UI                                          │
└─────────────────────────────────────────────────────────────┘
  • Read from in-memory cache (O(1))
  • Display data (100ms)
  ↓
Total time: ~2.1s (first time only!)
```

### Scenario 2: App Cold Start (Subsequent Times)

```
User opens app (not first time)
  ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Initialize Persistent Cache                        │
└─────────────────────────────────────────────────────────────┘
  • Open Hive boxes (50ms)
  • Load data from Hive → In-memory cache (50ms)
  ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Render UI IMMEDIATELY                              │
└─────────────────────────────────────────────────────────────┘
  • Read from in-memory cache (O(1))
  • Display data (100ms)
  ↓
Total time: ~150ms (instant!) 🚀
  ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Background Sync (User doesn't wait)                │
└─────────────────────────────────────────────────────────────┘
  • Check for updates on Supabase
  • Update caches if needed
  • User doesn't see loading spinner!
```

### Scenario 3: User Navigation with Smart Preloading

```
User is on Expense List page
  ↓
┌─────────────────────────────────────────────────────────────┐
│ Smart Preload: Predict User Will Tap First Expense         │
└─────────────────────────────────────────────────────────────┘
  ↓ (Background - doesn't block UI)
  • Preload expense details
  • Preload payer profile
  • Preload participant profiles
  • Preload group details (if group expense)
  ↓ (All cached BEFORE user taps!)
┌─────────────────────────────────────────────────────────────┐
│ User Taps Expense                                           │
└─────────────────────────────────────────────────────────────┘
  ↓
  • Navigate to details page (instant)
  • Load from cache (O(1) - 10ms)
  • Render (100ms)
  ↓
Total time: ~110ms (feels instant!) 🚀
```

### Scenario 4: Offline Mode

```
User opens app (no internet connection)
  ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Load from Persistent Cache                         │
└─────────────────────────────────────────────────────────────┘
  • Open Hive boxes (50ms)
  • Load data → In-memory cache (50ms)
  ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Render UI                                          │
└─────────────────────────────────────────────────────────────┘
  • App works 100% offline!
  • No "No Connection" error
  ↓
┌─────────────────────────────────────────────────────────────┐
│ User Creates Expense Offline                                │
└─────────────────────────────────────────────────────────────┘
  • Write to in-memory cache (instant)
  • Write to persistent cache (50ms)
  • Mark as "dirty" (needs sync)
  • UI updates immediately
  ↓
┌─────────────────────────────────────────────────────────────┐
│ User Reconnects to Internet                                 │
└─────────────────────────────────────────────────────────────┘
  • Sync coordinator detects connection
  • Push "dirty" items to Supabase
  • Mark as synced
  • User doesn't notice sync happening!
```

---

## 🧩 Component Integration

### 1. PersistentCacheableService + SmartPreloadCoordinator

```dart
/// ExpenseServiceCached with both persistent cache and smart preloading
class ExpenseServiceCached extends PersistentCacheableService<Expense, int> {
  // Singleton
  static final ExpenseServiceCached _instance = ExpenseServiceCached._internal();
  factory ExpenseServiceCached() => _instance;

  ExpenseServiceCached._internal()
      : super(
          config: CacheConfig.dynamic,
          persistentConfig: PersistentCacheConfig.dynamic,
        ) {
    CacheManager.instance.register('expenses', this);
  }

  @override
  String get boxName => 'expenses_cache';

  /// Preload method called by SmartPreloadCoordinator
  Future<void> preloadForGroup(String groupId) async {
    // This method is called by preload coordinator BEFORE user navigates
    print('📦 Preloading expenses for group: $groupId');

    // Fetch expenses for this group
    final expenses = await fetchAll(); // Uses cache if available

    // Filter by group
    final groupExpenses = expenses.where((e) => e.groupId == groupId).toList();

    // Ensure all in cache
    putManyInCache(groupExpenses);

    // Preload related data (profiles, balances)
    await _preloadRelatedData(groupExpenses);
  }

  Future<void> _preloadRelatedData(List<Expense> expenses) async {
    // Collect user IDs from expenses
    final userIds = <String>{};
    for (final expense in expenses) {
      if (expense.payerId != null) userIds.add(expense.payerId!);
      if (expense.paidFor != null) userIds.addAll(expense.paidFor!);
    }

    // Preload profiles
    await ProfileServiceCached().preloadProfiles(userIds.toList());

    // Preload balance calculations
    await calculateBulkUserBalances(expenses);
  }

  // ... rest of implementation (CRUD, etc.) ...
}
```

### 2. Integration in ContextManager

```dart
class ContextManager extends ChangeNotifier {
  final _preloadCoordinator = SmartPreloadCoordinator();

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Initialize persistent caches
      await Future.wait([
        ExpenseServiceCached().initPersistentCache(),
        GroupServiceCached().initPersistentCache(),
        ProfileServiceCached().initPersistentCache(),
      ]);

      // 2. Load user data (instant from persistent cache!)
      await loadUserGroups();
      await loadUserViews();
      await loadGroupPreferences();

      // 3. Initialize smart preloading
      _preloadCoordinator.initialize();

      // 4. Restore last context
      await restoreLastContext();

      // 5. Background sync (user doesn't wait)
      _syncInBackground();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchToGroup(ExpenseGroup group) {
    _currentContext = ExpenseContext.group(group);
    notifyListeners(); // Triggers preload coordinator listener!

    // Context change triggers automatic preload in SmartPreloadCoordinator
  }

  Future<void> _syncInBackground() async {
    // Background sync - user doesn't see loading
    await Future.wait([
      ExpenseServiceCached()._syncInBackground(),
      GroupServiceCached()._syncInBackground(),
      ProfileServiceCached()._syncInBackground(),
    ]);
  }
}
```

### 3. Integration in Views

```dart
class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final _expenseService = ExpenseServiceCached();
  final _preloadCoordinator = SmartPreloadCoordinator();

  @override
  void initState() {
    super.initState();

    // Trigger smart preload for this view
    _preloadCoordinator.preloadExpenseList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // This will rarely be shown due to persistent cache + preloading!
            return CircularProgressIndicator();
          }

          final expenses = snapshot.data!;

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];

              return ExpenseListItemOptimized(
                expense: expense,
                onTap: () {
                  // User taps expense
                  // Data is already preloaded! 🚀
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpenseDetailPage(expense: expense),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 🎨 Cache Hierarchy & Priorities

### Read Priority (Fastest to Slowest)

```
1. IN-MEMORY CACHE (O(1) - ~1ms)
   ↓ Cache miss
2. PERSISTENT CACHE (Hive read - ~10ms)
   ↓ Cache miss or expired
3. PRELOADED DATA (Smart preload - ~50ms)
   ↓ Not preloaded
4. SUPABASE QUERY (Network - ~500-1000ms)
```

### Write Strategy

```
User creates/updates data
  ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. UPDATE IN-MEMORY CACHE (instant)                        │
└─────────────────────────────────────────────────────────────┘
  ↓ UI updates immediately
┌─────────────────────────────────────────────────────────────┐
│ 2. UPDATE PERSISTENT CACHE (50ms)                          │
│    Mark as "dirty" (needs sync)                            │
└─────────────────────────────────────────────────────────────┘
  ↓ Data safe on disk
┌─────────────────────────────────────────────────────────────┐
│ 3. SYNC TO SUPABASE (background - 500ms)                   │
│    Mark as "clean" on success                              │
└─────────────────────────────────────────────────────────────┘
  ↓ User doesn't wait for this!
```

---

## 📊 Performance Matrix

| Scenario | Without System | With System | Improvement |
|----------|----------------|-------------|-------------|
| Cold start (first time) | 4s | 2.1s | 1.9x faster |
| Cold start (subsequent) | 2s | 150ms | **13.3x faster** 🚀 |
| Context switch | 1.6s | 110ms | **14.5x faster** 🚀 |
| Navigation to details | 1.7s | 110ms | **15.4x faster** 🚀 |
| Offline mode | ❌ Doesn't work | ✅ 100% functional | **Infinite improvement** |
| Network usage | 100% | 10-15% | **85-90% reduction** |
| Loading spinners | Every navigation | ~5% of navigations | **95% reduction** |

---

## 🧪 Testing Strategy

### 1. Unit Tests

```dart
// Test persistent cache survives restart
test('Persistent cache + preload integration', () async {
  // 1. Create expense
  await expenseService.create(testExpense);

  // 2. Simulate app restart
  await expenseService.dispose();
  await expenseService.initPersistentCache();

  // 3. Verify loaded from persistent cache
  expect(expenseService.cacheSize, greaterThan(0));

  // 4. Trigger preload
  await preloadCoordinator.preloadContext('personal');

  // 5. Verify preload used cached data (no network call)
  // (Monitor network calls)
});
```

### 2. Integration Tests

```dart
// Test complete flow: persistent cache → preload → navigation
testWidgets('Complete flow test', (tester) async {
  // 1. Start app
  await tester.pumpWidget(SolducciApp());
  await tester.pumpAndSettle();

  // 2. Verify instant load (persistent cache)
  expect(find.byType(CircularProgressIndicator), findsNothing);

  // 3. Navigate to expense list
  await tester.tap(find.text('Spese'));
  await tester.pumpAndSettle();

  // 4. Wait for preload (should be instant)
  await Future.delayed(Duration(milliseconds: 100));

  // 5. Tap first expense
  await tester.tap(find.byType(ExpenseListItem).first);
  await tester.pumpAndSettle();

  // 6. Verify instant navigation (preloaded data)
  expect(find.byType(ExpenseDetailPage), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

### 3. Performance Tests

```dart
// Measure cold start time
test('Cold start performance', () async {
  final stopwatch = Stopwatch()..start();

  // Initialize system
  await _initializeCaching();

  stopwatch.stop();

  // Should be < 200ms on subsequent starts
  expect(stopwatch.elapsedMilliseconds, lessThan(200));
});
```

---

## 🔧 Configuration Options

### Aggressive Configuration (Best UX, More Resources)

```dart
// For devices with good connection + storage
PersistentCacheConfig.aggressive = PersistentCacheConfig(
  ttl: Duration(days: 30), // Long TTL
  enableSync: true,
  syncInterval: Duration(minutes: 1), // Frequent sync
  encrypt: false,
);

SmartPreloadConfig.aggressive = SmartPreloadConfig(
  enableContextPreload: true,
  enableRoutePreload: true,
  enablePatternPreload: true,
  preloadDepth: 3, // Preload deeply nested data
);
```

### Balanced Configuration (Recommended)

```dart
// Default configuration
PersistentCacheConfig.balanced = PersistentCacheConfig(
  ttl: Duration(days: 7),
  enableSync: true,
  syncInterval: Duration(minutes: 5),
  encrypt: false,
);

SmartPreloadConfig.balanced = SmartPreloadConfig(
  enableContextPreload: true,
  enableRoutePreload: true,
  enablePatternPreload: false, // Disable ML prediction
  preloadDepth: 2,
);
```

### Conservative Configuration (Low Resources)

```dart
// For low-end devices or slow connections
PersistentCacheConfig.conservative = PersistentCacheConfig(
  ttl: Duration(days: 3), // Short TTL
  enableSync: true,
  syncInterval: Duration(minutes: 15), // Less frequent
  encrypt: false,
);

SmartPreloadConfig.conservative = SmartPreloadConfig(
  enableContextPreload: true,
  enableRoutePreload: false, // Disable route preload
  enablePatternPreload: false,
  preloadDepth: 1, // Shallow preload
);
```

---

## 📝 Migration Path

### Phase 1: Persistent Cache (Week 1-2)
1. Install Hive dependencies
2. Create type adapters
3. Implement PersistentCacheableService
4. Migrate services
5. Test offline mode
6. Test sync

### Phase 2: Smart Preloading (Week 3-4)
1. Create SmartPreloadCoordinator
2. Implement context-based preload
3. Implement route-based preload
4. Integrate with ContextManager
5. Add preload triggers to views
6. Test preload effectiveness

### Phase 3: Integration & Optimization (Week 5)
1. Integrate both systems
2. Performance testing
3. Memory profiling
4. Network optimization
5. Conflict resolution
6. Edge case handling

---

## 🎯 Success Metrics

### Primary KPIs
- ✅ **Cold start time**: < 200ms (target)
- ✅ **Offline mode**: 100% functional
- ✅ **Perceived latency**: < 100ms (target)
- ✅ **Loading spinners**: < 5% of navigations

### Secondary KPIs
- ✅ Network usage: 85-90% reduction
- ✅ Battery impact: 80% reduction
- ✅ Storage usage: < 10MB
- ✅ User satisfaction: > 90%

---

## 📚 Documentation

- [Persistent Cache Analysis](./PERSISTENT_CACHE_ANALYSIS.md)
- [Smart Preloading Analysis](./SMART_PRELOADING_ANALYSIS.md)
- [Implementation Plan](./IMPLEMENTATION_PLAN.md)
- [Agent Specifications](./AGENT_SPECIFICATIONS.md)

---

_Documento creato: 2026-01-14_
_Versione: 1.0_
_Autore: Claude Sonnet 4.5 + Alessio_
