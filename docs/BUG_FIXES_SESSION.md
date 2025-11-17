# 🐛 Bug Fixes Session - 2025-01-13

## 📋 Overview

Sessione di bug fixing post-FASE 4, con risoluzione di 4 bug critici e preparazione migration database.

---

## ✅ Bug Risolti

### 🐛 Bug 1: Type Error in Expense Splits (CRITICAL)

**Errore**:
```
❌ ERROR getting expense splits: TypeError: type 'int' is not a subtype of type 'String'
```

**Causa**: Il database Supabase ritorna `expense_id` e `id` come INTEGER, ma il modello Dart ExpenseSplit si aspettava String con cast esplicito `as String`, causando type error.

**Soluzione**: [lib/models/expense_split.dart:30-31](../lib/models/expense_split.dart#L30-L31)

```dart
// BEFORE (causing error):
id: map['id'] as String,
expenseId: map['expense_id'] as String,

// AFTER (fixed):
id: map['id'].toString(), // Handle both int and String
expenseId: map['expense_id'].toString(), // Handle both int and String
```

**Impatto**: ✅ Gli expense splits ora si caricano correttamente senza type errors

---

### 🐛 Bug 2: MoneyFlow Visibile per Spese Personali

**Problema**: Il campo "Direzione del flusso" (MoneyFlow) era stato nascosto solo per spese gruppo, ma rimaneva visibile per spese personali. Questo campo è obsoleto nel nuovo sistema.

**Soluzione**: [lib/models/expense_form.dart:256-260](../lib/models/expense_form.dart#L256-L260)

1. **Rimosso campo dalla UI** (completamente):
```dart
// DELETED:
// Money flow selector - ONLY for personal expenses (legacy)
if (!widget.isGroupContext) ...[
  FieldWidget(expenseField: widget.expenseForm.flowField),
  const SizedBox(height: 16),
],
```

2. **Forzato default per tutte le spese**:
```dart
// BEFORE:
moneyFlow: widget.isGroupContext
    ? MoneyFlow.carlucci  // Default for group
    : widget.expenseForm.flowField.getFieldValue() as MoneyFlow,  // From form

// AFTER:
moneyFlow: MoneyFlow.carlucci,  // Always default (legacy field)
```

**File Modificati**:
- [lib/models/expense_form.dart](../lib/models/expense_form.dart): Righe 256-260 (rimosso), 322-324, 342-344 (semplificato)

**Impatto**:
- ✅ UI più pulita senza campo obsoleto
- ✅ Tutte le spese usano default `MoneyFlow.carlucci`
- ✅ Compatibilità database mantenuta (campo ha sempre un valore)

---

### 🐛 Bug 3: Contatore Membri Gruppi Mostra "0 Membri"

**Problema**: Nella Profile Page, sezione "I miei gruppi", il sottotitolo mostrava sempre "0 Membri" anche quando i gruppi avevano membri.

**Causa**: La query `getUserGroups()` non caricava il campo `member_count` dal database. Il query `.select()` semplice non include aggregazioni.

**Soluzione**: [lib/service/group_service.dart:43-65](../lib/service/group_service.dart#L43-L65)

```dart
// BEFORE (missing member_count):
final groupsResponse = await _supabase
    .from('groups')
    .select()
    .inFilter('id', groupIds);

return (groupsResponse as List)
    .map((map) => ExpenseGroup.fromMap(map))
    .toList();

// AFTER (with member count aggregation):
final groupsResponse = await _supabase
    .from('groups')
    .select('*, member_count:group_members(count)')  // ← Aggregation!
    .inFilter('id', groupIds);

return (groupsResponse as List).map((map) {
  // Extract member count from aggregation
  final memberCountData = map['member_count'] as List?;
  final count = memberCountData != null && memberCountData.isNotEmpty
      ? memberCountData[0]['count'] as int?
      : 0;

  return ExpenseGroup.fromMap({
    ...map,
    'member_count': count,  // ← Inject count into map
  });
}).toList();
```

**Come Funziona**:
1. Supabase query con sub-query: `group_members(count)`
2. Risultato: `member_count: [{count: 2}]` (array con oggetto count)
3. Estraiamo il count e lo iniettiamo nel map
4. `ExpenseGroup.fromMap()` ora riceve `member_count: 2`

**Impatto**: ✅ Profile Page mostra correttamente "2 membri", "3 membri", etc.

---

### 🐛 Bug 4: Ultime Spese Non Reagisce a Cambio Contesto

**Problema**: Nella homepage (NewHomepage), la sezione "Ultime Spese" mostrava sempre le spese personali, anche dopo aver switchato al contesto gruppo.

**Causa**: Stesso problema di FASE 4D - lo stream in `NewHomepage` non veniva ricreato quando `ContextManager` cambiava. Il widget era StatelessWidget quindi non poteva ascoltare il ContextManager.

**Soluzione**: [lib/views/new_homepage.dart:1-43, 85, 99](../lib/views/new_homepage.dart)

1. **Convertito StatelessWidget → StatefulWidget**:
```dart
// BEFORE:
class NewHomepage extends StatelessWidget {
  const NewHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();  // Created every build

    return Scaffold(
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.stream,  // Never updates
```

2. **Aggiunto listener a ContextManager**:
```dart
// AFTER:
class NewHomepage extends StatefulWidget {
  const NewHomepage({super.key});

  @override
  State<NewHomepage> createState() => _NewHomepageState();
}

class _NewHomepageState extends State<NewHomepage> {
  final ExpenseService _expenseService = ExpenseService();
  final _contextManager = ContextManager();

  @override
  void initState() {
    super.initState();
    // Listen to context changes to rebuild stream
    _contextManager.addListener(_onContextChanged);
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    if (kDebugMode) {
      print('🔄 [UI - NewHomepage] Context changed, rebuilding widget');
    }
    // Force rebuild to recreate stream with new context
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.stream,  // ← Re-evaluated on rebuild!
```

**File Modificati**:
- [lib/views/new_homepage.dart](../lib/views/new_homepage.dart): +42 lines (imports, state class, lifecycle methods)

**Impatto**:
- ✅ "Ultime Spese" si aggiorna automaticamente al cambio contesto
- ✅ Mostra spese personali quando in Personal context
- ✅ Mostra spese gruppo quando in Group context

---

## 📊 Statistiche

### Code Changes

| File | Lines Added | Lines Modified | Lines Deleted |
|------|-------------|----------------|---------------|
| [lib/models/expense_split.dart](../lib/models/expense_split.dart) | 0 | 2 | 0 |
| [lib/models/expense_form.dart](../lib/models/expense_form.dart) | 0 | 4 | 9 |
| [lib/service/group_service.dart](../lib/service/group_service.dart) | 12 | 4 | 3 |
| [lib/views/new_homepage.dart](../lib/views/new_homepage.dart) | 42 | 2 | 1 |
| **TOTAL** | **+54** | **12** | **-13** |

**Net**: +53 lines

---

## 🧪 Testing Checklist

### Bug 1: Type Error in Splits
- [ ] Apri app e switch a contesto gruppo
- [ ] Verifica nessun log `❌ ERROR getting expense splits`
- [ ] Console dovrebbe essere pulita da type errors

### Bug 2: MoneyFlow Rimosso
- [ ] Crea nuova spesa personale → campo MoneyFlow non visibile
- [ ] Crea nuova spesa gruppo → campo MoneyFlow non visibile
- [ ] Verifica DB: tutte le nuove spese hanno `money_flow = 'carlucci'`

### Bug 3: Contatore Membri
- [ ] Apri Profile Page
- [ ] Sezione "I miei gruppi"
- [ ] Verifica sottotitolo: "2 membri", "3 membri", etc. (non "0 Membri")

### Bug 4: Ultime Spese Context Switch
- [ ] Apri homepage in contesto Personal
- [ ] Sezione "Ultime Spese" mostra spese personali
- [ ] Switch a contesto Group
- [ ] Log console: `🔄 [UI - NewHomepage] Context changed`
- [ ] Sezione "Ultime Spese" si aggiorna con spese gruppo ✅

---

## 🔄 Pattern Riutilizzabile: Context-Aware Stream

Questo pattern è stato usato sia in FASE 4D (ExpenseList) che in Bug 4 (NewHomepage):

```dart
class _MyWidgetState extends State<MyWidget> {
  final Service _service = Service();
  final _contextManager = ContextManager();

  @override
  void initState() {
    super.initState();
    _contextManager.addListener(_onContextChanged);
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    setState(() {});  // Force rebuild → stream re-evaluated
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _service.stream,  // Re-evaluated on setState
      // ...
    );
  }
}
```

**Quando Usare**:
- Widget usa stream che dipende da ContextManager
- Stream deve aggiornarsi quando utente cambia contesto (Personal ↔ Group)
- Widget può essere StatefulWidget

**Alternative** (se non applicabili):
- `StreamBuilder` con `key` che cambia al cambio contesto
- `StreamProvider` (Provider package)
- Riverpod `StreamProvider`

---

## 🚀 Prossimi Passi

1. **Testa tutti i bug fix** usando checklist sopra
2. **Prepara migration database**:
   - Fornisci UUID del gruppo target
   - Identifica valori MoneyFlow da mappare
   - Esegui [20250113_migrate_legacy_expenses.sql](../supabase/migrations/20250113_migrate_legacy_expenses.sql)
3. **Verifica date legacy** e applica fix se necessario

---

**Status**: ✅ TUTTI I BUG RISOLTI (4/4)
**Testing**: 🟡 Pending manual testing
**Migration**: 🟡 Pending configuration + execution
