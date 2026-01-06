# Component Library Usage Examples

This document provides practical examples of using the new component library components.

## Table of Contents
1. [TaskFilterableListView Examples](#taskfilterablelistview-examples)
2. [TaskReorderableListView Examples](#taskreorderablelistview-examples)
3. [CategoryScrollBar Examples](#categoryscrollbar-examples)
4. [HighlightAnimationMixin Examples](#highlightanimationmixin-examples)
5. [Combining Components](#combining-components)

---

## TaskFilterableListView Examples

### Basic Usage (No Filtering)

```dart
import 'package:solducci/features/documents/presentation/components/task_filterable_list_view.dart';

TaskFilterableListView(
  items: allTasks,
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

### With Filtering and Sorting

```dart
class MyTaskView extends StatefulWidget {
  @override
  State<MyTaskView> createState() => _MyTaskViewState();
}

class _MyTaskViewState extends State<MyTaskView> {
  FilterSortConfig _filterConfig = const FilterSortConfig();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter controls
        CompactFilterSortBar(
          config: _filterConfig,
          onConfigChanged: (newConfig) {
            setState(() => _filterConfig = newConfig);
          },
        ),

        // Filtered task list
        Expanded(
          child: TaskFilterableListView(
            items: allTasks,
            filterConfig: _filterConfig,
            onFilterChanged: (config) {
              setState(() => _filterConfig = config);
            },
            itemBuilder: (context, task, index) {
              return TaskListItem(task: task);
            },
          ),
        ),
      ],
    );
  }
}
```

### With Custom Order

```dart
TaskFilterableListView(
  items: allTasks,
  filterConfig: FilterSortConfig(
    sortBy: TaskSortOption.custom, // Enable custom sorting
  ),
  customOrder: savedTaskOrder, // List<String> of task IDs
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

### Hide Completed Tasks

```dart
TaskFilterableListView(
  items: allTasks,
  showCompletedTasks: false, // Hide completed tasks
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

### With Loading/Error States

```dart
class _MyTaskViewState extends State<MyTaskView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Task> _tasks = [];

  @override
  Widget build(BuildContext context) {
    return TaskFilterableListView(
      items: _tasks,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: () {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        _loadTasks();
      },
      itemBuilder: (context, task, index) {
        return TaskListItem(task: task);
      },
    );
  }
}
```

---

## TaskReorderableListView Examples

### Basic Drag-and-Drop

```dart
import 'package:solducci/features/documents/presentation/components/task_reorderable_list_view.dart';

TaskReorderableListView(
  documentId: document.id,
  items: allTasks,
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

### With Smooth Immediate Drag (No Animation)

```dart
TaskReorderableListView(
  documentId: document.id,
  items: allTasks,
  config: ReorderableListConfig.smoothImmediate, // No insert/remove animations
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

### With Custom Reorder Callback

```dart
TaskReorderableListView(
  documentId: document.id,
  items: allTasks,
  config: ReorderableListConfig.smoothImmediate,
  onReorderComplete: (reorderedTasks) {
    // Optional: additional handling after reorder
    print('Tasks reordered: ${reorderedTasks.length}');

    // Update parent state if needed
    setState(() {
      _displayedTasks = reorderedTasks;
    });
  },
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

### Disable Reordering

```dart
TaskReorderableListView(
  documentId: document.id,
  items: allTasks,
  config: ReorderableListConfig.disabled, // Static list, no dragging
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

### Without Highlight Animation

```dart
TaskReorderableListView(
  documentId: document.id,
  items: allTasks,
  enableHighlightAnimation: false, // Disable highlight on reorder
  itemBuilder: (context, task, index) {
    return TaskListItem(task: task);
  },
)
```

---

## CategoryScrollBar Examples

### Filter Tasks by Priority

```dart
import 'package:solducci/core/components/filters/bars/category_scroll_bar.dart';

class _MyViewState extends State<MyView> {
  TaskPriority? _selectedPriority;
  List<Task> _filteredTasks = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategoryScrollBar<Task, TaskPriority>(
          items: allTasks,
          getCategoryValue: (task) => task.priority,
          categoryValues: TaskPriority.values,
          categoryLabel: (priority) => priority.label,
          categoryColor: (priority) => priority.color,
          categoryIcon: (priority) => priority.icon,
          selectedCategory: _selectedPriority,
          onCategorySelected: (priority, filteredTasks) {
            setState(() {
              _selectedPriority = priority;
              _filteredTasks = filteredTasks;
            });
          },
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _filteredTasks.length,
            itemBuilder: (context, index) {
              return TaskListItem(task: _filteredTasks[index]);
            },
          ),
        ),
      ],
    );
  }
}
```

### Filter Tasks by Status

```dart
CategoryScrollBar<Task, TaskStatus>(
  items: allTasks,
  getCategoryValue: (task) => task.status,
  categoryValues: TaskStatus.values,
  categoryLabel: (status) => status.label,
  categoryColor: (status) => status.color,
  categoryIcon: (status) => status.icon,
  onCategorySelected: (status, filteredTasks) {
    setState(() => _filteredTasks = filteredTasks);
  },
)
```

### Custom Styling

```dart
CategoryScrollBar<Task, TaskPriority>(
  items: allTasks,
  getCategoryValue: (task) => task.priority,
  categoryValues: TaskPriority.values,
  categoryLabel: (priority) => priority.label,
  allLabel: 'Tutte le priorità', // Custom "All" label
  allIcon: Icons.list, // Custom "All" icon
  showCount: false, // Hide count badges
  height: 56, // Custom height
  padding: EdgeInsets.symmetric(vertical: 8),
  onCategorySelected: (priority, filteredTasks) {
    setState(() => _filteredTasks = filteredTasks);
  },
)
```

---

## HighlightAnimationMixin Examples

### Using the Mixin

```dart
import 'package:solducci/core/components/animations/highlight_animation_mixin.dart';

class MyAnimatedWidget extends StatefulWidget {
  @override
  State<MyAnimatedWidget> createState() => _MyAnimatedWidgetState();
}

class _MyAnimatedWidgetState extends State<MyAnimatedWidget>
    with SingleTickerProviderStateMixin, HighlightAnimationMixin {

  @override
  void initState() {
    super.initState();
    initHighlightAnimation(); // Initialize the animation

    // Trigger highlight on mount
    startHighlightAnimation();
  }

  @override
  void dispose() {
    disposeHighlightAnimation(); // Clean up
    super.dispose();
  }

  void _onTaskUpdated() {
    // Trigger highlight when task changes
    startHighlightAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return buildWithHighlight(
      context,
      child: TaskListItem(task: widget.task),
      maxOpacity: 0.4, // Custom opacity
      maxBlur: 16.0, // Custom blur
      maxSpread: 3.0, // Custom spread
      borderRadius: BorderRadius.circular(12), // Custom border
    );
  }
}
```

### Using HighlightContainer (Stateless)

```dart
import 'package:solducci/core/components/animations/highlight_animation_mixin.dart';

// Auto-start on mount
HighlightContainer(
  autoStart: true,
  child: TaskListItem(task: task),
)

// Manual trigger (for reorderable lists)
HighlightContainer(
  key: ValueKey('highlight_${task.id}'),
  autoStart: false, // Don't auto-start
  child: TaskListItem(task: task),
)
```

---

## Combining Components

### Complete Example: Filterable + Reorderable + Category Filter

```dart
class AllTasksView extends StatefulWidget {
  final TodoDocument document;

  const AllTasksView({required this.document});

  @override
  State<AllTasksView> createState() => _AllTasksViewState();
}

class _AllTasksViewState extends State<AllTasksView> {
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  FilterSortConfig _filterConfig = const FilterSortConfig();
  TaskPriority? _selectedPriority;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    // Load tasks from BLoC or repository
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Priority quick filter
        CategoryScrollBar<Task, TaskPriority>(
          items: _allTasks,
          getCategoryValue: (task) => task.priority,
          categoryValues: TaskPriority.values,
          categoryLabel: (priority) => priority.label,
          categoryColor: (priority) => priority.color,
          categoryIcon: (priority) => priority.icon,
          selectedCategory: _selectedPriority,
          onCategorySelected: (priority, filteredTasks) {
            setState(() {
              _selectedPriority = priority;
              _filteredTasks = filteredTasks;
            });
          },
        ),

        // Filter/Sort bar
        CompactFilterSortBar(
          config: _filterConfig,
          onConfigChanged: (newConfig) {
            setState(() => _filterConfig = newConfig);
          },
        ),

        // Task list with filtering, sorting, and reordering
        Expanded(
          child: TaskFilterableListView(
            items: _selectedPriority != null ? _filteredTasks : _allTasks,
            filterConfig: _filterConfig,
            isLoading: _isLoading,
            customOrder: savedTaskOrder, // From persistence
            itemBuilder: (context, task, index) {
              // Wrap with reorderable if custom sort enabled
              if (_filterConfig.sortBy == TaskSortOption.custom) {
                return _buildReorderableItem(task, index);
              }
              return TaskListItem(task: task);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableItem(Task task, int index) {
    return TaskReorderableListView(
      documentId: widget.document.id,
      items: [task], // Single item for this builder
      config: ReorderableListConfig.smoothImmediate,
      onReorderComplete: (reorderedTasks) {
        setState(() {
          _allTasks = reorderedTasks;
        });
      },
      itemBuilder: (context, task, _) {
        return TaskListItem(task: task);
      },
    );
  }
}
```

### Simplified Example: Most Common Use Case

```dart
class SimpleTaskList extends StatefulWidget {
  final String documentId;
  final List<Task> tasks;

  const SimpleTaskList({
    required this.documentId,
    required this.tasks,
  });

  @override
  State<SimpleTaskList> createState() => _SimpleTaskListState();
}

class _SimpleTaskListState extends State<SimpleTaskList> {
  FilterSortConfig _config = const FilterSortConfig(
    sortBy: TaskSortOption.custom,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple filter bar
        CompactFilterSortBar(
          config: _config,
          onConfigChanged: (config) => setState(() => _config = config),
        ),

        // Combined filterable + reorderable list
        Expanded(
          child: TaskFilterableListView(
            items: widget.tasks,
            filterConfig: _config,
            itemBuilder: (context, task, index) {
              return TaskListItem(task: task);
            },
          ),
        ),
      ],
    );
  }
}
```

---

## Migration Checklist

When migrating existing views to use these components:

- [ ] Replace manual filtering logic with `TaskFilterableListView`
- [ ] Replace manual sorting logic with `TaskFilterableListView`
- [ ] Replace `AnimatedReorderableListView` with `TaskReorderableListView`
- [ ] Extract highlight animation code to `HighlightAnimationMixin`
- [ ] Replace custom category filters with `CategoryScrollBar`
- [ ] Remove duplicate empty state rendering
- [ ] Remove duplicate loading/error state handling
- [ ] Update item builders to work with new component APIs
- [ ] Test filtering, sorting, and reordering behavior
- [ ] Verify persistence of custom order still works

---

## Performance Notes

### TaskFilterableListView
- Filtering is performed synchronously (use `applyFilters`)
- For tag filtering with preloading, use `applyFiltersAsync` in the future
- Sorting handles hierarchical tasks (subtasks maintain structure)

### TaskReorderableListView
- Automatically persists order to `TaskOrderPersistenceService`
- Uses `ReorderableListConfig.smoothImmediate` for best UX
- Highlight animation is optional and can be disabled

### CategoryScrollBar
- Automatically calculates counts for each category
- Updates counts when items change
- Optimized for enum-based categories

---

## Common Patterns

### Pattern 1: Read-Only List (No Reordering)
```dart
TaskFilterableListView(
  items: tasks,
  filterConfig: config,
  itemBuilder: (context, task, index) => TaskListItem(task: task),
)
```

### Pattern 2: Reorderable Only (No Filtering)
```dart
TaskReorderableListView(
  documentId: docId,
  items: tasks,
  config: ReorderableListConfig.smoothImmediate,
  itemBuilder: (context, task, index) => TaskListItem(task: task),
)
```

### Pattern 3: Both Filtering and Reordering
Use `TaskFilterableListView` with `customOrder` parameter when `sortBy == TaskSortOption.custom`.

### Pattern 4: Category Quick Filter + Full Filtering
Combine `CategoryScrollBar` with `TaskFilterableListView` for layered filtering.
