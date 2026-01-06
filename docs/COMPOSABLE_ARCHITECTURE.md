# Composable Component Architecture

## Il Problema dell'Astrazione Rigida

### Approccio Iniziale (❌ Fallito)

```dart
// Base class che forza un pattern specifico
abstract class FilterableListView<T, F> extends StatelessWidget {
  final F? filterConfig;

  // Forza il widget a implementare questi metodi
  List<T> filterItems(List<T> items, F? config);
  List<T> sortItems(List<T> items, F? config);
  Widget buildItem(BuildContext context, T item, int index);
}

// Problema: AllTasksView usa BLoC che già gestisce filtering/sorting!
// La classe base duplica la logica e crea conflitti.
```

**Problemi:**
1. **Coupling con pattern specifici**: Forza l'uso di filtering/sorting nel widget
2. **Incompatibile con BLoC**: Il BLoC già gestisce filtering, perché duplicarlo?
3. **Incompatibile con granular rebuilds**: Non permette ValueNotifier custom
4. **Non componibile**: Non puoi usare solo alcune parti

---

## La Soluzione: Composizione > Ereditarietà

### Principi Fondamentali

1. **Separation of Concerns**: UI separata da logica
2. **Pure Functions**: Utilities che non gestiscono stato
3. **Builder Pattern**: Iniettare comportamento tramite callback
4. **Composable**: Usa solo ciò che ti serve

### Architettura a Tre Livelli

```
┌─────────────────────────────────────┐
│   Application Layer (Views)         │
│   - AllTasksView                    │
│   - TagView                         │
│   - Uses BLoC/Provider/setState     │
└─────────────────────────────────────┘
              ↓ composes
┌─────────────────────────────────────┐
│   Composable Utilities              │
│   - buildTaskEmptyState()           │
│   - buildTaskLoadingState()         │
│   - filterTasksByCompletion()       │
│   - ReorderableListBuilder          │
│   - HighlightAnimationMixin         │
└─────────────────────────────────────┘
              ↓ uses
┌─────────────────────────────────────┐
│   Generic Core Utilities            │
│   - buildEmptyState()               │
│   - buildLoadingState()             │
│   - buildErrorState()               │
└─────────────────────────────────────┘
```

---

## Componenti Chiave

### 1. Generic List Helpers (Core Layer)

**File**: `lib/core/components/lists/utils/list_helpers.dart`

**Filosofia**: Pure functions che costruiscono UI, zero gestione stato.

```dart
// ✅ Funzione pura che costruisce UI
Widget buildEmptyState({
  required BuildContext context,
  required IconData icon,
  required String title,
  String? subtitle,
  Widget? action,
}) {
  // Ritorna solo UI, nessuna logica
  return Center(child: /* ... */);
}
```

**Vantaggi:**
- Funziona con **qualsiasi** state management
- Testabile facilmente (pure function)
- Zero coupling
- Riutilizzabile ovunque

**Uso con BLoC:**
```dart
BlocBuilder<TaskListBloc, TaskListState>(
  builder: (context, state) {
    if (state.tasks.isEmpty) {
      return buildEmptyState(
        context: context,
        icon: Icons.task_outlined,
        title: 'No tasks',
        action: FilledButton(
          onPressed: () => bloc.add(ClearFiltersEvent()),
          child: Text('Clear filters'),
        ),
      );
    }
    // ...
  },
)
```

**Uso con setState:**
```dart
if (_tasks.isEmpty) {
  return buildEmptyState(
    context: context,
    icon: Icons.task_outlined,
    title: 'No tasks',
    action: FilledButton(
      onPressed: () => setState(() => _filter = null),
      child: Text('Clear filters'),
    ),
  );
}
```

### 2. Task-Specific Helpers (Domain Layer)

**File**: `lib/features/documents/presentation/utils/task_list_helpers.dart`

**Filosofia**: Compone le utilities generiche con logica specifica delle task.

```dart
// ✅ Compone buildEmptyState() con logica task-specific
Widget buildTaskEmptyState({
  required BuildContext context,
  required FilterSortConfig filterConfig,
  required bool showCompletedTasks,
  VoidCallback? onClearFilters,
}) {
  final hasFilters = filterConfig.hasFilters;

  // Usa la utility generica
  return buildEmptyState(
    context: context,
    icon: hasFilters ? Icons.filter_alt_off : Icons.task_outlined,
    title: hasFilters ? 'Nessuna task trovata' : 'Nessuna task',
    subtitle: hasFilters
      ? 'Prova a modificare i filtri'
      : 'Aggiungi la tua prima task!',
    action: hasFilters && onClearFilters != null
        ? FilledButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Rimuovi filtri'),
          )
        : null,
  );
}
```

**Vantaggi:**
- Mantiene consistenza UI per tutte le task lists
- Ancora zero coupling con state management
- Facile da testare

### 3. ReorderableListBuilder (Builder Pattern)

**File**: `lib/core/components/lists/builders/reorderable_list_builder.dart`

**Filosofia**: Fornisce UI per drag-and-drop, la logica viene iniettata.

```dart
// ✅ Builder che non gestisce stato
class ReorderableListBuilder<T extends Object> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) getItemKey;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final Widget Function(BuildContext, T, int) itemBuilder;

  // ... NO filtering, NO sorting, NO persistence logic
}
```

**Uso con BLoC + TaskStateManager (AllTasksView):**
```dart
ReorderableListBuilder<Task>(
  items: displayedTasks,
  getItemKey: (task) => task.id,
  config: ReorderableConfig.smoothImmediate,

  // Inietta callback che usa BLoC
  onReorder: (oldIndex, newIndex) {
    setState(() {
      final task = displayedTasks.removeAt(oldIndex);
      displayedTasks.insert(newIndex, task);
    });

    // Persisti usando il service esistente
    _orderPersistenceService.saveCustomOrder(
      documentId: document.id,
      taskIds: displayedTasks.map((t) => t.id).toList(),
    );
  },

  // Inietta item builder con granular rebuild
  itemBuilder: (context, task, index) {
    return ValueListenableBuilder(
      valueListenable: taskNotifiers[task.id]!,
      builder: (context, updatedTask, _) {
        return TaskListItem(task: updatedTask);
      },
    );
  },
)
```

**Uso con Provider:**
```dart
ReorderableListBuilder<Task>(
  items: tasks,
  getItemKey: (task) => task.id,
  onReorder: (oldIndex, newIndex) {
    context.read<TaskProvider>().reorder(oldIndex, newIndex);
  },
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

**Vantaggi:**
- Funziona con BLoC, Provider, Riverpod, GetX, setState
- Permette granular rebuilds custom
- Non duplica logica già esistente
- Composable: usa solo il drag-and-drop UI

### 4. HighlightAnimationMixin

**File**: `lib/core/components/animations/highlight_animation_mixin.dart`

**Filosofia**: Mixin riutilizzabile per animazioni, non forza pattern.

```dart
// ✅ Mixin che aggiunge solo animazione
mixin HighlightAnimationMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {

  void initHighlightAnimation() { /* setup */ }
  void startHighlightAnimation() { /* trigger */ }
  void disposeHighlightAnimation() { /* cleanup */ }

  Widget buildWithHighlight(BuildContext context, {required Widget child}) {
    // Ritorna child wrappato con animazione
  }
}
```

**Uso:**
```dart
class _TaskItemState extends State<TaskItem>
    with SingleTickerProviderStateMixin, HighlightAnimationMixin {

  @override
  void initState() {
    super.initState();
    initHighlightAnimation();
    startHighlightAnimation();
  }

  @override
  void dispose() {
    disposeHighlightAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildWithHighlight(
      context,
      child: TaskListItem(task: widget.task),
    );
  }
}
```

---

## Confronto: Prima vs Dopo

### AllTasksView - Prima (1005 righe)

```dart
class _AnimatedTaskListBuilderState extends State<_AnimatedTaskListBuilder> {
  // 150+ linee di logica filtering/sorting duplicata
  void _applyFiltersToRawData(List<Task> allTasks) async {
    var tasks = allTasks.where((t) => t.status != TaskStatus.completed).toList();

    if (widget.filterConfig.tagIds.isNotEmpty) {
      tasks = await tasks.applyFilterSortAsync(widget.filterConfig);
    } else {
      tasks = tasks.applyFilterSort(widget.filterConfig);
    }

    if (widget.filterConfig.sortBy == TaskSortOption.custom) {
      final savedOrder = await orderPersistenceService.loadCustomOrder(widget.document.id);
      if (savedOrder != null) {
        tasks = tasks.applyCustomOrder(savedOrder);
      }
    }

    _updateDisplayedTasks(tasks);
  }

  // 72+ linee di highlight animation duplicata
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  // ... setup animation ...

  // 35+ linee di empty state custom
  Widget buildEmptyState() {
    return Center(child: Column(/* ... */));
  }

  // Logica complessa per incremental updates
  void _updateDisplayedTasks(List<Task> newTasks) {
    // 100+ linee di diff logic
  }
}
```

### AllTasksView - Dopo (331 righe, -67%)

```dart
class _AllTasksViewContentState extends State<_AllTasksViewContent> {
  // ✅ BLoC gestisce filtering/sorting (non duplicato)
  // ✅ Utilities gestiscono UI standard
  // ✅ Builder gestisce reordering
  // ✅ Mixin gestisce animation

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        return switch (state) {
          // Usa utilities invece di duplicare
          TaskListLoading() => buildTaskLoadingState(context: context),

          TaskListError(:final message) => buildTaskErrorState(
            context: context,
            message: message,
            onRetry: () => bloc.add(RetryEvent()),
          ),

          TaskListLoaded(:final tasks, :final filterConfig) =>
            tasks.isEmpty
              ? buildTaskEmptyState(
                  context: context,
                  filterConfig: filterConfig,
                  showCompletedTasks: false,
                  onClearFilters: () => bloc.add(ClearFiltersEvent()),
                )
              : ReorderableListBuilder<Task>(
                  items: tasks,
                  getItemKey: (task) => task.id,
                  onReorder: _handleReorder,
                  itemBuilder: _buildTaskItem,
                ),
        };
      },
    );
  }
}
```

---

## Benefici dell'Approccio Compositivo

### 1. Compatibilità con Qualsiasi State Management

```dart
// ✅ BLoC
BlocBuilder<Bloc, State>(
  builder: (context, state) {
    if (state.items.isEmpty) {
      return buildEmptyState(/* ... */);
    }
  },
)

// ✅ Provider
Consumer<ItemProvider>(
  builder: (context, provider, _) {
    if (provider.items.isEmpty) {
      return buildEmptyState(/* ... */);
    }
  },
)

// ✅ Riverpod
Consumer(
  builder: (context, ref, _) {
    final items = ref.watch(itemsProvider);
    if (items.isEmpty) {
      return buildEmptyState(/* ... */);
    }
  },
)

// ✅ setState
if (_items.isEmpty) {
  return buildEmptyState(/* ... */);
}
```

### 2. Zero Duplicazione Logica

**Prima**: Filtering in BLoC + Filtering in FilterableListView = duplicazione

**Dopo**: Filtering solo in BLoC, utilities forniscono solo UI

### 3. Granular Rebuilds Preservati

```dart
// AllTasksView usa TaskStateManager per rebuilds granulari
ReorderableListBuilder<Task>(
  items: tasks,
  itemBuilder: (context, task, index) {
    // Inietta il tuo sistema custom di rebuilds
    return ValueListenableBuilder(
      valueListenable: taskNotifiers[task.id]!,
      builder: (context, updatedTask, _) {
        return buildWithHighlight(
          context,
          child: TaskListItem(task: updatedTask),
        );
      },
    );
  },
)
```

### 4. Testabilità

```dart
// Test utilities pure functions
testWidgets('buildEmptyState shows correct icon', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: buildEmptyState(
        context: tester.element(find.byType(MaterialApp)),
        icon: Icons.task_outlined,
        title: 'No tasks',
      ),
    ),
  );

  expect(find.byIcon(Icons.task_outlined), findsOneWidget);
});
```

---

## Metriche di Miglioramento

### Riduzione Codice

| File | Prima | Dopo | Riduzione |
|------|-------|------|-----------|
| AllTasksView | 1005 linee | 331 linee | **-67%** |
| Highlight Animation | 72 linee × 3 = 216 | Mixin: 90 linee | **-58%** |
| Empty State | 35 linee × 3 = 105 | Utility: 40 linee | **-62%** |
| **Totale** | **~1326 linee** | **~461 linee** | **-65%** |

### Riutilizzabilità

- **Utilities generiche**: Usabili in **qualsiasi** feature (documents, tags, notes, etc.)
- **Utilities task-specific**: Usabili in tutte le task views (AllTasks, TagDetail, Completed, etc.)
- **Builder**: Funziona con **qualsiasi** tipo `<T>` e **qualsiasi** state management

### Manutenibilità

- **Single Source of Truth**: Empty state definito una volta, usato ovunque
- **Easy Updates**: Cambia `buildEmptyState()` e tutti i widgets beneficiano
- **No Breaking Changes**: Aggiungere parametri opzionali non rompe codice esistente

---

## Pattern di Utilizzo

### Pattern 1: View Semplice (Solo Empty State)

```dart
class SimpleListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = getItems();

    if (items.isEmpty) {
      return buildEmptyState(
        context: context,
        icon: Icons.inbox,
        title: 'No items',
      );
    }

    return ListView.builder(/* ... */);
  }
}
```

### Pattern 2: View con Filtering (BLoC)

```dart
class FilteredListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListBloc, ListState>(
      builder: (context, state) {
        return switch (state) {
          ListLoading() => buildLoadingState(context: context),
          ListError(:final error) => buildErrorState(
            context: context,
            message: error,
            onRetry: () => context.read<ListBloc>().add(RetryEvent()),
          ),
          ListLoaded(:final items, :final filter) => items.isEmpty
            ? buildEmptyState(
                context: context,
                icon: Icons.filter_alt_off,
                title: 'No results',
                action: FilledButton(
                  onPressed: () => context.read<ListBloc>().add(ClearFilterEvent()),
                  child: Text('Clear filters'),
                ),
              )
            : ListView.builder(/* ... */),
        };
      },
    );
  }
}
```

### Pattern 3: View con Reordering + Granular Rebuilds

```dart
class ReorderableView extends StatefulWidget {
  @override
  State<ReorderableView> createState() => _ReorderableViewState();
}

class _ReorderableViewState extends State<ReorderableView> {
  final _stateManager = StateManager();
  List<Item> _items = [];

  @override
  Widget build(BuildContext context) {
    return ReorderableListBuilder<Item>(
      items: _items,
      getItemKey: (item) => item.id,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
        _persistOrder(_items);
      },
      itemBuilder: (context, item, index) {
        return ValueListenableBuilder(
          valueListenable: _stateManager.getNotifier(item.id),
          builder: (context, updatedItem, _) {
            return ItemWidget(item: updatedItem);
          },
        );
      },
    );
  }
}
```

---

## Conclusioni

### Principi Chiave

1. **Composition > Inheritance**
   - Utilities componibili invece di base classes rigide

2. **Separation of Concerns**
   - UI utilities non gestiscono stato
   - State management delegato al pattern scelto dall'app

3. **Flexibility**
   - Funziona con BLoC, Provider, Riverpod, GetX, setState
   - Permette pattern custom (granular rebuilds, etc.)

4. **Reusability**
   - Utilities generiche usabili ovunque
   - Domain utilities mantengono consistenza

5. **Testability**
   - Pure functions facilmente testabili
   - No mocking di base classes complesse

### Quando Usare Questo Approccio

✅ **Usa utilities composable quando:**
- Hai multiple views con UI simili (empty state, loading, error)
- Usi già un pattern di state management (BLoC, Provider, etc.)
- Vuoi mantenere flessibilità nel rebuild system
- Vuoi riutilizzare solo parti specifiche

❌ **Non usare (usa widget diretto) quando:**
- View è completamente unica (nessuna riutilizzabilità)
- Non hai pattern comuni da astrarre
- View è molto semplice (< 50 linee)

---

## File Structure

```
lib/
├── core/
│   └── components/
│       ├── lists/
│       │   ├── utils/
│       │   │   └── list_helpers.dart          # Generic utilities
│       │   └── builders/
│       │       └── reorderable_list_builder.dart  # Builder component
│       └── animations/
│           └── highlight_animation_mixin.dart # Animation mixin
│
├── features/
│   └── documents/
│       └── presentation/
│           ├── utils/
│           │   └── task_list_helpers.dart     # Task-specific utilities
│           └── views/
│               └── all_tasks_view_v2.dart     # Using composable approach
│
└── views/
    └── documents/
        ├── all_tasks_view.dart                # Original (1005 lines)
        └── all_tasks_view_v2.dart             # Refactored (331 lines)
```
