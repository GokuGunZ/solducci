import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// Extension methods for filtering and sorting tasks
extension TaskFilterSort on List<Task> {
  /// Apply filters to the task list
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

    return filtered;
  }

  /// Sort the task list
  List<Task> applySorting(FilterSortConfig config) {
    final sorted = List<Task>.from(this);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (config.sortBy) {
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

  /// Apply both filters and sorting
  List<Task> applyFilterSort(FilterSortConfig config) {
    return applyFilters(config).applySorting(config);
  }
}
