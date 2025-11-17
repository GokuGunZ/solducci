# 🎯 FASE 4D: Fix Summary - Stream Context Bug

## 🐛 Problema Identificato

**Sintomo**: Le spese di gruppo venivano create correttamente nel database (con `group_id`), MA non apparivano nella lista quando si switchava al contesto di gruppo.

**Root Cause**: Lo stream di `ExpenseService` non veniva ricreato quando l'utente cambiava contesto (da Personal a Group o viceversa).

---

## 📊 Analisi dei Log

### ✅ Creazione Spesa: OK
```
🔍 [CREATE] Context: Group (d585824d-83cf-4654-9e6d-5d1eacd32608)
✅ [CREATE] Expense created successfully: 412 (ID: 122)
🔍 [CREATE] Verifying group_id in DB: d585824d-83cf-4654-9e6d-5d1eacd32608
✅ Created 2 expense splits
```

**Risultato**: Spesa salvata correttamente con `group_id` nel DB ✅

### ❌ Stream Update: PROBLEMA
```
📊 [STREAM] Personal received 119 rows from DB
📊 [STREAM] Personal after filter: 115 expenses (removed 4 group expenses)
```

**Problema**: Lo stream continua a queryare "Personal" anche dopo il cambio a "Group"!

**Log Mancante**: Non appare mai `🔍 [STREAM] Creating stream for context: Group`

---

## 🔍 Causa Tecnica

### Codice Problematico

```dart
class _ExpenseListState extends State<ExpenseList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.stream,  // ← PROBLEMA!
        builder: (context, snapshot) {
          // ...
        },
      ),
    );
  }
}
```

**Problema**:
1. Il getter `expenseService.stream` viene valutato solo al **primo build**
2. `StreamBuilder` mantiene il riferimento allo stream iniziale
3. Quando `ContextManager` cambia e fa `notifyListeners()`, il `ContextSwitcher` si rebuilda (aggiorna il titolo)
4. MA `ExpenseList.build()` **non viene chiamato di nuovo** perché non ascolta il `ContextManager`
5. Quindi lo stream rimane "congelato" al contesto iniziale

### Come Funziona expenseService.stream

```dart
Stream<List<Expense>> get stream {
  final context = _contextManager.currentContext;  // ← Legge contesto ATTUALE

  if (context.isPersonal) {
    return _supabase.from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);  // Query per personal
  } else {
    return _supabase.from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', context.groupId!);  // Query per group
  }
}
```

Il getter legge il contesto **al momento della chiamata**, ma viene chiamato solo una volta!

---

## 🔧 Soluzione Implementata

### Fix: Listener su ContextManager

```dart
class _ExpenseListState extends State<ExpenseList> {
  ExpenseService expenseService = ExpenseService();
  final _contextManager = ContextManager();  // Singleton

  @override
  void initState() {
    super.initState();
    // Listen to context changes
    _contextManager.addListener(_onContextChanged);
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    if (kDebugMode) {
      print('🔄 [UI] Context changed, rebuilding widget to refresh stream');
    }
    // Force rebuild to recreate stream with new context
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.stream,  // ← Ora viene rievalutato!
        builder: (context, snapshot) {
          // ...
        },
      ),
    );
  }
}
```

### Come Funziona il Fix

1. `_ExpenseListState` ascolta `ContextManager` via `addListener`
2. Quando l'utente cambia contesto:
   - `ContextSwitcher` → tap → `ContextManager.switchToGroup()` → `notifyListeners()`
3. `_onContextChanged()` viene chiamato
4. `setState(() {})` forza rebuild del widget
5. `build()` viene rieseguito
6. `expenseService.stream` viene **rievalutato** con il nuovo contesto
7. `StreamBuilder` riceve il nuovo stream con la query corretta

**Flusso**:
```
User taps context → ContextManager.switchToGroup()
  ↓
notifyListeners()
  ↓
ContextSwitcher rebuilds (titolo)
  ↓
ExpenseList._onContextChanged() ← NEW!
  ↓
setState(() {})
  ↓
ExpenseList.build() called
  ↓
expenseService.stream getter evaluated again
  ↓
StreamBuilder gets new stream with group query
  ↓
📊 [STREAM] Group received X rows from DB ✅
```

---

## 🧪 Test da Eseguire

Dopo questo fix, testa nuovamente:

### Test 1: Switch Personal → Group
1. Apri app in "Personale" → vedi spese personali
2. Log: `📊 [STREAM] Personal received X rows`
3. Tap context switcher → Seleziona gruppo
4. **Nuovo Log**: `🔄 [UI] Context changed, rebuilding widget to refresh stream`
5. **Nuovo Log**: `🔍 [STREAM] Creating stream for context: Group (...)`
6. **Nuovo Log**: `📊 [STREAM] Group received Y rows from DB`
7. Vedi spese di gruppo nella lista ✅

### Test 2: Create Group Expense
1. Nel contesto gruppo, crea spesa
2. Log: `✅ [CREATE] Expense created successfully`
3. **Nuovo Log**: `🔄 [UI] Context changed, rebuilding widget`
4. **Nuovo Log**: `📊 [STREAM] Group received Y+1 rows`
5. Spesa appare immediatamente nella lista ✅

### Test 3: Switch Group → Personal
1. Nel gruppo, tap context switcher → "Personale"
2. **Nuovo Log**: `🔄 [UI] Context changed, rebuilding widget`
3. **Nuovo Log**: `🔍 [STREAM] Creating stream for context: Personal`
4. Vedi solo spese personali ✅

---

## 📝 File Modificati

### [lib/views/expense_list.dart](../lib/views/expense_list.dart)

**Modifiche**:
1. Aggiunto import `context_manager.dart`
2. Aggiunto field `_contextManager`
3. Aggiunto `initState()` con `addListener`
4. Aggiunto `dispose()` con `removeListener`
5. Aggiunto metodo `_onContextChanged()`

**Righe cambiate**: +20 lines

---

## ✅ Risultato Atteso

Dopo questo fix:

- ✅ Spese gruppo create correttamente nel DB (già funzionava)
- ✅ Stream si aggiorna automaticamente al cambio context (FIXED!)
- ✅ Spese gruppo appaiono nella lista quando in context gruppo
- ✅ Spese personali appaiono quando in context personale
- ✅ Nessuna spesa "persa" o nascosta
- ✅ Context switching fluido e immediato

---

## 🎯 Prossimi Passi

1. **Test il fix**: Riavvia l'app e testa il flow completo
2. **Verifica i log**: Dovresti vedere i nuovi log `🔄 [UI] Context changed`
3. **Se funziona**: Procedi con **FASE 4C** (nascondere MoneyFlow)

---

## 💡 Lesson Learned

**Problema comune con StreamBuilder + Dynamic Query**:

Quando usi un getter che ritorna stream diversi basati su stato esterno:
```dart
Stream<T> get myStream {
  if (someCondition) return streamA;
  else return streamB;
}
```

E il `someCondition` cambia da un `ChangeNotifier` esterno, **devi ascoltare quel notifier e fare setState() per forzare rebuild!**

Altrimenti il `StreamBuilder` mantiene lo stream iniziale e non si accorge del cambio.

**Alternative**:
1. Listener esplicito (quello che abbiamo fatto) ✅
2. `StreamBuilder` con `key` che cambia al cambio contesto
3. `StreamProvider` con Provider package
4. Rivr con `StreamProvider`

La nostra soluzione è semplice ed efficace per questo caso d'uso.

---

**Status**: ✅ FASE 4D COMPLETATA
**Next**: FASE 4C - Nascondere MoneyFlow
