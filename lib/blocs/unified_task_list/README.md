# UnifiedTaskListBloc

**Status**: ✅ Ready for use (Phase 1 Complete)
**Created**: 2026-01-06
**Purpose**: Unified BLoC for task lists from any data source

---

## Overview

This BLoC combines the functionality of `TaskListBloc` and `TagBloc` into a single, reusable component using the **Strategy Pattern**.

### Key Benefits

- ✅ **Single Source of Truth**: One BLoC for all task list scenarios
- ✅ **Polymorphic Data Loading**: Works with any data source (document, tag, search, etc.)
- ✅ **Zero Duplication**: Eliminates ~700 lines of duplicated code
- ✅ **Easy Testing**: Mock data sources instead of entire services
- ✅ **Extensible**: Add new data sources without modifying BLoC

---

## Quick Start

### 1. Import

```dart
import 'package:solducci/blocs/unified_task_list/unified_task_list_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';
```

### 2. Create Data Source

```dart
// For document tasks
final dataSource = DocumentTaskDataSource(
  documentId: 'my-document-id',
  taskService: getIt<TaskService>(),
  stateManager: getIt<TaskStateManager>(),
);

// OR for tag-filtered tasks
final dataSource = TagTaskDataSource(
  tagId: 'my-tag-id',
  documentId: 'my-document-id',
  includeCompleted: true,
  taskService: getIt<TaskService>(),
  stateManager: getIt<TaskStateManager>(),
);
```

### 3. Use BLoC

```dart
final bloc = getIt<UnifiedTaskListBloc>();
bloc.add(TaskListLoadRequested(dataSource));
```

### 4. Listen to State

```dart
BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
  builder: (context, state) {
    return switch (state) {
      TaskListInitial() => const SizedBox.shrink(),
      TaskListLoading() => const CircularProgressIndicator(),
      TaskListError(:final message) => Text('Error: $message'),
      TaskListLoaded(:final tasks) => ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) => TaskListItem(task: tasks[index]),
      ),
    };
  },
)
```

---

## Files in This Module

### Core Components

- **`unified_task_list_bloc.dart`** - Main BLoC implementation
- **`unified_task_list_event.dart`** - Event definitions
- **`unified_task_list_state.dart`** - State definitions
- **`task_list_data_source.dart`** - Data source abstraction (Strategy Pattern)
- **`unified_task_list_bloc_export.dart`** - Convenient export file

### Supporting Files

- **`README.md`** - This file
- **`../../test/blocs/unified_task_list/unified_task_list_bloc_test.dart`** - Test suite

---

## Architecture

### Strategy Pattern

```
TaskListDataSource (Interface)
    ↑
    ├── DocumentTaskDataSource (loads all tasks from document)
    └── TagTaskDataSource (loads tag-filtered tasks)

UnifiedTaskListBloc (Context)
    ↓
Uses any TaskListDataSource polymorphically
```

### Event Flow

```
User Action → Event → BLoC → State → UI Update

Examples:
FAB Click → TaskListTaskCreationStarted → isCreatingTask=true → Show TaskCreationRow
Task Created → (auto-refresh via stream) → TaskListRefreshRequested → Updated tasks → Animate in
Filter Change → TaskListFilterChanged → Filtered tasks → UI updates
```

---

## Events

| Event | Purpose | Parameters |
|-------|---------|------------|
| `TaskListLoadRequested` | Load tasks from data source | `dataSource` |
| `TaskListFilterChanged` | Apply filters/sorting | `config: FilterSortConfig` |
| `TaskListTaskReordered` | Drag-and-drop reorder | `oldIndex`, `newIndex` |
| `TaskListTaskCreationStarted` | Show inline creation row | - |
| `TaskListTaskCreationCompleted` | Hide inline creation row | - |
| `TaskListRefreshRequested` | Manual refresh | - |
| `TaskListReorderModeToggled` | Toggle reorder UI | `enabled: bool` |

---

## States

| State | Description | Properties |
|-------|-------------|------------|
| `TaskListInitial` | Before loading | - |
| `TaskListLoading` | Fetching data | - |
| `TaskListLoaded` | Data ready | `tasks`, `rawTasks`, `filterConfig`, `isCreatingTask`, `isReorderMode`, `supportsReordering` |
| `TaskListError` | Error occurred | `message`, `error` |

---

## Data Sources

### DocumentTaskDataSource

**Purpose**: Load all tasks from a document

**Features**:
- ✅ Supports custom reordering
- ✅ Auto-refresh on task changes
- ✅ Loads entire document task tree

**Usage**:
```dart
final dataSource = DocumentTaskDataSource(
  documentId: document.id,
  taskService: getIt<TaskService>(),
  stateManager: getIt<TaskStateManager>(),
);
```

### TagTaskDataSource

**Purpose**: Load tasks filtered by specific tag

**Features**:
- ✅ Tag-based filtering
- ✅ Respects `includeCompleted` flag
- ✅ Auto-refresh on parent document changes
- ❌ No reordering support

**Usage**:
```dart
final dataSource = TagTaskDataSource(
  tagId: tag.id,
  documentId: document.id,
  includeCompleted: tag.showCompleted,
  taskService: getIt<TaskService>(),
  stateManager: getIt<TaskStateManager>(),
);
```

---

## Common Patterns

### Loading with Filters

```dart
// 1. Load data
bloc.add(TaskListLoadRequested(dataSource));

// 2. Wait for TaskListLoaded state

// 3. Apply filters
bloc.add(TaskListFilterChanged(
  FilterSortConfig(
    priorities: {TaskPriority.high},
    sortBy: TaskSortOption.dueDate,
  ),
));
```

### Inline Task Creation

```dart
// Show creation row
bloc.add(const TaskListTaskCreationStarted());

// ... user creates task via TaskCreationRow ...

// Hide creation row
bloc.add(const TaskListTaskCreationCompleted());

// Auto-refresh happens via stream subscription
```

### Reordering (DocumentTaskDataSource only)

```dart
// Check if reordering is supported
if (state is TaskListLoaded && state.supportsReordering) {
  // User drags task
  bloc.add(TaskListTaskReordered(oldIndex: 2, newIndex: 5));
}
```

---

## Integration with Existing Code

### Phase 1 (Current): Coexistence

- ✅ UnifiedTaskListBloc registered in service locator
- ✅ TaskListBloc still exists (used by AllTasksView)
- ✅ TagBloc still exists (used by TagView)
- ✅ Zero breaking changes

### Phase 2 (Future): AllTasksView Migration

- AllTasksView will use UnifiedTaskListBloc
- TaskListView component will be created
- AllTasksView becomes thin wrapper (~50 lines)

### Phase 3 (Future): TagView Migration

- TagView will use UnifiedTaskListBloc
- TagView becomes thin wrapper (~60 lines)

### Phase 4 (Future): Cleanup

- Remove old TaskListBloc
- Remove old TagBloc
- Single BLoC for all task lists

---

## Testing

### Unit Tests

Located at: `/test/blocs/unified_task_list/unified_task_list_bloc_test.dart`

**Coverage**:
- ✅ Load from data source
- ✅ Apply filters
- ✅ Inline creation flow
- ✅ Refresh with state preservation
- ✅ Error handling

**Run Tests**:
```bash
flutter test test/blocs/unified_task_list/
```

### Mocking

```dart
// Mock data source
final mockDataSource = MockTaskListDataSource();
when(() => mockDataSource.loadTasks()).thenAnswer((_) async => mockTasks);
when(() => mockDataSource.listChanges).thenAnswer((_) => Stream.empty());

// Use in BLoC
final bloc = UnifiedTaskListBloc(
  orderPersistenceService: mockOrderService,
);
bloc.add(TaskListLoadRequested(mockDataSource));
```

---

## Performance Considerations

### Optimizations

1. **Granular Rebuilds**: TaskStateManager ensures only changed tasks rebuild
2. **Cached Raw Data**: `rawTasks` cached for efficient re-filtering
3. **Stream Subscription**: Auto-refresh only when parent document changes
4. **buildWhen**: Optimize widget rebuilds based on specific state changes

### Best Practices

✅ **DO**: Use `buildWhen` to optimize rebuilds
```dart
BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
  buildWhen: (prev, curr) => prev.isCreatingTask != curr.isCreatingTask,
  builder: // ...
)
```

✅ **DO**: Dispose BLoC when done
```dart
@override
void dispose() {
  bloc.close();
  super.dispose();
}
```

❌ **DON'T**: Create new data sources on every rebuild
```dart
// Bad
Widget build(BuildContext context) {
  final dataSource = DocumentTaskDataSource(/*...*/); // Don't do this!
  bloc.add(TaskListLoadRequested(dataSource));
}
```

---

## Troubleshooting

### Issue: "Tasks not loading"

**Check**:
1. Is data source created correctly?
2. Did you call `TaskListLoadRequested`?
3. Is TaskService initialized?

### Issue: "Reordering not working"

**Solution**: Reordering only works with `DocumentTaskDataSource`
```dart
if (state is TaskListLoaded && state.supportsReordering) {
  // Reordering is available
}
```

### Issue: "isCreatingTask not updating"

**Check**: Are you using `buildWhen` correctly?
```dart
buildWhen: (previous, current) {
  if (previous is TaskListLoaded && current is TaskListLoaded) {
    return previous.isCreatingTask != current.isCreatingTask;
  }
  return true;
}
```

---

## Migration Guide

### From TaskListBloc

**Before**:
```dart
final bloc = getIt<TaskListBloc>();
bloc.add(TaskListLoadRequested(documentId));
```

**After**:
```dart
final dataSource = DocumentTaskDataSource(
  documentId: documentId,
  taskService: getIt<TaskService>(),
  stateManager: getIt<TaskStateManager>(),
);
final bloc = getIt<UnifiedTaskListBloc>();
bloc.add(TaskListLoadRequested(dataSource));
```

### From TagBloc

**Before**:
```dart
final bloc = getIt<TagBloc>();
bloc.add(TagLoadRequested(
  tagId: tagId,
  documentId: documentId,
  includeCompleted: true,
));
```

**After**:
```dart
final dataSource = TagTaskDataSource(
  tagId: tagId,
  documentId: documentId,
  includeCompleted: true,
  taskService: getIt<TaskService>(),
  stateManager: getIt<TaskStateManager>(),
);
final bloc = getIt<UnifiedTaskListBloc>();
bloc.add(TaskListLoadRequested(dataSource));
```

---

## Documentation

**Main Docs**:
- [Phase 1 Complete](../../../docs/UNIFIED_TASK_LIST_PHASE1_COMPLETE.md) - Technical overview
- [Usage Examples](../../../docs/UNIFIED_TASK_LIST_USAGE_EXAMPLES.md) - Practical examples
- [Refactoring Status](../../../docs/REFACTORING_STATUS.md) - Progress tracking

**Related Code**:
- Service Locator: `lib/core/di/service_locator.dart`
- Old BLoCs: `lib/blocs/task_list/`, `lib/blocs/tag/`
- Tests: `test/blocs/unified_task_list/`

---

## Future Extensions

### Adding New Data Sources

```dart
// Example: Search results
class SearchTaskDataSource implements TaskListDataSource {
  final String query;

  @override
  Future<List<Task>> loadTasks() async {
    // Implement search
  }

  @override
  Stream<String> get listChanges => /* ... */;

  @override
  String get identifier => 'search_$query';
}

// Use immediately
final dataSource = SearchTaskDataSource(query: 'urgent');
bloc.add(TaskListLoadRequested(dataSource));
```

---

## Support

**Questions?**
- See [Usage Examples](../../../docs/UNIFIED_TASK_LIST_USAGE_EXAMPLES.md)
- Check [Troubleshooting](#troubleshooting) section above
- Review test examples in `unified_task_list_bloc_test.dart`

**Found a Bug?**
- Check if it's a data source issue or BLoC issue
- Add test case to reproduce
- Submit with detailed description

---

**Version**: 1.0.0
**Phase**: 1 Complete ✅
**Status**: Production Ready (awaiting Phase 2 UI components)
**Last Updated**: 2026-01-06
