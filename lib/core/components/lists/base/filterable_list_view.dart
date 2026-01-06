import 'package:flutter/material.dart';

/// Abstract base class for filterable and sortable list views
///
/// This provides a generic foundation for any list that needs:
/// - Filtering by multiple criteria
/// - Sorting by multiple fields
/// - Empty state handling
/// - Loading state handling
/// - Error state handling
///
/// Type Parameters:
/// - [T]: The item type being displayed
/// - [F]: The filter configuration type
///
/// Usage:
/// ```dart
/// class TaskListView extends FilterableListView<Task, TaskFilterConfig> {
///   @override
///   Widget buildItem(BuildContext context, Task item, int index) {
///     return TaskListItem(task: item);
///   }
/// }
/// ```
abstract class FilterableListView<T, F> extends StatelessWidget {
  /// The complete list of items (unfiltered)
  final List<T> items;

  /// Current filter configuration
  final F? filterConfig;

  /// Callback when filter changes
  final ValueChanged<F>? onFilterChanged;

  /// Whether the list is currently loading
  final bool isLoading;

  /// Error message if load failed
  final String? errorMessage;

  /// Callback to retry after error
  final VoidCallback? onRetry;

  /// Whether to show empty state when filtered list is empty
  final bool showEmptyState;

  /// Padding around the list
  final EdgeInsetsGeometry? padding;

  /// Scroll physics
  final ScrollPhysics? physics;

  const FilterableListView({
    super.key,
    required this.items,
    this.filterConfig,
    this.onFilterChanged,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.showEmptyState = true,
    this.padding,
    this.physics,
  });

  /// Implement this to build individual items
  Widget buildItem(BuildContext context, T item, int index);

  /// Override to customize empty state
  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            getEmptyStateIcon(),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            getEmptyStateTitle(),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (getEmptyStateSubtitle() != null) ...[
            const SizedBox(height: 8),
            Text(
              getEmptyStateSubtitle()!,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
          if (hasActiveFilters() && onFilterChanged != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => onFilterChanged?.call(getDefaultFilter()),
              icon: const Icon(Icons.clear),
              label: const Text('Rimuovi filtri'),
            ),
          ],
        ],
      ),
    );
  }

  /// Override to customize loading state
  Widget buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Override to customize error state
  Widget buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Errore',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ],
      ),
    );
  }

  /// Filter the items based on current config
  /// Override to implement domain-specific filtering
  List<T> filterItems(List<T> items, F? config);

  /// Sort the items based on current config
  /// Override to implement domain-specific sorting
  List<T> sortItems(List<T> items, F? config);

  /// Check if there are active filters
  bool hasActiveFilters();

  /// Get default/empty filter config
  F getDefaultFilter();

  /// Get empty state icon
  IconData getEmptyStateIcon() {
    return hasActiveFilters() ? Icons.filter_alt_off : Icons.inbox_outlined;
  }

  /// Get empty state title
  String getEmptyStateTitle() {
    return hasActiveFilters() ? 'Nessun elemento trovato' : 'Nessun elemento';
  }

  /// Get empty state subtitle (optional)
  String? getEmptyStateSubtitle() {
    return hasActiveFilters()
        ? 'Prova a modificare i filtri'
        : 'Aggiungi il primo elemento';
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return buildLoadingState(context);
    }

    // Error state
    if (errorMessage != null) {
      return buildErrorState(context, errorMessage!);
    }

    // Apply filters and sorting
    List<T> processedItems = items;
    processedItems = filterItems(processedItems, filterConfig);
    processedItems = sortItems(processedItems, filterConfig);

    // Empty state
    if (processedItems.isEmpty && showEmptyState) {
      return buildEmptyState(context);
    }

    // Build list
    return ListView.builder(
      padding: padding,
      physics: physics,
      itemCount: processedItems.length,
      itemBuilder: (context, index) {
        return buildItem(context, processedItems[index], index);
      },
    );
  }
}

/// Protocol for items that can be filtered
abstract class Filterable<F> {
  bool matchesFilter(F filter);
}

/// Protocol for items that can be sorted
abstract class Sortable<S> implements Comparable<Sortable<S>> {
  int compareBy(S sortField, Sortable<S> other);
}
