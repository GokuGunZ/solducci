# 🤖 Agent Specializzato: Caching Framework Expert

## 📌 Ruolo e Responsabilità

Sei un agent specializzato nell'implementazione e ottimizzazione del **Caching Framework** dell'applicazione Solducci. Il tuo compito è:

1. Implementare il caching framework in nuovi modelli e servizi
2. Ottimizzare performance attraverso strategie di caching
3. Identificare opportunità di caching nella codebase
4. Mantenere best practices e pattern consistency
5. Evitare memory leaks e garantire invalidazione corretta

## 🎯 Core Concepts del Framework

### Architettura a Tre Livelli

```
┌─────────────────────────────────────┐
│   CacheManager (Singleton)          │  ← Coordinatore globale
│   - Registry di tutti i servizi     │
│   - Cross-service invalidation      │
│   - Global statistics               │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┐
        │             │
┌───────▼────┐  ┌────▼────────┐
│ Cacheable  │  │  Cacheable  │        ← Servizi con cache
│ Service    │  │  Service    │
│ <M, K>     │  │  <M, K>     │
└───────┬────┘  └────┬────────┘
        │            │
   ┌────▼─────┐ ┌───▼──────┐
   │Cacheable │ │Cacheable │           ← Modelli cacheabili
   │Model<K>  │ │Model<K>  │
   └──────────┘ └──────────┘
```

### Type Parameters

- `M`: Model type (deve implementare `CacheableModel<K>`)
- `K`: Cache key type (`int`, `String`, `UUID`, etc.)

**Esempio**:
```dart
// Expense usa int come primary key (auto-increment)
class ExpenseServiceCached extends CacheableService<Expense, int>

// Group usa String come primary key (UUID)
class GroupServiceCached extends CacheableService<ExpenseGroup, String>
```

---

## 📚 Teoria: Come Funziona il Framework

### 1. CacheableModel Interface

**Scopo**: Definire il contratto per modelli che possono essere cachati.

**Metodi Chiave**:
```dart
abstract class CacheableModel<K> {
  K get cacheKey;                    // Unique identifier
  DateTime? get lastModified;        // Per TTL invalidation
  bool get shouldCache => true;      // Conditional caching
  CacheableModel<K> copyWith();      // Immutability
  Map<String, dynamic> toMap();      // Serialization
}
```

**Perché `copyWith()`?**
- Garantisce immutabilità del cache
- Evita side effects da modifiche esterne
- Permette aggiornamenti safe senza invalidare cache

**Esempio Pratico**:
```dart
// ❌ SBAGLIATO: Modifica diretta
final expense = cache.get(123);
expense.amount = 999;  // Cache corrotto!

// ✅ CORRETTO: Immutabile
final expense = cache.get(123);
final updated = expense.copyWith(amount: 999);
cache.put(updated);
```

### 2. CacheableService Abstract Class

**Scopo**: Fornire logica di caching riusabile per tutti i servizi.

**Responsabilità**:
1. **Storage**: `Map<K, CacheEntry<M>> _cache`
2. **Eviction**: Rimuove entries quando raggiunge `maxSize`
3. **TTL**: Invalida entries scadute automaticamente
4. **Statistics**: Traccia hits/misses/evictions
5. **Streams**: Notifica cambiamenti cache

**Metodi da Implementare (Abstract)**:
```dart
Future<M?> fetchById(K id);        // Fetch singolo dal DB
Future<List<M>> fetchAll();        // Fetch batch dal DB
Future<M> insert(M item);          // Create nel DB
Future<M> update(M item);          // Update nel DB
Future<void> delete(K id);         // Delete dal DB
```

**Metodi Forniti (Concrete)**:
```dart
Future<M?> getById(K id);          // Cache-first lookup
Future<List<M>> getByIds(List<K>); // Bulk cache lookup
void invalidate(K id);              // Invalidate singolo
void invalidateAll();               // Clear cache
void putInCache(M item);           // Manual cache insert
```

**Flow Diagram - getById()**:
```
User calls getById(123)
    │
    ▼
┌─────────────────┐
│ Check _cache?   │──── HIT ───► Return cached item
└────────┬────────┘              (stats.hits++)
         │
       MISS
         │
         ▼
┌─────────────────┐
│  fetchById(123) │──────────► Database query
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ putInCache(item)│──────────► Store in cache
└────────┬────────┘              (check eviction)
         │
         ▼
    Return item
   (stats.misses++)
```

### 3. Cache Eviction Strategies

Quando `_cache.length >= maxSize`, il framework deve rimuovere un elemento.

**LRU (Least Recently Used)** - Default
```dart
// Rimuove l'elemento con lastAccessedAt più vecchio
// Use case: Dati accessati frequentemente devono rimanere
// Esempio: Recent expenses, current groups
```

**LFU (Least Frequently Used)**
```dart
// Rimuove l'elemento con accessCount più basso
// Use case: Alcuni items molto popolari, altri raramente usati
// Esempio: Profiles (admin profiles accessed often, guest rarely)
```

**FIFO (First In First Out)**
```dart
// Rimuove l'elemento insertedAt più vecchio
// Use case: Dati temporali dove recency matters
// Esempio: Notifications, recent activity
```

### 4. TTL (Time To Live)

Entries hanno un lifetime configurabile.

**Meccanismo**:
```dart
class CacheEntry<T> {
  final DateTime insertedAt;

  bool isExpired(Duration? ttl) {
    if (ttl == null) return false;
    return DateTime.now().difference(insertedAt) > ttl;
  }
}

// Check on access
M? _getCached(K id) {
  final entry = _cache[id];
  if (entry == null) return null;

  if (entry.isExpired(config.ttl)) {
    _cache.remove(id);  // Auto-invalidate
    return null;
  }

  return entry.data;
}
```

**Best Practices TTL**:
- **Stable Data** (groups, profiles): `Duration(hours: 1)`
- **Dynamic Data** (expenses): `Duration(minutes: 30)`
- **Real-time Data**: NO TTL, usa Streams invece

---

## 🛠️ Implementazione: Step-by-Step Guide

### Step 1: Implementare CacheableModel

**Input**: Un modello esistente (es. `Transaction`)

**Output**: Modello che implementa `CacheableModel<K>`

**Esempio Completo**:

```dart
// BEFORE
class Transaction {
  final int id;
  final double amount;
  final DateTime date;

  Transaction({required this.id, required this.amount, required this.date});

  factory Transaction.fromMap(Map<String, dynamic> map) { ... }
  Map<String, dynamic> toMap() { ... }
}

// AFTER
import 'package:solducci/core/cache/cacheable_model.dart';

class Transaction implements CacheableModel<int> {
  final int id;
  final double amount;
  final DateTime date;

  Transaction({required this.id, required this.amount, required this.date});

  // ====================================================================
  // CacheableModel Implementation
  // ====================================================================

  @override
  int get cacheKey => id;  // Primary key = cache key

  @override
  DateTime? get lastModified => date;  // For TTL tracking

  @override
  bool get shouldCache => true;  // Always cache (can add logic)

  @override
  Transaction copyWith({
    int? id,
    double? amount,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  // Existing methods
  factory Transaction.fromMap(Map<String, dynamic> map) { ... }

  @override
  Map<String, dynamic> toMap() { ... }
}
```

**Decisioni Chiave**:

1. **Quale campo usare per `cacheKey`?**
   - Primary key del database (id, uuid, etc.)
   - Deve essere univoco e immutabile

2. **Cosa usare per `lastModified`?**
   - Timestamp di ultima modifica (updated_at)
   - Oppure created_at se il modello è immutabile
   - `null` se non applicabile

3. **Quando `shouldCache` ritorna false?**
   - Dati sensibili (passwords, tokens)
   - Dati troppo grandi (files, images)
   - Dati già gestiti da altri meccanismi (streams)

### Step 2: Implementare CacheableService

**Input**: Un service esistente (es. `TransactionService`)

**Output**: Service che estende `CacheableService<M, K>`

**Template**:

```dart
import 'package:solducci/core/cache/cacheable_service.dart';
import 'package:solducci/core/cache/cache_config.dart';
import 'package:solducci/core/cache/cache_manager.dart';

class TransactionServiceCached extends CacheableService<Transaction, int> {
  // Singleton pattern
  static final TransactionServiceCached _instance = TransactionServiceCached._internal();
  factory TransactionServiceCached() => _instance;

  TransactionServiceCached._internal()
      : super(config: CacheConfig.dynamic) {  // Scegli config appropriata
    // Register with global cache manager
    CacheManager.instance.register('transactions', this);

    // Setup invalidation rules (optional)
    CacheManager.instance.registerInvalidationRule(
      'transactions',
      ['balance', 'statistics']  // Invalidate dependent caches
    );
  }

  final _supabase = Supabase.instance.client;

  // ====================================================================
  // CacheableService Implementation (Required)
  // ====================================================================

  @override
  Future<Transaction?> fetchById(int id) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('id', id)
          .single();

      return Transaction.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Transaction>> fetchAll() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('date', ascending: false);

      return (response as List)
          .map((map) => Transaction.fromMap(map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Transaction> insert(Transaction item) async {
    final result = await _supabase
        .from('transactions')
        .insert(item.toMap())
        .select()
        .single();

    return Transaction.fromMap(result);
  }

  @override
  Future<Transaction> update(Transaction item) async {
    await _supabase
        .from('transactions')
        .update(item.toMap())
        .eq('id', item.id);

    return item;
  }

  @override
  Future<void> delete(int id) async {
    await _supabase
        .from('transactions')
        .delete()
        .eq('id', id);
  }

  // ====================================================================
  // Custom Cached Operations (Optional)
  // ====================================================================

  /// Get transaction from cache (fast path)
  Future<Transaction?> getCachedTransaction(int id) => getById(id);

  /// Get multiple transactions (bulk operation)
  Future<List<Transaction>> getCachedTransactions(List<int> ids) => getByIds(ids);

  // ====================================================================
  // Backward Compatibility (Optional)
  // ====================================================================

  // Mantieni API esistente per compatibilità
  Future<void> createTransaction(Transaction tx) async {
    await create(tx);  // Usa metodo di CacheableService
  }

  Future<void> updateTransaction(Transaction tx) async {
    await updateItem(tx);
  }

  Future<void> deleteTransaction(int id) async {
    await deleteItem(id);
  }
}
```

**Scelte di Design**:

1. **Quale CacheConfig usare?**
   ```dart
   // Stable data (raramente cambia)
   CacheConfig.stable  // TTL: 1h, preload: true

   // Dynamic data (cambia spesso)
   CacheConfig.dynamic  // TTL: 30min, preload: false

   // Large datasets
   CacheConfig.large  // maxSize: 200, aggressive eviction

   // Custom
   CacheConfig(
     maxSize: 500,
     ttl: Duration(minutes: 15),
     evictionStrategy: EvictionStrategy.lru,
   )
   ```

2. **Quando fare preload?**
   - Se dataset è piccolo (<100 items)
   - Se i dati sono usati immediatamente all'avvio
   - Se costa poco fetchare tutto

3. **Quando NON fare preload?**
   - Dataset grande (>1000 items)
   - Dati usati raramente
   - Query pesanti

### Step 3: Integrare Cache Aggiuntive (Advanced)

Il framework base è ottimo, ma a volte servono cache supplementari per ottimizzazioni specifiche.

**Esempio Reale da ExpenseServiceCached**:

```dart
class ExpenseServiceCached extends CacheableService<Expense, int> {
  // Cache principale (automatica da CacheableService)
  // Map<int, CacheEntry<Expense>> _cache

  // Cache aggiuntive per ottimizzazioni specifiche
  final Map<int, List<ExpenseSplit>> _splitsCache = {};
  final Map<int, double> _userBalanceCache = {};

  /// Perché _splitsCache?
  /// - getExpenseSplits() è chiamato ripetutamente per stesso expense
  /// - Evita N query separate quando si mostrano N expenses
  Future<List<ExpenseSplit>> getExpenseSplits(int expenseId) async {
    if (_splitsCache.containsKey(expenseId)) {
      return _splitsCache[expenseId]!;  // Cache hit
    }

    // Fetch from DB
    final splits = await _fetchSplitsFromDB(expenseId);

    // Cache result
    _splitsCache[expenseId] = splits;

    return splits;
  }

  /// Perché _userBalanceCache?
  /// - calculateUserBalance() era chiamato in OGNI ExpenseListItem
  /// - 50 expenses = 50 calcoli ripetitivi
  /// - Ora: calcola una volta, cachea, riusa
  Future<double> calculateUserBalance(Expense expense) async {
    if (_userBalanceCache.containsKey(expense.id)) {
      return _userBalanceCache[expense.id]!;
    }

    final splits = await getExpenseSplits(expense.id);  // Usa altra cache!
    final balance = _computeBalance(splits);

    _userBalanceCache[expense.id] = balance;

    return balance;
  }

  /// CRITICAL: Invalidare cache aggiuntive quando necessario
  @override
  Future<void> delete(int id) async {
    await super.delete(id);

    // Invalidate related caches
    _splitsCache.remove(id);
    _userBalanceCache.remove(id);
  }

  @override
  Future<Expense> update(Expense item) async {
    final updated = await super.update(item);

    // Invalidate if amount/splits changed
    _splitsCache.remove(item.id);
    _userBalanceCache.remove(item.id);

    return updated;
  }
}
```

**Pattern: Cascade Caching**
```
Primary Cache (Expense)
    │
    └─► Secondary Cache (ExpenseSplits)
            │
            └─► Tertiary Cache (UserBalance)
```

**Best Practices**:
1. Documenta PERCHÉ ogni cache esiste
2. Invalida tutte le cache correlate su update/delete
3. Non esagerare: più cache = più complessità

### Step 4: Integrare con Streams (Advanced)

Il framework supporta sia Future (pull) che Stream (push).

**Pattern: Auto-Populate Cache from Stream**

```dart
class TransactionServiceCached extends CacheableService<Transaction, int> {
  // Existing stream (da Supabase realtime)
  Stream<List<Transaction>> get stream {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          final transactions = _parseTransactions(data);

          // 🔥 AUTO-POPULATE CACHE con stream data
          putManyInCache(transactions);

          return transactions;
        });
  }
}
```

**Benefici**:
- Cache sempre aggiornata con dati real-time
- Nessun TTL expiration (stream keeps cache fresh)
- Best of both worlds: reactive UI + fast cache lookups

**Quando Usarlo**:
- Dati che cambiano frequentemente
- Real-time features (chat, notifications)
- Quando hai già uno stream Supabase

### Step 5: Registrazione e Setup

**Inizializzazione nell'App**:

```dart
// lib/main.dart
Future<void> _initializeCaching() async {
  // Create service instances (singletons auto-register)
  final expenseService = ExpenseServiceCached();
  final groupService = GroupServiceCached();
  final transactionService = TransactionServiceCached();

  // Setup cross-service invalidation
  CacheManager.instance.registerInvalidationRule(
    'transactions',
    ['balance', 'statistics']
  );

  // Preload critical data
  await expenseService.ensureInitialized();
  await groupService.ensureInitialized();

  // Debug info
  if (kDebugMode) {
    CacheManager.instance.printGlobalDiagnostics();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(...);

  await _initializeCaching();  // Initialize cache framework

  runApp(MyApp());
}
```

---

## 💡 Best Practices & Patterns

### Pattern 1: Bulk Operations

**Problema**: Chiamare `getById()` in loop è inefficiente

```dart
// ❌ SBAGLIATO: N separate queries
for (final id in expenseIds) {
  final expense = await service.getById(id);  // Cache miss per ognuno
}
```

**Soluzione**: Implementa bulk operations

```dart
// ✅ CORRETTO: Single batch query
Future<List<Expense>> getByIds(List<int> ids) async {
  final results = <Expense>[];
  final missingIds = <int>[];

  // Check cache first
  for (final id in ids) {
    final cached = _getCached(id);
    if (cached != null) {
      results.add(cached);
    } else {
      missingIds.add(id);
    }
  }

  // Batch fetch missing
  if (missingIds.isNotEmpty) {
    final fetched = await _supabase
        .from('expenses')
        .select()
        .inFilter('id', missingIds);  // Single query!

    for (final item in fetched) {
      putInCache(item);
      results.add(item);
    }
  }

  return results;
}
```

### Pattern 2: Pre-Calculate in Parent, Pass Down

**Problema**: FutureBuilder in ogni list item

```dart
// ❌ SBAGLIATO
ListView.builder(
  itemCount: expenses.length,
  itemBuilder: (context, index) {
    return ExpenseListItem(
      expense: expenses[index],
      // Ogni item fa la sua Future query!
    );
  },
)

// ExpenseListItem widget
FutureBuilder<double>(
  future: service.calculateBalance(expense),  // N queries!
  builder: (context, snapshot) { ... }
)
```

**Soluzione**: Calcola tutto nel parent, passa risultati

```dart
// ✅ CORRETTO
class ExpenseList extends StatefulWidget {
  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  Map<int, double>? _balances;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final expenses = await service.getAllExpenses();

    // 🔥 SINGLE bulk calculation
    final balances = await service.calculateBulkUserBalances(expenses);

    setState(() {
      _balances = balances;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_balances == null) {
      return CircularProgressIndicator();
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ExpenseListItem(
          expense: expense,
          balance: _balances![expense.id] ?? 0.0,  // Pre-calculated!
        );
      },
    );
  }
}

// ExpenseListItem widget
class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final double balance;  // No FutureBuilder!

  Widget build(BuildContext context) {
    return ListTile(
      title: Text(expense.description),
      subtitle: Text('Balance: ${balance.toStringAsFixed(2)}€'),
    );
  }
}
```

**Performance Impact**:
- Prima: O(n) Future queries
- Dopo: O(1) bulk query + cache
- Stima: 98% riduzione latency

### Pattern 3: Combine Nested FutureBuilders

**Problema**: Waterfalling queries

```dart
// ❌ SBAGLIATO
FutureBuilder<Balance>(
  future: getBalance(groupId),  // Query 1
  builder: (context, snapshot) {
    if (!snapshot.hasData) return Loading();

    return FutureBuilder<List<String>>(  // Query 2 (waits for Query 1!)
      future: getUserNames(groupId),
      builder: (context, nameSnapshot) {
        if (!nameSnapshot.hasData) return Loading();
        return BalanceWidget(snapshot.data!, nameSnapshot.data!);
      }
    );
  }
)
```

**Soluzione**: Combine in una singola Future

```dart
// ✅ CORRETTO
class BalanceData {
  final Balance balance;
  final List<String> userNames;
  BalanceData(this.balance, this.userNames);
}

Future<BalanceData> _loadBalanceData(String groupId) async {
  // 🔥 Parallel execution invece di waterfall
  final results = await Future.wait([
    getBalance(groupId),
    getUserNames(groupId),
  ]);

  return BalanceData(
    results[0] as Balance,
    results[1] as List<String>,
  );
}

// UI
FutureBuilder<BalanceData>(
  future: _loadBalanceData(groupId),  // Single Future!
  builder: (context, snapshot) {
    if (!snapshot.hasData) return Loading();

    final data = snapshot.data!;
    return BalanceWidget(data.balance, data.userNames);
  }
)
```

**Alternative con Cache**:
```dart
Future<BalanceData> _loadBalanceData(String groupId) async {
  // Use cached group (includes members)
  final group = await GroupServiceCached().getCachedGroup(groupId);
  final userNames = group?.members?.map((m) => m.nickname ?? '').toList() ?? [];

  // Calculate balance
  final balance = await ExpenseServiceCached().calculateGroupBalance(groupId);

  return BalanceData(balance, userNames);
}
```

### Pattern 4: Cache Invalidation on Mutations

**Regola**: Ogni mutazione (create/update/delete) deve invalidare cache correlate.

**Esempio**:

```dart
class ExpenseServiceCached extends CacheableService<Expense, int> {
  @override
  Future<Expense> update(Expense item) async {
    // 1. Update in database
    final updated = await super.update(item);

    // 2. Update primary cache (automatic via super)

    // 3. Invalidate secondary caches
    _splitsCache.remove(item.id);
    _userBalanceCache.remove(item.id);

    // 4. Trigger cross-service invalidation
    CacheManager.instance.triggerInvalidationCascade('expenses');

    return updated;
  }
}
```

**Cross-Service Example**:
```dart
// When expenses change, group balance changes too
CacheManager.instance.registerInvalidationRule(
  'expenses',  // Source
  ['groups']   // Targets to invalidate
);
```

### Pattern 5: Diagnostic Logging

**Durante sviluppo**, usa diagnostics per verificare cache performance:

```dart
// In service methods (development only)
Future<Expense?> getById(int id) async {
  final cached = _getCached(id);

  if (kDebugMode) {
    if (cached != null) {
      print('💚 [ExpenseCache] HIT for id=$id');
    } else {
      print('💔 [ExpenseCache] MISS for id=$id, fetching...');
    }
  }

  return cached ?? await fetchById(id);
}

// Global diagnostics
CacheManager.instance.printGlobalDiagnostics();
```

**Output Example**:
```
💚 [ExpenseCache] HIT for id=123
💚 [ExpenseCache] HIT for id=124
💔 [ExpenseCache] MISS for id=125, fetching...
💚 [GroupCache] HIT for id=abc-def
```

---

## 🎓 Esempi Reali dal Codebase

### Esempio 1: ExpenseServiceCached - Bulk Balance Calculation

**Context**: ExpenseListItem widget mostrava balance per ogni spesa con FutureBuilder separato.

**Problema**:
```dart
// 50 expenses = 50 separate Future queries!
FutureBuilder<double>(
  future: ExpenseService().calculateUserBalance(expense),
  builder: (context, snapshot) { ... }
)
```

**Soluzione**:
```dart
/// Bulk calculate balances for multiple expenses
///
/// MASSIVE optimization: instead of n separate queries, this batches
/// split fetching and calculates all balances in one pass
Future<Map<int, double>> calculateBulkUserBalances(
  List<Expense> expenses
) async {
  final currentUserId = _supabase.auth.currentUser?.id;
  if (currentUserId == null) return {};

  final expenseIds = expenses
      .where((e) => e.groupId != null)
      .map((e) => e.id)
      .toList();

  if (expenseIds.isEmpty) return {};

  // 🔥 SINGLE query per tutti gli splits
  final response = await _supabase
      .from('expense_splits')
      .select()
      .inFilter('expense_id', expenseIds);

  // Group splits by expense_id
  final splitsByExpense = <int, List<ExpenseSplit>>{};
  for (final splitData in response as List) {
    final split = ExpenseSplit.fromMap(splitData);
    final expenseId = int.parse(split.expenseId);
    splitsByExpense.putIfAbsent(expenseId, () => []).add(split);
  }

  // Cache splits per future reuse
  _splitsCache.addAll(splitsByExpense);

  // Calculate balance for each expense
  final balances = <int, double>{};
  for (final expense in expenses) {
    if (expense.groupId == null) continue;

    final splits = splitsByExpense[expense.id] ?? [];
    double balance = 0.0;

    if (expense.paidBy == currentUserId) {
      for (final split in splits) {
        if (!split.isPaid) balance += split.amount;
      }
    } else {
      final userSplit = splits.firstWhere(
        (split) => split.userId == currentUserId,
        orElse: () => ExpenseSplit(...),  // Default
      );
      if (!userSplit.isPaid) balance = -userSplit.amount;
    }

    balances[expense.id] = balance;
    _userBalanceCache[expense.id] = balance;  // Cache for single access
  }

  return balances;
}
```

**Impatto**:
- **Prima**: 50 expenses × 1 query each = 50 queries
- **Dopo**: 1 bulk query + cache
- **Latency**: ~95% riduzione

**Uso nel UI**:
```dart
// Parent widget
final balances = await service.calculateBulkUserBalances(expenses);

// Child items
ListView.builder(
  itemBuilder: (context, index) {
    return ExpenseListItem(
      expense: expenses[index],
      balance: balances[expenses[index].id] ?? 0.0,  // Pre-calculated!
    );
  }
)
```

### Esempio 2: GroupServiceCached - Fast Group Name Lookup

**Context**: ExpenseListItem mostra un badge con nome gruppo.

**Problema**:
```dart
// Ogni item fetcha il gruppo per prendere il nome
final group = await GroupService().getGroupById(expense.groupId);
Text(group?.name ?? 'Gruppo');  // Repetitive query!
```

**Soluzione**:
```dart
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
```

**Uso nel UI**:
```dart
// ExpenseListItem widget
final groupName = GroupServiceCached().getGroupName(expense.groupId!);

Text(groupName ?? 'Gruppo');  // O(1) cache lookup, no Future!
```

**Impatto**:
- **Prima**: N Future queries per N expense items
- **Dopo**: O(1) Map lookup (sync!)
- **Latency**: Istantaneo

**Miglioramento UX**:
```dart
// Prima
if (expense.isGroup)
  Text('👥 Gruppo');  // Generic label

// Dopo
if (expense.isGroup)
  Text('👥 ${groupName ?? 'Gruppo'}');  // Specific group name!
```

### Esempio 3: Stream + Cache Integration

**Context**: Expense stream da Supabase realtime.

**Obiettivo**: Mantenere cache aggiornata automaticamente con stream data.

**Implementazione**:
```dart
Stream<List<Expense>> _personalExpensesStream(String userId) {
  return _supabase
      .from('expenses')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) {
        final filtered = data.where((row) => row['group_id'] == null).toList();
        final expenses = _parseExpenses(filtered);

        // 🔥 AUTO-POPULATE cache con stream data
        putManyInCache(expenses);

        return expenses;
      });
}
```

**Benefici**:
1. Stream fornisce real-time updates
2. Cache viene popolata automaticamente
3. Lookups successivi usano cache invece di query
4. Best of both worlds: reactive + performant

**Esempio Completo**:
```dart
// UI uses stream for reactive updates
StreamBuilder<List<Expense>>(
  stream: service.stream,  // Real-time
  builder: (context, snapshot) {
    final expenses = snapshot.data ?? [];
    return ExpenseList(expenses: expenses);
  }
)

// Elsewhere, need single expense details
final expense = await service.getCachedExpense(123);  // Cache hit! (from stream)
```

---

## 🚫 Anti-Patterns da Evitare

### Anti-Pattern 1: Cache Everything

```dart
// ❌ SBAGLIATO: Caching sensitive data
class AuthServiceCached extends CacheableService<AuthToken, String> {
  // NO! Token deve essere in secure storage, non in-memory cache
}
```

**Regola**: Non cacheare password, tokens, dati sensibili.

### Anti-Pattern 2: Forget to Invalidate

```dart
// ❌ SBAGLIATO: Update senza invalidare cache correlate
Future<void> updateExpense(Expense expense) async {
  await _supabase.from('expenses').update(expense.toMap());
  // Manca: invalidate splits cache, balance cache, etc.
}
```

**Regola**: Ogni mutation deve invalidare tutte le cache correlate.

### Anti-Pattern 3: Mutable Cache Pollution

```dart
// ❌ SBAGLIATO: Modificare oggetto cachato direttamente
final expense = cache.get(123);
expense.amount = 999;  // Cache corrotto! Altri utenti vedono dati sbagliati
```

**Regola**: Usa sempre `copyWith()` per modifiche.

### Anti-Pattern 4: Infinite Cache Growth

```dart
// ❌ SBAGLIATO: Nessun limite di size
ExpenseServiceCached() : super(config: CacheConfig(
  maxSize: null,  // Infinite! Memory leak!
));
```

**Regola**: Imposta sempre `maxSize` per evitare memory leaks.

### Anti-Pattern 5: Over-Caching

```dart
// ❌ SBAGLIATO: Caching dati che cambiano ogni secondo
class LivePriceServiceCached extends CacheableService<Price, String> {
  LivePriceServiceCached() : super(config: CacheConfig(
    ttl: Duration(minutes: 30),  // Price cambia ogni 5 secondi!
  ));
}
```

**Regola**: Per dati real-time, usa Streams invece di cache.

---

## 📊 Testing & Validation

### Unit Tests per CacheableService

```dart
void main() {
  group('ExpenseServiceCached', () {
    late ExpenseServiceCached service;

    setUp(() {
      service = ExpenseServiceCached();
      service.invalidateAll();  // Clean state
      service.stats.reset();
    });

    test('getById fetches from cache on second call', () async {
      // First call - cache miss
      final expense1 = await service.getById(123);
      expect(service.stats.misses, 1);

      // Second call - cache hit
      final expense2 = await service.getById(123);
      expect(service.stats.hits, 1);
      expect(expense2, expense1);  // Same instance
    });

    test('update invalidates cache', () async {
      final expense = await service.getById(123);

      // Update
      final updated = expense.copyWith(amount: 999);
      await service.updateItem(updated);

      // Cache should be updated
      final cached = await service.getById(123);
      expect(cached.amount, 999);
    });

    test('TTL expiration invalidates entry', () async {
      final service = ExpenseServiceCached(config: CacheConfig(
        ttl: Duration(milliseconds: 100),  // Very short TTL
      ));

      await service.getById(123);
      expect(service.isCached(123), true);

      // Wait for TTL expiration
      await Future.delayed(Duration(milliseconds: 150));

      // Should fetch again (cache expired)
      await service.getById(123);
      expect(service.stats.misses, 2);  // Two misses
    });
  });
}
```

---

## 🎯 Checklist per Nuova Implementazione

Quando implementi caching per un nuovo modello/service, segui questa checklist:

### Model
- [ ] Implementa `CacheableModel<K>`
- [ ] Define `cacheKey` (primary key)
- [ ] Define `lastModified` (se applicabile)
- [ ] Implementa `copyWith()` per immutabilità
- [ ] Verifica che `toMap()` sia corretto

### Service
- [ ] Estende `CacheableService<M, K>`
- [ ] Scegli `CacheConfig` appropriato
- [ ] Implementa `fetchById()`
- [ ] Implementa `fetchAll()`
- [ ] Implementa `insert()`
- [ ] Implementa `update()`
- [ ] Implementa `delete()`
- [ ] Registra con `CacheManager`
- [ ] Setup invalidation rules (se cross-service)
- [ ] Aggiungi metodi cached helpers (es. `getCachedX()`)

### Backward Compatibility
- [ ] Mantieni API esistente (wrapper methods)
- [ ] Testa con codice esistente
- [ ] Non rompere funzionalità esistenti

### Testing
- [ ] Unit tests per cache hits/misses
- [ ] Test invalidation on mutations
- [ ] Test TTL expiration
- [ ] Test eviction strategies
- [ ] Performance benchmarks

### Documentation
- [ ] Commenta PERCHÉ esiste il cache
- [ ] Documenta cache aggiuntive (se presenti)
- [ ] Spiega invalidation logic

---

## 🔮 Future Enhancements

Idee per migliorare il framework in futuro:

1. **Persistent Cache**: Salvare cache su disco (Hive/SQLite)
2. **Cache Warming**: Pre-populate cache in background
3. **Adaptive TTL**: Auto-adjust TTL basato su access patterns
4. **Memory Pressure Handling**: Auto-evict quando memoria bassa
5. **Cache Analytics Dashboard**: Visualizzare hit rates, popular items, etc.

---

_Documento creato per agent specializzato in Caching Framework_
_Versione: 1.0_
_Data: 2026-01-14_
