import 'package:flutter/material.dart';
import 'package:solducci/core/animations/app_animations.dart';

/// Controller for managing animated list operations
///
/// Provides methods to insert, remove, and update items in a list
/// with consistent animations from AppAnimations registry.
///
/// Usage:
/// ```dart
/// final controller = AnimatedListController<Task>(
///   listKey: GlobalKey<AnimatedListState>(),
///   itemBuilder: (task) => TaskListItem(task),
/// );
///
/// // Insert with animation
/// controller.insertItem(0, newTask);
///
/// // Remove with animation
/// controller.removeItem(2, oldTask);
/// ```
class AnimatedListController<T> extends ChangeNotifier {
  /// Key for AnimatedList widget
  final GlobalKey<AnimatedListState> listKey;

  /// Builder for creating widgets from items
  final Widget Function(T item) itemBuilder;

  /// Current items in the list
  List<T> _items;

  AnimatedListController({
    required this.listKey,
    required this.itemBuilder,
    List<T>? initialItems,
  }) : _items = initialItems ?? [];

  /// Current items (immutable copy)
  List<T> get items => List.unmodifiable(_items);

  /// Number of items
  int get length => _items.length;

  /// Check if list is empty
  bool get isEmpty => _items.isEmpty;

  /// Check if list is not empty
  bool get isNotEmpty => _items.isNotEmpty;

  // ============================================================
  // INSERT OPERATIONS
  // ============================================================

  /// Insert item at index with animation
  void insertItem(int index, T item) {
    assert(index >= 0 && index <= _items.length, 'Index out of range');

    _items.insert(index, item);

    listKey.currentState?.insertItem(
      index,
      duration: AppAnimations.insertDuration,
    );

    notifyListeners();
  }

  /// Insert item at the beginning
  void insertAtBeginning(T item) {
    insertItem(0, item);
  }

  /// Insert item at the end
  void insertAtEnd(T item) {
    insertItem(_items.length, item);
  }

  /// Insert multiple items at once
  void insertAll(int index, List<T> newItems) {
    for (var i = 0; i < newItems.length; i++) {
      insertItem(index + i, newItems[i]);
    }
  }

  // ============================================================
  // REMOVE OPERATIONS
  // ============================================================

  /// Remove item at index with animation
  void removeItem(int index) {
    assert(index >= 0 && index < _items.length, 'Index out of range');

    final removedItem = _items.removeAt(index);

    listKey.currentState?.removeItem(
      index,
      (context, animation) {
        return AppAnimations.buildRemoveAnimation(
          context,
          animation,
          itemBuilder(removedItem),
        );
      },
      duration: AppAnimations.removeDuration,
    );

    notifyListeners();
  }

  /// Remove specific item
  bool removeWhere(bool Function(T) predicate) {
    final index = _items.indexWhere(predicate);
    if (index != -1) {
      removeItem(index);
      return true;
    }
    return false;
  }

  /// Remove all items matching predicate
  void removeAllWhere(bool Function(T) predicate) {
    // Remove from end to beginning to maintain indices
    for (int i = _items.length - 1; i >= 0; i--) {
      if (predicate(_items[i])) {
        removeItem(i);
      }
    }
  }

  /// Clear all items with animations
  void clear() {
    removeAllWhere((_) => true);
  }

  // ============================================================
  // UPDATE OPERATIONS
  // ============================================================

  /// Replace item at index (no animation)
  void replaceItem(int index, T newItem) {
    assert(index >= 0 && index < _items.length, 'Index out of range');

    _items[index] = newItem;
    notifyListeners();
  }

  /// Update item matching predicate
  bool updateWhere(bool Function(T) predicate, T newItem) {
    final index = _items.indexWhere(predicate);
    if (index != -1) {
      replaceItem(index, newItem);
      return true;
    }
    return false;
  }

  // ============================================================
  // MOVE/REORDER OPERATIONS
  // ============================================================

  /// Move item from oldIndex to newIndex with animation
  void moveItem(int oldIndex, int newIndex) {
    assert(oldIndex >= 0 && oldIndex < _items.length, 'Old index out of range');
    assert(newIndex >= 0 && newIndex < _items.length, 'New index out of range');

    if (oldIndex == newIndex) return;

    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    // AnimatedList handles reorder animation automatically
    notifyListeners();
  }

  /// Reorder items (e.g., after manual drag-and-drop)
  void reorder(int oldIndex, int newIndex) {
    // Handle flutter reorderable list convention
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    moveItem(oldIndex, newIndex);
  }

  // ============================================================
  // BATCH OPERATIONS
  // ============================================================

  /// Replace entire list with new items
  ///
  /// This is useful when applying filters or sorting.
  /// Animation depends on the diff between old and new lists.
  void replaceAll(List<T> newItems, {String Function(T)? getItemId}) {
    if (getItemId == null) {
      // No ID function - replace everything
      _replaceAllWithoutDiff(newItems);
      return;
    }

    // Calculate diff and animate changes
    _replaceAllWithDiff(newItems, getItemId);
  }

  void _replaceAllWithoutDiff(List<T> newItems) {
    // Remove all old items
    final oldLength = _items.length;
    _items.clear();

    for (int i = oldLength - 1; i >= 0; i--) {
      listKey.currentState?.removeItem(
        i,
        (context, animation) => const SizedBox.shrink(),
        duration: Duration.zero,
      );
    }

    // Insert all new items
    _items.addAll(newItems);
    for (int i = 0; i < newItems.length; i++) {
      listKey.currentState?.insertItem(i, duration: Duration.zero);
    }

    notifyListeners();
  }

  void _replaceAllWithDiff(List<T> newItems, String Function(T) getItemId) {
    final oldIds = _items.map(getItemId).toSet();
    final newIds = newItems.map(getItemId).toSet();

    // Remove items not in new list
    for (int i = _items.length - 1; i >= 0; i--) {
      if (!newIds.contains(getItemId(_items[i]))) {
        removeItem(i);
      }
    }

    // Insert items not in old list
    for (int i = 0; i < newItems.length; i++) {
      if (!oldIds.contains(getItemId(newItems[i]))) {
        insertItem(i, newItems[i]);
      }
    }

    // Update order
    _items = List.from(newItems);
    notifyListeners();
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Get item at index
  T operator [](int index) => _items[index];

  /// Find index of item
  int indexOf(T item) => _items.indexOf(item);

  /// Find index where predicate is true
  int indexWhere(bool Function(T) predicate) => _items.indexWhere(predicate);

  /// Check if item exists
  bool contains(T item) => _items.contains(item);

  @override
  void dispose() {
    _items.clear();
    super.dispose();
  }
}
