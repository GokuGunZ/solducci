# Sprint D Phase 2: AllTasksView BLoC Migration - Complete Guide

**Status**: Ready to implement (all prep work done)
**Estimated Time**: 2-3 hours
**Complexity**: HIGH (1025-line file, complex nested structure)

---

## ✅ Prerequisites (COMPLETE)

- [x] TaskListBloc created and tested
- [x] Service locator configured
- [x] Dependencies wired correctly
- [x] All code compiles without errors

---

## 🎯 Migration Strategy

**Approach**: Incremental replacement, test after each step

**Key Principle**: Keep the app running at all times. Each step should compile and run.

---

## Step D.2b: Add BlocProvider Wrapper

### Current Code (lines 26-42)

```dart
class AllTasksView extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

  const AllTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  State<AllTasksView> createState() => _AllTasksViewState();
}
```

### Target Code

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/blocs/task_list/task_list_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';

class AllTasksView extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

  const AllTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<TaskListBloc>();
        // Trigger initial load
        bloc.add(TaskListLoadRequested(document.id));
        return bloc;
      },
      child: _AllTasksViewContent(
        document: document,
        showAllPropertiesNotifier: showAllPropertiesNotifier,
        onInlineCreationCallbackChanged: onInlineCreationCallbackChanged,
        availableTags: availableTags,
      ),
    );
  }
}

// Rename existing _AllTasksViewState to _AllTasksViewContent
class _AllTasksViewContent extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

  const _AllTasksViewContent({
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  State<_AllTasksViewContent> createState() => _AllTasksViewContentState();
}

class _AllTasksViewContentState extends State<_AllTasksViewContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Keep existing state variables for now (will be removed in later steps)
  final _stateManager = TaskStateManager();
  // ... rest of existing code
}
```

### Changes Summary

1. **Change AllTasksView**: StatefulWidget → StatelessWidget
2. **Add BlocProvider**: Wrap content with BlocProvider
3. **Trigger Load**: Add TaskListLoadRequested event
4. **Rename State Class**: _AllTasksViewState → _AllTasksViewContentState
5. **Add Imports**: flutter_bloc, bloc exports, service_locator

### Test After This Step

- App should compile
- View should still work (using old stream system)
- BLoC is created but not yet used

---

## Step D.2c: Replace StreamBuilder with BlocBuilder

### Current Code (lines ~178-266)

```dart
StreamBuilder<List<Task>>(
  stream: _taskStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    final tasks = snapshot.data ?? [];

    // Render task list (80+ lines)
    return _AnimatedTaskListBuilder(
      tasks: tasks,
      document: widget.document,
      // ...
    );
  },
)
```

### Target Code

```dart
BlocBuilder<TaskListBloc, TaskListState>(
  builder: (context, state) {
    return switch (state) {
      TaskListInitial() => const SizedBox.shrink(),

      TaskListLoading() => const Center(
        child: CircularProgressIndicator(),
      ),

      TaskListError(:final message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading tasks'),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<TaskListBloc>()
                  .add(TaskListRefreshRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),

      TaskListLoaded(:final tasks, :final isCreatingTask, :final isReorderMode) =>
        _AnimatedTaskListBuilder(
          tasks: tasks,
          document: widget.document,
          isCreatingTask: isCreatingTask,
          isReorderMode: isReorderMode,
          // ... existing parameters
        ),
    };
  },
)
```

### Changes Summary

1. **Replace StreamBuilder** with BlocBuilder
2. **Use Pattern Matching**: Dart 3 switch expression for states
3. **Handle All States**: Initial, Loading, Error, Loaded
4. **Extract State Data**: Use destructuring (:final tasks, etc.)
5. **Add Retry Button**: For error state

### Test After This Step

- Tasks should load via BLoC
- Filtering/sorting may not work yet (will fix in next steps)
- Error handling improved

---

## Step D.2d: Remove Stream Management Code

### Code to DELETE

**Lines 52-54** (stream declarations):
```dart
late Stream<List<Task>> _taskStream;
StreamSubscription? _listChangesSubscription;
final _taskStreamController = StreamController<List<Task>>.broadcast();
```

**Lines 66-67** (initState calls):
```dart
_initStream();
_checkForCustomOrder();
```

**Lines 70-77** (list changes subscription):
```dart
_listChangesSubscription = _stateManager.listChanges
    .where((docId) => docId == widget.document.id)
    .listen((_) async {
  // ...
});
```

**Lines 91-141** (_initStream and _refreshTasks methods):
```dart
void _initStream() async { /* ... */ }
Future<void> _refreshTasks() async { /* ... */ }
```

**Lines 159-165** (dispose cleanup):
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

### Keep These

- TaskStateManager (used for granular task updates)
- ValueListenableBuilder in TaskListItem (granular rebuilds)
- showAllPropertiesNotifier (UI-only state)

### Changes Summary

- **Delete**: ~90 lines of stream management
- **Keep**: Task state manager for granular updates
- **Result**: Simpler, cleaner code

---

## Step D.2e: Replace Filter ValueNotifier with BLoC Events

### Current Code (lines 57-59)

```dart
final ValueNotifier<FilterSortConfig> _filterConfigNotifier =
    ValueNotifier(const FilterSortConfig());
```

### Where It's Used

1. **filter_sort_dialog.dart** - Callback on filter change
2. **compact_filter_sort_bar.dart** - Displays current filters
3. **_applyFiltersToRawData()** - Applies filters to tasks

### Target: Replace with BLoC Events

**Remove ValueNotifier declaration** (lines 57-59)

**Update filter change handler**:
```dart
// OLD:
_filterConfigNotifier.value = newConfig;

// NEW:
context.read<TaskListBloc>().add(TaskListFilterChanged(newConfig));
```

**Update filter reading**:
```dart
// OLD:
ValueListenableBuilder<FilterSortConfig>(
  valueListenable: _filterConfigNotifier,
  builder: (context, config, _) {
    return CompactFilterSortBar(config: config, ...);
  },
)

// NEW:
BlocBuilder<TaskListBloc, TaskListState>(
  builder: (context, state) {
    final config = state is TaskListLoaded ? state.filterConfig : FilterSortConfig();
    return CompactFilterSortBar(config: config, ...);
  },
)
```

### Files to Update

1. **all_tasks_view.dart**: Remove ValueNotifier, use BLoC
2. **filter_sort_dialog.dart**: Pass BLoC context to callback
3. **compact_filter_sort_bar.dart**: Read from BLoC state

---

## Step D.2f: Handle Task Creation Lifecycle

### Current Code (lines 61-62)

```dart
final ValueNotifier<bool> _isCreatingTaskNotifier = ValueNotifier(false);
```

### Target: Use BLoC Events

**Start creation**:
```dart
void startInlineCreation() {
  context.read<TaskListBloc>().add(TaskListTaskCreationStarted());
}
```

**Complete creation**:
```dart
void _onTaskCreated() {
  context.read<TaskListBloc>().add(TaskListTaskCreationCompleted());
}
```

**Read creation state**:
```dart
// Already available in BlocBuilder:
TaskListLoaded(:final isCreatingTask) => ...
```

---

## Step D.2g: Handle Reorder Mode

### Current Implementation

Reorder mode is activated when user starts dragging (no explicit toggle yet).

### With BLoC

**Toggle reorder mode**:
```dart
void _toggleReorderMode(bool enabled) {
  context.read<TaskListBloc>().add(TaskListReorderModeToggled(enabled));
}
```

**Handle reorder**:
```dart
void _handleReorder(int oldIndex, int newIndex) {
  context.read<TaskListBloc>().add(TaskListTaskReordered(
    oldIndex: oldIndex,
    newIndex: newIndex,
  ));
}
```

**Read reorder state**:
```dart
// Available in BlocBuilder:
TaskListLoaded(:final isReorderMode) => ...
```

---

## Testing Checklist

### Manual Tests

- [ ] **Load Test**: Open document, verify tasks appear
- [ ] **Filter Test**: Apply priority filter, verify correct tasks shown
- [ ] **Sort Test**: Change sort to due date, verify order
- [ ] **Tag Filter Test**: Filter by tag, verify batch loading works
- [ ] **Reorder Test**: Drag-drop task in custom mode, verify persisted
- [ ] **Create Test**: Click add task, create new task, verify appears
- [ ] **Error Test**: Simulate error, verify error UI and retry button
- [ ] **Memory Test**: Open DevTools, check for memory leaks
- [ ] **Performance Test**: Scroll through 100+ tasks, verify smooth

### Regression Tests

- [ ] **Granular Updates**: Edit task title, verify only that item rebuilds
- [ ] **Subtasks**: Expand/collapse subtasks, verify works
- [ ] **Navigation**: Navigate to task detail, verify back button works
- [ ] **Multiple Documents**: Switch between documents, verify independent state

---

## Common Issues & Solutions

### Issue 1: "BLoC not found in context"

**Error**: `BlocProvider.of() called with a context that does not contain a TaskListBloc`

**Solution**: Ensure BlocProvider wraps the widget using context.read()

### Issue 2: "Tasks not loading"

**Debug**:
1. Check BLoC is receiving TaskListLoadRequested event
2. Verify TaskService.initialize() was called
3. Check AppLogger output for BLoC state transitions

### Issue 3: "Filters not working"

**Debug**:
1. Verify TaskListFilterChanged event is dispatched
2. Check BLoC emits new TaskListLoaded state
3. Verify BlocBuilder rebuilds

### Issue 4: "Memory leak after migration"

**Solution**: BLoC is automatically disposed by BlocProvider. TaskStateManager should remain for granular updates.

---

## Rollback Plan

If migration causes critical issues:

1. **Revert commit**: `git revert HEAD`
2. **Keep BLoC code**: Don't delete blocs folder (useful for future)
3. **Remove service locator registration**: Comment out TaskListBloc registration
4. **Test**: Verify app works with old stream system

---

## Success Criteria

✅ **Functionality**: All features work (load, filter, sort, reorder, create)
✅ **Performance**: No regression, smooth scrolling
✅ **Memory**: No leaks detected in DevTools
✅ **Code Quality**: ~200 lines removed, cleaner architecture
✅ **Testability**: Business logic extracted to BLoC (testable without widgets)

---

## Next Steps After Migration

1. **Sprint D.3**: Write TaskListBloc unit tests (bloc_test package)
2. **Sprint D.4**: Migrate TagView to BLoC
3. **Sprint D.5**: Migrate TaskDetailPage to BLoC
4. **Sprint D.6**: Remove remaining manual state management

---

**Estimated Total Time**: 2-3 hours for careful, incremental migration

**Recommended Approach**: Work in 30-minute increments, commit after each successful step

**Last Updated**: 2024-12-24
