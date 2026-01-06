import 'package:flutter/material.dart';
import 'package:solducci/core/components/category_scroll_bar/controllers/category_scroll_bar_controller.dart';

/// CategoryScrollBar - Swipeable category-filtered lists
///
/// Architecture:
/// - CategoryFilterBar (chips) at top
/// - PageView (lists) below
/// - Bidirectional sync via controller
///
/// Features:
/// - Swipe list → update chip
/// - Tap chip → animate to list
/// - Create category → swipe to empty + modal
///
/// Usage:
/// ```dart
/// CategoryScrollBar<Task, Tag>(
///   controller: categoryController,
///   categories: tags,
///   buildListForCategory: (tag) => TaskListView(
///     tasks: tasks.where((t) => t.tags.contains(tag)),
///   ),
///   buildCategoryChip: (tag) => Chip(
///     label: Text(tag.name),
///     avatar: Icon(tag.icon),
///   ),
///   onCreateCategory: () async {
///     return await showDialog<Tag>(...);
///   },
/// )
/// ```
class CategoryScrollBar<T, C> extends StatefulWidget {
  /// Controller for coordination
  final CategoryScrollBarController<T, C> controller;

  /// List of categories
  final List<C> categories;

  /// Builder for list view for each category
  final Widget Function(C? category) buildListForCategory;

  /// Builder for category chip
  final Widget Function(C category) buildCategoryChip;

  /// Builder for "All" chip (optional)
  final Widget Function()? buildAllChip;

  /// Label for "All" category
  final String allLabel;

  /// Icon for "All" category
  final IconData? allIcon;

  /// Show "All" category
  final bool showAllCategory;

  /// Show create button
  final bool showCreateButton;

  /// Icon for create button
  final IconData createIcon;

  /// Tooltip for create button
  final String createTooltip;

  /// Callback when create button pressed
  final Future<C?> Function()? onCreateCategory;

  /// Padding for chip bar
  final EdgeInsetsGeometry? chipBarPadding;

  /// Height of chip bar
  final double chipBarHeight;

  /// Background decoration for chip bar
  final Decoration? chipBarDecoration;

  const CategoryScrollBar({
    super.key,
    required this.controller,
    required this.categories,
    required this.buildListForCategory,
    required this.buildCategoryChip,
    this.buildAllChip,
    this.allLabel = 'Tutte',
    this.allIcon = Icons.apps,
    this.showAllCategory = true,
    this.showCreateButton = true,
    this.createIcon = Icons.add,
    this.createTooltip = 'Aggiungi categoria',
    this.onCreateCategory,
    this.chipBarPadding,
    this.chipBarHeight = 60,
    this.chipBarDecoration,
  });

  @override
  State<CategoryScrollBar<T, C>> createState() =>
      _CategoryScrollBarState<T, C>();
}

class _CategoryScrollBarState<T, C> extends State<CategoryScrollBar<T, C>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category chips at top
        _buildCategoryFilterBar(),

        // Lists below
        Expanded(
          child: _buildPageView(),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterBar() {
    return Container(
      height: widget.chipBarHeight,
      decoration: widget.chipBarDecoration,
      padding: widget.chipBarPadding ?? const EdgeInsets.symmetric(vertical: 8),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // "All" chip
              if (widget.showAllCategory) _buildAllCategoryChip(),

              // Category chips
              ...widget.categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final pageIndex = widget.showAllCategory ? index + 1 : index;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildSelectableChip(
                    child: widget.buildCategoryChip(category),
                    isSelected: widget.controller.currentIndex == pageIndex,
                    onTap: () => widget.controller.selectCategoryByIndex(pageIndex),
                  ),
                );
              }),

              // Create button
              if (widget.showCreateButton && widget.onCreateCategory != null)
                _buildCreateButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAllCategoryChip() {
    Widget allChip;

    if (widget.buildAllChip != null) {
      allChip = widget.buildAllChip!();
    } else {
      allChip = Chip(
        avatar: widget.allIcon != null ? Icon(widget.allIcon, size: 18) : null,
        label: Text(widget.allLabel),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _buildSelectableChip(
        child: allChip,
        isSelected: widget.controller.isAllSelected,
        onTap: () => widget.controller.selectAll(),
      ),
    );
  }

  Widget _buildSelectableChip({
    required Widget child,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ActionChip(
        avatar: Icon(widget.createIcon, size: 18),
        label: Text(widget.createTooltip),
        onPressed: () => widget.controller.createCategory(),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: widget.controller.pageController,
      onPageChanged: widget.controller.onPageChanged,
      itemCount: widget.controller.totalPages,
      itemBuilder: (context, index) {
        // Last page is creation page (empty)
        if (index == widget.controller.totalPages - 1) {
          return _buildCreationPage();
        }

        // Get category for this page
        final category = widget.controller.getCategoryAtIndex(index);

        // Build list for category (null = "All")
        return widget.buildListForCategory(category);
      },
    );
  }

  Widget _buildCreationPage() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
