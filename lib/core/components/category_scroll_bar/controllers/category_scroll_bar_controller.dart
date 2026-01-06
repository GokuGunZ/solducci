import 'package:flutter/material.dart';
import 'package:solducci/core/animations/app_animations.dart';

/// Controller for CategoryScrollBar component
///
/// Coordinates bidirectional synchronization between:
/// - Category chips (horizontal list at top)
/// - PageView (swipeable lists below)
/// - Category creation flow
///
/// Features:
/// - Tap chip → animate to page
/// - Swipe page → update selected chip
/// - Tap "+" → swipe to creation page + show modal
///
/// Usage:
/// ```dart
/// final controller = CategoryScrollBarController<Task, Tag>(
///   pageController: PageController(initialPage: 0),
///   categories: tags,
///   onCategoryChanged: (tag) => print('Selected: $tag'),
/// );
///
/// // From chip tap
/// controller.selectCategory(2);
///
/// // From page swipe
/// controller.onPageChanged(3);
///
/// // Create new category
/// await controller.createCategory();
/// ```
class CategoryScrollBarController<T, C> extends ChangeNotifier {
  /// PageController for the list views
  final PageController pageController;

  /// Current list of categories
  List<C> _categories;

  /// Current selected category index
  int _currentIndex;

  /// Callback when category selection changes
  final void Function(C? category, int index)? onCategoryChanged;

  /// Callback to create new category (shows modal, returns new category)
  final Future<C?> Function()? onCreateCategory;

  /// Whether controller is currently animating
  bool _isAnimating = false;

  /// Whether "All" category is shown as first item
  final bool showAllCategory;

  CategoryScrollBarController({
    required this.pageController,
    required List<C> categories,
    int initialIndex = 0,
    this.onCategoryChanged,
    this.onCreateCategory,
    this.showAllCategory = true,
  })  : _categories = categories,
        _currentIndex = initialIndex {
    // Listen to page controller for swipe detection
    pageController.addListener(_onPageScrolled);
  }

  // ============================================================
  // GETTERS
  // ============================================================

  /// Current categories (immutable)
  List<C> get categories => List.unmodifiable(_categories);

  /// Total number of pages (categories + optional "all" + creation page)
  int get totalPages => _categories.length + (showAllCategory ? 1 : 0) + 1;

  /// Current selected index
  int get currentIndex => _currentIndex;

  /// Current selected category (null if "All" is selected)
  C? get currentCategory {
    if (!showAllCategory) {
      return _currentIndex < _categories.length ? _categories[_currentIndex] : null;
    }

    // "All" is at index 0
    if (_currentIndex == 0) return null;

    final categoryIndex = _currentIndex - 1;
    return categoryIndex < _categories.length ? _categories[categoryIndex] : null;
  }

  /// Whether currently animating
  bool get isAnimating => _isAnimating;

  /// Whether currently on "All" page
  bool get isAllSelected => showAllCategory && _currentIndex == 0;

  /// Whether currently on creation page
  bool get isOnCreationPage => _currentIndex == totalPages - 1;

  // ============================================================
  // CATEGORY SELECTION
  // ============================================================

  /// Select category by index (from chip tap)
  ///
  /// Animates PageView to the corresponding page
  Future<void> selectCategoryByIndex(int index) async {
    if (_isAnimating) return;
    if (index == _currentIndex) return;
    if (index < 0 || index >= totalPages) return;

    _isAnimating = true;
    notifyListeners();

    try {
      await pageController.animateToPage(
        index,
        duration: AppAnimations.swipeDuration,
        curve: AppAnimations.swipeCurve,
      );

      _currentIndex = index;
      _notifyCategoryChanged();
    } finally {
      _isAnimating = false;
      notifyListeners();
    }
  }

  /// Select "All" category
  Future<void> selectAll() async {
    if (!showAllCategory) return;
    await selectCategoryByIndex(0);
  }

  /// Select specific category
  Future<void> selectCategory(C category) async {
    final index = _categories.indexOf(category);
    if (index == -1) return;

    final pageIndex = showAllCategory ? index + 1 : index;
    await selectCategoryByIndex(pageIndex);
  }

  // ============================================================
  // PAGE CHANGES (from swipe)
  // ============================================================

  /// Called when PageView page changes (from user swipe)
  void onPageChanged(int pageIndex) {
    if (_currentIndex == pageIndex) return;

    _currentIndex = pageIndex;
    _notifyCategoryChanged();
    notifyListeners();
  }

  void _onPageScrolled() {
    // Detect when page has settled after swipe
    if (pageController.hasClients) {
      final page = pageController.page?.round() ?? _currentIndex;
      if (page != _currentIndex && !_isAnimating) {
        onPageChanged(page);
      }
    }
  }

  void _notifyCategoryChanged() {
    onCategoryChanged?.call(currentCategory, _currentIndex);
  }

  // ============================================================
  // CATEGORY MANAGEMENT
  // ============================================================

  /// Update categories list
  ///
  /// Useful when categories are loaded asynchronously
  void updateCategories(List<C> newCategories) {
    _categories = newCategories;

    // Adjust current index if out of bounds
    if (_currentIndex >= totalPages) {
      _currentIndex = totalPages - 2; // Last real category
    }

    notifyListeners();
  }

  /// Add new category
  void addCategory(C category) {
    _categories.add(category);
    notifyListeners();
  }

  /// Remove category
  void removeCategory(C category) {
    final index = _categories.indexOf(category);
    if (index == -1) return;

    _categories.removeAt(index);

    // Adjust current index if needed
    if (_currentIndex > index) {
      _currentIndex--;
    } else if (_currentIndex == index) {
      _currentIndex = 0; // Go to "All"
    }

    notifyListeners();
  }

  /// Create new category workflow
  ///
  /// 1. Animate to creation page (empty page)
  /// 2. Show creation modal
  /// 3. Add new category if created
  /// 4. Animate to new category page
  Future<C?> createCategory() async {
    if (onCreateCategory == null) return null;
    if (_isAnimating) return null;

    // Step 1: Animate to creation page
    await selectCategoryByIndex(totalPages - 1);

    // Step 2: Show modal and wait for result
    final newCategory = await onCreateCategory!();

    if (newCategory != null) {
      // Step 3: Add category
      addCategory(newCategory);

      // Step 4: Animate to new category
      final newIndex = _categories.length - 1 + (showAllCategory ? 1 : 0);
      await selectCategoryByIndex(newIndex);
    } else {
      // Cancelled - go back to previous page
      await selectCategoryByIndex(_currentIndex > 0 ? _currentIndex - 1 : 0);
    }

    return newCategory;
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  /// Navigate to next category
  Future<void> nextCategory() async {
    if (_currentIndex < totalPages - 2) {
      // -2 to exclude creation page
      await selectCategoryByIndex(_currentIndex + 1);
    }
  }

  /// Navigate to previous category
  Future<void> previousCategory() async {
    if (_currentIndex > 0) {
      await selectCategoryByIndex(_currentIndex - 1);
    }
  }

  // ============================================================
  // UTILITY
  // ============================================================

  /// Get category at index (accounting for "All")
  C? getCategoryAtIndex(int index) {
    if (showAllCategory) {
      if (index == 0) return null; // "All"
      final categoryIndex = index - 1;
      return categoryIndex < _categories.length ? _categories[categoryIndex] : null;
    }

    return index < _categories.length ? _categories[index] : null;
  }

  /// Get page index for category
  int getIndexForCategory(C category) {
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex == -1) return -1;

    return showAllCategory ? categoryIndex + 1 : categoryIndex;
  }

  @override
  void dispose() {
    pageController.removeListener(_onPageScrolled);
    super.dispose();
  }
}
