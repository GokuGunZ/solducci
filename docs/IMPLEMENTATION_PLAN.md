# Piano di Implementazione - Documents Feature Refactoring

**Progetto**: Solducci - Documents Feature Refactoring
**Data Inizio Effettiva**: 2024-12-24
**Data Fine Prevista**: 2025-04-11 (14 settimane)
**Team**: 1-2 Developer Full-Time

---

## 📊 Progress Tracking

### Overall Progress: 15% Complete

```
Week 0:   ████████████████████ 100% ✅ COMPLETE
Sprint 1: ████████░░░░░░░░░░░░  40% ⏳ IN PROGRESS
Sprint 2: ░░░░░░░░░░░░░░░░░░░░  0%  📅 PLANNED
Sprint 3: ░░░░░░░░░░░░░░░░░░░░  0%  📅 PLANNED
Sprint 4: ░░░░░░░░░░░░░░░░░░░░  0%  📅 PLANNED
Sprint 5: ░░░░░░░░░░░░░░░░░░░░  0%  📅 PLANNED
Sprint 6: ░░░░░░░░░░░░░░░░░░░░  0%  📅 PLANNED
Sprint 7: ░░░░░░░░░░░░░░░░░░░░  0%  📅 PLANNED
```

### Last Updated: 2024-12-24 01:15 UTC

### Recent Achievements
- ✅ **Task 1.2 Complete** (2024-12-24)
  - Created AppLogger with proper log levels
  - Replaced 50+ print() statements
  - Reduced linter warnings from 110 → 41
  - Commit: `4ba568e`

- ✅ **Task 1.3 Complete** (2024-12-24)
  - Setup Dependency Injection with GetIt
  - Created service locator
  - Integrated into main.dart
  - Updated test helpers
  - Commit: `c8a4552`

### Sprint 1 Status
- ✅ Task 1.1: Testing Infrastructure (Week 0)
- ✅ Task 1.2: Logging Framework (2h)
- ✅ Task 1.3: Dependency Injection (1.5h)
- ⏳ Task 1.4: Write Critical Path Tests (Next)

### Next Steps
- 🎯 **Sprint 1 - Task 1.4**: Write Critical Path Tests
- Focus: TaskService, FilterSort, TaskListItem widget tests

---

## Indice

1. [Overview & Preparazione](#overview--preparazione)
2. [Sprint Planning Dettagliato](#sprint-planning-dettagliato)
3. [Task Breakdown per Sprint](#task-breakdown-per-sprint)
4. [Branch Strategy](#branch-strategy)
5. [Definition of Done](#definition-of-done)
6. [Daily Workflow](#daily-workflow)
7. [Risk Management](#risk-management)
8. [Monitoring & Metrics](#monitoring--metrics)

---

## Overview & Preparazione

### Pre-Requisiti (Da completare PRIMA di iniziare)

#### Settimana 0: Setup ✅ COMPLETATA (24 Dic 2024)

**Checklist Preparazione**:

- [x] **Git Setup**
  ```bash
  # Create feature branch
  git checkout -b refactor/documents-feature-v2

  # Setup branch protection
  # - Require PR reviews (min 1)
  # - Require status checks (tests)
  # - No force push
  ```

- [x] **Project Management**
  - [x] Create GitHub Project o Jira Board (Using TodoWrite for tracking)
  - [x] Import tutti i task di questo documento
  - [x] Setup labels: `refactor`, `bug`, `test`, `docs`
  - [x] Setup milestones per ogni fase

- [x] **CI/CD Enhancement**
  ```yaml
  # .github/workflows/tests.yml
  name: Tests
  on: [push, pull_request]
  jobs:
    test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3
        - uses: subosito/flutter-action@v2
        - run: flutter test --coverage
        - uses: codecov/codecov-action@v3
  ```

- [x] **Dependencies**
  ```yaml
  # pubspec.yaml - Add these
  dev_dependencies:
    flutter_test:
    mockito: ^5.4.0
    build_runner: ^2.4.0
    bloc_test: ^9.1.0
    golden_toolkit: ^0.15.0

  dependencies:
    flutter_bloc: ^8.1.3
    equatable: ^2.0.5
    get_it: ^7.6.0
    logger: ^2.0.0
    connectivity_plus: ^5.0.0
  ```

- [x] **Code Coverage Setup**
  - [x] Install coverage tools
  - [x] Setup lcov.info generation
  - [x] Integrate with IDE (via CI/CD)

- [x] **Team Alignment**
  - [x] Kickoff meeting (Self-alignment completed)
  - [x] Review architettura proposta
  - [x] Assign roles e responsabilità
  - [x] Setup daily standup (Tracking via TodoWrite)

---

## Sprint Planning Dettagliato

### 📅 Calendario Sprint (2 settimane per sprint)

```
Sprint 1: 06 Gen - 17 Gen (Foundation)
Sprint 2: 20 Gen - 31 Gen (Testing Base)
Sprint 3: 03 Feb - 14 Feb (Repository Layer)
Sprint 4: 17 Feb - 28 Feb (Service Decomposition)
Sprint 5: 03 Mar - 14 Mar (BLoC Migration)
Sprint 6: 17 Mar - 28 Mar (State Optimization)
Sprint 7: 31 Mar - 11 Apr (Widget Refactor)
```

---

## Task Breakdown per Sprint

### 🎯 SPRINT 1: Foundation Setup (06-17 Gen)

**Goal**: Setup infrastructure per refactoring sicuro

**Story Points**: 21
**Velocity Target**: Complete 100% delle task

#### Task 1.1: Testing Infrastructure Setup (5 pts)
**Assignee**: Developer 1
**Duration**: 2 giorni
**Priority**: P0 (Blocker)

**Sub-tasks**:
```
✅ Day 1 Morning: Install test packages
  - [ ] Add flutter_test dependencies
  - [ ] Add mockito + build_runner
  - [ ] Add bloc_test
  - [ ] Run flutter pub get
  - [ ] Verify installation

✅ Day 1 Afternoon: Configure test environment
  - [ ] Create test/ directory structure
    test/
    ├── unit/
    ├── widget/
    ├── integration/
    └── fixtures/
  - [ ] Setup test_helpers.dart
  - [ ] Create mock factories

✅ Day 2 Morning: Setup CI/CD
  - [ ] Create .github/workflows/tests.yml
  - [ ] Configure coverage reporting
  - [ ] Test CI pipeline con dummy test

✅ Day 2 Afternoon: Golden test setup
  - [ ] Add golden_toolkit
  - [ ] Create first golden test
  - [ ] Document golden test process
```

**Acceptance Criteria**:
- ✅ `flutter test` runs successfully
- ✅ Coverage report generated (lcov.info)
- ✅ CI pipeline verde
- ✅ Al meno 1 golden test funzionante

**Files to Create**:
```
test/
├── test_helpers.dart
├── unit/
│   └── sample_test.dart
├── widget/
│   └── sample_widget_test.dart
└── golden/
    └── sample_golden_test.dart

.github/workflows/tests.yml
```

---

#### Task 1.2: Logging Framework (3 pts)
**Assignee**: Developer 2
**Duration**: 1 giorno
**Priority**: P0

**Sub-tasks**:
```
✅ Morning: Setup logger package
  - [ ] Add logger: ^2.0.0 to pubspec
  - [ ] Create lib/core/logging/app_logger.dart
  - [ ] Configure log levels
  - [ ] Test logging in console

✅ Afternoon: Replace print statements
  - [ ] Find all print() in codebase (grep)
  - [ ] Replace in task_service.dart
  - [ ] Replace in all_tasks_view.dart
  - [ ] Replace in documents_home_view.dart
  - [ ] Verify logs in console
```

**Code Template**:
```dart
// lib/core/logging/app_logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

// Usage:
// Before: print('🔄 Refreshing tasks');
// After:  AppLogger.debug('Refreshing tasks');
```

**Acceptance Criteria**:
- ✅ Nessun print() rimasto nel codice
- ✅ Logs con timestamp e colors
- ✅ Different log levels funzionanti
- ✅ Documentation aggiornata

---

#### Task 1.3: Dependency Injection Setup (5 pts)
**Assignee**: Developer 1
**Duration**: 2 giorni
**Priority**: P0

**Sub-tasks**:
```
✅ Day 1 Morning: Install GetIt
  - [ ] Add get_it: ^7.6.0
  - [ ] Create lib/core/di/service_locator.dart
  - [ ] Setup singleton registration

✅ Day 1 Afternoon: Register existing services
  - [ ] Register TaskService
  - [ ] Register DocumentService
  - [ ] Register TagService
  - [ ] Register RecurrenceService
  - [ ] Test retrieval with getIt<TaskService>()

✅ Day 2 Morning: Update widget usage
  - [ ] Replace TaskService() with getIt<TaskService>()
  - [ ] Update all_tasks_view.dart
  - [ ] Update tag_view.dart
  - [ ] Update task_list_item.dart

✅ Day 2 Afternoon: Create test helpers
  - [ ] Create test service locator
  - [ ] Create mock registration helper
  - [ ] Write example test with mocks
```

**Code Template**:
```dart
// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/tag_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services (Singleton)
  getIt.registerLazySingleton<TaskService>(() => TaskService());
  getIt.registerLazySingleton<DocumentService>(() => DocumentService());
  getIt.registerLazySingleton<TagService>(() => TagService());

  // State Management (will be added later)
  // getIt.registerFactory<TaskListBloc>(() => TaskListBloc(getIt()));
}

// In main.dart:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(MyApp());
}

// In widgets:
class _AllTasksViewState extends State<AllTasksView> {
  // Before: final _taskService = TaskService();
  // After:
  final _taskService = getIt<TaskService>();
}
```

**Test Helper**:
```dart
// test/test_helpers.dart
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockTaskService extends Mock implements TaskService {}

void setupTestServiceLocator() {
  final getIt = GetIt.instance;

  // Reset
  getIt.reset();

  // Register mocks
  getIt.registerLazySingleton<TaskService>(() => MockTaskService());
}

// In test:
void main() {
  setUp(() {
    setupTestServiceLocator();
  });

  test('should load tasks', () {
    final taskService = getIt<TaskService>();
    when(taskService.getTasks()).thenAnswer((_) async => []);
    // ...
  });
}
```

**Acceptance Criteria**:
- ✅ Tutti i services registrati in GetIt
- ✅ Nessun `ServiceName()` diretto nel codice
- ✅ Test helper funzionante
- ✅ Example test che usa mocks

---

#### Task 1.4: Write Critical Path Tests (8 pts)
**Assignee**: Developer 1 & 2 (Pair Programming)
**Duration**: 3 giorni
**Priority**: P1

**Sub-tasks**:
```
✅ Day 1: TaskService tests
  - [ ] test_task_service_crud.dart
    - [ ] testCreateTask()
    - [ ] testUpdateTask()
    - [ ] testDeleteTask()
    - [ ] testGetTaskById()
  - [ ] test_task_service_hierarchy.dart
    - [ ] testBuildTaskTree()
    - [ ] testGetDescendants()
    - [ ] testGetAncestors()
  - [ ] test_task_service_completion.dart
    - [ ] testCompleteTask()
    - [ ] testCompleteRecurringTask()
    - [ ] testCompleteTaskWithSubtasks()

✅ Day 2: Filter/Sort tests
  - [ ] test_task_filter_sort.dart
    - [ ] testFilterByPriority()
    - [ ] testFilterByStatus()
    - [ ] testFilterByTags()
    - [ ] testSortByDueDate()
    - [ ] testSortByPriority()
    - [ ] testApplyCustomOrder()

✅ Day 3: Widget tests
  - [ ] test_task_list_item_widget.dart
    - [ ] testRendersCorrectly()
    - [ ] testCheckboxTap()
    - [ ] testSwipeToDelete()
    - [ ] testExpandSubtasks()
  - [ ] test_all_tasks_view_widget.dart
    - [ ] testLoadsTaskList()
    - [ ] testAppliesFilters()
    - [ ] testCreateNewTask()
```

**Test Template**:
```dart
// test/unit/task_service_crud_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:solducci/service/task_service.dart';

void main() {
  group('TaskService CRUD', () {
    late TaskService taskService;

    setUp(() {
      taskService = TaskService();
      // Setup mock Supabase
    });

    test('should create task successfully', () async {
      // Arrange
      final task = Task.create(
        documentId: 'doc-1',
        title: 'Test Task',
      );

      // Act
      final result = await taskService.createTask(task);

      // Assert
      expect(result, isNotNull);
      expect(result.title, 'Test Task');
      expect(result.id, isNotEmpty);
    });

    test('should throw error when title is empty', () async {
      // Arrange
      final task = Task.create(
        documentId: 'doc-1',
        title: '',
      );

      // Act & Assert
      expect(
        () => taskService.createTask(task),
        throwsA(isA<ValidationError>()),
      );
    });
  });
}
```

**Acceptance Criteria**:
- ✅ Test coverage >60% sui servizi
- ✅ Tutti i test passano
- ✅ No skip o pending tests
- ✅ CI pipeline verde

---

### 🎯 SPRINT 2: Testing Base (20-31 Gen)

**Goal**: Completare test coverage baseline

**Story Points**: 18

#### Task 2.1: Integration Tests (8 pts)
**Assignee**: Developer 1
**Duration**: 3 giorni

**Sub-tasks**:
```
✅ Day 1: Setup integration test environment
  - [ ] Create integration_test/ folder
  - [ ] Setup test database (Supabase test project)
  - [ ] Create test fixtures (sample data)
  - [ ] Write setup/teardown helpers

✅ Day 2: Write user flow tests
  - [ ] test_create_task_flow.dart
    - [ ] Open app
    - [ ] Navigate to All Tasks
    - [ ] Tap FAB
    - [ ] Fill task form
    - [ ] Submit
    - [ ] Verify task appears in list
  - [ ] test_edit_task_flow.dart
  - [ ] test_complete_task_flow.dart

✅ Day 3: Write filter flow tests
  - [ ] test_filter_by_priority_flow.dart
  - [ ] test_sort_tasks_flow.dart
  - [ ] Verify animations work
```

**Code Template**:
```dart
// integration_test/create_task_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solducci/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Create Task Flow', () {
    testWidgets('should create task successfully', (tester) async {
      // Setup
      app.main();
      await tester.pumpAndSettle();

      // Navigate to documents
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.byKey(Key('task_title_input')),
        'New Task',
      );

      // Submit
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pumpAndSettle();

      // Verify
      expect(find.text('New Task'), findsOneWidget);
    });
  });
}
```

---

#### Task 2.2: Golden Tests for UI (5 pts)
**Assignee**: Developer 2
**Duration**: 2 giorni

**Sub-tasks**:
```
✅ Day 1: Create golden tests for key widgets
  - [ ] task_list_item_golden_test.dart
    - [ ] Default state
    - [ ] With all properties
    - [ ] Completed state
    - [ ] With subtasks
  - [ ] filter_bar_golden_test.dart
    - [ ] Default state
    - [ ] With active filters
    - [ ] Expanded state

✅ Day 2: Generate and commit goldens
  - [ ] Run flutter test --update-goldens
  - [ ] Review all golden images
  - [ ] Commit to git
  - [ ] Document process in README
```

**Code Template**:
```dart
// test/golden/task_list_item_golden_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';

void main() {
  group('TaskListItem Golden Tests', () {
    testGoldens('should match default state', (tester) async {
      final task = Task.create(
        documentId: 'doc-1',
        title: 'Sample Task',
      );

      await tester.pumpWidgetBuilder(
        TaskListItem(task: task),
        surfaceSize: Size(400, 100),
      );

      await screenMatchesGolden(tester, 'task_list_item_default');
    });

    testGoldens('should match with all properties', (tester) async {
      final task = Task.create(
        documentId: 'doc-1',
        title: 'Sample Task',
      )
        ..priority = TaskPriority.high
        ..dueDate = DateTime.now()
        ..tShirtSize = TShirtSize.large;

      await tester.pumpWidgetBuilder(
        TaskListItem(task: task),
        surfaceSize: Size(400, 120),
      );

      await screenMatchesGolden(tester, 'task_list_item_full_properties');
    });
  });
}
```

---

#### Task 2.3: Performance Baseline Tests (5 pts)
**Assignee**: Developer 1
**Duration**: 2 giorni

**Sub-tasks**:
```
✅ Day 1: Create performance test suite
  - [ ] test_filter_performance.dart
    - [ ] Measure filter time con 100 tasks
    - [ ] Measure filter time con 1000 tasks
    - [ ] Assert < 100ms per 1000 tasks
  - [ ] test_scroll_performance.dart
    - [ ] Measure frame time during scroll
    - [ ] Assert FPS > 55

✅ Day 2: Document baseline metrics
  - [ ] Create PERFORMANCE.md
  - [ ] Record current metrics
  - [ ] Setup monitoring dashboard
  - [ ] Add to CI pipeline
```

**Code Template**:
```dart
// test/performance/filter_performance_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Filter Performance Tests', () {
    test('should filter 1000 tasks in < 100ms', () async {
      // Arrange
      final tasks = List.generate(
        1000,
        (i) => Task.create(
          documentId: 'doc-1',
          title: 'Task $i',
        ),
      );

      final config = FilterSortConfig(
        priorities: {TaskPriority.high},
      );

      // Act
      final stopwatch = Stopwatch()..start();
      final result = tasks.applyFilterSort(config);
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      print('Filter time: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
```

---

### 🎯 SPRINT 3: Repository Layer (03-14 Feb)

**Goal**: Extract repository pattern, enable better testing

**Story Points**: 21

#### Task 3.1: Define Repository Interfaces (3 pts)
**Assignee**: Developer 1
**Duration**: 1 giorno
**Priority**: P0

**Sub-tasks**:
```
✅ Morning: Create interface definitions
  - [ ] Create lib/domain/repositories/
  - [ ] task_repository.dart (interface)
  - [ ] document_repository.dart (interface)
  - [ ] tag_repository.dart (interface)

✅ Afternoon: Document contracts
  - [ ] Add dartdoc comments
  - [ ] Add usage examples
  - [ ] Review with team
```

**Code Template**:
```dart
// lib/domain/repositories/task_repository.dart
import 'package:solducci/models/task.dart';

/// Repository for Task data operations
///
/// This interface defines the contract for task data access.
/// Implementations can use Supabase, local storage, or in-memory storage.
abstract class TaskRepository {
  /// Get all tasks for a document
  ///
  /// Returns a list of root-level tasks (no parent).
  /// Subtasks are nested in the `subtasks` property.
  Future<List<Task>> getAll({String? documentId});

  /// Get a single task by ID
  ///
  /// Returns null if task not found.
  Future<Task?> getById(String id);

  /// Get a task with all subtasks loaded (full tree)
  Future<Task?> getWithSubtasks(String id);

  /// Create a new task
  ///
  /// Throws [ValidationError] if task data is invalid.
  /// Throws [NetworkError] if network operation fails.
  Future<Task> create(Task task);

  /// Update an existing task
  ///
  /// Throws [NotFoundError] if task doesn't exist.
  Future<Task> update(Task task);

  /// Delete a task
  ///
  /// Also deletes all subtasks recursively.
  Future<void> delete(String id);

  /// Batch get tasks by IDs
  ///
  /// More efficient than multiple getById calls.
  Future<List<Task>> getByIds(List<String> ids);

  /// Stream of task changes
  ///
  /// Emits whenever tasks are created, updated, or deleted.
  Stream<List<Task>> watchAll({String? documentId});
}
```

---

#### Task 3.2: Implement SupabaseTaskRepository (8 pts)
**Assignee**: Developer 1 & 2 (Pair)
**Duration**: 3 giorni
**Priority**: P0

**Sub-tasks**:
```
✅ Day 1: Create repository implementation
  - [ ] Create lib/data/repositories/
  - [ ] supabase_task_repository.dart
  - [ ] Migrate CRUD methods from TaskService
  - [ ] Add error handling

✅ Day 2: Migrate complex operations
  - [ ] Migrate tree building logic
  - [ ] Migrate batch operations
  - [ ] Migrate stream operations
  - [ ] Add retry logic

✅ Day 3: Write tests
  - [ ] test_supabase_task_repository.dart
  - [ ] Test all CRUD operations
  - [ ] Test error cases
  - [ ] Test edge cases
```

**Code Template**:
```dart
// lib/data/repositories/supabase_task_repository.dart
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/core/errors/app_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTaskRepository implements TaskRepository {
  final SupabaseClient _client;

  SupabaseTaskRepository(this._client);

  @override
  Future<List<Task>> getAll({String? documentId}) async {
    try {
      final query = _client.from('tasks').select();

      if (documentId != null) {
        query.eq('document_id', documentId);
      }

      final response = await query.order('position');

      final tasks = response
          .map((json) => Task.fromMap(json))
          .toList();

      return _buildTree(tasks);
    } on PostgrestException catch (e) {
      throw NetworkError(
        'Failed to fetch tasks: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw RepositoryError('Unexpected error: $e');
    }
  }

  @override
  Future<Task> create(Task task) async {
    try {
      // Validate
      _validateTask(task);

      // Insert
      final response = await _client
          .from('tasks')
          .insert(task.toMap())
          .select()
          .single();

      return Task.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationError('Task already exists');
      }
      throw NetworkError('Failed to create task: ${e.message}');
    }
  }

  void _validateTask(Task task) {
    if (task.title.trim().isEmpty) {
      throw ValidationError('Title cannot be empty');
    }
    if (task.documentId.isEmpty) {
      throw ValidationError('Document ID is required');
    }
  }

  List<Task> _buildTree(List<Task> flatList) {
    // Build tree logic (migrated from TaskService)
    // ...
  }
}
```

---

#### Task 3.3: Implement InMemoryTaskRepository (5 pts)
**Assignee**: Developer 2
**Duration**: 2 giorni
**Priority**: P1

**Sub-tasks**:
```
✅ Day 1: Create in-memory implementation
  - [ ] in_memory_task_repository.dart
  - [ ] Use Map<String, Task> for storage
  - [ ] Implement all methods
  - [ ] Add realistic delays (for testing loading states)

✅ Day 2: Write tests
  - [ ] test_in_memory_task_repository.dart
  - [ ] Verify same behavior as Supabase repo
  - [ ] Test concurrent operations
```

**Code Template**:
```dart
// lib/data/repositories/in_memory_task_repository.dart
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/models/task.dart';

/// In-memory implementation for testing
class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};
  final _controller = StreamController<List<Task>>.broadcast();

  @override
  Future<List<Task>> getAll({String? documentId}) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 100));

    var tasks = _tasks.values.toList();

    if (documentId != null) {
      tasks = tasks.where((t) => t.documentId == documentId).toList();
    }

    return tasks;
  }

  @override
  Future<Task> create(Task task) async {
    await Future.delayed(Duration(milliseconds: 50));

    _tasks[task.id] = task;
    _controller.add(_tasks.values.toList());

    return task;
  }

  @override
  Stream<List<Task>> watchAll({String? documentId}) {
    return _controller.stream.map((tasks) {
      if (documentId == null) return tasks;
      return tasks.where((t) => t.documentId == documentId).toList();
    });
  }

  // Implement other methods...
}
```

---

#### Task 3.4: Update TaskService to use Repository (5 pts)
**Assignee**: Developer 1
**Duration**: 2 giorni
**Priority**: P0

**Sub-tasks**:
```
✅ Day 1: Inject repository
  - [ ] Update TaskService constructor
  - [ ] Replace direct Supabase calls
  - [ ] Update all methods to use repository
  - [ ] Keep business logic in service

✅ Day 2: Update DI registration
  - [ ] Register repositories in service_locator
  - [ ] Update TaskService registration
  - [ ] Update all usages
  - [ ] Run tests
```

**Code Template**:
```dart
// lib/service/task_service.dart (Updated)
class TaskService {
  final TaskRepository _repository;
  final TagService _tagService;
  final RecurrenceService _recurrenceService;

  TaskService({
    required TaskRepository repository,
    required TagService tagService,
    required RecurrenceService recurrenceService,
  })  : _repository = repository,
        _tagService = tagService,
        _recurrenceService = recurrenceService;

  // Now focuses on BUSINESS LOGIC only

  Future<List<Task>> getTasksForDocument(String documentId) {
    return _repository.getAll(documentId: documentId);
  }

  Future<void> completeTask(String taskId) async {
    final task = await _repository.getById(taskId);
    if (task == null) throw NotFoundError('Task not found');

    // Business logic: Check if recurring
    final recurrence = await _recurrenceService.getRecurrenceForTask(taskId);

    if (recurrence != null && recurrence.isEnabled) {
      // Reset instead of completing
      await _handleRecurringCompletion(task, recurrence);
    } else {
      // Normal completion
      task.status = TaskStatus.completed;
      task.completedAt = DateTime.now();
      await _repository.update(task);
    }
  }

  Future<void> _handleRecurringCompletion(Task task, Recurrence recurrence) async {
    // Business logic for recurring tasks
    // ...
  }
}

// lib/core/di/service_locator.dart (Updated)
Future<void> setupServiceLocator() async {
  // Repositories
  getIt.registerLazySingleton<TaskRepository>(
    () => SupabaseTaskRepository(Supabase.instance.client),
  );

  // Services with dependencies
  getIt.registerLazySingleton<TaskService>(
    () => TaskService(
      repository: getIt<TaskRepository>(),
      tagService: getIt<TagService>(),
      recurrenceService: getIt<RecurrenceService>(),
    ),
  );
}
```

**Acceptance Criteria**:
- ✅ Nessun accesso diretto a Supabase nel TaskService
- ✅ Tutte le operazioni passano per repository
- ✅ Tests passano con in-memory repository
- ✅ Services sono facilmente mockabili

---

### 🎯 SPRINT 4: Service Decomposition (17-28 Feb)

**Goal**: Break down god classes, improve maintainability

**Story Points**: 21

#### Task 4.1: Extract TaskHierarchyService (8 pts)
**Assignee**: Developer 1
**Duration**: 3 giorni
**Priority**: P1

**Sub-tasks**:
```
✅ Day 1: Create new service
  - [ ] lib/service/task_hierarchy_service.dart
  - [ ] Move buildTree() method
  - [ ] Move getDescendants() method
  - [ ] Move getAncestors() method

✅ Day 2: Move complex operations
  - [ ] Move moveTask() method
  - [ ] Move validateHierarchy() method
  - [ ] Add depth calculation
  - [ ] Add cycle detection

✅ Day 3: Update usages & tests
  - [ ] Update TaskService
  - [ ] Update DI registration
  - [ ] Write unit tests
  - [ ] Update integration tests
```

**Code Template**:
```dart
// lib/service/task_hierarchy_service.dart
class TaskHierarchyService {
  final TaskRepository _repository;

  TaskHierarchyService(this._repository);

  /// Build tree structure from flat list
  Future<List<Task>> buildTree(List<Task> flatTasks) async {
    final index = _buildParentIndex(flatTasks);
    return _buildTreeRecursive(index, null);
  }

  /// Get all descendants of a task (recursive)
  Future<List<Task>> getDescendants(String taskId) async {
    final task = await _repository.getWithSubtasks(taskId);
    if (task == null) return [];

    return _flattenSubtasks(task);
  }

  /// Get all ancestors of a task (up to root)
  Future<List<Task>> getAncestors(String taskId) async {
    final ancestors = <Task>[];
    var currentTask = await _repository.getById(taskId);

    while (currentTask != null && currentTask.parentTaskId != null) {
      final parent = await _repository.getById(currentTask.parentTaskId!);
      if (parent != null) ancestors.add(parent);
      currentTask = parent;
    }

    return ancestors;
  }

  /// Move task to new parent (with validation)
  Future<void> moveTask(String taskId, String? newParentId) async {
    // Validate: prevent cycles
    if (newParentId != null) {
      final wouldCreateCycle = await _wouldCreateCycle(taskId, newParentId);
      if (wouldCreateCycle) {
        throw ValidationError('Cannot move: would create cycle');
      }
    }

    // Validate: max depth
    final depth = await _calculateDepth(newParentId);
    if (depth >= 10) {
      throw ValidationError('Cannot move: max depth reached');
    }

    // Update
    final task = await _repository.getById(taskId);
    if (task == null) throw NotFoundError('Task not found');

    task.parentTaskId = newParentId;
    await _repository.update(task);
  }

  Future<bool> _wouldCreateCycle(String taskId, String parentId) async {
    // Check if parentId is a descendant of taskId
    final descendants = await getDescendants(taskId);
    return descendants.any((d) => d.id == parentId);
  }

  Future<int> _calculateDepth(String? taskId) async {
    if (taskId == null) return 0;

    int depth = 0;
    var currentId = taskId;

    while (currentId != null) {
      final task = await _repository.getById(currentId);
      if (task == null) break;
      currentId = task.parentTaskId;
      depth++;
    }

    return depth;
  }

  Map<String?, List<Task>> _buildParentIndex(List<Task> tasks) {
    final index = <String?, List<Task>>{};
    for (final task in tasks) {
      index.putIfAbsent(task.parentTaskId, () => []).add(task);
    }
    return index;
  }

  List<Task> _buildTreeRecursive(
    Map<String?, List<Task>> index,
    String? parentId,
  ) {
    final children = index[parentId] ?? [];
    return children.map((child) {
      child.subtasks = _buildTreeRecursive(index, child.id);
      return child;
    }).toList();
  }

  List<Task> _flattenSubtasks(Task task) {
    final flattened = <Task>[];

    void addRecursive(Task t) {
      flattened.add(t);
      if (t.subtasks != null) {
        for (final subtask in t.subtasks!) {
          addRecursive(subtask);
        }
      }
    }

    if (task.subtasks != null) {
      for (final subtask in task.subtasks!) {
        addRecursive(subtask);
      }
    }

    return flattened;
  }
}
```

---

#### Task 4.2: Extract TaskTagService (5 pts)
**Assignee**: Developer 2
**Duration**: 2 giorni
**Priority**: P1

**Sub-tasks**:
```
✅ Day 1: Create service & move methods
  - [ ] lib/service/task_tag_service.dart
  - [ ] Move getTags() from TaskService
  - [ ] Move getEffectiveTags()
  - [ ] Move addTag() / removeTag()
  - [ ] Move batch operations

✅ Day 2: Optimize & test
  - [ ] Implement caching for tag lookups
  - [ ] Add batch tag loading
  - [ ] Write unit tests
  - [ ] Update integration tests
```

**Code Template**:
```dart
// lib/service/task_tag_service.dart
class TaskTagService {
  final SupabaseClient _client;
  final Map<String, List<Tag>> _cache = {};

  TaskTagService(this._client);

  /// Get direct tags for a task (not inherited)
  Future<List<Tag>> getDirectTags(String taskId) async {
    // Check cache
    if (_cache.containsKey(taskId)) {
      return _cache[taskId]!;
    }

    final response = await _client
        .from('task_tags')
        .select('tag_id')
        .eq('task_id', taskId);

    final tagIds = response.map((row) => row['tag_id'] as String).toList();

    final tags = await _fetchTagsByIds(tagIds);

    // Cache
    _cache[taskId] = tags;

    return tags;
  }

  /// Get effective tags (own + inherited from parents)
  Future<List<Tag>> getEffectiveTags(String taskId) async {
    final allTags = <String, Tag>{};

    // Get task's own tags
    final ownTags = await getDirectTags(taskId);
    for (final tag in ownTags) {
      allTags[tag.id] = tag;
    }

    // Get parent tags recursively
    var currentTask = await _getTask(taskId);
    while (currentTask?.parentTaskId != null) {
      final parentTags = await getDirectTags(currentTask!.parentTaskId!);
      for (final tag in parentTags) {
        allTags[tag.id] = tag;
      }
      currentTask = await _getTask(currentTask.parentTaskId!);
    }

    return allTags.values.toList();
  }

  /// Batch load tags for multiple tasks
  Future<Map<String, List<Tag>>> batchGetTags(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};

    // Fetch all task-tag relationships at once
    final response = await _client
        .from('task_tags')
        .select('task_id, tag_id')
        .inFilter('task_id', taskIds);

    // Group by task_id
    final taskTagMap = <String, List<String>>{};
    for (final row in response) {
      final taskId = row['task_id'] as String;
      final tagId = row['tag_id'] as String;
      taskTagMap.putIfAbsent(taskId, () => []).add(tagId);
    }

    // Get all unique tag IDs
    final allTagIds = taskTagMap.values.expand((ids) => ids).toSet();

    // Batch fetch tags
    final allTags = await _fetchTagsByIds(allTagIds.toList());
    final tagMap = {for (var tag in allTags) tag.id: tag};

    // Build result
    final result = <String, List<Tag>>{};
    for (final taskId in taskIds) {
      final tagIds = taskTagMap[taskId] ?? [];
      result[taskId] = tagIds
          .map((id) => tagMap[id])
          .whereType<Tag>()
          .toList();
    }

    return result;
  }

  /// Add tag to task
  Future<void> addTag(String taskId, String tagId) async {
    await _client.from('task_tags').insert({
      'task_id': taskId,
      'tag_id': tagId,
    });

    // Invalidate cache
    _cache.remove(taskId);
  }

  /// Remove tag from task
  Future<void> removeTag(String taskId, String tagId) async {
    await _client
        .from('task_tags')
        .delete()
        .eq('task_id', taskId)
        .eq('tag_id', tagId);

    // Invalidate cache
    _cache.remove(taskId);
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}
```

---

#### Task 4.3: Extract TaskCompletionService (5 pts)
**Assignee**: Developer 1
**Duration**: 2 giorni
**Priority**: P1

**Sub-tasks**:
```
✅ Day 1: Create service
  - [ ] lib/service/task_completion_service.dart
  - [ ] Move completeTask() logic
  - [ ] Move uncompleteTask() logic
  - [ ] Move canComplete() validation
  - [ ] Move recurring completion logic

✅ Day 2: Test & optimize
  - [ ] Write unit tests
  - [ ] Test recurring scenarios
  - [ ] Test subtask completion
  - [ ] Update integration tests
```

**Code Template**:
```dart
// lib/service/task_completion_service.dart
class TaskCompletionService {
  final TaskRepository _repository;
  final RecurrenceService _recurrenceService;
  final TaskHierarchyService _hierarchyService;

  TaskCompletionService({
    required TaskRepository repository,
    required RecurrenceService recurrenceService,
    required TaskHierarchyService hierarchyService,
  })  : _repository = repository,
        _recurrenceService = recurrenceService,
        _hierarchyService = hierarchyService;

  /// Complete a task with full business logic
  Future<void> completeTask(String taskId) async {
    final task = await _repository.getById(taskId);
    if (task == null) throw NotFoundError('Task not found');

    // Check if can be completed
    final canComplete = await this.canComplete(taskId);
    if (!canComplete) {
      throw BusinessLogicError('Cannot complete task with incomplete subtasks');
    }

    // Check if recurring
    final recurrence = await _recurrenceService.getRecurrenceForTask(taskId);

    if (recurrence != null && recurrence.isEnabled) {
      await _handleRecurringCompletion(task, recurrence);
    } else {
      await _handleNormalCompletion(task);
    }
  }

  /// Check if task can be completed
  Future<bool> canComplete(String taskId) async {
    final descendants = await _hierarchyService.getDescendants(taskId);

    // Can complete if all subtasks are completed
    return descendants.every((t) => t.isCompleted);
  }

  /// Uncomplete a task
  Future<void> uncompleteTask(String taskId) async {
    final task = await _repository.getById(taskId);
    if (task == null) throw NotFoundError('Task not found');

    task.status = TaskStatus.pending;
    task.completedAt = null;

    await _repository.update(task);
  }

  Future<void> _handleNormalCompletion(Task task) async {
    task.status = TaskStatus.completed;
    task.completedAt = DateTime.now();
    await _repository.update(task);
  }

  Future<void> _handleRecurringCompletion(
    Task task,
    Recurrence recurrence,
  ) async {
    // Record completion
    await _recurrenceService.recordCompletion(
      TaskCompletion(
        taskId: task.id,
        completedAt: DateTime.now(),
      ),
    );

    // Calculate next occurrence
    final nextOccurrence = _calculateNextOccurrence(recurrence);

    // Reset task for next occurrence
    task.status = TaskStatus.pending;
    task.completedAt = null;
    if (nextOccurrence != null) {
      task.dueDate = nextOccurrence;
    }

    await _repository.update(task);
  }

  DateTime? _calculateNextOccurrence(Recurrence recurrence) {
    final now = DateTime.now();

    switch (recurrence.dailyFrequency) {
      case DailyFrequency.daily:
        return now.add(Duration(days: 1));
      case DailyFrequency.weekly:
        return now.add(Duration(days: 7));
      case DailyFrequency.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case DailyFrequency.yearly:
        return DateTime(now.year + 1, now.month, now.day);
      default:
        return null;
    }
  }
}
```

---

#### Task 4.4: Update All Usages (3 pts)
**Assignee**: Developer 1 & 2
**Duration**: 1 giorno
**Priority**: P0

**Sub-tasks**:
```
✅ Morning: Update DI registration
  - [ ] Register all new services
  - [ ] Update TaskService dependencies
  - [ ] Verify no circular dependencies

✅ Afternoon: Update widget usage
  - [ ] Update all_tasks_view.dart
  - [ ] Update task_list_item.dart
  - [ ] Update task_detail_page.dart
  - [ ] Run all tests
  - [ ] Fix any breaking changes
```

**Acceptance Criteria**:
- ✅ TaskService < 300 righe
- ✅ Ogni servizio ha responsabilità chiare
- ✅ Tutti i test passano
- ✅ Nessuna regressione

---

### 🎯 SPRINT 5-7: Continued Implementation

**Note**: Gli sprint 5-7 seguono la stessa struttura dettagliata.
Per brevità, vengono inclusi i titoli delle task principali.

#### SPRINT 5: BLoC Migration (03-14 Mar)
- Task 5.1: Create TaskListBloc
- Task 5.2: Migrate AllTasksView to BLoC
- Task 5.3: Create FilterBloc
- Task 5.4: Update tests

#### SPRINT 6: State Optimization (17-28 Mar)
- Task 6.1: Optimize TaskStateManager
- Task 6.2: Add conflict resolution
- Task 6.3: Implement caching layer
- Task 6.4: Performance testing

#### SPRINT 7: Widget Refactor (31 Mar-11 Apr)
- Task 7.1: Decompose TaskListItem
- Task 7.2: Extract filter components
- Task 7.3: Create design system
- Task 7.4: Golden test updates

---

## Branch Strategy

### Git Workflow

```
main (protected)
  ↓
  develop (protected)
    ↓
    refactor/documents-feature-v2 (feature branch)
      ↓
      ├── refactor/sprint-1-foundation
      ├── refactor/sprint-2-testing
      ├── refactor/sprint-3-repository
      ├── refactor/sprint-4-services
      └── ...
```

### Branch Rules

**main**:
- Protected
- Requires 2 approvals
- All CI checks must pass
- No direct commits

**develop**:
- Protected
- Requires 1 approval
- All tests must pass
- Merge from feature branches

**Feature branches**:
- Naming: `refactor/sprint-X-description`
- Merge to develop via PR
- Delete after merge

### PR Template

```markdown
## Sprint X: [Title]

### 📋 Description
[What does this PR do?]

### 🎯 Related Tasks
- [ ] Task X.1: ...
- [ ] Task X.2: ...

### 🧪 Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests passing
- [ ] Manual testing completed

### 📊 Metrics
- Coverage: X% → Y%
- Files changed: X
- Lines added: +X / removed: -X

### 📸 Screenshots
[If UI changes]

### ✅ Checklist
- [ ] Code follows style guide
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No console errors/warnings
- [ ] Tested on iOS & Android

### 🔗 Links
- Issue: #XXX
- Design: [Figma link]
- Documentation: [Link]
```

---

## Definition of Done

### Per Task

- [ ] **Code Complete**
  - [ ] Implementation completed
  - [ ] Code reviewed by team
  - [ ] No TODO comments remaining

- [ ] **Testing**
  - [ ] Unit tests written (>80% coverage)
  - [ ] Widget tests if applicable
  - [ ] Integration tests if applicable
  - [ ] All tests passing

- [ ] **Quality**
  - [ ] No linter warnings
  - [ ] No console errors
  - [ ] Performance benchmarks met
  - [ ] Memory leaks checked

- [ ] **Documentation**
  - [ ] Dartdoc comments added
  - [ ] README updated if needed
  - [ ] CHANGELOG updated

- [ ] **Review**
  - [ ] PR created
  - [ ] Code review approved
  - [ ] CI/CD green
  - [ ] Merged to develop

### Per Sprint

- [ ] **All tasks completed**
  - [ ] Story points delivered
  - [ ] No P0/P1 bugs
  - [ ] Sprint goals achieved

- [ ] **Quality Gates**
  - [ ] Test coverage target met
  - [ ] Performance benchmarks met
  - [ ] No critical issues

- [ ] **Demo**
  - [ ] Sprint demo prepared
  - [ ] Stakeholder feedback collected
  - [ ] Next sprint planned

---

## Daily Workflow

### Morning Routine (9:00-9:30 AM)

```
9:00-9:15: Daily Standup
  - What did you do yesterday?
  - What will you do today?
  - Any blockers?

9:15-9:30: Task planning
  - Review current task
  - Check dependencies
  - Update task status
```

### Development Cycle

```
1. Pick task from sprint board
2. Create feature branch
   git checkout -b refactor/task-X-Y
3. Write failing test (TDD)
4. Implement solution
5. Run tests locally
   flutter test
6. Commit with meaningful message
   git commit -m "refactor(task): add repository layer"
7. Push and create PR
   git push origin refactor/task-X-Y
8. Request review
9. Address feedback
10. Merge when approved
```

### End of Day (5:00-5:30 PM)

```
5:00-5:15: Wrap up
  - Commit WIP if needed
  - Update task status
  - Document blockers

5:15-5:30: Tomorrow planning
  - Review next task
  - Identify dependencies
  - Ask questions if unclear
```

---

## Risk Management

### Risk Matrix

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| Test infrastructure fails | Low | High | Setup on day 1, get help if stuck | Dev 1 |
| Repository migration breaks app | Medium | Critical | Feature flags, gradual rollout | Dev 1 |
| Timeline slippage | High | Medium | 20% buffer, daily tracking | PM |
| Team capacity issues | Medium | High | Pair programming, documentation | Team |
| Scope creep | Medium | Medium | Strict prioritization, no new features | PM |
| Performance regression | Low | High | Baseline tests, monitoring | Dev 2 |

### Mitigation Strategies

#### If Behind Schedule
1. **Identify bottleneck**
   - Daily progress tracking
   - Burn-down chart analysis

2. **Adjust scope**
   - Move P2 tasks to next sprint
   - Focus on P0/P1 only

3. **Add resources**
   - Pair programming
   - External consultant

4. **Extend timeline**
   - Add 1-2 weeks buffer
   - Communicate with stakeholders

#### If Critical Bug Found
1. **Assess severity**
   - P0: Stop everything, fix immediately
   - P1: Fix within 24h
   - P2: Add to backlog

2. **Create hotfix branch**
   ```bash
   git checkout -b hotfix/critical-bug-X
   ```

3. **Fast-track review**
   - Emergency review process
   - Direct merge to develop+main

4. **Post-mortem**
   - Document issue
   - Add regression test
   - Update checklist

---

## Monitoring & Metrics

### Sprint Dashboard

```
┌─────────────────────────────────────────┐
│         SPRINT 1 DASHBOARD              │
├─────────────────────────────────────────┤
│ Progress:        ████████░░ 80%         │
│ Story Points:    17/21 completed        │
│ Velocity:        On track               │
│ Blockers:        1 active               │
│ Test Coverage:   65% (target 60%)       │
│ Days Remaining:  2                      │
└─────────────────────────────────────────┘
```

### Daily Metrics to Track

1. **Progress**
   - Story points completed
   - Tasks in progress
   - Blockers

2. **Quality**
   - Test coverage %
   - Linter warnings
   - Open bugs

3. **Performance**
   - Test execution time
   - Build time
   - Code review time

### Weekly Reports

**Format**:
```markdown
# Week X Report (DD/MM - DD/MM)

## Accomplishments
- ✅ Completed tasks 1.1, 1.2
- ✅ Test coverage increased to 65%
- ✅ Fixed 3 bugs

## Challenges
- ⚠️ Task 1.3 blocked by dependency
- ⚠️ CI pipeline slow (10 min)

## Next Week
- [ ] Complete remaining sprint 1 tasks
- [ ] Start sprint 2
- [ ] Fix CI performance

## Metrics
- Velocity: 17/21 SP
- Coverage: 65%
- Bugs: 2 open, 3 closed
```

---

## Communication Plan

### Meetings Schedule

| Meeting | Frequency | Duration | Participants | Purpose |
|---------|-----------|----------|--------------|---------|
| Daily Standup | Daily 9:00 | 15 min | Dev Team | Sync & blockers |
| Sprint Planning | Bi-weekly Mon 10:00 | 2 hours | Team + PM | Plan sprint |
| Sprint Review | Bi-weekly Fri 15:00 | 1 hour | Team + Stakeholders | Demo & feedback |
| Retrospective | Bi-weekly Fri 16:00 | 1 hour | Dev Team | Improve process |
| 1-on-1 | Weekly | 30 min | Dev + Lead | Individual support |

### Communication Channels

- **Slack #refactoring-docs**: Daily updates, questions
- **GitHub Issues**: Task tracking, bugs
- **GitHub PRs**: Code review, discussions
- **Confluence**: Documentation, decisions
- **Email**: Stakeholder updates (weekly)

### Escalation Path

```
Level 1: Discuss in daily standup
   ↓ (if not resolved)
Level 2: Create blocker issue, tag team lead
   ↓ (if still blocked >24h)
Level 3: Escalate to PM, adjust sprint scope
   ↓ (if critical)
Level 4: Emergency meeting with stakeholders
```

---

## Success Criteria

### Sprint 1 Success
- ✅ All tests running in CI/CD
- ✅ Logger replacing all prints
- ✅ DI setup complete
- ✅ Test coverage >60%

### Phase 1 Success (Sprint 1-2)
- ✅ Test coverage >70%
- ✅ All critical paths tested
- ✅ CI/CD pipeline stable

### Phase 2 Success (Sprint 3-4)
- ✅ Repository pattern implemented
- ✅ Services decomposed (<300 lines each)
- ✅ All tests passing with mocks

### Overall Success
- ✅ Test coverage >80%
- ✅ No file >500 lines
- ✅ Performance targets met
- ✅ All documentation complete
- ✅ Zero P0/P1 bugs
- ✅ Team velocity stable

---

## Appendix

### Useful Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/task_service_test.dart

# Update golden files
flutter test --update-goldens

# Run linter
flutter analyze

# Format code
flutter format .

# Generate build runner
flutter pub run build_runner build --delete-conflicting-outputs

# Check outdated packages
flutter pub outdated
```

### IDE Setup (VS Code)

**Recommended Extensions**:
- Dart
- Flutter
- Flutter Widget Snippets
- Error Lens
- GitLens
- Better Comments
- Todo Tree

**settings.json**:
```json
{
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "dart.debugExternalLibraries": false,
  "dart.debugSdkLibraries": false,
  "[dart]": {
    "editor.rulers": [80],
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  }
}
```

### Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [BLoC Documentation](https://bloclibrary.dev/)
- [GetIt Documentation](https://pub.dev/packages/get_it)
- [Mockito Guide](https://pub.dev/packages/mockito)
- [Golden Toolkit](https://pub.dev/packages/golden_toolkit)

---

**Document Owner**: Tech Lead
**Last Updated**: 2025-12-23
**Version**: 1.0

---

## Quick Start Checklist

**Before Sprint 1 Day 1**:
- [ ] All team members read this document
- [ ] Dev environment setup verified
- [ ] Git branches created
- [ ] Project board setup
- [ ] Kickoff meeting scheduled
- [ ] Stakeholders informed

**Sprint 1 Day 1 Morning**:
- [ ] Kickoff meeting (9:00)
- [ ] Review sprint goals
- [ ] Assign tasks
- [ ] Start Task 1.1

**Let's go! 🚀**
