# TaskListItem Decomposition Plan

**Status**: 🔄 In Progress
**File**: `lib/widgets/documents/task_list_item.dart`
**Current Size**: 1558 lines
**Target**: < 300 lines per file

---

## Current Analysis

### File Structure (Analyzed 2024-12-24)

```dart
TaskListItem (StatefulWidget) - 1558 lines total
├── Parameters: 9 (task, document, onTap, depth, showAllPropertiesNotifier, etc.)
├── _TaskListItemState
│   ├── Fields: 6 (isExpanded, taskService, recurrence, isTogglingComplete, etc.)
│   ├── Responsibilities:
│   │   1. Task rendering & layout (~200 lines)
│   │   2. Checkbox completion logic (~100 lines)
│   │   3. Properties management (priority, date, size, tags) (~400 lines)
│   │   4. Swipe actions (delete, duplicate) (~150 lines)
│   │   5. Subtask expansion (~100 lines)
│   │   6. Inline creation subtask (~80 lines)
│   │   7. State synchronization with TaskStateManager (~50 lines)
│   └── Already extracted (internal widgets):
│       ├── _TaskTitle (116 lines) - lines 1099-1214
│       ├── _TaskDescription (108 lines) - lines 1214-1325
│       └── _TaskTagsRow (230 lines) - lines 1325-1558
```

### Dependencies

**Services**:
- TaskService (singleton - need DI)
- RecurrenceService (singleton - need DI)
- TaskStateManager (singleton - ok for now)

**Models**:
- Task, TodoDocument, Tag, Recurrence

**Other Widgets**:
- TaskCreationRow (inline subtask creation)
- TaskDetailPage (navigation on tap)
- QuickEditDialogs (priority, date, size pickers)
- RecurrenceFormDialog
- SubtaskAnimatedList (expansion)

---

## Decomposition Strategy

### Phase 1: Extract Configuration Object ✅ NEXT

**Goal**: Reduce 9 parameters → 3 parameters

**Before**:
```dart
TaskListItem({
  required Task task,
  TodoDocument? document,
  VoidCallback? onTap,
  int depth = 0,
  ValueNotifier<bool>? showAllPropertiesNotifier,
  List<Tag>? preloadedTags,
  Map<String, List<Tag>>? taskTagsMap,
  bool dismissibleEnabled = true,
})
```

**After**:
```dart
TaskListItem({
  required Task task,
  required TaskItemConfig config,
  TaskItemCallbacks? callbacks,
})

class TaskItemConfig {
  final TodoDocument? document;
  final int depth;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final List<Tag>? preloadedTags;
  final Map<String, List<Tag>>? taskTagsMap;
  final bool dismissibleEnabled;
  final bool showProperties;
  final bool allowSubtasks;
  final bool allowInlineEdit;

  // Presets
  static const readOnly = TaskItemConfig(allowInlineEdit: false, dismissibleEnabled: false);
  static const compact = TaskItemConfig(showProperties: false, allowSubtasks: false);
}

class TaskItemCallbacks {
  final VoidCallback? onTap;
  final VoidCallback? onChanged;
  final Future<void> Function(Task)? onDelete;
  final Future<void> Function(Task)? onDuplicate;
}
```

**Files to Create**:
- `lib/widgets/documents/task_list_item/task_item_config.dart`
- `lib/widgets/documents/task_list_item/task_item_callbacks.dart`

**Time**: 1 hour

---

### Phase 2: Extract Checkbox Component

**Goal**: Isolate completion logic

**File**: `lib/widgets/documents/task_list_item/components/task_checkbox.dart`

```dart
class TaskCheckbox extends StatelessWidget {
  final Task task;
  final bool isToggling;
  final Future<void> Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: task.status == TaskStatus.completed,
      onChanged: isToggling ? null : (value) => onToggle(value ?? false),
      // ... styling
    );
  }
}
```

**Lines Extracted**: ~50 lines

**Time**: 30 minutes

---

### Phase 3: Extract Properties Bar Component

**Goal**: Separate property rendering from main widget

**File**: `lib/widgets/documents/task_list_item/components/task_properties_bar.dart`

```dart
class TaskPropertiesBar extends StatelessWidget {
  final Task task;
  final Recurrence? recurrence;
  final VoidCallback onPriorityTap;
  final VoidCallback onDueDateTap;
  final VoidCallback onSizeTap;
  final VoidCallback onRecurrenceTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (task.priority != null) _PriorityChip(priority: task.priority!),
        if (task.dueDate != null) _DueDateChip(dueDate: task.dueDate!),
        if (task.tShirtSize != null) _SizeChip(size: task.tShirtSize!),
        if (recurrence != null) _RecurrenceChip(recurrence: recurrence!),
      ],
    );
  }
}

// Internal chips
class _PriorityChip extends StatelessWidget { /* ... */ }
class _DueDateChip extends StatelessWidget { /* ... */ }
class _SizeChip extends StatelessWidget { /* ... */ }
class _RecurrenceChip extends StatelessWidget { /* ... */ }
```

**Lines Extracted**: ~300 lines

**Time**: 2 hours

---

### Phase 4: Extract Swipe Actions Handler

**Goal**: Isolate delete/duplicate logic

**File**: `lib/widgets/documents/task_list_item/actions/task_swipe_actions.dart`

```dart
class TaskSwipeActions extends StatelessWidget {
  final Widget child;
  final Task task;
  final bool enabled;
  final Future<void> Function() onDelete;
  final Future<void> Function() onDuplicate;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Dismissible(
      key: ValueKey('dismissible_${task.id}'),
      background: _buildSwipeBackground(isDelete: true),
      secondaryBackground: _buildSwipeBackground(isDelete: false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await _confirmDelete(context);
        } else {
          await onDuplicate();
          return false;
        }
      },
      onDismissed: (_) => onDelete(),
      child: child,
    );
  }
}
```

**Lines Extracted**: ~150 lines

**Time**: 1.5 hours

---

### Phase 5: Extract Subtasks Section

**Goal**: Separate expansion/collapse logic

**File**: `lib/widgets/documents/task_list_item/components/task_subtasks_section.dart`

```dart
class TaskSubtasksSection extends StatefulWidget {
  final Task task;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final TaskItemConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SubtaskToggleButton(
          subtaskCount: task.subtasks.length,
          isExpanded: isExpanded,
          onTap: onToggleExpand,
        ),
        if (isExpanded)
          SubtaskAnimatedList(
            subtasks: task.subtasks,
            // ...
          ),
      ],
    );
  }
}
```

**Lines Extracted**: ~100 lines

**Time**: 1 hour

---

### Phase 6: Extract Completion Handler (Business Logic)

**Goal**: Separate completion logic from UI

**File**: `lib/widgets/documents/task_list_item/actions/task_completion_handler.dart`

```dart
class TaskCompletionHandler {
  final TaskService taskService;

  TaskCompletionHandler(this.taskService);

  Future<void> toggleComplete(Task task) async {
    // Validation
    if (task.status == TaskStatus.completed) {
      return await _uncomplete(task);
    } else {
      return await _complete(task);
    }
  }

  Future<void> _complete(Task task) async {
    // Check subtasks
    if (task.subtasks.isNotEmpty) {
      final incompleteCount = task.subtasks
          .where((st) => st.status != TaskStatus.completed)
          .length;

      if (incompleteCount > 0) {
        throw ValidationException(
          'Cannot complete task with $incompleteCount incomplete subtasks'
        );
      }
    }

    // Update status
    await taskService.updateTask(
      task.copyWith(status: TaskStatus.completed),
    );
  }

  Future<void> _uncomplete(Task task) async {
    await taskService.updateTask(
      task.copyWith(status: TaskStatus.pending),
    );
  }
}
```

**Lines Extracted**: ~100 lines

**Time**: 1.5 hours

---

### Phase 7: Refactor Main Widget (Coordinator)

**Goal**: Reduce main widget to coordination only

**File**: `lib/widgets/documents/task_list_item/task_list_item.dart`

```dart
class TaskListItem extends StatefulWidget {
  final Task task;
  final TaskItemConfig config;
  final TaskItemCallbacks? callbacks;

  @override
  _TaskListItemState createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  late TaskCompletionHandler _completionHandler;
  AlwaysNotifyValueNotifier<Task>? _taskNotifier;
  bool _isExpanded = false;
  Recurrence? _recurrence;

  @override
  void initState() {
    super.initState();
    _completionHandler = TaskCompletionHandler(getIt<TaskService>());
    _setupTaskNotifier();
    _loadRecurrence();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Task>(
      valueListenable: _taskNotifier!,
      builder: (context, task, _) {
        return TaskSwipeActions(
          task: task,
          enabled: widget.config.dismissibleEnabled,
          onDelete: () => _deleteTask(task),
          onDuplicate: () => _duplicateTask(task),
          child: _buildTaskCard(task),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      // Glass morphism styling
      child: Row(
        children: [
          TaskCheckbox(
            task: task,
            onToggle: _handleToggleComplete,
          ),
          Expanded(
            child: Column(
              children: [
                TaskTitle(task: task, onEdit: _handleTitleEdit),
                if (widget.config.showProperties)
                  TaskPropertiesBar(
                    task: task,
                    recurrence: _recurrence,
                    onPriorityTap: () => _showPriorityPicker(task),
                    // ...
                  ),
                if (task.tags.isNotEmpty)
                  TaskTagsRow(task: task, tags: _getTaskTags(task)),
                if (widget.config.allowSubtasks && task.subtasks.isNotEmpty)
                  TaskSubtasksSection(
                    task: task,
                    isExpanded: _isExpanded,
                    onToggleExpand: () => setState(() => _isExpanded = !_isExpanded),
                    config: widget.config,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleComplete(bool value) async {
    try {
      await _completionHandler.toggleComplete(widget.task);
    } catch (e) {
      // Show error snackbar
    }
  }
}
```

**Result**: ~250 lines (coordinator logic only)

**Time**: 2 hours

---

## Final Structure

```
lib/widgets/documents/task_list_item/
├── task_list_item.dart (250 lines - coordinator)
├── task_item_config.dart (80 lines)
├── task_item_callbacks.dart (30 lines)
├── components/
│   ├── task_checkbox.dart (50 lines)
│   ├── task_content.dart (100 lines)
│   ├── task_properties_bar.dart (300 lines)
│   │   ├── priority_chip.dart
│   │   ├── due_date_chip.dart
│   │   ├── size_chip.dart
│   │   └── recurrence_chip.dart
│   ├── task_tags_row.dart (230 lines - already exists)
│   └── task_subtasks_section.dart (100 lines)
├── editors/
│   ├── task_title_editor.dart (116 lines - already exists)
│   └── task_description_editor.dart (108 lines - already exists)
└── actions/
    ├── task_completion_handler.dart (100 lines)
    └── task_swipe_actions.dart (150 lines)
```

**Total**: ~1614 lines (distributed across 15 files)
**Average per file**: ~107 lines
**Main file**: 250 lines (✅ Target achieved!)

---

## Migration Strategy

### Option A: Big Bang (NOT Recommended)
- Refactor everything at once
- High risk of breaking changes
- ❌ 2-3 days without working code

### Option B: Incremental (Recommended) ✅
1. Create new structure alongside old code
2. Migrate one component at a time
3. Test after each component
4. Remove old code when complete
5. ✅ Always working code

### Implementation Order
1. ✅ Phase 1: Config objects (no breaking changes)
2. ✅ Phase 2: TaskCheckbox (small, isolated)
3. ✅ Phase 3: PropertiesBar (large impact)
4. ✅ Phase 4: SwipeActions (medium complexity)
5. ✅ Phase 5: SubtasksSection (depends on 3)
6. ✅ Phase 6: CompletionHandler (business logic)
7. ✅ Phase 7: Main widget refactor (final integration)

---

## Testing Strategy

### Unit Tests (Per Component)
- [ ] TaskCheckbox: toggle states
- [ ] PropertiesBar: chip rendering
- [ ] SwipeActions: confirm dialogs
- [ ] CompletionHandler: business logic
- [ ] TaskItemConfig: presets

### Integration Tests
- [ ] Full TaskListItem rendering
- [ ] Complete → uncomplete flow
- [ ] Delete flow with confirmation
- [ ] Subtask expansion
- [ ] Tag filtering

### Golden Tests
- [ ] TaskListItem various states (pending, completed, with subtasks)
- [ ] Different depths (depth 0, 1, 2)
- [ ] Different configs (readOnly, compact, full)

---

## Timeline

| Phase | Time | Dependencies |
|-------|------|--------------|
| Phase 1 | 1h | None |
| Phase 2 | 0.5h | Phase 1 |
| Phase 3 | 2h | Phase 1 |
| Phase 4 | 1.5h | Phase 1 |
| Phase 5 | 1h | Phase 3 |
| Phase 6 | 1.5h | None |
| Phase 7 | 2h | All above |
| Testing | 3h | Phase 7 |
| **Total** | **12.5 hours** | (~2 days) |

---

## Benefits

### Before
- ❌ 1558 lines in one file
- ❌ 9 constructor parameters
- ❌ 6 responsibilities mixed
- ❌ Hard to test
- ❌ Hard to maintain
- ❌ Hard to reuse components

### After
- ✅ ~250 lines main file
- ✅ 3 constructor parameters
- ✅ Single responsibility per file
- ✅ Easy to unit test
- ✅ Easy to maintain
- ✅ Reusable components

---

## Next Steps

1. Get approval for decomposition plan
2. Start with Phase 1 (Config objects)
3. Incremental implementation with testing
4. Code review after each phase
5. Update all usages when complete

---

**Created**: 2024-12-24
**Status**: 📋 Plan Ready - Awaiting Approval
