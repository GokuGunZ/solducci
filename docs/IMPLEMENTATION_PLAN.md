# 🚀 Implementation Plan - Persistent Cache + Smart Preloading

## 📋 Overview

Piano di implementazione **step-by-step** per integrare Persistent Cache e Smart Preloading nel progetto Solducci.

**Timeline totale**: 5 settimane
**Effort stimato**: ~80-100 ore
**Difficoltà**: 🟡 Media-Alta

---

## 🎯 Obiettivi per Fase

### Phase 1: Persistent Cache (Settimane 1-2)
- ✅ Setup Hive e type adapters
- ✅ Implementare PersistentCacheableService
- ✅ Migrare i 3 servizi cached
- ✅ Testing offline mode

### Phase 2: Smart Preloading (Settimane 3-4)
- ✅ Implementare SmartPreloadCoordinator
- ✅ Context-aware preloading
- ✅ Route-based preloading
- ✅ Integration testing

### Phase 3: Integration & Polish (Settimana 5)
- ✅ Integrazione completa
- ✅ Performance optimization
- ✅ Bug fixing & edge cases
- ✅ Documentation

---

## 📅 Phase 1: Persistent Cache (Settimane 1-2)

### Week 1, Day 1: Setup & Dependencies

#### Task 1.1: Install Hive Dependencies
**Effort**: 15 min

```yaml
# pubspec.yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.0  # For getting app directory

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

**Commands**:
```bash
flutter pub add hive hive_flutter path_provider
flutter pub add --dev hive_generator build_runner
flutter pub get
```

**Verification**:
- Run `flutter pub get` successfully
- No dependency conflicts

---

#### Task 1.2: Create Hive Type Adapters
**Effort**: 1-2 hours

**File**: `lib/core/cache/hive_adapters.dart`

```dart
import 'package:hive/hive.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/user_profile.dart';
import 'package:solducci/models/group.dart';

/// Register all Hive type adapters
Future<void> registerHiveAdapters() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(ExpenseGroupAdapter());
  Hive.registerAdapter(PersistentCacheEntryAdapter());

  print('✅ Hive adapters registered');
}
```

**Generate Adapters**:

1. Add annotations to models:

```dart
// lib/models/expense.dart
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
class Expense extends CacheableModel<int> {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final Tipologia type;

  @HiveField(5)
  final String? payerId;

  @HiveField(6)
  final List<String>? paidFor;

  @HiveField(7)
  final String? groupId;

  @HiveField(8)
  final bool isGroup;

  // ... rest of class ...
}
```

2. Run code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Verification**:
- Generated files: `expense.g.dart`, `user_profile.g.dart`, `group.g.dart`
- No compilation errors

---

#### Task 1.3: Create PersistentCacheEntry
**Effort**: 30 min

**File**: `lib/core/cache/persistent_cache_entry.dart`

```dart
import 'package:hive/hive.dart';

part 'persistent_cache_entry.g.dart';

/// Wrapper for cached items with metadata
@HiveType(typeId: 0)
class PersistentCacheEntry<M> {
  @HiveField(0)
  final M data;

  @HiveField(1)
  final DateTime cachedAt;

  @HiveField(2)
  final DateTime lastSyncedAt;

  @HiveField(3)
  final bool dirty;

  @HiveField(4)
  final int version;

  PersistentCacheEntry({
    required this.data,
    required this.cachedAt,
    required this.lastSyncedAt,
    this.dirty = false,
    this.version = 1,
  });

  PersistentCacheEntry<M> markDirty() {
    return PersistentCacheEntry(
      data: data,
      cachedAt: cachedAt,
      lastSyncedAt: lastSyncedAt,
      dirty: true,
      version: version + 1,
    );
  }

  PersistentCacheEntry<M> markSynced() {
    return PersistentCacheEntry(
      data: data,
      cachedAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
      dirty: false,
      version: version,
    );
  }
}
```

**Verification**:
- Generate: `flutter pub run build_runner build`
- No errors

---

### Week 1, Days 2-3: Core Implementation

#### Task 1.4: Create PersistentCacheConfig
**Effort**: 30 min

**File**: `lib/core/cache/persistent_cache_config.dart`

```dart
/// Configuration for persistent cache behavior
class PersistentCacheConfig {
  final Duration? ttl;
  final bool enableSync;
  final Duration syncInterval;
  final bool encrypt;

  const PersistentCacheConfig({
    this.ttl,
    this.enableSync = true,
    this.syncInterval = const Duration(minutes: 5),
    this.encrypt = false,
  });

  static const PersistentCacheConfig defaultConfig = PersistentCacheConfig(
    ttl: Duration(days: 7),
    enableSync: true,
  );

  static const PersistentCacheConfig stable = PersistentCacheConfig(
    ttl: Duration(days: 30),
    enableSync: true,
    syncInterval: Duration(minutes: 10),
  );

  static const PersistentCacheConfig dynamic = PersistentCacheConfig(
    ttl: Duration(days: 7),
    enableSync: true,
    syncInterval: Duration(minutes: 1),
  );
}
```

---

#### Task 1.5: Create PersistentCacheableService
**Effort**: 3-4 hours

**File**: `lib/core/cache/persistent_cacheable_service.dart`

Implementare l'abstract class seguendo la specifica in [PERSISTENT_CACHE_ANALYSIS.md](./PERSISTENT_CACHE_ANALYSIS.md#2-persistentcacheableservice-abstract-class).

**Key Methods**:
- `initPersistentCache()`
- `_loadFromPersistentCache()`
- `_saveToPersistentCache()`
- `_syncInBackground()`
- `getDirtyItems()`

**Verification**:
- Compilation successful
- No type errors

---

### Week 1, Days 4-5: Service Migration

#### Task 1.6: Migrate ExpenseServiceCached
**Effort**: 2 hours

**File**: `lib/service/expense_service_cached.dart`

**Changes**:
1. Change extends clause:
```dart
// Before
class ExpenseServiceCached extends CacheableService<Expense, int> {

// After
class ExpenseServiceCached extends PersistentCacheableService<Expense, int> {
```

2. Add boxName:
```dart
@override
String get boxName => 'expenses_cache';
```

3. Update constructor:
```dart
ExpenseServiceCached._internal()
    : super(
        config: CacheConfig.dynamic,
        persistentConfig: PersistentCacheConfig.dynamic,
      ) {
  CacheManager.instance.register('expenses', this);
}
```

**Verification**:
- Compilation successful
- Run existing tests (should still pass)

---

#### Task 1.7: Migrate GroupServiceCached
**Effort**: 1.5 hours

Similar to Task 1.6, but for `GroupServiceCached`.

**Box name**: `'groups_cache'`
**Config**: `PersistentCacheConfig.stable`

---

#### Task 1.8: Migrate ProfileServiceCached
**Effort**: 1.5 hours

Similar to Task 1.6, but for `ProfileServiceCached`.

**Box name**: `'profiles_cache'`
**Config**: `PersistentCacheConfig.stable`

---

### Week 2: Testing & Refinement

#### Task 1.9: Update Main Initialization
**Effort**: 1 hour

**File**: `lib/main.dart`

```dart
Future<void> _initializeCaching() async {
  // 1. Register Hive adapters
  await registerHiveAdapters();

  // 2. Initialize services
  final expenseService = ExpenseServiceCached();
  final groupService = GroupServiceCached();
  final profileService = ProfileServiceCached();

  // 3. Initialize persistent caches
  await Future.wait([
    expenseService.initPersistentCache(),
    groupService.initPersistentCache(),
    profileService.initPersistentCache(),
  ]);

  // 4. Setup cross-service invalidation
  CacheManager.instance.registerInvalidationRule('expenses', ['groups']);

  // 5. Preload
  await Future.wait([
    expenseService.ensureInitialized(),
    groupService.ensureInitialized(),
    profileService.ensureInitialized(),
  ]);

  debugPrint('✅ Persistent caching framework initialized');
}
```

**Verification**:
- App starts successfully
- Check logs for "Persistent caching framework initialized"

---

#### Task 1.10: Unit Tests for Persistent Cache
**Effort**: 3-4 hours

**File**: `test/persistent_cache_test.dart`

```dart
void main() {
  group('Persistent Cache Tests', () {
    test('Save and load from persistent cache', () async {
      final service = ExpenseServiceCached();
      await service.initPersistentCache();

      // Create expense
      final expense = Expense(/* ... */);
      await service.create(expense);

      // Verify in persistent cache
      expect(service.persistentCacheSize, equals(1));

      // Dispose and reinit (simulate restart)
      await service.dispose();
      await service.initPersistentCache();

      // Verify data survived
      final loaded = await service.getById(expense.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, equals(expense.id));
    });

    test('Dirty items marked correctly', () async {
      // TODO: Test dirty flag
    });

    test('TTL expiration works', () async {
      // TODO: Test TTL
    });
  });
}
```

**Run Tests**:
```bash
flutter test test/persistent_cache_test.dart
```

---

#### Task 1.11: Integration Test - Offline Mode
**Effort**: 2 hours

**File**: `integration_test/offline_mode_test.dart`

```dart
void main() {
  testWidgets('App works offline', (tester) async {
    // 1. Start app with network
    await tester.pumpWidget(SolducciApp());
    await tester.pumpAndSettle();

    // 2. Create expense
    // ... (interact with UI)

    // 3. Simulate offline (disable network)
    // (Use dev tools or mock)

    // 4. Restart app
    await tester.pumpWidget(SolducciApp());
    await tester.pumpAndSettle();

    // 5. Verify data still visible
    expect(find.text('Test Expense'), findsOneWidget);
  });
}
```

---

#### Task 1.12: Performance Benchmarks
**Effort**: 2 hours

Misurare le performance:

```dart
void main() {
  test('Cold start performance', () async {
    final stopwatch = Stopwatch()..start();

    await _initializeCaching();

    stopwatch.stop();
    print('Cold start time: ${stopwatch.elapsedMilliseconds}ms');

    // Should be < 200ms on subsequent starts
    expect(stopwatch.elapsedMilliseconds, lessThan(200));
  });
}
```

**Metrics to Collect**:
- Cold start time (first run): target < 2s
- Cold start time (subsequent): target < 200ms
- Persistent cache size: expect < 5MB
- Memory usage: monitor with DevTools

---

## 📅 Phase 2: Smart Preloading (Settimane 3-4)

### Week 3, Days 1-2: Core Coordinator

#### Task 2.1: Create Supporting Classes
**Effort**: 2 hours

**Files**:
- `lib/core/preload/preload_task.dart`
- `lib/core/preload/preload_priority.dart`
- `lib/core/preload/priority_queue.dart`
- `lib/core/preload/cancelable_operation.dart`

Implementare seguendo le specifiche in [SMART_PRELOADING_ANALYSIS.md](./SMART_PRELOADING_ANALYSIS.md#2-supporting-classes).

---

#### Task 2.2: Create SmartPreloadCoordinator
**Effort**: 4-5 hours

**File**: `lib/core/preload/smart_preload_coordinator.dart`

Implementare la classe principale seguendo la specifica completa nel documento di analisi.

**Key Methods**:
- `initialize()`
- `_onContextChanged()`
- `_preloadPersonalContext()`
- `_preloadGroupContext()`
- `_queuePreload()`
- `_processQueue()`

---

### Week 3, Days 3-5: Context-Based Preloading

#### Task 2.3: Implement Context-Based Preloading
**Effort**: 3 hours

Implementare i metodi:
- `_preloadPersonalContext()`
- `_preloadGroupContext(String groupId)`
- `_preloadViewContext(List<String> groupIds)`

**Verification**:
- Log preload activity
- Verify correct data preloaded

---

#### Task 2.4: Integrate with ContextManager
**Effort**: 1 hour

**File**: `lib/service/context_manager.dart`

```dart
class ContextManager extends ChangeNotifier {
  final _preloadCoordinator = SmartPreloadCoordinator();

  Future<void> initialize() async {
    // ... existing code ...

    // Initialize preload coordinator
    _preloadCoordinator.initialize();
  }

  void switchToGroup(ExpenseGroup group) {
    _currentContext = ExpenseContext.group(group);
    notifyListeners(); // Triggers preload!
  }
}
```

---

### Week 4, Days 1-3: Route-Based Preloading

#### Task 2.5: Implement Route-Based Preloading
**Effort**: 4 hours

Implementare i metodi:
- `preloadExpenseList()`
- `_preloadExpenseDetails(int expenseId)`
- `preloadGroupDetails(String groupId)`

---

#### Task 2.6: Add Preload Triggers to Views
**Effort**: 2-3 hours

**Files to modify**:
- `lib/views/expense_list.dart`
- `lib/views/groups/group_detail_page.dart`

```dart
// Example: expense_list.dart
class _ExpenseListState extends State<ExpenseList> {
  final _preloadCoordinator = SmartPreloadCoordinator();

  @override
  void initState() {
    super.initState();
    _preloadCoordinator.preloadExpenseList();
  }
}
```

---

### Week 4, Days 4-5: Testing

#### Task 2.7: Unit Tests for Smart Preload
**Effort**: 3 hours

**File**: `test/smart_preload_test.dart`

```dart
void main() {
  group('Smart Preload Tests', () {
    test('Context change triggers preload', () async {
      // TODO
    });

    test('Priority queue works correctly', () async {
      // TODO
    });

    test('Preload cancellation works', () async {
      // TODO
    });
  });
}
```

---

#### Task 2.8: Integration Test - Preload Effectiveness
**Effort**: 2 hours

Verificare che il preload riduca effettivamente la latenza:

```dart
testWidgets('Navigation is instant with preload', (tester) async {
  // 1. Navigate to expense list
  // 2. Wait for preload
  // 3. Tap expense
  // 4. Measure navigation time
  // 5. Expect < 200ms
});
```

---

## 📅 Phase 3: Integration & Polish (Settimana 5)

### Week 5, Days 1-2: Integration

#### Task 3.1: Full System Integration
**Effort**: 3-4 hours

Verificare che Persistent Cache e Smart Preloading lavorino insieme:

1. Test cold start with preload
2. Test offline mode with preload
3. Test sync after preload
4. Test edge cases

---

#### Task 3.2: Performance Optimization
**Effort**: 3 hours

Profilare e ottimizzare:
- Memory usage (DevTools)
- Network usage (Charles Proxy)
- Battery usage (Battery Historian)

**Tools**:
```bash
# Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Performance overlay
flutter run --profile
```

---

### Week 5, Days 3-4: Bug Fixing

#### Task 3.3: Edge Case Handling
**Effort**: 4 hours

Testare e fixare edge cases:
- [ ] Sync conflict resolution
- [ ] Network timeout handling
- [ ] Memory pressure handling
- [ ] Storage quota exceeded
- [ ] Corrupted cache recovery

---

#### Task 3.4: User Testing
**Effort**: 2-3 hours

Test con utenti reali:
1. Beta testing con 5-10 utenti
2. Raccogliere feedback
3. Monitorare crash reports
4. Misurare performance metrics

---

### Week 5, Day 5: Documentation & Release

#### Task 3.5: Update Documentation
**Effort**: 2 hours

Aggiornare:
- [ ] README.md
- [ ] CHANGELOG.md
- [ ] API documentation
- [ ] User guide

---

#### Task 3.6: Release Preparation
**Effort**: 2 hours

```bash
# 1. Update version
# pubspec.yaml: version: 2.0.0+1

# 2. Run all tests
flutter test

# 3. Build release
flutter build apk --release

# 4. Create git tag
git tag -a v2.0.0 -m "Persistent Cache + Smart Preloading"
git push origin v2.0.0

# 5. Deploy to stores
# (Google Play, App Store)
```

---

## 📊 Timeline Summary

| Phase | Duration | Effort | Key Deliverables |
|-------|----------|--------|------------------|
| Phase 1: Persistent Cache | 2 weeks | 30-40h | Working offline mode, data persistence |
| Phase 2: Smart Preloading | 2 weeks | 25-30h | Context-aware preloading, instant navigation |
| Phase 3: Integration | 1 week | 15-20h | Polish, testing, release |
| **TOTAL** | **5 weeks** | **70-90h** | **Complete system** |

---

## ✅ Checklist Finale

### Persistent Cache
- [ ] Hive dependencies installed
- [ ] Type adapters created and generated
- [ ] PersistentCacheableService implemented
- [ ] All 3 services migrated
- [ ] Main initialization updated
- [ ] Offline mode tested
- [ ] Sync tested
- [ ] Performance benchmarked

### Smart Preloading
- [ ] SmartPreloadCoordinator implemented
- [ ] Context-based preload working
- [ ] Route-based preload working
- [ ] Integration with ContextManager
- [ ] Preload triggers added to views
- [ ] Priority queue tested
- [ ] Cancellation tested
- [ ] Performance verified

### Integration
- [ ] Both systems working together
- [ ] Cold start < 200ms
- [ ] Offline mode 100% functional
- [ ] Loading spinners < 5%
- [ ] Network usage reduced 85%+
- [ ] No memory leaks
- [ ] All tests passing
- [ ] Documentation updated

---

## 🎯 Success Criteria

### Must Have (P0)
- ✅ App opens in < 200ms (subsequent starts)
- ✅ App works 100% offline
- ✅ Data syncs automatically when online
- ✅ No data loss on app restart
- ✅ All existing tests pass

### Should Have (P1)
- ✅ Loading spinners reduced by 90%+
- ✅ Navigation feels instant
- ✅ Network usage reduced 80%+
- ✅ Memory usage stable

### Nice to Have (P2)
- ✅ Pattern-based prediction
- ✅ Adaptive preloading
- ✅ Debug panel
- ✅ Analytics tracking

---

## 🚨 Risk Mitigation

### High Risk Areas
1. **Hive Migration Issues**
   - Mitigation: Thorough testing on multiple devices
   - Fallback: Keep old service implementations

2. **Sync Conflicts**
   - Mitigation: Last-write-wins strategy
   - Fallback: Manual conflict resolution UI

3. **Memory Issues**
   - Mitigation: Aggressive cache limits
   - Fallback: Disable preloading on low-memory devices

4. **Performance Regression**
   - Mitigation: Continuous benchmarking
   - Fallback: Feature flags to disable preload

---

## 📞 Support & Resources

### Documentation
- [Persistent Cache Analysis](./PERSISTENT_CACHE_ANALYSIS.md)
- [Smart Preloading Analysis](./SMART_PRELOADING_ANALYSIS.md)
- [Integrated Architecture](./INTEGRATED_ARCHITECTURE.md)

### External Resources
- [Hive Documentation](https://docs.hivedb.dev/)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf)
- [Connectivity Plus Package](https://pub.dev/packages/connectivity_plus)

---

_Documento creato: 2026-01-14_
_Versione: 1.0_
_Timeline: 5 settimane_
_Effort: 70-90 ore_
