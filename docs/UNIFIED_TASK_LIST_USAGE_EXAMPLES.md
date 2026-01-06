# Unified Task List - Usage Examples

This document provides practical examples of how to use the new unified task list components created in Phase 1.

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Creating Data Sources](#creating-data-sources)
3. [Using UnifiedTaskListBloc](#using-unifiedtasklistbloc)
4. [Event Examples](#event-examples)
5. [State Handling](#state-handling)
6. [Testing Examples](#testing-examples)

---

## Basic Usage

### Document-Based Task List

```dart
import 'package:solducci/blocs/unified_task_list/unified_task_list_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';

// Create data source for document tasks
final dataSource = DocumentTaskDataSource(
  documentId: 'my-document-id',
  taskService: getIt<TaskService>(),
  stateManager: getIt<TaskStateManager>(),
);

// Get BLoC instance from service locator
final bloc = getIt<UnifiedTaskListBloc>();

// Load tasks
bloc.add(TaskListLoadRequested(dataSource));
```

### Tag-Filtered Task List

```dart
// Create data source for tag-filtered tasks
final dataSource = TagTaskDataSource(
  tagId: 'my-tag-id',
  documentId: 'my-document-id',
  includeCompleted: true,
  taskService: getIt<TaskService>(),
  stateManager: getIt<TaskStateManager>(),
);

final bloc = getIt<UnifiedTaskListBloc>();
bloc.add(TaskListLoadRequested(dataSource));
```

---

## Creating Data Sources

### DocumentTaskDataSource

```dart
// For "All Tasks" view
final allTasksDataSource = DocumentTaskDataSource(
  documentId: document.id,
  taskService: TaskService(),
  stateManager: TaskStateManager(),
);

// Features:
// - Loads ALL tasks in the document
// - Supports custom reordering (supportsReordering = true)
// - Auto-refresh on task changes via listChanges stream
```

### TagTaskDataSource

```dart
// For tag-filtered view
final tagDataSource = TagTaskDataSource(
  tagId: tag.id,
  documentId: document.id,
  includeCompleted: tag.showCompleted,
  taskService: TaskService(),
  stateManager: TaskStateManager(),
);

// Features:
// - Loads only tasks with specific tag
// - No reordering support (supportsReordering = false)
// - Auto-refresh on task changes in parent document
// - Respects includeCompleted flag
```

### Custom Data Source (Future Extension)

```dart
// Example: Priority-filtered tasks
class PriorityTaskDataSource implements TaskListDataSource {
  final TaskPriority priority;
  final String documentId;

  @override
  Future<List<Task>> loadTasks() async {
    final allTasks = await taskService.fetchTasksForDocument(documentId);
    return allTasks.where((t) => t.priority == priority).toList();
  }

  @override
  Stream<String> get listChanges => stateManager.listChanges
      .where((docId) => docId == documentId);

  @override
  String get identifier => 'priority_${priority.name}_$documentId';
}
```

---

## Using UnifiedTaskListBloc

### Complete Example with BlocProvider

```dart
class MyTaskListPage extends StatelessWidget {
  final TodoDocument document;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<UnifiedTaskListBloc>();

        // Create data source
        final dataSource = DocumentTaskDataSource(
          documentId: document.id,
          taskService: getIt<TaskService>(),
          stateManager: getIt<TaskStateManager>(),
        );

        // Load tasks
        bloc.add(TaskListLoadRequested(dataSource));

        return bloc;
      },
      child: BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
        builder: (context, state) {
          return switch (state) {
            TaskListInitial() => const SizedBox.shrink(),
            TaskListLoading() => const CircularProgressIndicator(),
            TaskListError(:final message) => Text('Error: $message'),
            TaskListLoaded(:final tasks) => ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => TaskListItem(
                task: tasks[index],
                // ...
              ),
            ),
          };
        },
      ),
    );
  }
}
```

---

## Event Examples

### Loading Tasks

```dart
// Initial load
bloc.add(TaskListLoadRequested(dataSource));

// This will:
// 1. Emit TaskListLoading state
// 2. Fetch tasks from data source
// 3. Subscribe to auto-refresh stream
// 4. Emit TaskListLoaded with tasks
```

### Applying Filters

```dart
// Filter by priority and status
final filterConfig = FilterSortConfig(
  priorities: {TaskPriority.high, TaskPriority.urgent},
  statuses: {TaskStatus.pending, TaskStatus.inProgress},
  sortBy: TaskSortOption.dueDate,
  sortAscending: true,
);

bloc.add(TaskListFilterChanged(filterConfig));

// This will:
// 1. Apply filters to rawTasks (cached unfiltered data)
// 2. Emit TaskListLoaded with filtered tasks
// 3. Preserve isCreatingTask and other UI state
```

### Sorting Tasks

```dart
// Sort by due date
bloc.add(TaskListFilterChanged(
  currentConfig.copyWith(
    sortBy: TaskSortOption.dueDate,
    sortAscending: false, // Descending
  ),
));

// Sort by custom order (only if supportsReordering)
bloc.add(TaskListFilterChanged(
  currentConfig.copyWith(sortBy: TaskSortOption.custom),
));
```

### Reordering Tasks

```dart
// User drags task from index 2 to index 5
bloc.add(TaskListTaskReordered(oldIndex: 2, newIndex: 5));

// This will:
// 1. Update task list order
// 2. Persist custom order (if DocumentTaskDataSource)
// 3. Emit TaskListLoaded with reordered tasks
```

### Inline Task Creation

```dart
// Show creation row
bloc.add(const TaskListTaskCreationStarted());
// State: isCreatingTask = true

// ... user creates task ...

// Hide creation row
bloc.add(const TaskListTaskCreationCompleted());
// State: isCreatingTask = false

// Auto-refresh will happen via stream subscription
```

### Manual Refresh

```dart
// Force refresh from data source
bloc.add(const TaskListRefreshRequested());

// This will:
// 1. Re-fetch tasks from data source
// 2. Re-apply current filters
// 3. Preserve UI state (isCreatingTask, filterConfig)
// 4. Emit TaskListLoaded with fresh data
```

### Toggle Reorder Mode

```dart
// Enable reorder mode (only if supportsReordering)
bloc.add(const TaskListReorderModeToggled(true));
// State: isReorderMode = true, sortBy auto-switches to custom

// Disable reorder mode
bloc.add(const TaskListReorderModeToggled(false));
// State: isReorderMode = false
```

---

## State Handling

### Checking Current State

```dart
BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
  builder: (context, state) {
    if (state is TaskListLoaded) {
      final tasks = state.tasks;
      final isCreating = state.isCreatingTask;
      final canReorder = state.supportsReordering;

      // Build UI based on state
    }
  },
)
```

### Listening to State Changes

```dart
BlocListener<UnifiedTaskListBloc, UnifiedTaskListState>(
  listener: (context, state) {
    if (state is TaskListError) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }

    if (state is TaskListLoaded) {
      // Log successful load
      print('Loaded ${state.tasks.length} tasks');
    }
  },
  child: // ... your UI
)
```

### Conditional Building Based on Multiple State Properties

```dart
BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
  buildWhen: (previous, current) {
    // Only rebuild when tasks or isCreatingTask changes
    if (previous is TaskListLoaded && current is TaskListLoaded) {
      return previous.tasks != current.tasks ||
             previous.isCreatingTask != current.isCreatingTask;
    }
    return true;
  },
  builder: (context, state) {
    // Optimized rebuild
  },
)
```

---

## Testing Examples

### Unit Test: DocumentTaskDataSource

```dart
test('DocumentTaskDataSource loads tasks correctly', () async {
  // Arrange
  final mockTaskService = MockTaskService();
  final mockStateManager = MockTaskStateManager();
  final mockTasks = [Task.create(title: 'Test Task')];

  when(mockTaskService.fetchTasksForDocument('doc123'))
      .thenAnswer((_) async => mockTasks);

  final dataSource = DocumentTaskDataSource(
    documentId: 'doc123',
    taskService: mockTaskService,
    stateManager: mockStateManager,
  );

  // Act
  final tasks = await dataSource.loadTasks();

  // Assert
  expect(tasks, equals(mockTasks));
  verify(mockTaskService.fetchTasksForDocument('doc123')).called(1);
});
```

### Unit Test: UnifiedTaskListBloc

```dart
blocTest<UnifiedTaskListBloc, UnifiedTaskListState>(
  'emits [Loading, Loaded] when TaskListLoadRequested is added',
  build: () => UnifiedTaskListBloc(
    orderPersistenceService: mockOrderService,
  ),
  act: (bloc) {
    final dataSource = MockDocumentTaskDataSource();
    when(dataSource.loadTasks()).thenAnswer((_) async => mockTasks);
    when(dataSource.listChanges).thenAnswer((_) => Stream.empty());

    bloc.add(TaskListLoadRequested(dataSource));
  },
  expect: () => [
    const TaskListLoading(),
    TaskListLoaded(
      tasks: mockTasks,
      rawTasks: mockTasks,
      supportsReordering: true,
    ),
  ],
);
```

### Widget Test: Using UnifiedTaskListBloc

```dart
testWidgets('displays task list when loaded', (tester) async {
  // Arrange
  final mockBloc = MockUnifiedTaskListBloc();
  final loadedState = TaskListLoaded(
    tasks: [
      Task.create(title: 'Task 1'),
      Task.create(title: 'Task 2'),
    ],
    rawTasks: [],
  );

  whenListen(
    mockBloc,
    Stream.fromIterable([loadedState]),
    initialState: const TaskListInitial(),
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: mockBloc,
        child: MyTaskListWidget(),
      ),
    ),
  );
  await tester.pump();

  // Assert
  expect(find.text('Task 1'), findsOneWidget);
  expect(find.text('Task 2'), findsOneWidget);
});
```

---

## Comparison: Old vs New Approach

### Old Approach (Separate BLoCs)

```dart
// For document tasks
final docBloc = getIt<TaskListBloc>();
docBloc.add(TaskListLoadRequested(documentId));

// For tag tasks
final tagBloc = getIt<TagBloc>();
tagBloc.add(TagLoadRequested(
  tagId: tagId,
  documentId: documentId,
  includeCompleted: true,
));

// Two different BLoCs, two different APIs
```

### New Approach (Unified BLoC)

```dart
// For document tasks
final docDataSource = DocumentTaskDataSource(
  documentId: documentId,
  taskService: taskService,
  stateManager: stateManager,
);
final bloc = getIt<UnifiedTaskListBloc>();
bloc.add(TaskListLoadRequested(docDataSource));

// For tag tasks
final tagDataSource = TagTaskDataSource(
  tagId: tagId,
  documentId: documentId,
  includeCompleted: true,
  taskService: taskService,
  stateManager: stateManager,
);
final bloc2 = getIt<UnifiedTaskListBloc>();
bloc2.add(TaskListLoadRequested(tagDataSource));

// Same BLoC, same API, different data source
```

---

## Best Practices

### 1. Data Source Creation

✅ **DO**: Create data sources close to where they're used
```dart
final dataSource = DocumentTaskDataSource(/*...*/);
bloc.add(TaskListLoadRequested(dataSource));
```

❌ **DON'T**: Reuse data sources across different contexts
```dart
// Bad: sharing data source might cause unexpected refreshes
final globalDataSource = DocumentTaskDataSource(/*...*/);
bloc1.add(TaskListLoadRequested(globalDataSource));
bloc2.add(TaskListLoadRequested(globalDataSource)); // Don't do this
```

### 2. State Preservation

✅ **DO**: Use buildWhen to optimize rebuilds
```dart
BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
  buildWhen: (prev, curr) => prev.isCreatingTask != curr.isCreatingTask,
  builder: // ...
)
```

### 3. Error Handling

✅ **DO**: Always handle TaskListError state
```dart
return switch (state) {
  TaskListError(:final message) => ErrorWidget(message),
  // ... other states
};
```

### 4. Testing

✅ **DO**: Mock data sources in tests
```dart
final mockDataSource = MockDocumentTaskDataSource();
when(mockDataSource.loadTasks()).thenAnswer((_) async => mockTasks);
```

---

## Future Extensions (Post-Migration)

Once Phase 2-4 are complete, we can easily add new data sources:

### Example: Search Results

```dart
class SearchTaskDataSource implements TaskListDataSource {
  final String query;
  final String documentId;

  @override
  Future<List<Task>> loadTasks() async {
    // Search implementation
  }
}
```

### Example: Date-Filtered Tasks

```dart
class DateRangeTaskDataSource implements TaskListDataSource {
  final DateTime start;
  final DateTime end;

  @override
  Future<List<Task>> loadTasks() async {
    // Filter by date range
  }
}
```

---

**Document Version**: 1.0
**Last Updated**: 2026-01-06
**Status**: Phase 1 Complete
