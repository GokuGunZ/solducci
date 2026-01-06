import 'package:flutter/material.dart';
import 'package:solducci/core/components/lists/base/filterable_list_view.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/utils/task_filter_sort.dart';

/// Task-specific implementation of FilterableListView
///
/// Provides Task domain logic on top of the generic FilterableListView:
/// - Filtering by priority, status, size, date, tags
/// - Sorting by dueDate, priority, size, title, createdAt, custom order
/// - Task-specific empty states with Italian localization
/// - Integration with FilterSortConfig
/// - Optional completed task filtering
///
/// Usage:
/// ```dart
/// TaskFilterableListView(
///   items: allTasks,
///   filterConfig: FilterSortConfig(
///     priorities: {TaskPriority.urgent},
///     sortBy: TaskSortOption.dueDate,
///   ),
///   onFilterChanged: (config) => setState(() => _config = config),
///   itemBuilder: (context, task, index) {
///     return TaskListItem(task: task);
///   },
/// )
/// ```
class TaskFilterableListView extends StatelessWidget {
  final List<Task> items;
  final FilterSortConfig? filterConfig;
  final ValueChanged<FilterSortConfig>? onFilterChanged;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showEmptyState;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  /// Custom order for tasks (when sortBy == TaskSortOption.custom)
  final List<String>? customOrder;

  /// Whether to show completed tasks
  final bool showCompletedTasks;

  /// Builder for individual task items
  final Widget Function(BuildContext context, Task task, int index) itemBuilder;

  const TaskFilterableListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.filterConfig,
    this.onFilterChanged,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.showEmptyState = true,
    this.padding,
    this.physics,
    this.customOrder,
    this.showCompletedTasks = true,
  });

  @override
  Widget build(BuildContext context) {
    return _TaskFilterableListViewImpl(
      items: items,
      filterConfig: filterConfig,
      onFilterChanged: onFilterChanged,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRetry: onRetry,
      showEmptyState: showEmptyState,
      padding: padding,
      physics: physics,
      customOrder: customOrder,
      showCompletedTasks: showCompletedTasks,
      itemBuilder: itemBuilder,
    );
  }
}

/// Private implementation that extends FilterableListView
class _TaskFilterableListViewImpl
    extends FilterableListView<Task, FilterSortConfig> {
  final List<String>? customOrder;
  final bool showCompletedTasks;
  final Widget Function(BuildContext context, Task task, int index) itemBuilder;

  const _TaskFilterableListViewImpl({
    required super.items,
    required this.itemBuilder,
    super.filterConfig,
    super.onFilterChanged,
    super.isLoading,
    super.errorMessage,
    super.onRetry,
    super.showEmptyState,
    super.padding,
    super.physics,
    this.customOrder,
    required this.showCompletedTasks,
  });

  @override
  Widget buildItem(BuildContext context, Task item, int index) {
    return itemBuilder(context, item, index);
  }

  @override
  List<Task> filterItems(List<Task> items, FilterSortConfig? config) {
    if (config == null) {
      return _filterCompletedTasks(items);
    }

    // Use the existing TaskFilterSort extension
    final filtered = items.applyFilters(config);
    return _filterCompletedTasks(filtered);
  }

  /// Filter out completed tasks if showCompletedTasks is false
  List<Task> _filterCompletedTasks(List<Task> tasks) {
    if (showCompletedTasks) {
      return tasks;
    }

    // Recursively filter completed tasks
    Task filterCompleted(Task task) {
      if (task.subtasks == null || task.subtasks!.isEmpty) {
        return task;
      }

      final filteredSubtasks = task.subtasks!
          .where((subtask) => subtask.status != TaskStatus.completed)
          .map((subtask) => filterCompleted(subtask))
          .toList();

      return task.copyWith(subtasks: filteredSubtasks);
    }

    return tasks
        .where((task) => task.status != TaskStatus.completed)
        .map((task) => filterCompleted(task))
        .toList();
  }

  @override
  List<Task> sortItems(List<Task> items, FilterSortConfig? config) {
    if (config == null || config.sortBy == null) {
      return items;
    }

    // Handle custom order sorting
    if (config.sortBy == TaskSortOption.custom && customOrder != null) {
      return items.applyCustomOrder(customOrder!);
    }

    // Use the existing TaskFilterSort extension
    return items.applySorting(config);
  }

  @override
  bool hasActiveFilters() {
    return filterConfig?.hasFilters ?? false;
  }

  @override
  FilterSortConfig getDefaultFilter() {
    return const FilterSortConfig();
  }

  @override
  IconData getEmptyStateIcon() {
    if (hasActiveFilters()) {
      return Icons.filter_alt_off;
    }
    if (!showCompletedTasks) {
      return Icons.check_circle_outline;
    }
    return Icons.task_outlined;
  }

  @override
  String getEmptyStateTitle() {
    if (hasActiveFilters()) {
      return 'Nessuna task trovata';
    }
    if (!showCompletedTasks) {
      return 'Nessuna task in sospeso';
    }
    return 'Nessuna task';
  }

  @override
  String? getEmptyStateSubtitle() {
    if (hasActiveFilters()) {
      return 'Prova a modificare i filtri di ricerca';
    }
    if (!showCompletedTasks) {
      return 'Tutte le task sono state completate!';
    }
    return 'Inizia aggiungendo la tua prima task';
  }

  @override
  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getEmptyStateIcon(),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              getEmptyStateTitle(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (getEmptyStateSubtitle() != null) ...[
              const SizedBox(height: 12),
              Text(
                getEmptyStateSubtitle()!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (hasActiveFilters() && onFilterChanged != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => onFilterChanged?.call(getDefaultFilter()),
                icon: const Icon(Icons.clear_all),
                label: const Text('Rimuovi tutti i filtri'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Caricamento task...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Errore nel caricamento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
