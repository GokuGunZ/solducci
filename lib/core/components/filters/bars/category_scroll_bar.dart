import 'package:flutter/material.dart';

/// Generic horizontal scrolling category filter bar
///
/// Takes any enum type and creates a horizontally scrollable list of chips
/// that filter items by that category.
///
/// Type Parameters:
/// - [T]: The item type being filtered
/// - [C]: The category enum type
///
/// Usage:
/// ```dart
/// CategoryScrollBar<Task, TaskPriority>(
///   items: allTasks,
///   getCategoryValue: (task) => task.priority,
///   categoryValues: TaskPriority.values,
///   categoryLabel: (priority) => priority.label,
///   categoryColor: (priority) => priority.color,
///   categoryIcon: (priority) => priority.icon,
///   onCategorySelected: (priority, filteredTasks) {
///     setState(() => _filteredTasks = filteredTasks);
///   },
/// )
/// ```
class CategoryScrollBar<T, C extends Enum> extends StatefulWidget {
  /// All items to be filtered
  final List<T> items;

  /// Function to extract category value from item
  final C? Function(T item) getCategoryValue;

  /// All possible category values
  final List<C> categoryValues;

  /// Function to get display label for category
  final String Function(C category) categoryLabel;

  /// Optional: Function to get color for category
  final Color? Function(C category)? categoryColor;

  /// Optional: Function to get icon for category
  final IconData? Function(C category)? categoryIcon;

  /// Callback when category is selected
  final void Function(C? category, List<T> filteredItems) onCategorySelected;

  /// Currently selected category (null = show all)
  final C? selectedCategory;

  /// Label for "All" option
  final String allLabel;

  /// Icon for "All" option
  final IconData allIcon;

  /// Whether to show count badges on chips
  final bool showCount;

  /// Padding around the bar
  final EdgeInsetsGeometry? padding;

  /// Height of the bar
  final double height;

  const CategoryScrollBar({
    super.key,
    required this.items,
    required this.getCategoryValue,
    required this.categoryValues,
    required this.categoryLabel,
    required this.onCategorySelected,
    this.categoryColor,
    this.categoryIcon,
    this.selectedCategory,
    this.allLabel = 'Tutti',
    this.allIcon = Icons.grid_view,
    this.showCount = true,
    this.padding,
    this.height = 48,
  });

  @override
  State<CategoryScrollBar<T, C>> createState() =>
      _CategoryScrollBarState<T, C>();
}

class _CategoryScrollBarState<T, C extends Enum>
    extends State<CategoryScrollBar<T, C>> {
  late C? _selectedCategory;
  late Map<C?, int> _counts;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _calculateCounts();
  }

  @override
  void didUpdateWidget(CategoryScrollBar<T, C> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _calculateCounts();
    }
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _selectedCategory = widget.selectedCategory;
    }
  }

  void _calculateCounts() {
    _counts = {null: widget.items.length}; // "All" count

    for (final category in widget.categoryValues) {
      _counts[category] = widget.items
          .where((item) => widget.getCategoryValue(item) == category)
          .length;
    }
  }

  List<T> _getFilteredItems(C? category) {
    if (category == null) {
      return widget.items; // All items
    }
    return widget.items
        .where((item) => widget.getCategoryValue(item) == category)
        .toList();
  }

  void _onCategoryTap(C? category) {
    if (_selectedCategory == category) {
      return; // Already selected
    }

    setState(() {
      _selectedCategory = category;
    });

    final filteredItems = _getFilteredItems(category);
    widget.onCategorySelected(category, filteredItems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          // "All" chip
          _buildCategoryChip(
            context: context,
            category: null,
            label: widget.allLabel,
            icon: widget.allIcon,
            color: null,
            count: _counts[null] ?? 0,
            isSelected: _selectedCategory == null,
          ),
          const SizedBox(width: 8),

          // Category chips
          ...widget.categoryValues.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                context: context,
                category: category,
                label: widget.categoryLabel(category),
                icon: widget.categoryIcon?.call(category),
                color: widget.categoryColor?.call(category),
                count: _counts[category] ?? 0,
                isSelected: _selectedCategory == category,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required C? category,
    required String label,
    required IconData? icon,
    required Color? color,
    required int count,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return InkWell(
      onTap: () => _onCategoryTap(category),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? chipColor : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? chipColor : Colors.grey[700],
              ),
            ),
            if (widget.showCount && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
