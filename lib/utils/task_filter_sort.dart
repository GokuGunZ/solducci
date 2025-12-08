import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/service/task_service.dart';

/// Extension methods for filtering and sorting tasks
extension TaskFilterSort on List<Task> {
  /// Apply filters to the task list
  Future<List<Task>> applyFiltersAsync(FilterSortConfig config) async {
    var filtered = this;

    // Filter by priority
    if (config.priorities.isNotEmpty) {
      filtered = filtered
          .where((task) =>
              task.priority != null && config.priorities.contains(task.priority))
          .toList();
    }

    // Filter by status
    if (config.statuses.isNotEmpty) {
      filtered = filtered
          .where((task) => config.statuses.contains(task.status))
          .toList();
    }

    // Filter by overdue
    if (config.showOverdueOnly) {
      filtered = filtered.where((task) => task.isOverdue).toList();
    }

    // Filter by tags (requires async operation to load task tags)
    if (config.tagIds.isNotEmpty) {
      final taskService = TaskService();
      final tasksWithMatchingTags = <Task>[];

      for (final task in filtered) {
        final taskTags = await taskService.getEffectiveTags(task.id);
        final taskTagIds = taskTags.map((t) => t.id).toSet();

        // Task must have at least one of the selected tags
        if (taskTagIds.any((tagId) => config.tagIds.contains(tagId))) {
          tasksWithMatchingTags.add(task);
        }
      }

      filtered = tasksWithMatchingTags;
    }

    return filtered;
  }

  /// Apply filters to the task list (synchronous version without tag filtering)
  List<Task> applyFilters(FilterSortConfig config) {
    var filtered = this;

    // Filter by priority
    if (config.priorities.isNotEmpty) {
      filtered = filtered
          .where((task) =>
              task.priority != null && config.priorities.contains(task.priority))
          .toList();
    }

    // Filter by status
    if (config.statuses.isNotEmpty) {
      filtered = filtered
          .where((task) => config.statuses.contains(task.status))
          .toList();
    }

    // Filter by overdue
    if (config.showOverdueOnly) {
      filtered = filtered.where((task) => task.isOverdue).toList();
    }

    // Note: Tag filtering is not supported in synchronous mode
    // Use applyFiltersAsync for tag filtering

    return filtered;
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
