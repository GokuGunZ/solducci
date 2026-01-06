# 🤖 Documents Feature - Claude Agent Guide

> **Purpose**: Enable Claude Code agents to maintain and extend the Documents feature
> **Agent Type**: Feature-specific development agent
> **Scope**: `/documents` feature in Solducci app

---

## Agent Mission

You are a specialized agent responsible for maintaining, debugging, and extending the **Documents feature** in the Solducci Flutter app. This feature provides task management capabilities with advanced filtering, sorting, and organization.

### Core Responsibilities
1. ✅ Fix bugs in task management logic
2. ✅ Implement new features for Documents section
3. ✅ Optimize performance of task lists
4. ✅ Maintain state management (BLoC pattern)
5. ✅ Ensure UI consistency across views

---

## Codebase Structure

### Key Directories

```
lib/
├── blocs/unified_task_list/           # STATE MANAGEMENT
│   ├── unified_task_list_bloc.dart    # Main BLoC (single source of truth)
│   ├── unified_task_list_event.dart   # Events (Load, Filter, Create, etc)
│   └── unified_task_list_state.dart   # States (Loading, Loaded, Error)
│
├── views/documents/                    # MAIN VIEWS
│   ├── all_tasks_view.dart            # Main task list with filters
│   ├── tag_view.dart                  # Tag-filtered view
│   ├── completed_tasks_view.dart      # Completed tasks view
│   └── documents_home_view.dart       # Tab navigation wrapper
│
├── features/documents/presentation/    # COMPONENTS
│   └── components/
│       └── granular_task_item.dart    # Individual task widget
│
├── widgets/documents/                  # SHARED WIDGETS
│   ├── compact_filter_sort_bar.dart   # Filter/sort UI
│   └── task_creation_row.dart         # Inline task creation
│
├── models/                             # DATA MODELS
│   ├── task.dart                      # Task entity
│   ├── tag.dart                       # Tag entity
│   ├── filter_sort_config.dart        # Filter configuration
│   └── task_enums.dart                # Priority, Status, Size
│
└── services/                           # DATA LAYER
    ├── task_service.dart              # Task CRUD operations
    └── tag_service.dart               # Tag CRUD operations
```

---

## Architecture Patterns

### 1. BLoC Pattern (State Management)

**Pattern**: Business Logic Component
**Location**: `lib/blocs/unified_task_list/`

**How it works**:
```dart
// 1. UI dispatches event
context.read<UnifiedTaskListBloc>().add(CreateTask(newTask));

// 2. BLoC handles event
Future<void> _onCreateTask(CreateTask event, Emitter emit) async {
  emit(TaskListLoading());
  try {
    await _taskService.createTask(event.task);
    emit(TaskListLoaded(updatedTasks));
  } catch (e) {
    emit(TaskListError(e.toString()));
  }
}

// 3. UI reacts to state
BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
  builder: (context, state) {
    if (state is TaskListLoaded) {
      return TaskList(tasks: state.tasks);
    }
  },
)
```

**When to modify BLoC**:
- ✅ Adding new task operations (e.g., bulk delete)
- ✅ Adding new filtering logic
- ✅ Changing how data is fetched/cached

**What NOT to change**:
- ❌ Don't add UI logic to BLoC
- ❌ Don't bypass BLoC for data operations
- ❌ Don't create multiple BLoCs for same domain

### 2. Granular Rebuilds (Performance)

**Pattern**: ValueListenableBuilder for individual items
**Location**: `lib/features/documents/presentation/components/granular_task_item.dart`

**How it works**:
```dart
// TaskStateManager holds ValueNotifier per task
class TaskStateManager {
  static final Map<String, ValueNotifier<Task>> _taskNotifiers = {};

  static ValueNotifier<Task> getNotifier(Task task) {
    _taskNotifiers[task.id] ??= ValueNotifier<Task>(task);
    return _taskNotifiers[task.id]!;
  }

  static void updateTask(Task task) {
    _taskNotifiers[task.id]?.value = task;
  }
}

// GranularTaskItem uses notifier
class GranularTaskItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Task>(
      valueListenable: TaskStateManager.getNotifier(task),
      builder: (context, updatedTask, _) {
        return TaskCard(task: updatedTask); // Only this rebuilds!
      },
    );
  }
}
```

**Why this matters**:
- ✅ Editing task X doesn't rebuild task Y
- ✅ Smooth drag & drop (no jank)
- ✅ 97% faster than full list rebuilds

**When to use**:
- ✅ Always for list items that can be individually updated
- ✅ For widgets that show real-time data changes
- ✅ When performance profiling shows unnecessary rebuilds

### 3. Repository Pattern (Data Layer)

**Pattern**: Abstract data access behind service interfaces
**Location**: `lib/services/`

**Structure**:
```dart
// Service abstracts Supabase (could be SQLite, mock, etc)
class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Task>> getTasksForDocument(String documentId) async {
    final response = await _client
      .from('tasks')
      .select()
      .eq('document_id', documentId)
      .order('manual_order');

    return response.map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> createTask(Task task) async {
    final response = await _client
      .from('tasks')
      .insert(task.toJson())
      .select()
      .single();

    return Task.fromJson(response);
  }
}
```

**When modifying services**:
- ✅ Adding new CRUD operations
- ✅ Changing query logic (filters, joins)
- ✅ Adding caching layer

**Important**:
- ❌ Never call Supabase directly from widgets
- ❌ Always go through service layer
- ✅ Services should be testable (mockable)

---

## Common Tasks

### Task 1: Add New Filter Type

**Example**: Add "Assigned To" filter

**Steps**:
1. **Update FilterSortConfig model**:
```dart
// lib/models/filter_sort_config.dart
class FilterSortConfig {
  final Set<String>? assignedToUserIds; // NEW

  FilterSortConfig copyWith({
    Set<String>? assignedToUserIds,
  }) { /* ... */ }

  bool get hasFilters =>
    // ... existing checks
    assignedToUserIds?.isNotEmpty ?? false; // NEW
}
```

2. **Update filtering logic**:
```dart
// lib/utils/task_filter_sort.dart
static List<Task> filterTasks(List<Task> tasks, FilterSortConfig config) {
  return tasks.where((task) {
    // ... existing filters

    // NEW: Assigned to filter
    if (config.assignedToUserIds?.isNotEmpty ?? false) {
      if (!config.assignedToUserIds!.contains(task.assignedTo)) {
        return false;
      }
    }

    return true;
  }).toList();
}
```

3. **Update UI**:
```dart
// lib/widgets/documents/compact_filter_sort_bar.dart
// Add new filter chip in _buildFilterChips()
if (config.assignedToUserIds?.isNotEmpty ?? false)
  FilterChip(
    label: Text('Assigned: ${config.assignedToUserIds!.length}'),
    onDeleted: () => _clearAssignedToFilter(),
  ),
```

4. **Test**:
```dart
// test/utils/task_filter_sort_test.dart
test('filters by assigned user', () {
  final tasks = [
    Task(id: '1', assignedTo: 'user1'),
    Task(id: '2', assignedTo: 'user2'),
  ];

  final config = FilterSortConfig(assignedToUserIds: {'user1'});
  final filtered = TaskFilterSort.filterTasks(tasks, config);

  expect(filtered, hasLength(1));
  expect(filtered[0].id, equals('1'));
});
```

### Task 2: Fix Bug in Task Creation

**Example**: Tasks not appearing after creation

**Debugging Checklist**:
1. **Check BLoC event dispatch**:
```dart
// In widget where task is created
context.read<UnifiedTaskListBloc>().add(CreateTask(newTask));
// ✅ Ensure this is called
```

2. **Check BLoC handler**:
```dart
// lib/blocs/unified_task_list/unified_task_list_bloc.dart
Future<void> _onCreateTask(CreateTask event, Emitter emit) async {
  print('🔧 DEBUG: Creating task ${event.task.id}'); // Add logging

  final currentState = state as TaskListLoaded;

  try {
    final createdTask = await _taskService.createTask(event.task);
    print('✅ DEBUG: Task created: $createdTask');

    final updatedTasks = [...currentState.tasks, createdTask];
    emit(currentState.copyWith(tasks: updatedTasks));
    print('✅ DEBUG: State emitted with ${updatedTasks.length} tasks');
  } catch (e) {
    print('❌ DEBUG: Error creating task: $e');
    emit(TaskListError(e.toString()));
  }
}
```

3. **Check UI rebuilds**:
```dart
// lib/views/documents/all_tasks_view.dart
BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
  builder: (context, state) {
    print('🔧 DEBUG: State changed to ${state.runtimeType}');
    if (state is TaskListLoaded) {
      print('✅ DEBUG: Rendering ${state.tasks.length} tasks');
      // ...
    }
  },
)
```

4. **Check service layer**:
```dart
// lib/services/task_service.dart
Future<Task> createTask(Task task) async {
  print('🔧 DEBUG: Inserting task to Supabase');
  final response = await _client
    .from('tasks')
    .insert(task.toJson())
    .select()
    .single();

  print('✅ DEBUG: Supabase response: $response');
  return Task.fromJson(response);
}
```

**Common causes**:
- ❌ BLoC event not dispatched
- ❌ Service layer throws exception (not caught)
- ❌ UI doesn't listen to correct state
- ❌ Task filter excludes newly created task

### Task 3: Add New Task Property

**Example**: Add "dueDate" to tasks

**Steps**:
1. **Update model**:
```dart
// lib/models/task.dart
class Task {
  final String id;
  final String title;
  final DateTime? dueDate; // NEW

  Task({
    required this.id,
    required this.title,
    this.dueDate, // NEW
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      dueDate: json['due_date'] != null // NEW
        ? DateTime.parse(json['due_date'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'due_date': dueDate?.toIso8601String(), // NEW
    };
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? dueDate, // NEW
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate, // NEW
    );
  }
}
```

2. **Update database** (Supabase):
```sql
-- Run in Supabase SQL editor
ALTER TABLE tasks
ADD COLUMN due_date TIMESTAMP WITH TIME ZONE;
```

3. **Update UI**:
```dart
// lib/features/documents/presentation/components/granular_task_item.dart
if (task.dueDate != null)
  Text(
    'Due: ${_formatDate(task.dueDate!)}',
    style: TextStyle(
      color: _isOverdue(task.dueDate!) ? Colors.red : Colors.grey,
    ),
  ),
```

4. **Update creation form**:
```dart
// lib/widgets/documents/task_creation_row.dart
DateTimePicker(
  labelText: 'Due Date',
  initialValue: _dueDate,
  onChanged: (date) => setState(() => _dueDate = date),
),
```

### Task 4: Optimize Performance

**Example**: List stutters when scrolling

**Profiling**:
1. **Use Flutter DevTools**:
```bash
flutter run --profile
# Open DevTools → Performance tab
# Scroll list and identify jank
```

2. **Common issues**:
   - ❌ Entire list rebuilding on item change
   - ❌ Heavy computations in build method
   - ❌ Unnecessary network requests

3. **Solutions**:

**Solution A: Use const constructors**:
```dart
// ❌ BAD
return Card(
  child: Text('Hello'),
);

// ✅ GOOD
return const Card(
  child: Text('Hello'),
);
```

**Solution B: Memoize expensive computations**:
```dart
// ❌ BAD: Recompute ogni rebuild
Widget build(BuildContext context) {
  final sortedTasks = tasks.sort((a, b) => ...); // SLOW!
  return ListView.builder(...);
}

// ✅ GOOD: Compute once
class _MyWidgetState extends State<MyWidget> {
  late List<Task> _sortedTasks;

  @override
  void initState() {
    super.initState();
    _sortedTasks = widget.tasks.sort((a, b) => ...);
  }

  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _sortedTasks = widget.tasks.sort((a, b) => ...);
    }
  }
}
```

**Solution C: Use ListView.builder (not ListView)**:
```dart
// ❌ BAD: All items created upfront
return ListView(
  children: tasks.map((t) => TaskItem(task: t)).toList(),
);

// ✅ GOOD: Items created lazily
return ListView.builder(
  itemCount: tasks.length,
  itemBuilder: (context, index) => TaskItem(task: tasks[index]),
);
```

---

## Data Models Reference

### Task Model
```dart
class Task {
  final String id;                    // UUID (auto-generated)
  final String documentId;            // Parent document ID
  final String title;                 // Task title
  final String? description;          // Optional description
  final TaskPriority priority;        // high | medium | low
  final TaskStatus status;            // todo | inProgress | done
  final TaskSize size;                // small | medium | large
  final DateTime createdAt;
  final DateTime? completedAt;
  final int manualOrder;              // For drag & drop
  final List<String> tagIds;          // Associated tag IDs

  // Methods
  bool get isCompleted => status == TaskStatus.done;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());
}
```

### Tag Model
```dart
class Tag {
  final String id;                    // UUID
  final String name;                  // Tag name
  final Color color;                  // Tag color
  final DateTime createdAt;
}
```

### FilterSortConfig Model
```dart
class FilterSortConfig {
  final Set<TaskPriority>? selectedPriorities;
  final Set<TaskStatus>? selectedStatuses;
  final Set<TaskSize>? selectedSizes;
  final DateRange? dateRange;
  final Set<String>? tagIds;
  final SortBy sortBy;                // date | priority | alphabetical
  final bool ascending;

  bool get hasFilters => /* any filter is active */;
}
```

---

## Testing Guidelines

### Unit Tests (BLoC)
```dart
// test/blocs/unified_task_list_bloc_test.dart
blocTest<UnifiedTaskListBloc, UnifiedTaskListState>(
  'emits [Loading, Loaded] when LoadTasks succeeds',
  build: () {
    when(() => mockTaskService.getTasksForDocument(any()))
      .thenAnswer((_) async => [task1, task2]);
    return UnifiedTaskListBloc(taskService: mockTaskService);
  },
  act: (bloc) => bloc.add(LoadTasks(document)),
  expect: () => [
    TaskListLoading(),
    TaskListLoaded(tasks: [task1, task2]),
  ],
);
```

### Widget Tests
```dart
// test/components/granular_task_item_test.dart
testWidgets('renders task title', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GranularTaskItem(task: Task(id: '1', title: 'Test')),
    ),
  );

  expect(find.text('Test'), findsOneWidget);
});
```

### Integration Tests
```dart
// integration_test/documents_flow_test.dart
testWidgets('create and filter task', (tester) async {
  await tester.pumpWidget(MyApp());

  // Create task
  await tester.tap(find.byType(TaskCreationRow));
  await tester.enterText(find.byType(TextField), 'New Task');
  await tester.tap(find.text('Crea'));
  await tester.pumpAndSettle();

  expect(find.text('New Task'), findsOneWidget);

  // Apply filter
  await tester.tap(find.text('Alta priorità'));
  await tester.pumpAndSettle();

  // Verify filtering
  expect(find.text('New Task'), findsNothing); // Filtered out
});
```

---

## Error Handling

### Supabase Errors
```dart
try {
  await _client.from('tasks').insert(task.toJson());
} on PostgrestException catch (e) {
  if (e.code == '23505') {
    // Unique constraint violation
    throw DuplicateTaskException('Task already exists');
  } else if (e.code == '23503') {
    // Foreign key violation
    throw InvalidDocumentException('Document not found');
  } else {
    throw DatabaseException('Database error: ${e.message}');
  }
} catch (e) {
  throw UnexpectedException('Unexpected error: $e');
}
```

### User-Friendly Messages
```dart
Future<void> _onCreateTask(CreateTask event, Emitter emit) async {
  try {
    // ...
  } on DuplicateTaskException {
    emit(TaskListError('Un task con questo titolo esiste già'));
  } on InvalidDocumentException {
    emit(TaskListError('Documento non trovato'));
  } on DatabaseException catch (e) {
    emit(TaskListError('Errore del database: ${e.message}'));
  } catch (e) {
    emit(TaskListError('Errore imprevisto. Riprova più tardi.'));
  }
}
```

---

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| **List initial render** | <100ms | ~80ms |
| **Single item update** | <5ms | ~3ms |
| **Filter application** | <50ms | ~30ms |
| **Drag & drop frame rate** | 60fps | 60fps |
| **Task creation** | <200ms | ~150ms |
| **Memory usage (1000 tasks)** | <100MB | ~70MB |

### Profiling Commands
```bash
# Profile mode (optimized, but debuggable)
flutter run --profile

# Profile widget rebuilds
flutter run --profile --trace-skia

# Profile memory
flutter run --profile --trace-to-file=trace.json
```

---

## Agent Decision Tree

```
User requests change
       ↓
Is it a new feature?
  ├─ Yes → Check if requires:
  │         ├─ New BLoC events/states? → Modify BLoC
  │         ├─ New UI components? → Create in /components
  │         └─ New data fields? → Update models + database
  └─ No → Is it a bug?
            ├─ Yes → Follow debugging checklist
            │         ├─ Add logging
            │         ├─ Check BLoC flow
            │         ├─ Check service layer
            │         └─ Verify UI rebuilds
            └─ No → Is it a performance issue?
                      ├─ Yes → Profile with DevTools
                      │         ├─ Identify bottleneck
                      │         ├─ Apply optimization
                      │         └─ Verify improvement
                      └─ No → Is it a refactor?
                                → Follow component extraction pattern
                                → Maintain backward compatibility
                                → Add tests
```

---

## Quick Reference Commands

### Run App
```bash
flutter run
```

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/blocs/unified_task_list_bloc_test.dart

# With coverage
flutter test --coverage
```

### Format Code
```bash
dart format lib/ test/
```

### Analyze Code
```bash
flutter analyze
```

### Generate Mocks
```bash
flutter pub run build_runner build
```

---

## Contact & Escalation

### When to Escalate
- 🚨 Breaking changes to public APIs
- 🚨 Database schema changes
- 🚨 Major architectural decisions
- 🚨 Security vulnerabilities

### Who to Contact
- **Tech Lead**: For architectural questions
- **PM**: For feature scope/priority
- **QA**: For testing strategy

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 2025 | Initial agent guide |

---

**Agent Status**: ✅ ACTIVE
**Last Updated**: January 2025
**Maintained By**: Senior Dev Team
