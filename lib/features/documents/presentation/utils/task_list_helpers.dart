import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/core/components/lists/utils/list_helpers.dart';

/// Task-specific UI helpers that compose generic list helpers
///
/// These functions work with ANY state management pattern
/// They simply provide consistent UI components for task lists

/// Build task-specific empty state
///
/// Usage with BLoC:
/// ```dart
/// if (state.tasks.isEmpty) {
///   return buildTaskEmptyState(
///     context: context,
///     filterConfig: state.filterConfig,
///     showCompletedTasks: false,
///     onClearFilters: () => bloc.add(ClearFiltersEvent()),
///   );
/// }
/// ```
///
/// Usage with setState:
/// ```dart
/// if (_tasks.isEmpty) {
///   return buildTaskEmptyState(
///     context: context,
///     filterConfig: _filterConfig,
///     showCompletedTasks: _showCompleted,
///     onClearFilters: () => setState(() => _filterConfig = FilterSortConfig()),
///   );
/// }
/// ```
Widget buildTaskEmptyState({
  required BuildContext context,
  required FilterSortConfig filterConfig,
  required bool showCompletedTasks,
  VoidCallback? onClearFilters,
}) {
  final hasFilters = filterConfig.hasFilters;

  return buildEmptyState(
    context: context,
    icon: getEmptyStateIcon(
      hasFilters: hasFilters,
      showCompleted: showCompletedTasks,
    ),
    title: hasFilters
        ? 'Nessuna task trovata'
        : showCompletedTasks
            ? 'Nessuna task'
            : 'Nessuna task in sospeso',
    subtitle: hasFilters
        ? 'Prova a modificare i filtri di ricerca'
        : showCompletedTasks
            ? 'Aggiungi la tua prima task!'
            : 'Tutte le task sono state completate!',
    action: hasFilters && onClearFilters != null
        ? FilledButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Rimuovi tutti i filtri'),
          )
        : null,
  );
}

/// Build task loading state
Widget buildTaskLoadingState({
  required BuildContext context,
}) {
  return buildLoadingState(
    context: context,
    message: 'Caricamento task...',
  );
}

/// Build task error state
Widget buildTaskErrorState({
  required BuildContext context,
  required String message,
  VoidCallback? onRetry,
}) {
  return buildErrorState(
    context: context,
    message: message,
    onRetry: onRetry,
  );
}

/// Filter tasks by completion status
///
/// This is a pure function that works with any state pattern
List<Task> filterTasksByCompletion(
  List<Task> tasks, {
  required bool showCompleted,
}) {
  if (showCompleted) return tasks;

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
