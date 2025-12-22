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

/// Manager for individual task state using ValueNotifiers
/// Enables granular rebuilds - only the affected task rebuilds, not the entire list
class TaskStateManager {
  static final TaskStateManager _instance = TaskStateManager._internal();
  factory TaskStateManager() => _instance;
  TaskStateManager._internal();

  // Map of task ID -> ValueNotifier for granular updates
  final Map<String, AlwaysNotifyValueNotifier<Task>> _taskNotifiers = {};

  // Stream controller for task list changes (add/remove/reorder)
  final _listChangesController = StreamController<String>.broadcast();

  /// Stream of document IDs that have list-level changes (add/remove/reorder)
  Stream<String> get listChanges => _listChangesController.stream;

  /// Get or create a ValueNotifier for a specific task
  /// CRITICAL: Only call this ONCE per task to avoid overwriting updates
  AlwaysNotifyValueNotifier<Task> getOrCreateTaskNotifier(
    String taskId,
    Task initialTask,
  ) {
    if (!_taskNotifiers.containsKey(taskId)) {
      _taskNotifiers[taskId] = AlwaysNotifyValueNotifier(initialTask);
    }
    // Do NOT update here - only create if missing
    return _taskNotifiers[taskId]!;
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

  /// Remove a task notifier (cleanup)
  void removeTask(String taskId) {
    final notifier = _taskNotifiers.remove(taskId);
    notifier?.dispose();
  }

  /// Dispose all notifiers
  void dispose() {
    for (var notifier in _taskNotifiers.values) {
      notifier.dispose();
    }
    _taskNotifiers.clear();
    _listChangesController.close();
  }
}
