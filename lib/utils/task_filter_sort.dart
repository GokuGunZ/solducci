import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/service/task_service.dart';

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

      // Filter by overdue
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

      // Filter by overdue
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

  /// Sort the task list
  List<Task> applySorting(FilterSortConfig config) {
    // If no sorting option selected, return as-is
    if (config.sortBy == null) {
      return this;
    }

    final sorted = List<Task>.from(this);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (config.sortBy!) {
        case TaskSortOption.dueDate:
          // Tasks with no due date go to the end
          if (a.dueDate == null && b.dueDate == null) {
            comparison = 0;
          } else if (a.dueDate == null) {
            comparison = 1;
          } else if (b.dueDate == null) {
            comparison = -1;
          } else {
            comparison = a.dueDate!.compareTo(b.dueDate!);
          }
          break;

        case TaskSortOption.priority:
          // Tasks with no priority go to the end
          if (a.priority == null && b.priority == null) {
            comparison = 0;
          } else if (a.priority == null) {
            comparison = 1;
          } else if (b.priority == null) {
            comparison = -1;
          } else {
            // Higher priority (urgent=3) should come first
            comparison = b.priority!.index.compareTo(a.priority!.index);
          }
          break;

        case TaskSortOption.title:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;

        case TaskSortOption.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }

      return config.sortAscending ? comparison : -comparison;
    });

    return sorted;
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
