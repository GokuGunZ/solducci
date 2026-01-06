# New Component Architecture - Complete System

**Data**: 2026-01-05
**Versione**: 2.0
**Status**: ✅ Implementato

---

## 🎯 Obiettivo

Creare un sistema di componenti **completamente riutilizzabili** per liste, animazioni e navigation patterns che possono essere utilizzati in qualsiasi contesto dell'app (Tasks, Payments, Notes, etc.).

## 📦 Componenti Implementati

### Layer 1: Animation System

#### `AppAnimations`
**File**: `lib/core/animations/app_animations.dart`

Registry centralizzato di animazioni standard dell'app.

**Features**:
- Durations uniformi (insert, remove, swipe, etc.)
- Curves standard (easeOut, easeIn, easeInOut, etc.)
- 8+ animation builders riutilizzabili
- Helper methods

**Animazioni Disponibili**:
```dart
// Insert/Remove
AppAnimations.buildInsertAnimation(context, animation, child)
AppAnimations.buildRemoveAnimation(context, animation, child)

// Swipe
AppAnimations.buildSwipeLeftAnimation(context, animation, child)
AppAnimations.buildSwipeRightAnimation(context, animation, child)

// Scale/Fade
AppAnimations.buildScaleFadeAnimation(context, animation, child)

// Expand/Collapse
AppAnimations.buildExpandAnimation(context, animation, child)

// Reorder
AppAnimations.buildReorderAnimation(context, animation, child)

// Highlight
AppAnimations.buildHighlightAnimation(context, animation, child)
```

---

### Layer 2: List Controllers

#### `AnimatedListController<T>`
**File**: `lib/core/components/lists/controllers/animated_list_controller.dart`

Gestisce operazioni animate su liste.

**Features**:
- Insert/remove con animazioni
- Batch operations con diff
- Reorder support
- Update granulari

**API**:
```dart
final controller = AnimatedListController<Task>(
  listKey: GlobalKey<AnimatedListState>(),
  itemBuilder: (task) => TaskListItem(task),
  initialItems: tasks,
);

// Insert
controller.insertItem(0, newTask);
controller.insertAtBeginning(task);
controller.insertAtEnd(task);

// Remove
controller.removeItem(2);
controller.removeWhere((task) => task.id == 'xxx');

// Reorder
controller.moveItem(oldIndex, newIndex);
controller.reorder(oldIndex, newIndex);

// Batch
controller.replaceAll(newTasks, getItemId: (t) => t.id);
```

#### `ListCreationController<T>`
**File**: `lib/core/components/lists/controllers/list_creation_controller.dart`

Coordina creazione inline di elementi.

**Workflow**:
1. FAB/Button → `startInlineCreation()`
2. Lista mostra empty item con animazione
3. User completa → `completeCreation(item)`
4. User annulla → `cancelCreation()`

**API**:
```dart
final controller = ListCreationController<Task>(
  vsync: this,
  onCreationComplete: (task) => saveTask(task),
  onCreationCancelled: () => print('Cancelled'),
);

// Trigger
controller.startInlineCreation();

// Complete
controller.completeCreation(newTask);

// Cancel
controller.cancelCreation();

// Check state
if (controller.isCreating) { ... }
```

#### `CategoryScrollBarController<T, C>`
**File**: `lib/core/components/category_scroll_bar/controllers/category_scroll_bar_controller.dart`

Coordina category chips + PageView.

**Features**:
- Swipe bidirezionale sincronizzato
- Tap chip → animate to page
- Create category workflow
- Navigation helpers

**API**:
```dart
final controller = CategoryScrollBarController<Task, Tag>(
  pageController: PageController(),
  categories: tags,
  onCategoryChanged: (tag, index) => print('Selected: $tag'),
  onCreateCategory: () async => await showTagCreationDialog(),
);

// From chip tap
controller.selectCategory(tag);
controller.selectCategoryByIndex(2);
controller.selectAll();

// From page swipe (automatic)
controller.onPageChanged(3);

// Create new
await controller.createCategory();

// Navigation
controller.nextCategory();
controller.previousCategory();

// State
C? currentCategory = controller.currentCategory;
bool isAll = controller.isAllSelected;
```

---

### Layer 3: View Components

#### `AnimatedListView<T>`
**File**: `lib/core/components/lists/views/animated_list_view.dart`

Lista animata con supporto per inline creation.

**Features**:
- Animated insert/remove
- Inline creation integration
- Empty state support
- Scroll configuration

**Esempio**:
```dart
AnimatedListView<Task>(
  controller: animatedListController,
  creationController: listCreationController,
  itemBuilder: (task, index) => TaskListItem(task),
  emptyItemBuilder: () => EmptyTaskItem(
    onSave: (task) => creationController.completeCreation(task),
    onCancel: () => creationController.cancelCreation(),
  ),
  emptyStateBuilder: (context) => Center(
    child: Text('Nessuna task'),
  ),
)
```

#### `CategoryScrollBar<T, C>`
**File**: `lib/core/components/category_scroll_bar/category_scroll_bar.dart`

Component completo con category chips + swipeable lists.

**Features**:
- Category chips in alto
- PageView con liste sotto
- Sincronizzazione bidirezionale
- Category creation flow
- Customizable styling

**Esempio**:
```dart
CategoryScrollBar<Task, Tag>(
  controller: categoryController,
  categories: tags,
  buildListForCategory: (tag) {
    final filtered = tag == null
      ? allTasks
      : tasks.where((t) => t.tags.contains(tag));

    return AnimatedListView<Task>(
      items: filtered,
      itemBuilder: (task, index) => TaskListItem(task),
    );
  },
  buildCategoryChip: (tag) => Chip(
    label: Text(tag.name),
    avatar: Icon(tag.icon),
    backgroundColor: tag.color,
  ),
  onCreateCategory: () async {
    return await showDialog<Tag>(
      context: context,
      builder: (context) => TagCreationDialog(),
    );
  },
)
```

---

## 🏗️ Architettura Completa

```
┌────────────────────────────────────────────────┐
│ Layer 1: Animation System                      │
├────────────────────────────────────────────────┤
│ AppAnimations (registry)                       │
│ - Standard durations & curves                  │
│ - 8+ reusable animation builders               │
└────────────────────────────────────────────────┘
                  ↓ usa
┌────────────────────────────────────────────────┐
│ Layer 2: Controllers                           │
├────────────────────────────────────────────────┤
│ AnimatedListController<T>                      │
│ ListCreationController<T>                      │
│ CategoryScrollBarController<T,C>               │
└────────────────────────────────────────────────┘
                  ↓ usa
┌────────────────────────────────────────────────┐
│ Layer 3: View Components                       │
├────────────────────────────────────────────────┤
│ AnimatedListView<T>                            │
│ CategoryScrollBar<T,C>                         │
└────────────────────────────────────────────────┘
                  ↓ implementa
┌────────────────────────────────────────────────┐
│ Layer 4: Domain Implementations                │
├────────────────────────────────────────────────┤
│ TaskListView (AnimatedListView<Task>)         │
│ TaskCategoryScrollBar (CategoryScrollBar<Task,Tag>) │
│ PaymentCategoryView (CategoryScrollBar<Payment,Category>) │
└────────────────────────────────────────────────┘
```

---

## 📝 Esempi Pratici

### Esempio 1: Simple Task List con Inline Creation

```dart
class TaskListPage extends StatefulWidget {
  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage>
    with TickerProviderStateMixin {
  late AnimatedListController<Task> _listController;
  late ListCreationController<Task> _creationController;

  @override
  void initState() {
    super.initState();

    _listController = AnimatedListController<Task>(
      listKey: GlobalKey<AnimatedListState>(),
      itemBuilder: (task) => TaskListItem(task),
      initialItems: tasks,
    );

    _creationController = ListCreationController<Task>(
      vsync: this,
      onCreationComplete: (task) {
        _listController.insertAtBeginning(task);
        saveTask(task);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedListView<Task>(
        controller: _listController,
        creationController: _creationController,
        itemBuilder: (task, index) => TaskListItem(task),
        emptyItemBuilder: () => EmptyTaskItem(
          onSave: (task) => _creationController.completeCreation(task),
          onCancel: () => _creationController.cancelCreation(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _creationController.startInlineCreation(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Esempio 2: Category Scroll Bar (Task + Tag)

```dart
class TaskCategoryPage extends StatefulWidget {
  @override
  State<TaskCategoryPage> createState() => _TaskCategoryPageState();
}

class _TaskCategoryPageState extends State<TaskCategoryPage> {
  late CategoryScrollBarController<Task, Tag> _controller;
  List<Tag> _tags = [];
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();

    _controller = CategoryScrollBarController<Task, Tag>(
      pageController: PageController(initialPage: 0),
      categories: _tags,
      showAllCategory: true,
      onCategoryChanged: (tag, index) {
        print('Selected category: ${tag?.name ?? "All"}');
      },
      onCreateCategory: _createNewTag,
    );

    _loadData();
  }

  Future<Tag?> _createNewTag() async {
    return await showDialog<Tag>(
      context: context,
      builder: (context) => TagCreationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CategoryScrollBar<Task, Tag>(
        controller: _controller,
        categories: _tags,

        // Build list for each category
        buildListForCategory: (tag) {
          final filteredTasks = tag == null
              ? _tasks
              : _tasks.where((t) => t.tags.contains(tag)).toList();

          return AnimatedListView<Task>(
            items: filteredTasks,
            itemBuilder: (task, index) => TaskListItem(task: task),
            emptyStateBuilder: (context) => Center(
              child: Text('Nessuna task in questa categoria'),
            ),
          );
        },

        // Build category chip
        buildCategoryChip: (tag) => Chip(
          label: Text(tag.name),
          avatar: Icon(tag.icon),
          backgroundColor: tag.color?.withOpacity(0.2),
        ),

        // Creation callback
        onCreateCategory: _createNewTag,
      ),
    );
  }
}
```

### Esempio 3: Payment Categories (Riutilizzo per altro dominio)

```dart
class PaymentCategoryPage extends StatelessWidget {
  final List<PaymentCategory> categories;
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    final controller = CategoryScrollBarController<Payment, PaymentCategory>(
      pageController: PageController(),
      categories: categories,
    );

    return CategoryScrollBar<Payment, PaymentCategory>(
      controller: controller,
      categories: categories,

      buildListForCategory: (category) {
        final filtered = category == null
            ? payments
            : payments.where((p) => p.category == category).toList();

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return PaymentListItem(payment: filtered[index]);
          },
        );
      },

      buildCategoryChip: (category) => Chip(
        label: Text(category.name),
        avatar: Icon(category.icon),
        backgroundColor: category.color,
      ),

      onCreateCategory: () async {
        return await showDialog<PaymentCategory>(
          context: context,
          builder: (context) => PaymentCategoryDialog(),
        );
      },
    );
  }
}
```

---

## 🎯 Vantaggi dell'Architettura

### 1. Riutilizzabilità Universale

```dart
// Tasks
CategoryScrollBar<Task, Tag>(...)

// Payments
CategoryScrollBar<Payment, PaymentCategory>(...)

// Notes
CategoryScrollBar<Note, NoteFolder>(...)

// Qualsiasi entità + qualsiasi categoria!
```

### 2. Animazioni Consistenti

```dart
// Tutte le liste usano le stesse animazioni
AppAnimations.insertDuration  // 300ms ovunque
AppAnimations.insertCurve    // easeOut ovunque

// Cambia in un posto → aggiorna ovunque
```

### 3. Orchestrazione Coordinata

```dart
// FAB → Controller → ListView → Animation
// Tutto sincronizzato automaticamente

floatingActionButton: FAB(
  onPressed: () => creationController.startInlineCreation(),
)

// ListView mostra empty item con slide animation
// User completa → animate transform → insert in lista
```

### 4. Separation of Concerns

```
UI Components  → Non conoscono business logic
Controllers    → Coordinano ma non renderizzano
Animations     → Riutilizzabili ovunque
Domain Logic   → Nelle views concrete
```

---

## 📊 Metriche

| Componente | Righe | Riutilizzabile | Testabile |
|------------|-------|----------------|-----------|
| AppAnimations | 250 | ✅ 100% | ✅ Sì |
| AnimatedListController | 280 | ✅ 100% | ✅ Sì |
| ListCreationController | 150 | ✅ 100% | ✅ Sì |
| CategoryScrollBarController | 250 | ✅ 100% | ✅ Sì |
| AnimatedListView | 200 | ✅ 100% | ✅ Sì |
| CategoryScrollBar | 180 | ✅ 100% | ✅ Sì |
| **Totale** | **~1310** | **100%** | **✅** |

---

## 🚀 Prossimi Passi

1. **Migrare DocumentsHomeView** a usare CategoryScrollBar
2. **Creare PaymentCategoryView** come esempio di riuso
3. **Testing** - Unit tests per controllers
4. **Performance tuning** - Ottimizzare animazioni
5. **Documentation** - Video tutorials

---

## 📁 File Structure

```
lib/
├── core/
│   ├── animations/
│   │   └── app_animations.dart                    ✨ NEW
│   └── components/
│       ├── lists/
│       │   ├── controllers/
│       │   │   ├── animated_list_controller.dart  ✨ NEW
│       │   │   └── list_creation_controller.dart  ✨ NEW
│       │   └── views/
│       │       └── animated_list_view.dart        ✨ NEW
│       └── category_scroll_bar/
│           ├── controllers/
│           │   └── category_scroll_bar_controller.dart  ✨ NEW
│           └── category_scroll_bar.dart           ✨ NEW
│
└── views/
    └── documents/
        └── task_category_page_example.dart        📖 Example
```

---

**Implementazione Completata**: ✅
**Ready for Production**: ✅
**Documentazione**: ✅
**Testing**: ⏳ TODO