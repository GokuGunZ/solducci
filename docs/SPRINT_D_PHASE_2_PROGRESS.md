# Sprint D Phase 2: AllTasksView BLoC Migration - Progress Report

**Status**: IN PROGRESS (40% Complete)

---

## ✅ Completed Steps

### 1. Service Locator Setup (DONE)
**File**: `lib/core/di/service_locator.dart`

**Changes Made**:
- Added TaskListBloc import
- Registered TaskListBloc as factory (NOT singleton - each view gets own instance)
- Dependencies wired: TaskService, TaskStateManager, TaskOrderPersistenceService

**Code**:
```dart
getIt.registerFactory<TaskListBloc>(
  () => TaskListBloc(
    taskService: getIt<TaskService>(),
    stateManager: getIt<TaskStateManager>(),
    orderPersistenceService: getIt<TaskOrderPersistenceService>(),
  ),
);
```

**Note**: Factory pattern used because BLoCs should NOT be shared across views.

---

## 📋 Next Steps (D.2b - D.2f)

### Step D.2b: Add BlocProvider to AllTasksView
**File**: `lib/views/documents/all_tasks_view.dart`

**Current Structure** (lines 26-42):
```dart
class AllTasksView extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  // ...

  @override
  State<AllTasksView> createState() => _AllTasksViewState();
}
```

**Target Structure**:
```dart
class AllTasksView extends StatelessWidget {  // Change to StatelessWidget
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  // ...

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<TaskListBloc>();
        bloc.add(TaskListLoadRequested(document.id));
        return bloc;
      },
      child: _AllTasksViewContent(
        document: document,
        showAllPropertiesNotifier: showAllPropertiesNotifier,
        // ...
      ),
    );
  }
}

// New widget for actual content
class _AllTasksViewContent extends StatefulWidget {
  // Keep StatefulWidget for local UI state (animations, controllers, etc.)
}
```

**Lines to Modify**: 26-42

---

### Step D.2c: Replace StreamBuilder with BlocBuilder
**File**: `lib/views/documents/all_tasks_view.dart`

**Current Code** (lines 178-266):
```dart
StreamBuilder<List<Task>>(
  stream: _taskStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    final tasks = snapshot.data ?? [];
    // ... 80+ lines of rendering logic
  },
)
```

**Target Code**:
```dart
BlocBuilder<TaskListBloc, TaskListState>(
  builder: (context, state) {
    return switch (state) {
      TaskListInitial() => SizedBox.shrink(),
      TaskListLoading() => Center(child: CircularProgressIndicator()),
      TaskListError(:final message) => Center(child: Text('Error: $message')),
      TaskListLoaded(:final tasks, :final isCreatingTask, :final isReorderMode) =>
        // ... existing rendering logic with tasks
        _buildTaskList(context, tasks, isCreatingTask, isReorderMode),
    };
  },
)
```

**Lines to Modify**: 178-266

**Note**: Use Dart 3 pattern matching for clean state handling.

---

### Step D.2d: Remove Manual Stream Management
**File**: `lib/views/documents/all_tasks_view.dart`

**Code to Remove** (lines 53-55):
```dart
late Stream<List<Task>> _taskStream;
StreamSubscription? _listChangesSubscription;
final _taskStreamController = StreamController<List<Task>>.broadcast();
```

**Code to Remove** (lines 92-105):
```dart
void _initStream() async {
  // ... 13 lines of stream setup
}
```

**Code to Remove** (lines 160-165):
```dart
@override
void dispose() {
  _listChangesSubscription?.cancel();
  _taskStreamController.close();
  _filterConfigNotifier.dispose();
  _isCreatingTaskNotifier.dispose();
  super.dispose();
}
```

**Lines to Remove**: ~50 lines total

---

### Step D.2e: Replace Filter ValueNotifier with BLoC Events
**Current Code** (lines 58-59):
```dart
final ValueNotifier<FilterSortConfig> _filterConfigNotifier =
    ValueNotifier(const FilterSortConfig());
```

**Target**: Remove ValueNotifier, use BLoC events instead

**Example Usage**:
```dart
// OLD:
_filterConfigNotifier.value = newConfig;

// NEW:
context.read<TaskListBloc>().add(TaskListFilterChanged(newConfig));
```

**Files Affected**:
- filter_sort_dialog.dart (callback to parent)
- compact_filter_sort_bar.dart (filter UI)

---

### Step D.2f: Handle Task Creation Lifecycle
**Current Code** (lines 61-62):
```dart
final ValueNotifier<bool> _isCreatingTaskNotifier = ValueNotifier(false);
```

**Target**:
```dart
// Start creation:
context.read<TaskListBloc>().add(TaskListTaskCreationStarted());

// Complete creation:
context.read<TaskListBloc>().add(TaskListTaskCreationCompleted());
```

**Where Used**:
- startInlineCreation() method
- TaskCreationRow widget

---

## 🎯 Expected Results After Migration

**Before** (Current AllTasksView):
- 1025 lines total
- ~200 lines of stream management boilerplate
- Manual StreamController lifecycle
- ValueNotifiers for UI state
- setState() calls scattered throughout

**After** (Migrated AllTasksView):
- ~825 lines total (200 lines removed)
- Zero manual stream management
- BLoC handles all business logic
- Clean state transitions
- Testable without widget tree

---

## 🧪 Testing Plan

### Manual Testing
1. **Load Test**: Open document, verify tasks load
2. **Filter Test**: Apply filters, verify correct tasks shown
3. **Sort Test**: Change sort option, verify order
4. **Reorder Test**: Drag-drop tasks in custom mode
5. **Create Test**: Inline task creation works
6. **Memory Test**: DevTools shows no leaks after Sprint 6 optimizations

### Automated Testing (D.3)
- BLoC unit tests already planned
- Widget tests for AllTasksView (optional)

---

## 📝 Migration Checklist

- [x] D.2a: Service locator registration
- [ ] D.2b: Add BlocProvider wrapper
- [ ] D.2c: Replace StreamBuilder → BlocBuilder
- [ ] D.2d: Remove stream management code
- [ ] D.2e: Replace filter ValueNotifier
- [ ] D.2f: Handle creation lifecycle
- [ ] D.2g: Test all functionality
- [ ] D.2h: Commit migration

---

## ⚠️ Risks & Mitigation

**Risk 1**: Breaking existing functionality
- **Mitigation**: Incremental changes, test after each step

**Risk 2**: Performance regression
- **Mitigation**: Keep TaskStateManager for granular updates

**Risk 3**: Complex nested widgets
- **Mitigation**: Extract to separate widgets (_buildTaskList, etc.)

---

## 📚 Reference

**Related Files**:
- `lib/blocs/task_list/task_list_bloc.dart` - BLoC implementation
- `lib/blocs/task_list/task_list_event.dart` - Events
- `lib/blocs/task_list/task_list_state.dart` - States
- `lib/core/di/service_locator.dart` - DI setup

**Dependencies**:
- flutter_bloc: ^8.1.3 (already installed)
- equatable: ^2.0.5 (already installed)

---

**Last Updated**: 2024-12-24
**Next Session**: Continue from Step D.2b
