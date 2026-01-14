# 📋 Piano di Implementazione Framework di Caching

> **NOTA**: Questo documento è temporaneo e andrà eliminato una volta completata l'implementazione.

## 🎯 Obiettivi

1. ✅ Ridurre latenza nelle operazioni di lettura (cache in-memory)
2. ✅ Eliminare query ripetute al database
3. ✅ Migliorare UX con dati immediatamente disponibili
4. ✅ Ottimizzare rendering liste (balance calculations)
5. ✅ Preparare architettura scalabile per futuri modelli

## 📐 Architettura del Framework

### Core Components

```
lib/core/cache/
├── cacheable_model.dart      ✅ COMPLETATO - Interface per modelli cacheabili
├── cacheable_service.dart    ✅ COMPLETATO - Classe astratta per servizi con cache
├── cache_config.dart         ✅ COMPLETATO - Configurazione e strategie di eviction
└── cache_manager.dart        ✅ COMPLETATO - Manager centralizzato per coordinate caches
```

### Implementazioni

```
lib/models/
├── expense.dart              ✅ COMPLETATO - Implements CacheableModel<int>
├── group.dart                ✅ COMPLETATO - Implements CacheableModel<String>
└── user_profile.dart         ✅ COMPLETATO - Implements CacheableModel<String>

lib/service/
├── expense_service_cached.dart   ✅ COMPLETATO - Extends CacheableService
├── group_service_cached.dart     ✅ COMPLETATO - Extends CacheableService
└── profile_service_cached.dart   ⏳ DA COMPLETARE
```

---

## 🚀 Fasi di Implementazione

### ✅ FASE 1: Framework Base (COMPLETATA)

**Obiettivo**: Creare le fondamenta del sistema di caching

**Deliverables**:
- [x] `CacheableModel<K>` - Interface per modelli
- [x] `CacheableService<M, K>` - Classe astratta per servizi
- [x] `CacheConfig` - Configurazione cache (TTL, maxSize, eviction)
- [x] `CacheManager` - Coordinamento globale
- [x] `CacheStats` - Statistiche e monitoring

**Caratteristiche Implementate**:
- Eviction strategies: LRU, LFU, FIFO
- TTL (Time-To-Live) automatico
- Cache statistics tracking
- Stream support per notifiche di cambiamenti
- Invalidazione cross-service

---

### ✅ FASE 2: Implementazione Modelli (COMPLETATA)

**Obiettivo**: Integrare i modelli esistenti con il framework

#### 2.1 Expense Model
```dart
class Expense implements CacheableModel<int> {
  @override
  int get cacheKey => id;

  @override
  DateTime? get lastModified => date;

  @override
  Expense copyWith({...}) { ... }
}
```

**Benefici**:
- Cache lookup O(1) per expense ID
- Immutabilità garantita tramite copyWith()
- TTL based su data spesa

#### 2.2 ExpenseGroup Model
```dart
class ExpenseGroup implements CacheableModel<String> {
  @override
  String get cacheKey => id;  // UUID

  @override
  DateTime? get lastModified => updatedAt;
}
```

**Benefici**:
- Fast group name lookups per UI
- Member list caching
- Invalidazione automatica su update

#### 2.3 UserProfile Model
```dart
class UserProfile implements CacheableModel<String> {
  @override
  String get cacheKey => id;

  @override
  DateTime? get lastModified => updatedAt;
}
```

**Benefici**:
- Profile data immediately available
- Reduced avatar/nickname fetches

---

### ✅ FASE 3: Implementazione Servizi (80% COMPLETATA)

#### 3.1 ✅ ExpenseServiceCached

**Implementato**:
```dart
class ExpenseServiceCached extends CacheableService<Expense, int> {
  // Config ottimizzato per dati dinamici
  ExpenseServiceCached._internal() : super(config: CacheConfig.dynamic);

  // Cache aggiuntive per ottimizzazioni specifiche
  final Map<int, List<ExpenseSplit>> _splitsCache = {};
  final Map<int, double> _userBalanceCache = {};

  // Bulk operations
  Future<Map<int, double>> calculateBulkUserBalances(List<Expense> expenses);
}
```

**Ottimizzazioni Chiave**:
1. **Splits Caching**: `_splitsCache` - Elimina fetch ripetute di expense_splits
2. **Balance Caching**: `_userBalanceCache` - O(1) lookup invece di query
3. **Bulk Calculations**: Batch query per multiple expenses
4. **Stream Integration**: Cache auto-popolata da Supabase stream

**Performance Impact**:
- **Prima**: N queries per N expense items in lista (O(n))
- **Dopo**: 1 bulk query + cache lookups (O(1) per item successivo)
- **Stima**: ~90% riduzione query per expense lists

#### 3.2 ✅ GroupServiceCached

**Implementato**:
```dart
class GroupServiceCached extends CacheableService<ExpenseGroup, String> {
  // Config ottimizzato per dati stabili
  GroupServiceCached._internal() : super(config: CacheConfig.stable);

  // Cache members (heavily used)
  final Map<String, List<GroupMember>> _membersCache = {};

  // Bulk operations
  Future<Map<String, List<GroupMember>>> getBulkGroupMembers(List<String> groupIds);

  // Fast path methods
  String? getGroupName(String groupId);  // O(1) lookup!
}
```

**Ottimizzazioni Chiave**:
1. **Members Caching**: Riduce fetch di getGroupMembers() (chiamata frequentissima)
2. **Group Name Lookup**: `getGroupName()` - Ultra-fast per expense list items
3. **Bulk Member Loading**: Per viste multi-gruppo

**Performance Impact**:
- **Prima**: `getGroupMembers()` chiamata ~10-20 volte per form/balance calc
- **Dopo**: 1 fetch + cache reuse
- **Stima**: ~95% riduzione query per group members

#### 3.3 ⏳ ProfileServiceCached (DA COMPLETARE)

**Da Implementare**:
```dart
class ProfileServiceCached extends CacheableService<UserProfile, String> {
  ProfileServiceCached._internal() : super(config: CacheConfig.stable);

  // Bulk profile fetching
  Future<Map<String, UserProfile>> getBulkProfiles(List<String> userIds);

  // Nickname lookup
  String? getNickname(String userId);
}
```

**Use Cases**:
- Group member displays
- Expense "paid by" displays
- Chat/comment author names

---

### ⏳ FASE 4: Refactoring UI Components (IN CORSO)

#### 4.1 ⏳ ExpenseListItem Widget

**Problema Attuale**:
```dart
// lib/widgets/expense_list_item.dart:201
FutureBuilder<double>(
  future: ExpenseService().calculateUserBalance(expense),  // Query per OGNI item!
  builder: (context, snapshot) { ... }
)
```

**Soluzione Proposta**:
```dart
class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final double? cachedBalance;  // Pre-calculated!

  Widget build(BuildContext context) {
    final balance = cachedBalance ?? 0.0;  // No FutureBuilder!

    if (balance.abs() < 0.01) return const SizedBox.shrink();

    return Text(balance > 0
        ? '↗️ +${balance.toStringAsFixed(2)}€ da recuperare'
        : '↙️ ${balance.toStringAsFixed(2)}€ devi');
  }
}
```

**Refactoring Necessario**:
1. Calcolare balances in bulk nella parent widget (expense_list o homepage)
2. Passare balance pre-calcolato a ExpenseListItem
3. Rimuovere FutureBuilder

**Performance Impact**:
- **Prima**: 50 expenses = 50 Future queries
- **Dopo**: 1 bulk query + pass data down
- **Stima**: ~98% riduzione latency per list rendering

#### 4.2 ⏳ Homepage Debt Balance Section

**Problema Attuale**:
```dart
// lib/views/new_homepage.dart:464-549
FutureBuilder<Map<String, double>>(
  future: calculateGroupBalance(),  // Query 1
  builder: (context, snapshot) {
    return FutureBuilder<List<String>>(  // Query 2 (NESTED!)
      future: _getUserNames(groupId),
      builder: (context, nameSnapshot) { ... }
    )
  }
)
```

**Soluzione Proposta**:
```dart
class DebtBalanceData {
  final Map<String, double> balances;
  final String currentUserName;
  final String otherUserName;
}

// Single Future combining both
Future<DebtBalanceData> _loadDebtBalanceData() async {
  final groupId = _contextManager.currentContext.groupId!;

  // Use cached group service
  final group = await GroupServiceCached().getCachedGroup(groupId);
  final members = group?.members ?? await GroupServiceCached().getGroupMembers(groupId);

  // Calculate balance
  final balances = await ExpenseServiceCached().calculateGroupBalance(groupId);

  return DebtBalanceData(
    balances: balances,
    currentUserName: members[0].nickname ?? 'Tu',
    otherUserName: members[1].nickname ?? 'Altro',
  );
}

// UI
FutureBuilder<DebtBalanceData>(
  future: _loadDebtBalanceData(),  // Single Future!
  builder: (context, snapshot) {
    final data = snapshot.data!;
    return _buildDebtBalanceSection(data.balances, data.currentUserName, data.otherUserName);
  }
)
```

**Performance Impact**:
- **Prima**: Waterfall queries (N + 1 problem)
- **Dopo**: Parallel/batch queries + cached members
- **Stima**: 50% riduzione latency

---

### ⏳ FASE 5: Ulteriori Ottimizzazioni UI/UX (DA COMPLETARE)

**Opportunità Identificate**:

1. **Group Badge in Expense List**
   - **Attuale**: Mostra solo "Gruppo"
   - **Proposta**: Mostra nome gruppo (usando `GroupServiceCached().getGroupName()`)
   - **File**: `lib/widgets/expense_list_item.dart:64`

2. **Category Breakdown in Homepage**
   - **Proposta**: Pre-calculate category totals usando cached expenses
   - **File**: `lib/views/new_homepage.dart`

3. **Timeline View Optimizations**
   - **Proposta**: Group expenses by month usando cached data
   - **File**: `lib/views/timeline_view.dart`

4. **Profile Display in Group Details**
   - **Proposta**: Use cached profiles invece di fetch ripetute
   - **File**: `lib/views/group_detail_page.dart`

---

## 🔧 Setup e Inizializzazione

### Inizializzazione App

```dart
// lib/main.dart o dove inizializza l'app
Future<void> _initializeCaching() async {
  final cacheManager = CacheManager.instance;

  // Register services
  final expenseService = ExpenseServiceCached();
  final groupService = GroupServiceCached();
  final profileService = ProfileServiceCached();

  // Setup invalidation rules
  cacheManager.registerInvalidationRule('expenses', ['groups']);

  // Preload critical data
  await cacheManager.ensureAllInitialized();

  // Optional: Print diagnostics in debug mode
  if (kDebugMode) {
    cacheManager.printGlobalDiagnostics();
  }
}
```

### Migration da Service Vecchi

**Strategia**: Graduale, mantenendo backward compatibility

**Passo 1**: Usare nuovi servizi in nuovi component
```dart
// Nuovo codice
final expenses = await ExpenseServiceCached().getCachedExpenses(ids);
```

**Passo 2**: Refactor componenti esistenti uno alla volta
```dart
// Prima
final expense = await ExpenseService().getById(id);

// Dopo
final expense = await ExpenseServiceCached().getCachedExpense(id);
```

**Passo 3**: Deprecare servizi vecchi (una volta migrato tutto)

---

## 📊 Metriche di Successo

### KPIs da Monitorare

1. **Cache Hit Rate**: Target >80%
2. **Latency Riduzione**: Target -70% per list views
3. **Query Count**: Target -80% per session
4. **Memory Usage**: Target <10MB overhead

### Strumenti di Monitoring

```dart
// In debug mode
CacheManager.instance.printGlobalDiagnostics();

// Output example:
// ========================================
//     GLOBAL CACHE DIAGNOSTICS
// ========================================
//
// 📊 GLOBAL STATISTICS
// Total Cache Size: 437 items
// Total Hits: 1,234
// Total Misses: 156
// Global Hit Rate: 88.8%
// Total Evictions: 12
// Total Invalidations: 34
//
// 📦 SERVICE BREAKDOWN
//
//   expenses:
//     Size: 234 items
//     Hits: 890
//     Misses: 78
//     Hit Rate: 91.9%
//
//   groups:
//     Size: 15 items
//     Hits: 312
//     Misses: 5
//     Hit Rate: 98.4%
```

---

## ✅ Checklist Implementazione

### Core Framework
- [x] CacheableModel interface
- [x] CacheableService abstract class
- [x] CacheConfig + strategies
- [x] CacheManager singleton
- [x] Cache statistics

### Models Integration
- [x] Expense implements CacheableModel
- [x] ExpenseGroup implements CacheableModel
- [x] UserProfile implements CacheableModel

### Services Implementation
- [x] ExpenseServiceCached
- [x] GroupServiceCached
- [ ] ProfileServiceCached

### UI Refactoring
- [ ] ExpenseListItem (bulk balance calculation)
- [ ] Homepage debt balance section
- [ ] Group name in expense items
- [ ] Timeline view optimization

### Testing & Validation
- [ ] Unit tests per CacheableService
- [ ] Integration tests per cached services
- [ ] Performance benchmarks (before/after)
- [ ] Memory leak testing

### Documentation
- [x] Implementation plan (questo documento)
- [ ] Agent instructions for future development
- [ ] API documentation per cached services
- [ ] Migration guide

---

## 🎓 Lessons Learned & Best Practices

### DO ✅

1. **Cache Stable Data Aggressively**
   - Groups, profiles raramente cambiano
   - Use `CacheConfig.stable` (TTL 1h, preload enabled)

2. **Batch Operations Where Possible**
   - `getBulkUserBalances()` invece di N separate calls
   - `getBulkGroupMembers()` per multi-group views

3. **Invalidate Proactively**
   - Dopo create/update/delete operations
   - Cross-service invalidation (expenses → groups)

4. **Use Cached Data in UI**
   - Pre-calculate in parent, pass down to children
   - Avoid FutureBuilder per ogni list item

### DON'T ❌

1. **Don't Cache Everything Blindly**
   - Real-time data (notifications, live updates) meglio con Stream
   - User-specific sensitive data needs careful consideration

2. **Don't Forget Memory Limits**
   - Set `maxSize` per evitare memory leaks
   - Use eviction strategies (LRU for most cases)

3. **Don't Block UI Thread**
   - Cache operations sono sync (Map lookups)
   - Fetch operations restano async

4. **Don't Cache Mutable References**
   - Always use `copyWith()` for immutability
   - Prevent accidental cache pollution

---

## 🗑️ Quando Eliminare Questo Documento

Questo documento va eliminato quando:
- [x] Framework core completato
- [ ] Tutti i servizi migrati
- [ ] UI components refactored
- [ ] Tests passano
- [ ] Documentation finale scritta

**Target Date**: Da definire in base alla velocità di implementazione

---

_Documento creato: 2026-01-14_
_Ultimo aggiornamento: 2026-01-14_
