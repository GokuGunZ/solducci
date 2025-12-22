import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:solducci/models/task.dart';

/// Custom ValueNotifier that ALWAYS notifies listeners, even if value seems equal
/// This is critical for Flutter to detect task changes
class AlwaysNotifyValueNotifier<T> extends ValueNotifier<T> {
  AlwaysNotifyValueNotifier(super.value);

  @override
  set value(T newValue) {
    // Force notification by always calling notifyListeners
    super.value = newValue;
    notifyListeners(); // Force rebuild even if value appears same
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
    print('🔄 TaskStateManager.updateTask called for: ${task.id.substring(0, 8)}');
    print('   Subtasks count: ${task.subtasks?.length ?? 0}');
    print('   Subtask IDs: ${task.subtasks?.map((t) => t.id.substring(0, 8)).join(", ")}');

    if (_taskNotifiers.containsKey(task.id)) {
      // Update the notifier - AlwaysNotifyValueNotifier will force rebuild
      _taskNotifiers[task.id]!.value = task;

      // Verify it was set correctly
      final storedValue = _taskNotifiers[task.id]!.value;
      print('   ✓ Notifier value updated');
      print('   ✓ Stored subtasks count: ${storedValue.subtasks?.length ?? 0}');
      print('   ✓ Stored subtask IDs: ${storedValue.subtasks?.map((t) => t.id.substring(0, 8)).join(", ")}');
    } else {
      _taskNotifiers[task.id] = AlwaysNotifyValueNotifier(task);
      print('   ✓ Created new notifier');
    }
  }

  /// Notify that the task list structure has changed (add/remove/reorder)
  void notifyListChange(String documentId) {
    print(
      '📋 TaskStateManager: Broadcasting list change for document $documentId',
    );
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
