# Component Library - Guida all'Uso

## Obiettivo

Creare **componenti astratti riutilizzabili** che possono essere usati in future views o migrazioni, **senza modificare le view esistenti**.

## ⚠️ IMPORTANTE

- ✅ **I componenti sono stati creati** e sono pronti all'uso
- ✅ **Le view esistenti rimangono invariate** (AllTasksView, TagView, etc.)
- ✅ **Nessuna migrazione forzata** - le view funzionano esattamente come prima
- ✅ **Uso opzionale** - i componenti sono disponibili per nuove features o future migrazioni

## Componenti Disponibili

### 1. Core Utilities (Generic)

**File**: `lib/core/components/lists/utils/list_helpers.dart`

Utilities pure che costruiscono UI standard:

```dart
// Empty state
Widget buildEmptyState({
  required BuildContext context,
  required IconData icon,
  required String title,
  String? subtitle,
  Widget? action,
})

// Loading state
Widget buildLoadingState({
  required BuildContext context,
  String? message,
})

// Error state
Widget buildErrorState({
  required BuildContext context,
  required String message,
  VoidCallback? onRetry,
})
```

**Esempio d'uso**:

```dart
// In qualsiasi StatefulWidget o StatelessWidget
@override
Widget build(BuildContext context) {
  if (items.isEmpty) {
    return buildEmptyState(
      context: context,
      icon: Icons.inbox,
      title: 'Nessun elemento',
      subtitle: 'Aggiungi il tuo primo elemento',
    );
  }

  // ... render list
}
```

### 2. Task Utilities (Domain-Specific)

**File**: `lib/features/documents/presentation/utils/task_list_helpers.dart`

Utilities specifiche per le task:

```dart
// Empty state task-specific con logica filtri
Widget buildTaskEmptyState({
  required BuildContext context,
  required FilterSortConfig filterConfig,
  required bool showCompletedTasks,
  VoidCallback? onClearFilters,
})

// Loading state task-specific
Widget buildTaskLoadingState({required BuildContext context})

// Error state task-specific
Widget buildTaskErrorState({
  required BuildContext context,
  required String message,
  VoidCallback? onRetry,
})

// Pure function per filtrare completed tasks
List<Task> filterTasksByCompletion(
  List<Task> tasks, {
  required bool showCompleted,
})
```

**Esempio d'uso**:

```dart
@override
Widget build(BuildContext context) {
  if (tasks.isEmpty) {
    return buildTaskEmptyState(
      context: context,
      filterConfig: _filterConfig,
      showCompletedTasks: false,
      onClearFilters: () => setState(() => _filterConfig = FilterSortConfig()),
    );
  }

  // ... render task list
}
```

### 3. Highlight Animation Mixin

**File**: `lib/core/components/animations/highlight_animation_mixin.dart`

Mixin riutilizzabile per animazioni di highlight:

```dart
mixin HighlightAnimationMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {

  void initHighlightAnimation();
  void startHighlightAnimation();
  void disposeHighlightAnimation();
  Widget buildWithHighlight(BuildContext context, {required Widget child});
}
```

**Esempio d'uso**:

```dart
class _MyItemState extends State<MyItem>
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
      child: ListTile(title: Text('Item')),
    );
  }
}
```

### 4. Reorderable List Builder (Optional)

**File**: `lib/core/components/lists/builders/reorderable_list_builder.dart`

Builder pattern per liste riordinabili (uso opzionale):

```dart
ReorderableListBuilder<T>(
  items: items,
  getItemKey: (item) => item.id,
  config: ReorderableConfig.smoothImmediate,
  onReorder: (oldIndex, newIndex) {
    // Handle reorder
  },
  itemBuilder: (context, item, index) {
    return ItemWidget(item: item);
  },
)
```

## View di Esempio

**File**: `lib/views/documents/all_tasks_view_with_components_example.dart`

Questo file dimostra come una view può utilizzare tutti i componenti creati.

**Caratteristiche**:
- Comportamento identico ad AllTasksView originale
- Usa tutti i componenti astratti
- Riduzione codice stimata ~40%
- Mantiene granular rebuilds con TaskStateManager
- Mantiene drag-and-drop con AnimatedReorderableListView

**NON sostituisce AllTasksView** - è solo un esempio di riferimento.

## Quando Usare i Componenti

### ✅ Usare per:

1. **Nuove views/features**
   - Qualsiasi nuova lista che necessita di empty/loading/error states
   - Nuove task views
   - Altre feature simili (notes, projects, etc.)

2. **Migrazioni future (opzionali)**
   - Se una view esistente necessita refactoring
   - Se si vuole ridurre duplicazione
   - Solo se la migrazione mantiene comportamento identico

3. **Consistency**
   - Mantenere UI consistente in tutta l'app
   - Empty states con stessa struttura
   - Loading/error con stesso styling

### ❌ Non usare per:

1. **View esistenti che funzionano**
   - AllTasksView originale funziona perfettamente → non toccare
   - TagView funziona → non toccare
   - Se non è rotto, non aggiustarlo

2. **View molto custom**
   - Se la view ha logica molto specifica
   - Se i componenti non si adattano naturalmente

3. **Solo per ridurre righe**
   - La riduzione codice è un beneficio, non l'obiettivo
   - La priorità è mantenere funzionalità e performance

## Come Migrare una View (Se Necessario)

### Processo Raccomandato:

1. **Crea una copia** della view originale con suffisso `_with_components`
2. **Sostituisci progressivamente** le parti duplicate con utilities
3. **Testa accuratamente** che il comportamento sia identico
4. **Verifica performance** (granular rebuilds, animations, etc.)
5. **Solo se tutto funziona**, considera di sostituire l'originale
6. **Mantieni backup** della versione originale

### Checklist di Migrazione:

- [ ] Comportamento identico (drag-and-drop, animations, etc.)
- [ ] Performance identiche (granular rebuilds)
- [ ] Tutti i test passano
- [ ] Zero breaking changes
- [ ] Approvazione team/stakeholder

## Vantaggi dei Componenti

### 1. Riutilizzabilità

```dart
// Prima: Duplicato in 3 views (105 righe totali)
Widget buildEmptyState() {
  return Center(child: Column(/* 35 righe */));
}

// Dopo: Definito una volta (40 righe), usato ovunque
buildEmptyState(context: context, icon: Icons.inbox, title: 'Empty')
```

### 2. Consistenza

Tutte le empty states hanno:
- Stessa struttura
- Stesso styling
- Stesso comportamento
- Facile da aggiornare globalmente

### 3. Testabilità

```dart
testWidgets('buildEmptyState shows correct icon', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: buildEmptyState(
        context: tester.element(find.byType(MaterialApp)),
        icon: Icons.task,
        title: 'No tasks',
      ),
    ),
  );

  expect(find.byIcon(Icons.task), findsOneWidget);
  expect(find.text('No tasks'), findsOneWidget);
});
```

### 4. Manutenibilità

Cambio in un posto = aggiornamento globale:

```dart
// Aggiorna padding di tutti gli empty states
Widget buildEmptyState({...}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(48.0), // Era 32.0
      // ...
    ),
  );
}
```

## Metriche

### Codice Riutilizzabile Creato

| Componente | Righe | Uso | Risparmio Potenziale |
|------------|-------|-----|----------------------|
| list_helpers.dart | 150 | Empty/Loading/Error | ~60 righe per view |
| task_list_helpers.dart | 100 | Task-specific utils | ~40 righe per task view |
| HighlightAnimationMixin | 90 | Animation | ~72 righe per view |
| **Totale** | **340** | **Utilities riusabili** | **~170 righe per view** |

### View di Esempio

| Metrica | AllTasksView Originale | Example with Components | Risparmio |
|---------|------------------------|-------------------------|-----------|
| Righe totali | 1005 | ~600 (stima) | -40% |
| Empty state | 35 | Utility | -35 |
| Loading state | 20 | Utility | -20 |
| Error state | 30 | Utility | -30 |
| Highlight animation | 72 | Mixin | -72 |
| **Totale duplicazione rimossa** | **~160** | **Utilities** | **-160** |

## File Structure

```
lib/
├── core/
│   └── components/
│       ├── lists/
│       │   ├── utils/
│       │   │   └── list_helpers.dart              ✨ Utilities generiche
│       │   ├── builders/
│       │   │   └── reorderable_list_builder.dart  ✨ Builder (opzionale)
│       │   └── base/
│       │       └── reorderable_list_view_base.dart
│       └── animations/
│           └── highlight_animation_mixin.dart     ✨ Animation mixin
│
├── features/
│   └── documents/
│       └── presentation/
│           ├── utils/
│           │   └── task_list_helpers.dart         ✨ Task utilities
│           └── components/
│               ├── task_filterable_list_view.dart (legacy)
│               └── task_reorderable_list_view.dart (legacy)
│
├── views/
│   └── documents/
│       ├── all_tasks_view.dart                    ✅ ORIGINALE (funziona)
│       └── all_tasks_view_with_components_example.dart  ✨ ESEMPIO d'uso
│
└── docs/
    ├── COMPOSABLE_ARCHITECTURE.md                 📖 Architettura completa
    ├── COMPONENT_LIBRARY_USAGE.md                 📖 Questa guida
    └── MIGRATION_REPORT.md                        📖 Report migrazione
```

## Conclusioni

### ✅ Cosa È Stato Fatto

1. **Creati componenti astratti riutilizzabili** - Utilities, builders, mixins
2. **Mantenute view esistenti invariate** - AllTasksView funziona come prima
3. **Creato esempio di riferimento** - all_tasks_view_with_components_example.dart
4. **Documentazione completa** - Come e quando usare i componenti

### 🎯 Prossimi Passi (Opzionali)

1. **Usa utilities in nuove views** - Quando crei nuove features
2. **Valuta migrazioni caso per caso** - Solo se porta valore reale
3. **Estendi i componenti** - Aggiungi nuove utilities se necessario
4. **Mantieni documentazione aggiornata** - Quando aggiungi nuovi componenti

### 🔑 Principio Guida

> "Se funziona, non toccarlo. Se crei qualcosa di nuovo, usa i componenti astratti."

I componenti esistono come **opzione**, non come **obbligo**. Usali quando ha senso, non solo per ridurre righe di codice.
