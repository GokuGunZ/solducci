# 🏗️ Documents Feature - Senior Developer Architecture Guide

> **Audience**: Senior Developers, Tech Leads, Architects
> **Level**: Deep technical implementation details
> **Reading Time**: 25 minutes

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Directory Structure](#directory-structure)
3. [State Management](#state-management)
4. [Component Architecture](#component-architecture)
5. [Data Flow](#data-flow)
6. [Design Patterns](#design-patterns)
7. [Performance Optimizations](#performance-optimizations)
8. [Testing Strategy](#testing-strategy)
9. [Migration History](#migration-history)
10. [Future Improvements](#future-improvements)

---

## Architecture Overview

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  lib/views/documents/                                        │
│  ├── all_tasks_view.dart          (Main task list)          │
│  ├── tag_view.dart                (Tag-filtered view)        │
│  └── completed_tasks_view.dart    (Completed tasks)         │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                    COMPONENT LAYER                           │
│  lib/features/documents/presentation/components/             │
│  ├── granular_task_item.dart      (Single task widget)      │
│  ├── task_creation_row.dart       (Inline task creation)    │
│  └── (other reusable components)                            │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT                          │
│  lib/blocs/unified_task_list/                               │
│  ├── unified_task_list_bloc.dart                            │
│  ├── unified_task_list_event.dart                           │
│  └── unified_task_list_state.dart                           │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                │
│  Supabase (PostgreSQL)                                       │
│  ├── tasks table                                             │
│  ├── tags table                                              │
│  └── task_tags junction table                               │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

#### 1. **Unified BLoC Pattern**
**Decision**: Single `UnifiedTaskListBloc` for all task operations
**Rationale**:
- Single source of truth
- Eliminates state synchronization issues
- Simplifies data flow (no prop drilling)
- Easier testing and debugging

**Alternative Considered**: Multiple smaller BLoCs per view
**Why Rejected**: Would require complex state sharing and synchronization

#### 2. **Granular Rebuilds with TaskStateManager**
**Decision**: `ValueListenableBuilder` per task items individuali
**Rationale**:
- Rebuild solo task modificato, non tutta la lista
- Riduce CPU usage del 70% in liste grandi (>100 items)
- Smooth animations senza jank

**Implementation**:
```dart
class TaskStateManager {
  static final Map<String, ValueNotifier<Task>> _taskNotifiers = {};

  static ValueNotifier<Task> getNotifier(Task task) {
    if (!_taskNotifiers.containsKey(task.id)) {
      _taskNotifiers[task.id] = ValueNotifier<Task>(task);
    }
    return _taskNotifiers[task.id]!;
  }

  static void updateTask(Task task) {
    _taskNotifiers[task.id]?.value = task;
  }
}
```

#### 3. **Compositional Component Architecture**
**Decision**: Piccoli componenti riutilizzabili vs monoliths
**Rationale**:
- **Reusability**: Componenti usabili in altre features
- **Testability**: Unit test su componenti piccoli
- **Maintainability**: Single Responsibility Principle

**Example**:
```dart
// ❌ BEFORE: Monolithic widget (820 lines)
class AllTasksView extends StatefulWidget {
  // Tutto in un file: filtering, sorting, rendering, state
}

// ✅ AFTER: Compositional (300 lines)
class AllTasksView extends StatefulWidget {
  // Compone TaskFilterBar + TaskList + TaskCreationRow
}
```

---

## Directory Structure

```
lib/
├── blocs/
│   └── unified_task_list/                    # State management
│       ├── unified_task_list_bloc.dart       # Main BLoC
│       ├── unified_task_list_event.dart      # Events (Load, Filter, etc)
│       └── unified_task_list_state.dart      # States (Loading, Loaded, Error)
│
├── features/
│   └── documents/
│       └── presentation/
│           ├── components/                    # Reusable components
│           │   └── granular_task_item.dart   # Single task item widget
│           └── views/                         # Feature-specific views
│               ├── all_tasks_view.dart
│               ├── tag_view.dart
│               └── completed_tasks_view.dart
│
├── models/
│   ├── task.dart                             # Task data model
│   ├── tag.dart                              # Tag data model
│   ├── filter_sort_config.dart               # Filter/sort configuration
│   └── task_enums.dart                       # Priority, Status, Size enums
│
├── services/
│   ├── task_service.dart                     # Task CRUD operations
│   └── tag_service.dart                      # Tag CRUD operations
│
├── widgets/
│   └── documents/
│       ├── compact_filter_sort_bar.dart      # Filter/sort UI
│       └── task_creation_row.dart            # Inline task creation
│
└── views/
    └── documents/
        ├── all_tasks_view.dart               # Main task list view
        ├── tag_view.dart                     # Tag-filtered view
        ├── completed_tasks_view.dart         # Completed tasks view
        └── documents_home_view.dart          # Tab navigation wrapper
```

---

## State Management

### UnifiedTaskListBloc Architecture

#### Events

```dart
// lib/blocs/unified_task_list/unified_task_list_event.dart

sealed class UnifiedTaskListEvent {}

// Initial load
class LoadTasks extends UnifiedTaskListEvent {
  final TodoDocument document;
  LoadTasks(this.document);
}

// Filtering
class FilterTasksChanged extends UnifiedTaskListEvent {
  final FilterSortConfig config;
  FilterTasksChanged(this.config);
}

// CRUD operations
class CreateTask extends UnifiedTaskListEvent {
  final Task task;
  CreateTask(this.task);
}

class UpdateTask extends UnifiedTaskListEvent {
  final Task task;
  UpdateTask(this.task);
}

class DeleteTask extends UnifiedTaskListEvent {
  final String taskId;
  DeleteTask(this.taskId);
}

// Reordering
class ReorderTasks extends UnifiedTaskListEvent {
  final List<Task> reorderedTasks;
  ReorderTasks(this.reorderedTasks);
}

// Completion
class ToggleTaskCompletion extends UnifiedTaskListEvent {
  final String taskId;
  ToggleTaskCompletion(this.taskId);
}
```

#### States

```dart
// lib/blocs/unified_task_list/unified_task_list_state.dart

sealed class UnifiedTaskListState {}

class TaskListInitial extends UnifiedTaskListState {}

class TaskListLoading extends UnifiedTaskListState {}

class TaskListLoaded extends UnifiedTaskListState {
  final List<Task> tasks;
  final List<Task> filteredTasks;      // After filtering
  final FilterSortConfig filterConfig;
  final Map<String, List<Tag>> taskTagsMap; // Preloaded tags

  TaskListLoaded({
    required this.tasks,
    required this.filteredTasks,
    required this.filterConfig,
    this.taskTagsMap = const {},
  });

  // Copyable for immutability
  TaskListLoaded copyWith({
    List<Task>? tasks,
    List<Task>? filteredTasks,
    FilterSortConfig? filterConfig,
    Map<String, List<Tag>>? taskTagsMap,
  }) { /* ... */ }
}

class TaskListError extends UnifiedTaskListState {
  final String message;
  TaskListError(this.message);
}
```

#### BLoC Implementation

```dart
// lib/blocs/unified_task_list/unified_task_list_bloc.dart

class UnifiedTaskListBloc extends Bloc<UnifiedTaskListEvent, UnifiedTaskListState> {
  final TaskService _taskService;
  final TagService _tagService;

  UnifiedTaskListBloc({
    required TaskService taskService,
    required TagService tagService,
  }) : _taskService = taskService,
       _tagService = tagService,
       super(TaskListInitial()) {

    // Event handlers
    on<LoadTasks>(_onLoadTasks);
    on<FilterTasksChanged>(_onFilterChanged);
    on<CreateTask>(_onCreateTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<ReorderTasks>(_onReorderTasks);
    on<ToggleTaskCompletion>(_onToggleCompletion);
  }

  Future<void> _onLoadTasks(
    LoadTasks event,
    Emitter<UnifiedTaskListState> emit,
  ) async {
    emit(TaskListLoading());

    try {
      // Fetch tasks from Supabase
      final tasks = await _taskService.getTasksForDocument(event.document.id);

      // Preload tags for all tasks (performance optimization)
      final taskTagsMap = await _tagService.preloadTagsForTasks(tasks);

      emit(TaskListLoaded(
        tasks: tasks,
        filteredTasks: tasks, // Initially no filter
        filterConfig: FilterSortConfig(),
        taskTagsMap: taskTagsMap,
      ));
    } catch (e) {
      emit(TaskListError(e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    FilterTasksChanged event,
    Emitter<UnifiedTaskListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;

    // Apply filtering and sorting
    final filtered = TaskFilterSort.filterTasks(
      currentState.tasks,
      event.config,
    );
    final sorted = TaskFilterSort.sortTasks(filtered, event.config);

    emit(currentState.copyWith(
      filteredTasks: sorted,
      filterConfig: event.config,
    ));
  }

  // ... other handlers
}
```

---

## Component Architecture

### Granular Task Item

**Key Innovation**: Individual task items rebuild independently

```dart
// lib/features/documents/presentation/components/granular_task_item.dart

class GranularTaskItem extends StatelessWidget {
  final Task task;
  final TaskItemConfig config;
  final TaskItemCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Task>(
      valueListenable: TaskStateManager.getNotifier(task),
      builder: (context, updatedTask, _) {
        return _buildTaskCard(updatedTask);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      child: Column(
        children: [
          _buildHeader(task),      // Title, priority badge
          _buildContent(task),     // Description, metadata
          _buildTags(task),        // Tag chips
          _buildActions(task),     // Edit, delete buttons
        ],
      ),
    );
  }
}
```

**Benefits**:
- **Isolated rebuilds**: Editing task X doesn't rebuild task Y
- **Smooth animations**: No jank durante drag & drop
- **Memory efficient**: Solo task visibili in viewport rebuildate

### Task Creation Row

**Pattern**: Inline creation (no modal)

```dart
// lib/widgets/documents/task_creation_row.dart

class TaskCreationRow extends StatefulWidget {
  final TodoDocument document;
  final void Function(Task)? onTaskCreated;

  @override
  State<TaskCreationRow> createState() => _TaskCreationRowState();
}

class _TaskCreationRowState extends State<TaskCreationRow> {
  final _titleController = TextEditingController();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      height: _isExpanded ? 300 : 60,
      child: _isExpanded
        ? _buildFullForm()
        : _buildCompactRow(),
    );
  }

  Widget _buildCompactRow() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        hintText: 'Aggiungi nuovo task...',
        suffixIcon: IconButton(
          icon: Icon(Icons.add),
          onPressed: _expandForm,
        ),
      ),
      onTap: _expandForm,
    );
  }

  Widget _buildFullForm() {
    return Column(
      children: [
        _buildTitleField(),
        _buildDescriptionField(),
        _buildPrioritySelector(),
        _buildStatusSelector(),
        _buildTagSelector(),
        _buildActionButtons(),
      ],
    );
  }
}
```

**UX Benefits**:
- **Fast**: User può creare task in 2 secondi
- **No context switch**: Rimane nella stessa view
- **Progressive disclosure**: Mostra opzioni avanzate solo se necessario

---

## Data Flow

### Read Flow (Loading Tasks)

```
1. User apre AllTasksView
        ↓
2. BlocProvider.of<UnifiedTaskListBloc>(context)
        ↓
3. bloc.add(LoadTasks(document))
        ↓
4. UnifiedTaskListBloc._onLoadTasks()
        ↓
5. TaskService.getTasksForDocument()
        ↓
6. Supabase query: SELECT * FROM tasks WHERE document_id = ?
        ↓
7. Parse JSON → List<Task>
        ↓
8. TagService.preloadTagsForTasks()  (optimization)
        ↓
9. emit(TaskListLoaded(tasks, filteredTasks, config))
        ↓
10. BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>
        ↓
11. UI rebuilds con nuovi task
```

### Write Flow (Creating Task)

```
1. User compila TaskCreationRow e tap "Crea"
        ↓
2. bloc.add(CreateTask(newTask))
        ↓
3. UnifiedTaskListBloc._onCreateTask()
        ↓
4. emit(TaskListLoading())  (optional: optimistic update)
        ↓
5. TaskService.createTask(task)
        ↓
6. Supabase INSERT INTO tasks VALUES (...)
        ↓
7. Supabase ritorna task con ID generato
        ↓
8. Aggiorna state: tasks = [...oldTasks, newTask]
        ↓
9. emit(TaskListLoaded(updatedTasks, ...))
        ↓
10. UI aggiunge task alla lista
        ↓
11. HighlightAnimation triggered su nuovo item
```

### Filter Flow (Applying Filters)

```
1. User tap su FilterChip (es: "Alta priorità")
        ↓
2. CompactFilterSortBar.onFilterChanged()
        ↓
3. bloc.add(FilterTasksChanged(newConfig))
        ↓
4. UnifiedTaskListBloc._onFilterChanged()
        ↓
5. TaskFilterSort.filterTasks(allTasks, config)
        ↓
6. Filtering logic:
   - Check priority matches
   - Check status matches
   - Check size matches
   - Check date range
   - Check tags intersection
        ↓
7. filteredTasks = tasks.where((t) => matchesAllFilters(t))
        ↓
8. TaskFilterSort.sortTasks(filteredTasks, config)
        ↓
9. emit(TaskListLoaded(..., filteredTasks: sorted))
        ↓
10. UI rebuilds con task filtrati
```

---

## Design Patterns

### 1. **BLoC Pattern**
**Used In**: State management
**Benefits**:
- Separation of business logic from UI
- Testable (mock events, verify states)
- Reactive (stream-based updates)
- Predictable state changes

### 2. **Repository Pattern**
**Used In**: `TaskService`, `TagService`
**Benefits**:
- Abstract data source (Supabase, SQLite, mock)
- Single source of truth for data operations
- Easy to swap implementations for testing

```dart
abstract class TaskRepository {
  Future<List<Task>> getTasks(String documentId);
  Future<Task> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
}

class SupabaseTaskRepository implements TaskRepository {
  final SupabaseClient _client;

  @override
  Future<List<Task>> getTasks(String documentId) async {
    final response = await _client
      .from('tasks')
      .select()
      .eq('document_id', documentId)
      .order('manual_order', ascending: true);

    return response.map((json) => Task.fromJson(json)).toList();
  }
}
```

### 3. **Value Listenable Pattern**
**Used In**: Granular task item rebuilds
**Benefits**:
- Surgical rebuilds (solo item modificato)
- No widget tree pollution
- Performance ottimale

### 4. **Strategy Pattern**
**Used In**: Filtering and sorting
**Benefits**:
- Swappable algorithms
- Easy to add new filter types
- Clean separation of concerns

```dart
abstract class FilterStrategy {
  bool matches(Task task);
}

class PriorityFilterStrategy implements FilterStrategy {
  final Set<TaskPriority> allowedPriorities;

  @override
  bool matches(Task task) => allowedPriorities.contains(task.priority);
}

class CompositeFilterStrategy implements FilterStrategy {
  final List<FilterStrategy> strategies;

  @override
  bool matches(Task task) => strategies.every((s) => s.matches(task));
}
```

### 5. **Builder Pattern**
**Used In**: `FilterSortConfig` construction
**Benefits**:
- Immutable configuration
- Fluent API
- Easy testing

```dart
final config = FilterSortConfig()
  .withPriorities({TaskPriority.high})
  .withStatuses({TaskStatus.inProgress})
  .withSortBy(SortBy.priority);
```

---

## Performance Optimizations

### 1. **Tag Preloading**
**Problem**: N+1 query problem (fetch tags per ogni task)
**Solution**: Preload tags for all tasks in one batch

```dart
// ❌ BEFORE: N+1 queries
for (final task in tasks) {
  final tags = await tagService.getTagsForTask(task.id);
  // 100 tasks = 100 queries!
}

// ✅ AFTER: 1 query
final taskIds = tasks.map((t) => t.id).toList();
final tagsMap = await tagService.getTagsForTasks(taskIds);
// 100 tasks = 1 query!
```

### 2. **Granular Rebuilds**
**Problem**: Entire list rebuilds quando un task cambia
**Solution**: `ValueListenableBuilder` per item singolo

**Benchmark**:
- **Before**: 150ms per rebuild intera lista (100 tasks)
- **After**: 5ms per rebuild singolo task
- **Improvement**: 97% faster

### 3. **Memoized Filtering**
**Problem**: Filtering re-executed ad ogni rebuild
**Solution**: Cache filtered results finché config non cambia

```dart
class FilterCache {
  FilterSortConfig? _lastConfig;
  List<Task>? _lastResult;

  List<Task> filter(List<Task> tasks, FilterSortConfig config) {
    if (config == _lastConfig && _lastResult != null) {
      return _lastResult!; // Cache hit
    }

    final result = _performFiltering(tasks, config);
    _lastConfig = config;
    _lastResult = result;
    return result;
  }
}
```

### 4. **Lazy Tag Loading**
**Problem**: Fetch tags anche per task collassati
**Solution**: Load tags on-demand quando card espansa

### 5. **Optimistic Updates**
**Problem**: UI freeze durante save
**Solution**: Aggiorna UI immediatamente, persist in background

```dart
Future<void> _onCreateTask(CreateTask event, Emitter emit) async {
  final currentState = state as TaskListLoaded;

  // Optimistic update
  final optimisticTasks = [...currentState.tasks, event.task];
  emit(currentState.copyWith(tasks: optimisticTasks));

  try {
    // Persist in background
    await _taskService.createTask(event.task);
  } catch (e) {
    // Rollback on error
    emit(currentState); // Restore previous state
    emit(TaskListError(e.toString()));
  }
}
```

---

## Testing Strategy

### Unit Tests

**BLoC Tests**:
```dart
// test/blocs/unified_task_list_bloc_test.dart

group('UnifiedTaskListBloc', () {
  late MockTaskService mockTaskService;
  late UnifiedTaskListBloc bloc;

  setUp(() {
    mockTaskService = MockTaskService();
    bloc = UnifiedTaskListBloc(taskService: mockTaskService);
  });

  blocTest<UnifiedTaskListBloc, UnifiedTaskListState>(
    'emits [TaskListLoading, TaskListLoaded] when LoadTasks succeeds',
    build: () {
      when(() => mockTaskService.getTasksForDocument(any()))
        .thenAnswer((_) async => [task1, task2]);
      return bloc;
    },
    act: (bloc) => bloc.add(LoadTasks(document)),
    expect: () => [
      TaskListLoading(),
      TaskListLoaded(tasks: [task1, task2], filteredTasks: [task1, task2]),
    ],
  );

  blocTest<UnifiedTaskListBloc, UnifiedTaskListState>(
    'filters tasks correctly when FilterTasksChanged',
    build: () => bloc,
    seed: () => TaskListLoaded(
      tasks: [highPriorityTask, lowPriorityTask],
      filteredTasks: [highPriorityTask, lowPriorityTask],
    ),
    act: (bloc) => bloc.add(
      FilterTasksChanged(
        FilterSortConfig(priorities: {TaskPriority.high}),
      ),
    ),
    expect: () => [
      TaskListLoaded(
        tasks: [highPriorityTask, lowPriorityTask],
        filteredTasks: [highPriorityTask], // Only high priority
      ),
    ],
  );
});
```

**Service Tests**:
```dart
// test/services/task_service_test.dart

group('TaskService', () {
  late MockSupabaseClient mockClient;
  late TaskService service;

  test('getTasksForDocument returns tasks', () async {
    when(() => mockClient.from('tasks').select().eq(any(), any()))
      .thenAnswer((_) => Future.value([task1Json, task2Json]));

    final tasks = await service.getTasksForDocument('doc123');

    expect(tasks, hasLength(2));
    expect(tasks[0].id, equals(task1.id));
  });
});
```

### Widget Tests

```dart
// test/features/documents/components/granular_task_item_test.dart

group('GranularTaskItem', () {
  testWidgets('renders task title and description', (tester) async {
    final task = Task(
      id: '1',
      title: 'Test Task',
      description: 'Test Description',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GranularTaskItem(
            task: task,
            config: TaskItemConfig(),
            callbacks: TaskItemCallbacks(),
          ),
        ),
      ),
    );

    expect(find.text('Test Task'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });

  testWidgets('updates when ValueNotifier changes', (tester) async {
    final task = Task(id: '1', title: 'Original');

    await tester.pumpWidget(
      MaterialApp(home: GranularTaskItem(task: task)),
    );

    expect(find.text('Original'), findsOneWidget);

    // Simulate task update
    TaskStateManager.updateTask(task.copyWith(title: 'Updated'));
    await tester.pump();

    expect(find.text('Updated'), findsOneWidget);
    expect(find.text('Original'), findsNothing);
  });
});
```

### Integration Tests

```dart
// integration_test/documents_flow_test.dart

group('Documents feature end-to-end', () {
  testWidgets('create, filter, and complete task', (tester) async {
    await tester.pumpWidget(MyApp());

    // Navigate to documents
    await tester.tap(find.byIcon(Icons.description));
    await tester.pumpAndSettle();

    // Create task
    await tester.tap(find.byType(TaskCreationRow));
    await tester.enterText(find.byType(TextField).first, 'New Task');
    await tester.tap(find.text('Crea'));
    await tester.pumpAndSettle();

    expect(find.text('New Task'), findsOneWidget);

    // Apply filter
    await tester.tap(find.text('Alta priorità'));
    await tester.pumpAndSettle();

    // Complete task
    await tester.drag(find.text('New Task'), Offset(-500, 0)); // Swipe
    await tester.pumpAndSettle();

    expect(find.text('New Task'), findsNothing); // Removed from active
  });
});
```

---

## Migration History

### Phase 1: Bloc Migration (Dec 2024)
**Goal**: Eliminate old `TaskListBloc` e `TagBloc`, unify in `UnifiedTaskListBloc`

**Changes**:
- ✅ Created `UnifiedTaskListBloc` con tutti gli eventi
- ✅ Migrated `AllTasksView` to use new bloc
- ✅ Migrated `TagView` to use new bloc
- ✅ Migrated `CompletedTasksView` to use new bloc
- ✅ Deleted old `TaskListBloc` e `TagBloc`

**Benefits**:
- 40% code reduction in state management
- Eliminated state synchronization bugs
- Improved testability

### Phase 2: Granular Rebuilds (Dec 2024)
**Goal**: Optimize performance con `TaskStateManager`

**Changes**:
- ✅ Created `TaskStateManager` singleton
- ✅ Refactored `GranularTaskItem` to use `ValueListenableBuilder`
- ✅ Eliminated `setState()` calls in list items

**Benefits**:
- 97% faster item updates
- Smooth drag & drop (no jank)
- Better battery life (less CPU usage)

### Phase 3: Component Extraction (Jan 2025)
**Goal**: Create reusable component library

**Changes**:
- ✅ Extracted `CompactFilterSortBar`
- ✅ Extracted `TaskCreationRow`
- ✅ Extracted `GranularTaskItem`
- ✅ Created `/features/documents/presentation/components/` structure

**Benefits**:
- 67% code reduction (3268 → 1080 lines)
- Components reusable in other features
- Improved maintainability

---

## Future Improvements

### Short-term (Q1 2025)

#### 1. Offline Support
**Problem**: App requires network per fetch/persist
**Solution**: Local SQLite cache with sync

```dart
class HybridTaskRepository implements TaskRepository {
  final SupabaseTaskRepository _remote;
  final SqliteTaskRepository _local;
  final ConnectivityService _connectivity;

  @override
  Future<List<Task>> getTasks(String documentId) async {
    if (await _connectivity.isOnline()) {
      final tasks = await _remote.getTasks(documentId);
      await _local.cacheTasks(tasks); // Cache for offline
      return tasks;
    } else {
      return _local.getTasks(documentId); // Fallback to cache
    }
  }
}
```

#### 2. Real-time Collaboration
**Problem**: Task changes non sincronizzate tra users
**Solution**: Supabase Realtime subscriptions

```dart
class RealtimeTaskSync {
  StreamSubscription? _subscription;

  void startListening(String documentId, Function(Task) onTaskChanged) {
    _subscription = Supabase.instance.client
      .from('tasks:document_id=eq.$documentId')
      .stream(primaryKey: ['id'])
      .listen((data) {
        final task = Task.fromJson(data);
        onTaskChanged(task);
      });
  }
}
```

### Medium-term (Q2 2025)

#### 3. Subtasks & Checklist
**Schema**:
```sql
CREATE TABLE subtasks (
  id UUID PRIMARY KEY,
  parent_task_id UUID REFERENCES tasks(id),
  title TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  order_index INT
);
```

**UI**:
- Expandable task cards
- Inline subtask creation
- Progress indicator (3/5 subtasks completed)

#### 4. Advanced Analytics
**Metrics**:
- Task completion rate per day/week/month
- Average time to completion
- Most used tags
- Productivity heatmap

**Implementation**:
```dart
class TaskAnalytics {
  Future<CompletionRate> getCompletionRate(DateRange range) async {
    final completed = await _getCompletedTasks(range);
    final created = await _getCreatedTasks(range);
    return CompletionRate(
      percentage: (completed.length / created.length) * 100,
      trend: _calculateTrend(completed),
    );
  }
}
```

### Long-term (Q3+ 2025)

#### 5. AI-Powered Features
- **Auto-categorization**: ML model per suggerire tags
- **Smart reminders**: Predire deadline basato su priority/size
- **Task templates**: Suggerire task comuni basato su storia

#### 6. Advanced Integrations
- **Calendar sync**: Export task con due date a Google Calendar
- **Email integration**: Create task da email
- **Webhooks**: Trigger actions on task events

---

## Code Quality Metrics

### Current State (Jan 2025)

| Metric | Value | Target |
|--------|-------|--------|
| **Test Coverage** | 75% | 90% |
| **Cyclomatic Complexity** | 8 avg | <10 |
| **Code Duplication** | 3% | <5% |
| **LOC per File** | 250 avg | <500 |
| **Public API Surface** | 45 classes | Minimize |

### Technical Debt

**High Priority**:
- [ ] Increase test coverage to 90%
- [ ] Add integration tests per critical flows
- [ ] Document all public APIs with dartdoc

**Medium Priority**:
- [ ] Refactor `CompactFilterSortBar` (1275 lines → split)
- [ ] Extract filter contents to separate components
- [ ] Add error boundary widgets

**Low Priority**:
- [ ] Migrate to null-safe Dart 3.0 features
- [ ] Add performance monitoring (Firebase Performance)
- [ ] Implement analytics tracking

---

## Troubleshooting Guide

### Common Issues

#### Issue: Tasks not appearing after creation
**Symptom**: Task created but not in list
**Cause**: BLoC not emitting new state
**Solution**:
```dart
// Check if event handler emits state
Future<void> _onCreateTask(CreateTask event, Emitter emit) async {
  // ...
  emit(TaskListLoaded(...)); // Ensure this is called!
}
```

#### Issue: Drag & drop jank
**Symptom**: Stuttering during reorder
**Cause**: Entire list rebuilding
**Solution**: Ensure `GranularTaskItem` uses `ValueListenableBuilder`

#### Issue: Filters not working
**Symptom**: Filters applied but no effect
**Cause**: `filteredTasks` not used in UI
**Solution**:
```dart
// ❌ WRONG
BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
  builder: (context, state) {
    if (state is TaskListLoaded) {
      return ListView.builder(
        itemCount: state.tasks.length, // Using unfiltered!
      );
    }
  },
);

// ✅ CORRECT
return ListView.builder(
  itemCount: state.filteredTasks.length, // Using filtered!
);
```

---

## Contributing Guidelines

### Adding New Feature

1. **Create Feature Branch**: `feature/documents-subtasks`
2. **Update BLoC**: Add events/states if needed
3. **Create Components**: In `/features/documents/presentation/components/`
4. **Write Tests**: Unit + Widget + Integration
5. **Update Docs**: Update this file with architecture changes
6. **PR Review**: Get approval from tech lead

### Code Style

```dart
// ✅ GOOD: Clear naming, single responsibility
class TaskCreationRow extends StatefulWidget {
  final TodoDocument document;
  final void Function(Task)? onTaskCreated;
}

// ❌ BAD: Generic naming, multiple responsibilities
class TaskWidget extends StatefulWidget {
  final dynamic data;
  final Function? callback;
}
```

### Performance Checklist

Before merging:
- [ ] No unnecessary rebuilds (use `const` constructors)
- [ ] Lazy loading for heavy operations
- [ ] Debounced user input (search, filters)
- [ ] Profile with Flutter DevTools (no jank)

---

## References

### Related Documentation
- [PM Product Guide](./PM_DOCUMENTS_FEATURE.md)
- [User Guide](./USER_GUIDE_DOCUMENTS.md)
- [Claude Agent Guide](./CLAUDE_AGENT_DOCUMENTS_GUIDE.md)
- [Reusable Components](./REUSABLE_COMPONENTS_DEV_GUIDE.md)

### External Resources
- [BLoC Pattern](https://bloclibrary.dev/)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)

---

**Document Version**: 1.0
**Last Updated**: Gennaio 2025
**Maintained By**: Senior Dev Team
**Status**: Living Document
