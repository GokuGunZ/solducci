import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/utils/task_state_manager.dart';

/// Abstract data source for task list loading
///
/// Strategy pattern: allows UnifiedTaskListBloc to work with different
/// data sources (document-based, tag-based, etc.) without knowing the details.
abstract class TaskListDataSource {
  /// Load tasks from this data source
  Future<List<Task>> loadTasks();

  /// Stream that emits document IDs when task list changes (add/remove/reorder)
  /// Used by BLoC to know when to refresh
  Stream<String> get listChanges;

  /// Unique identifier for this data source (for caching/comparison)
  String get identifier;
}

/// Data source for loading all tasks in a document
class DocumentTaskDataSource implements TaskListDataSource {
  final String documentId;
  final TaskService taskService;
  final TaskStateManager stateManager;

  DocumentTaskDataSource({
    required this.documentId,
    required this.taskService,
    required this.stateManager,
  });

  @override
  Future<List<Task>> loadTasks() {
    return taskService.fetchTasksForDocument(documentId);
  }

  @override
  Stream<String> get listChanges {
    // Filter stream to only emit when THIS document changes
    return stateManager.listChanges.where((docId) => docId == documentId);
  }

  @override
  String get identifier => 'document_$documentId';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentTaskDataSource && other.documentId == documentId;
  }

  @override
  int get hashCode => documentId.hashCode;
}

/// Data source for loading tasks filtered by a specific tag
class TagTaskDataSource implements TaskListDataSource {
  final String tagId;
  final String documentId;
  final bool includeCompleted;
  final TaskService taskService;
  final TaskStateManager stateManager;

  TagTaskDataSource({
    required this.tagId,
    required this.documentId,
    required this.includeCompleted,
    required this.taskService,
    required this.stateManager,
  });

  @override
  Future<List<Task>> loadTasks() {
    return taskService.getTasksByTag(
      tagId,
      includeCompleted: includeCompleted,
    );
  }

  @override
  Stream<String> get listChanges {
    // Filter stream to only emit when the parent document changes
    return stateManager.listChanges.where((docId) => docId == documentId);
  }

  @override
  String get identifier => 'tag_${tagId}_completed_$includeCompleted';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagTaskDataSource &&
        other.tagId == tagId &&
        other.includeCompleted == includeCompleted;
  }

  @override
  int get hashCode => Object.hash(tagId, includeCompleted);
}

/// Data source for loading only completed tasks in a document
class CompletedTaskDataSource implements TaskListDataSource {
  final String documentId;
  final TaskService taskService;
  final TaskStateManager stateManager;

  CompletedTaskDataSource({
    required this.documentId,
    required this.taskService,
    required this.stateManager,
  });

  @override
  Future<List<Task>> loadTasks() async {
    // Load all tasks and filter to completed only
    final allTasks = await taskService.fetchTasksForDocument(documentId);
    return allTasks.where((task) => task.status == TaskStatus.completed).toList();
  }

  @override
  Stream<String> get listChanges {
    // Filter stream to only emit when THIS document changes
    return stateManager.listChanges.where((docId) => docId == documentId);
  }

  @override
  String get identifier => 'completed_$documentId';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompletedTaskDataSource && other.documentId == documentId;
  }

  @override
  int get hashCode => documentId.hashCode;
}
