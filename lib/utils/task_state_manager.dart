import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:solducci/models/task.dart';

/// Custom notifier that ALWAYS notifies listeners and ALWAYS updates value
/// Uses ChangeNotifier instead of ValueNotifier to avoid equality check issues
class AlwaysNotifyValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  T _value;

  AlwaysNotifyValueNotifier(this._value);

  @override
  T get value => _value;

  set value(T newValue) {
    // CRITICAL: Always update _value, never skip based on equality
    _value = newValue;

    // Always notify, regardless of whether value changed
    notifyListeners();
  }
}

/// Reference-counted notifier that automatically cleans up when the last reference is removed
/// Wraps AlwaysNotifyValueNotifier with automatic memory management
class _ReferenceCountedNotifier<T> extends AlwaysNotifyValueNotifier<T> {
  final String taskId;
  final VoidCallback onLastReferenceRemoved;

  _ReferenceCountedNotifier(
    T value,
    this.taskId,
    this.onLastReferenceRemoved,
  ) : super(value);

  @override
  void dispose() {
    // When this notifier is disposed, notify the TaskStateManager
    onLastReferenceRemoved();
    super.dispose();
  }
}

/// Manager for individual task state using ValueNotifiers
/// Enables granular rebuilds - only the affected task rebuilds, not the entire list
///
/// Memory Management:
/// - Uses reference counting to automatically clean up notifiers
/// - Each call to getOrCreateTaskNotifier() increments the reference count
/// - Widgets should dispose their notifiers to decrement the count
/// - When reference count reaches 0, the notifier is automatically removed
class TaskStateManager {
  static final TaskStateManager _instance = TaskStateManager._internal();
  factory TaskStateManager() => _instance;
  TaskStateManager._internal();

  // Map of task ID -> ValueNotifier for granular updates
  final Map<String, AlwaysNotifyValueNotifier<Task>> _taskNotifiers = {};

  // Map of task ID -> reference count for automatic cleanup
  final Map<String, int> _referenceCount = {};

  // Stream controller for task list changes (add/remove/reorder)
  final _listChangesController = StreamController<String>.broadcast();

  /// Stream of document IDs that have list-level changes (add/remove/reorder)
  Stream<String> get listChanges => _listChangesController.stream;

  /// Get or create a ValueNotifier for a specific task with automatic reference counting
  ///
  /// Each call increments the reference count. When the notifier is disposed,
  /// the count is decremented. When it reaches 0, the notifier is automatically removed.
  ///
  /// IMPORTANT: Widgets MUST dispose the returned notifier to avoid memory leaks.
  AlwaysNotifyValueNotifier<Task> getOrCreateTaskNotifier(
    String taskId,
    Task initialTask,
  ) {
    if (!_taskNotifiers.containsKey(taskId)) {
      // Create new reference-counted notifier
      _taskNotifiers[taskId] = _ReferenceCountedNotifier(
        initialTask,
        taskId,
        () => _decrementReference(taskId),
      );
      _referenceCount[taskId] = 0;
    }

    // Increment reference count
    _referenceCount[taskId] = (_referenceCount[taskId] ?? 0) + 1;

    // Do NOT update here - only create if missing
    return _taskNotifiers[taskId]!;
  }

  /// Decrement reference count and cleanup if no more references
  void _decrementReference(String taskId) {
    final count = _referenceCount[taskId] ?? 0;

    if (count <= 1) {
      // Last reference being removed - cleanup
      _taskNotifiers.remove(taskId);
      _referenceCount.remove(taskId);
    } else {
      // Still have other references
      _referenceCount[taskId] = count - 1;
    }
  }

  /// Update a specific task (triggers only that task's rebuild)
  void updateTask(Task task) {
    if (_taskNotifiers.containsKey(task.id)) {
      _taskNotifiers[task.id]!.value = task;
    } else {
      _taskNotifiers[task.id] = AlwaysNotifyValueNotifier(task);
    }
  }

  /// Recursively update a task and all its subtasks
  /// CRITICAL: Updates subtasks FIRST, then parent (bottom-up)
  /// This ensures parent notifiers have updated subtask lists when they notify listeners
  void updateTaskRecursively(Task task, {int depth = 0}) {
    // CRITICAL FIX: Create a COPY of the subtasks list BEFORE iterating
    // This prevents the list from being modified during iteration
    final subtasksCopy = task.subtasks != null ? List<Task>.from(task.subtasks!) : null;

    // CRITICAL FIX: Update subtasks FIRST (bottom-up approach)
    // This ensures when parent notifier fires, subtasks are already updated
    if (subtasksCopy != null && subtasksCopy.isNotEmpty) {
      for (final subtask in subtasksCopy) {
        updateTaskRecursively(subtask, depth: depth + 1);
      }
    }

    // THEN update this task (after children are done)
    updateTask(task);
  }

  /// Notify that the task list structure has changed (add/remove/reorder)
  void notifyListChange(String documentId) {
    if (!_listChangesController.isClosed) {
      _listChangesController.add(documentId);
    }
  }

  /// Remove a task notifier (manual cleanup - usually not needed with reference counting)
  void removeTask(String taskId) {
    final notifier = _taskNotifiers.remove(taskId);
    _referenceCount.remove(taskId);
    notifier?.dispose();
  }

  /// Get current notifier count (for debugging/testing)
  int get notifierCount => _taskNotifiers.length;

  /// Get reference count for a specific task (for debugging/testing)
  int? getReferenceCount(String taskId) => _referenceCount[taskId];

  /// Check if a task exists in the notifier map
  bool hasNotifier(String taskId) => _taskNotifiers.containsKey(taskId);

  /// Get the current task value if the notifier exists (for comparison)
  Task? getTaskValue(String taskId) => _taskNotifiers[taskId]?.value;

  /// Dispose all notifiers
  void dispose() {
    for (var notifier in _taskNotifiers.values) {
      notifier.dispose();
    }
    _taskNotifiers.clear();
    _referenceCount.clear();
    _listChangesController.close();
  }
}
