import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/service/task_service.dart';

/// Helper function to check if a task matches a date filter
bool _matchesDateFilter(Task task, DateFilterOption filter) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (filter) {
    case DateFilterOption.today:
      if (task.dueDate == null) return false;
      final dueDay = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return dueDay.isAtSameMomentAs(today);

    case DateFilterOption.thisWeek:
      if (task.dueDate == null) return false;
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
      return task.dueDate!.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
             task.dueDate!.isBefore(weekEnd.add(const Duration(seconds: 1)));

    case DateFilterOption.thisMonth:
      if (task.dueDate == null) return false;
      return task.dueDate!.year == now.year && task.dueDate!.month == now.month;

    case DateFilterOption.overdue:
      return task.isOverdue;

    case DateFilterOption.noDueDate:
      return task.dueDate == null;
  }
}

/// Extension methods for filtering and sorting tasks
extension TaskFilterSort on List<Task> {
  /// Flatten task tree recursively into a single list
  List<Task> _flattenTaskTree() {
    final flatList = <Task>[];

    void addTaskAndChildren(Task task) {
      flatList.add(task);
      if (task.subtasks != null) {
        for (final subtask in task.subtasks!) {
          addTaskAndChildren(subtask);
        }
      }
    }

    for (final task in this) {
      addTaskAndChildren(task);
    }

    return flatList;
  }

  /// Apply filters to the task list (handles hierarchical tasks)
  Future<List<Task>> applyFiltersAsync(FilterSortConfig config) async {
    final taskService = TaskService();
    final matchingTasks = <String>{}; // Track matching task IDs
    final tasksToInclude = <String>{}; // Tasks to include in final result

    // Flatten the task tree to include all subtasks
    final allTasks = _flattenTaskTree();

    // Build a map of all tasks for quick lookup
    final taskMap = <String, Task>{};
    for (final task in allTasks) {
      taskMap[task.id] = task;
    }

    // First pass: Find all tasks that match the filters directly
    for (final task in allTasks) {
      bool matches = true;

      // Filter by priority
      if (config.priorities.isNotEmpty) {
        matches = matches &&
                  task.priority != null &&
                  config.priorities.contains(task.priority);
      }

      // Filter by status
      if (config.statuses.isNotEmpty) {
        matches = matches && config.statuses.contains(task.status);
      }

      // Filter by size (t-shirt size)
      if (config.sizes.isNotEmpty) {
        matches = matches &&
                  task.tShirtSize != null &&
                  config.sizes.contains(task.tShirtSize);
      }

      // Filter by date
      if (config.dateFilter != null) {
        matches = matches && _matchesDateFilter(task, config.dateFilter!);
      }

      // Filter by overdue (deprecated, use dateFilter instead)
      if (config.showOverdueOnly) {
        matches = matches && task.isOverdue;
      }

      // Filter by tags (requires async operation to load task tags)
      if (config.tagIds.isNotEmpty) {
        final taskTags = await taskService.getEffectiveTags(task.id);
        final taskTagIds = taskTags.map((t) => t.id).toSet();
        matches = matches &&
                  taskTagIds.any((tagId) => config.tagIds.contains(tagId));
      }

      if (matches) {
        matchingTasks.add(task.id);
      }
    }

    // Second pass: Include parent tasks of matching subtasks
    for (final taskId in matchingTasks) {
      tasksToInclude.add(taskId);

      // Walk up the parent chain and include all ancestors
      var currentTask = taskMap[taskId];
      while (currentTask != null && currentTask.parentTaskId != null) {
        tasksToInclude.add(currentTask.parentTaskId!);
        currentTask = taskMap[currentTask.parentTaskId];
      }
    }

    // Third pass: Rebuild tree with filtered subtasks
    Task filterSubtasks(Task task) {
      if (task.subtasks == null || task.subtasks!.isEmpty) {
        return task;
      }

      // Filter subtasks to only include those in tasksToInclude
      final filteredSubtasks = task.subtasks!
          .where((subtask) => tasksToInclude.contains(subtask.id))
          .map((subtask) => filterSubtasks(subtask)) // Recursively filter
          .toList();

      // Return task with filtered subtasks
      return task.copyWith(subtasks: filteredSubtasks);
    }

    // Apply filtering to root tasks
    return where((task) => tasksToInclude.contains(task.id))
        .map((task) => filterSubtasks(task))
        .toList();
  }

  /// Apply filters to the task list (synchronous version without tag filtering)
  List<Task> applyFilters(FilterSortConfig config) {
    final matchingTasks = <String>{}; // Track matching task IDs
    final tasksToInclude = <String>{}; // Tasks to include in final result

    // Flatten the task tree to include all subtasks
    final allTasks = _flattenTaskTree();

    // Build a map of all tasks for quick lookup
    final taskMap = <String, Task>{};
    for (final task in allTasks) {
      taskMap[task.id] = task;
    }

    // First pass: Find all tasks that match the filters directly
    for (final task in allTasks) {
      bool matches = true;

      // Filter by priority
      if (config.priorities.isNotEmpty) {
        matches = matches &&
                  task.priority != null &&
                  config.priorities.contains(task.priority);
      }

      // Filter by status
      if (config.statuses.isNotEmpty) {
        matches = matches && config.statuses.contains(task.status);
      }

      // Filter by size (t-shirt size)
      if (config.sizes.isNotEmpty) {
        matches = matches &&
                  task.tShirtSize != null &&
                  config.sizes.contains(task.tShirtSize);
      }

      // Filter by date
      if (config.dateFilter != null) {
        matches = matches && _matchesDateFilter(task, config.dateFilter!);
      }

      // Filter by overdue (deprecated, use dateFilter instead)
      if (config.showOverdueOnly) {
        matches = matches && task.isOverdue;
      }

      // Note: Tag filtering is not supported in synchronous mode
      // Use applyFiltersAsync for tag filtering

      if (matches) {
        matchingTasks.add(task.id);
      }
    }

    // Second pass: Include parent tasks of matching subtasks
    for (final taskId in matchingTasks) {
      tasksToInclude.add(taskId);

      // Walk up the parent chain and include all ancestors
      var currentTask = taskMap[taskId];
      while (currentTask != null && currentTask.parentTaskId != null) {
        tasksToInclude.add(currentTask.parentTaskId!);
        currentTask = taskMap[currentTask.parentTaskId];
      }
    }

    // Third pass: Rebuild tree with filtered subtasks
    Task filterSubtasks(Task task) {
      if (task.subtasks == null || task.subtasks!.isEmpty) {
        return task;
      }

      // Filter subtasks to only include those in tasksToInclude
      final filteredSubtasks = task.subtasks!
          .where((subtask) => tasksToInclude.contains(subtask.id))
          .map((subtask) => filterSubtasks(subtask)) // Recursively filter
          .toList();

      // Return task with filtered subtasks
      return task.copyWith(subtasks: filteredSubtasks);
    }

    // Apply filtering to root tasks
    return where((task) => tasksToInclude.contains(task.id))
        .map((task) => filterSubtasks(task))
        .toList();
  }

  /// Sort the task list recursively (includes subtasks)
  ///
  /// For custom sort, use [applyCustomOrder] instead with the saved order
  List<Task> applySorting(FilterSortConfig config) {
    // If no sorting option selected, return as-is
    if (config.sortBy == null) {
      return this;
    }

    // Custom sort is handled separately via applyCustomOrder
    if (config.sortBy == TaskSortOption.custom) {
      return this; // Return as-is, order should already be applied
    }

    // Helper function to recursively sort a task and its subtasks
    Task sortTaskAndSubtasks(Task task) {
      if (task.subtasks == null || task.subtasks!.isEmpty) {
        return task;
      }

      // Sort the subtasks recursively
      final sortedSubtasks = task.subtasks!
          .map((subtask) => sortTaskAndSubtasks(subtask))
          .toList()
        ..sort((a, b) => _compareTasksForSorting(a, b, config));

      return task.copyWith(subtasks: sortedSubtasks);
    }

    // Sort the top-level tasks
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) => _compareTasksForSorting(a, b, config));

    // Recursively sort subtasks for each task
    return sorted.map((task) => sortTaskAndSubtasks(task)).toList();
  }

  /// Apply custom order based on saved task IDs order
  ///
  /// Tasks not in the saved order will be appended at the end in their original order
  List<Task> applyCustomOrder(List<String> taskIdsOrder) {
    if (taskIdsOrder.isEmpty) {
      return this;
    }

    // Create a map for quick lookup by task ID
    final taskMap = <String, Task>{};
    for (final task in this) {
      taskMap[task.id] = task;
    }

    // Build ordered list based on saved order
    final ordered = <Task>[];
    final processedIds = <String>{};

    // First, add tasks in the saved order
    for (final taskId in taskIdsOrder) {
      final task = taskMap[taskId];
      if (task != null) {
        ordered.add(task);
        processedIds.add(taskId);
      }
    }

    // Then, add any tasks not in the saved order (new tasks)
    for (final task in this) {
      if (!processedIds.contains(task.id)) {
        ordered.add(task);
      }
    }

    return ordered;
  }

  /// Compare two tasks for sorting (null values always go to end)
  int _compareTasksForSorting(Task a, Task b, FilterSortConfig config) {
    int comparison = 0;

    switch (config.sortBy!) {
      case TaskSortOption.dueDate:
        // Tasks with no due date always go to the end
        if (a.dueDate == null && b.dueDate == null) {
          comparison = 0;
        } else if (a.dueDate == null) {
          return 1; // a goes to end
        } else if (b.dueDate == null) {
          return -1; // b goes to end
        } else {
          comparison = a.dueDate!.compareTo(b.dueDate!);
        }
        break;

      case TaskSortOption.priority:
        // Tasks with no priority always go to the end
        if (a.priority == null && b.priority == null) {
          comparison = 0;
        } else if (a.priority == null) {
          return 1; // a goes to end
        } else if (b.priority == null) {
          return -1; // b goes to end
        } else {
          // Higher priority (urgent=3) should come first
          comparison = b.priority!.index.compareTo(a.priority!.index);
        }
        break;

      case TaskSortOption.size:
        // Tasks with no size always go to the end
        if (a.tShirtSize == null && b.tShirtSize == null) {
          comparison = 0;
        } else if (a.tShirtSize == null) {
          return 1; // a goes to end
        } else if (b.tShirtSize == null) {
          return -1; // b goes to end
        } else {
          // Smaller sizes (xs=0) should come first by default
          comparison = a.tShirtSize!.index.compareTo(b.tShirtSize!.index);
        }
        break;

      case TaskSortOption.title:
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        break;

      case TaskSortOption.createdAt:
        comparison = a.createdAt.compareTo(b.createdAt);
        break;

      case TaskSortOption.custom:
        // Custom sort should not use this comparison method
        // Use applyCustomOrder instead
        comparison = 0;
        break;
    }

    // Apply sort direction only to non-null comparisons
    return config.sortAscending ? comparison : -comparison;
  }

  /// Apply both filters and sorting (async version with tag support)
  Future<List<Task>> applyFilterSortAsync(FilterSortConfig config) async {
    final filtered = await applyFiltersAsync(config);
    return filtered.applySorting(config);
  }

  /// Apply both filters and sorting (sync version without tag filtering)
  List<Task> applyFilterSort(FilterSortConfig config) {
    return applyFilters(config).applySorting(config);
  }
}
