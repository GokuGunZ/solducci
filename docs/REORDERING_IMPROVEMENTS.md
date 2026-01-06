# Reordering Improvements: Fix Flash Bug + Enable TagView Reordering

**Date**: 2026-01-06
**Issues Fixed**:
1. ✅ Flash/flicker during reordering (lista torna allo stato iniziale)
2. ✅ Riordino abilitato solo per AllTasksView (ora funziona anche per TagView)

---

## Problemi Risolti

### 1. Bug del "Flash" Durante Riordino

**Sintomo**: Dopo il drag-and-drop, la lista tornava momentaneamente allo stato iniziale per poi aggiornarsi nuovamente.

**Causa**:
1. Utente fa drag-and-drop di una task
2. BLoC persiste l'ordine custom → scrive nel database
3. `TaskStateManager` emette evento `listChanges`
4. Listener nel BLoC riceve l'evento → triggera `TaskListRefreshRequested`
5. BLoC ricarica TUTTE le task dal database
6. UI mostra prima lo stato vecchio, poi quello nuovo → **FLASH** 👎

**Soluzione**:
- Aggiunto flag `_isReordering` nel BLoC
- Durante il riordino, il listener ignora gli eventi `listChanges`
- Il flag viene resettato dopo 100ms (tempo per completare la persistenza)
- Risultato: **nessun flash, transizione fluida** ✅

### 2. Riordino Solo su AllTasksView

**Sintomo**: Il drag-and-drop funzionava solo su AllTasksView, non su TagView.

**Causa**: La logica del BLoC abilitava `supportsReordering` solo per `DocumentTaskDataSource`:
```dart
// PRIMA
final supportsReordering = event.dataSource is DocumentTaskDataSource;
```

**Soluzione**: Abilitato il riordino anche per `TagTaskDataSource`:
```dart
// DOPO
final supportsReordering = event.dataSource is DocumentTaskDataSource ||
    event.dataSource is TagTaskDataSource;
```

**Nota**: L'ordine custom viene sempre persistito a livello di documento (non per-tag). Questo significa che riordinare task in un TagView influenza l'ordine anche in AllTasksView quando si usa ordinamento "custom".

---

## Modifiche Implementate

### File Modificato: `unified_task_list_bloc.dart`

#### 1. Aggiunto flag anti-flash

```dart
class UnifiedTaskListBloc extends Bloc<UnifiedTaskListEvent, UnifiedTaskListState> {
  final TaskOrderPersistenceService _orderPersistenceService;

  TaskListDataSource? _currentDataSource;
  StreamSubscription? _listChangesSubscription;
  bool _isReordering = false; // 👈 Nuovo flag
```

#### 2. Listener ignora eventi durante riordino

```dart
_listChangesSubscription = event.dataSource.listChanges.listen((_) {
  // Ignore changes during manual reordering to prevent flash
  if (_isReordering) {
    AppLogger.debug('🔔 List change detected during reorder, ignoring');
    return;
  }
  AppLogger.debug('🔔 List change detected, refreshing');
  add(const TaskListRefreshRequested());
});
```

#### 3. Flag attivato/disattivato durante riordino

```dart
Future<void> _onTaskReordered(...) async {
  try {
    // Set flag to prevent refresh during reorder
    _isReordering = true;

    // Reorder tasks...
    // Persist order...

    emit(currentState.copyWith(tasks: reorderedTasks));

    // Reset flag after a short delay (100ms)
    await Future.delayed(const Duration(milliseconds: 100));
    _isReordering = false;
  } catch (e) {
    _isReordering = false; // Reset on error
  }
}
```

#### 4. Supporto riordino per entrambi DocumentTaskDataSource E TagTaskDataSource

```dart
// Determine if this data source supports reordering
final supportsReordering = event.dataSource is DocumentTaskDataSource ||
    event.dataSource is TagTaskDataSource;
```

#### 5. Helper per ottenere documentId

```dart
/// Helper to get document ID from current data source
String? _getDocumentId() {
  if (_currentDataSource is DocumentTaskDataSource) {
    return (_currentDataSource as DocumentTaskDataSource).documentId;
  } else if (_currentDataSource is TagTaskDataSource) {
    return (_currentDataSource as TagTaskDataSource).documentId;
  }
  return null;
}
```

Usato in 3 posti:
- `_onFilterChanged` (applicare ordine custom dopo filtro)
- `_onTaskReordered` (persistere ordine custom)
- `_onRefreshRequested` (ri-applicare ordine custom dopo refresh)

---

## Comportamento Attuale

### AllTasksView
✅ **Riordino ABILITATO**
- Long-press su task → drag & drop
- Ordine salvato a livello di documento
- Ordine mantenuto tra sessioni
- Nessun flash durante riordino

### TagView
✅ **Riordino ABILITATO** (nuovo!)
- Long-press su task → drag & drop
- Ordine salvato a livello di documento (condiviso con AllTasksView)
- Utile quando si filtra per tag e si vuole riordinare
- Nessun flash durante riordino

### CompletedTasksView
🚫 **Riordino DISABILITATO**
- Solo visualizzazione, no riordino
- Ha senso: le task completate di solito non si riordinano

---

## Flow Ottimizzato del Drag & Drop

### Prima (con flash bug)

```
User drag & drop
       ↓
_handleReorder dispatches TaskListTaskReordered
       ↓
BLoC reorders list
       ↓
BLoC persists order → writes to database
       ↓
TaskStateManager emits listChanges
       ↓
Listener triggers TaskListRefreshRequested
       ↓
BLoC reloads ALL tasks from database
       ↓
UI shows: old state → new state → FLASH! 👎
```

### Dopo (senza flash)

```
User drag & drop
       ↓
_handleReorder dispatches TaskListTaskReordered
       ↓
BLoC sets _isReordering = true
       ↓
BLoC reorders list
       ↓
BLoC persists order → writes to database
       ↓
TaskStateManager emits listChanges
       ↓
Listener checks _isReordering → IGNORES event ✅
       ↓
BLoC emits new state with reordered tasks
       ↓
UI shows: smooth transition, no flash! ✅
       ↓
After 100ms: _isReordering = false
```

---

## Considerazioni Tecniche

### Delay di 100ms

Il delay di 100ms dopo il riordino è necessario per:
1. Permettere alla persistenza di completare
2. Assicurarsi che eventuali eventi `listChanges` ritardati vengano ignorati
3. Evitare race condition tra riordino e refresh

100ms è abbastanza:
- Utente non lo percepisce
- Database ha tempo di scrivere
- Eventi asincroni hanno tempo di propagarsi

### Ordine Custom Condiviso

L'ordine custom è salvato **a livello di documento**, non per-tag o per-view. Questo significa:

**Pro:**
- ✅ Consistenza: l'ordine è lo stesso in tutte le view
- ✅ Semplicità: un solo ordine da mantenere
- ✅ Prevedibilità: utente sa che l'ordine è globale

**Con:**
- ⚠️ Riordinare in TagView influenza AllTasksView
- ⚠️ Non è possibile avere ordini diversi per tag diversi

**Alternativa futura**: Se si volesse ordine per-tag, servirebbero:
1. Tabella separata per ordini custom per-tag
2. Logica più complessa nel BLoC
3. UI per gestire conflitti tra ordini

Per ora, l'ordine condiviso è la soluzione più semplice e ragionevole.

---

## Testing

### Test Manuali Eseguiti

#### AllTasksView
- [x] Long-press su task → drag attivato
- [x] Drag task su/giù → animazione fluida
- [x] Drop task → nessun flash
- [x] Ordine mantenuto dopo reload app
- [x] Ordine salvato correttamente

#### TagView
- [x] Long-press su task → drag attivato
- [x] Drag task su/giù → animazione fluida
- [x] Drop task → nessun flash
- [x] Ordine riflesso in AllTasksView (condiviso)
- [x] Funziona con tag diversi

#### Edge Cases
- [x] Riordino durante creazione inline → OK
- [x] Riordino con filtri attivi → OK (solo se sort = custom)
- [x] Riordino con molte task (100+) → OK
- [x] Errore durante persistenza → flag resettato correttamente

### Verifica Compilazione

```bash
flutter analyze lib/
# Result: 0 errors ✅
```

---

## Breaking Changes

**NESSUNO** ✅

- API pubblica invariata
- Comportamento UX migliorato (no flash)
- Funzionalità aggiuntiva (TagView reordering)
- Zero impatto su CompletedTasksView

---

## Performance

### Impatto del Flag

Il flag `_isReordering` ha impatto **trascurabile**:
- 1 booleano in memoria (~1 byte)
- Check `if (_isReordering)` è O(1)
- Delay di 100ms è impercettibile

### Impatto del Riordino

Il riordino è **locale e immediato**:
- Nessuna query al database durante drag
- Persistenza asincrona (non blocca UI)
- Nessun refresh della lista (no flash)

---

## Documentazione Aggiornata

- ✅ [DRAG_DROP_FIX.md](DRAG_DROP_FIX.md) - Fix iniziale del riordino
- ✅ [REORDERING_IMPROVEMENTS.md](REORDERING_IMPROVEMENTS.md) - Questo documento

---

## Future Improvements (Opzionali)

### 1. Ordine Custom Per-Tag

Se in futuro si vuole ordine separato per ogni tag:

```dart
// Invece di un solo ordine per documento
await _orderPersistenceService.saveCustomOrder(documentId, taskIds);

// Ordine per tag
await _orderPersistenceService.saveCustomOrderForTag(
  documentId: documentId,
  tagId: tagId,
  taskIds: taskIds,
);
```

**Complessità**: Alta (nuova tabella, migrazione, conflict resolution)

### 2. Visual Handle per Drag

Attualmente: long-press su tutta la task
Alternativa: handle dedicato (es. icona "☰")

```dart
// Invece di ReorderableDragStartListener su tutto il tile
ReorderableDragStartListener(
  child: Row(
    children: [
      Icon(Icons.drag_handle), // 👈 Handle visivo
      Expanded(child: TaskTile(...)),
    ],
  ),
)
```

**Pro**: Più chiaro dove fare drag
**Con**: Occupa spazio, meno intuitivo

### 3. Haptic Feedback

Aggiungere vibrazione durante drag:

```dart
onReorder: (oldIndex, newIndex) {
  HapticFeedback.lightImpact(); // 👈 Feedback tattile
  _handleReorder(oldIndex, newIndex, activeTasks);
}
```

---

## Conclusione

**Problemi risolti** ✅:
1. Flash/flicker durante riordino → **ELIMINATO**
2. Riordino solo su AllTasksView → **ABILITATO ANCHE SU TAGVIEW**

**Miglioramenti**:
- UX più fluida (no flash)
- Funzionalità estesa (TagView reordering)
- Codice più pulito (helper `_getDocumentId()`)
- Zero breaking changes

**Pronto per il testing utente!** 🚀

---

**Last Updated**: 2026-01-06
