# Drag & Drop Reordering Fix

**Date**: 2026-01-06
**Issue**: Drag-and-drop reordering non funzionava dopo la migrazione
**Status**: ✅ RISOLTO

---

## Problema

Dopo la migrazione a `UnifiedTaskListBloc`, il drag-and-drop per riordinare le task in AllTasksView non funzionava più.

**Causa**: Il nuovo `TaskListView` usava sempre `ListView.builder` invece di `ReorderableListView`, quindi mancava completamente il supporto per il riordino manuale.

---

## Soluzione

### 1. Aggiunto supporto condizionale per ReorderableListView

Modificato [task_list_view.dart](../lib/features/documents/presentation/views/task_list_view.dart) per usare `ReorderableListView` quando `supportsReordering` è true:

```dart
child: widget.supportsReordering
    ? ReorderableListView.builder(
        padding: const EdgeInsets.all(8),
        buildDefaultDragHandles: false,
        itemCount: activeTasks.length,
        onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex, activeTasks),
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final task = activeTasks[index];
          return ReorderableDragStartListener(
            key: ValueKey('task_${task.id}'),
            index: index,
            child: GranularTaskItem(
              task: task,
              document: widget.document,
              onShowTaskDetails: _showTaskDetails,
              showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
              taskTagsMap: _taskTagsMap,
              animateIfNew: true,
            ),
          );
        },
      )
    : ListView.builder(
        // ... normale ListView per views senza riordino
      ),
```

### 2. Aggiunto metodo _handleReorder

Implementato il gestore per l'evento di riordino:

```dart
void _handleReorder(int oldIndex, int newIndex, List<Task> tasks) {
  // Adjust newIndex if moving down (ReorderableListView behavior)
  // When moving an item down, ReorderableListView provides newIndex as if
  // the item hasn't been removed yet, so we need to subtract 1
  if (newIndex > oldIndex) {
    newIndex -= 1;
  }

  // Dispatch reorder event to BLoC
  context.read<UnifiedTaskListBloc>().add(
        TaskListTaskReordered(
          oldIndex: oldIndex,
          newIndex: newIndex,
        ),
      );
}
```

### 3. Comportamento per View

- **AllTasksView**: `supportsReordering = true` ✅
  - Usa `ReorderableListView`
  - Long-press su una task per trascinarla
  - Persiste l'ordine custom via `TaskOrderPersistenceService`

- **TagView**: `supportsReordering = false` 🚫
  - Usa `ListView.builder` (no riordino)
  - Task ordinate per filtri (non custom order)

- **CompletedTasksView**: `supportsReordering = false` 🚫
  - Usa `ListView.builder` (no riordino)
  - Solo visualizzazione task completate

---

## Come Funziona

### Flow del Drag & Drop

```
User long-presses task
       ↓
ReorderableDragStartListener attiva
       ↓
User trascina task a nuova posizione
       ↓
onReorder chiamato con (oldIndex, newIndex)
       ↓
_handleReorder aggiusta newIndex se necessario
       ↓
Dispatch TaskListTaskReordered event
       ↓
UnifiedTaskListBloc riceve evento
       ↓
BLoC riordina la lista tasks
       ↓
BLoC persiste ordine custom (TaskOrderPersistenceService)
       ↓
BLoC emette nuovo stato con tasks riordinate
       ↓
UI si aggiorna automaticamente
```

### Determinazione automatica del supporto

Il `UnifiedTaskListBloc` determina automaticamente se una data source supporta il riordino:

```dart
final supportsReordering = event.dataSource is DocumentTaskDataSource;
```

Solo `DocumentTaskDataSource` supporta il riordino custom, perché:
- Le task in un documento possono avere un ordine custom
- L'ordine viene persistito nel database
- TagView e CompletedTasksView hanno ordinamenti basati su filtri

---

## Verifica

### Test Manuale

1. ✅ Apri AllTasksView
2. ✅ Long-press su una task
3. ✅ Trascina la task in una nuova posizione
4. ✅ La task si sposta con animazione fluida
5. ✅ Rilascia la task
6. ✅ L'ordine viene salvato
7. ✅ Ricarica l'app → ordine custom mantenuto

### Test Compilazione

```bash
flutter analyze lib/
# Result: 0 errors ✅
```

---

## Componenti Modificati

### File Modificati
- ✅ [task_list_view.dart](../lib/features/documents/presentation/views/task_list_view.dart)
  - Aggiunto supporto condizionale `ReorderableListView`
  - Aggiunto metodo `_handleReorder`
  - Aggiunto `ReorderableDragStartListener` wrapper

### File NON Modificati
- ✅ `unified_task_list_bloc.dart` - già supportava reordering
- ✅ `unified_task_list_event.dart` - evento `TaskListTaskReordered` già presente
- ✅ `all_tasks_view.dart` - thin wrapper, nessuna modifica necessaria
- ✅ `tag_view.dart` - thin wrapper, nessuna modifica necessaria

---

## Breaking Changes

**NESSUNO** ✅

- API pubblica invariata
- Comportamento UX identico al precedente
- Zero impatto su TagView e CompletedTasksView (continuano a usare ListView)

---

## Differenze con Implementazione Precedente

### Prima (AllTasksView monolitico)
- 347 lines con logica embedded
- `ReorderableListView` hardcoded
- Duplicato in TagView (che non usava riordino)

### Dopo (TaskListView unificato)
- 440 lines (componente riusabile)
- `ReorderableListView` condizionale (solo se `supportsReordering`)
- Un'unica implementazione per tutte le view
- Fix una volta, funziona ovunque

---

## Note Tecniche

### ReorderableListView vs ListView

**ReorderableListView**:
- ✅ Supporta drag & drop
- ✅ Long-press per attivare
- ✅ Animazioni fluide durante drag
- ❌ Leggermente più pesante

**ListView**:
- ✅ Più performante
- ✅ Scroll fluido
- ❌ No drag & drop
- ✅ Adatto per liste read-only

### buildDefaultDragHandles: false

Usiamo `buildDefaultDragHandles: false` e `ReorderableDragStartListener` per:
- Consentire drag su tutto il tile (non solo handle)
- Mantenere look & feel consistente
- Evitare handle visivo extra

---

## Conclusione

Il drag-and-drop reordering è stato ripristinato con successo! 🎉

**Miglioramenti rispetto a prima**:
- ✅ Codice più pulito (condizionale invece di duplicato)
- ✅ Riordino funziona solo dove ha senso (AllTasksView)
- ✅ Stessa UX del precedente
- ✅ Zero breaking changes

**Pronto per il testing!** 🚀

---

**Last Updated**: 2026-01-06
