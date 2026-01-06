import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task/task_tag_service.dart';
import 'package:solducci/service/task/task_hierarchy_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/data/repositories/in_memory_task_tag_repository.dart';
import 'package:solducci/data/repositories/in_memory_task_repository.dart';

/// TaskTagService Unit Tests
///
/// Tests the business logic of TaskTagService using in-memory repositories.
/// Covers tag assignment, retrieval, inheritance, and batch operations.
void main() {
  late TaskTagService service;
  late InMemoryTaskTagRepository tagRepository;
  late InMemoryTaskRepository taskRepository;
  late TaskHierarchyService hierarchyService;
  late TaskStateManager stateManager;

  // Helper to create test tags
  Tag createTestTag(String id, String name) {
    return Tag(
      id: id,
      userId: 'test-user',
      name: name,
      useAdvancedStates: false,
      showCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      color: 'FF0000',
    );
  }

  setUp(() {
    tagRepository = InMemoryTaskTagRepository();
    taskRepository = InMemoryTaskRepository(enableDelays: false);
    stateManager = TaskStateManager();
    hierarchyService = TaskHierarchyService(taskRepository);
    service = TaskTagService(tagRepository, hierarchyService, stateManager);
  });

  tearDown(() {
    tagRepository.clear();
    taskRepository.clear();
  });

  group('getTaskTags', () {
    test('should return tags for a task', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      final tag1 = createTestTag('tag-1', 'Tag 1');
      final tag2 = createTestTag('tag-2', 'Tag 2');

      tagRepository.registerTag(tag1);
      tagRepository.registerTag(tag2);
      await tagRepository.assignTags(task.id, [tag1.id, tag2.id]);

      // Act
      final tags = await service.getTaskTags(task.id);

      // Assert
      expect(tags, hasLength(2));
      expect(tags.map((t) => t.id), containsAll([tag1.id, tag2.id]));
    });

    test('should return empty list if no tags', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');

      // Act
      final tags = await service.getTaskTags(task.id);

      // Assert
      expect(tags, isEmpty);
    });

    test('should handle errors gracefully', () async {
      // Act - Non-existent task
      final tags = await service.getTaskTags('non-existent');

      // Assert - Should return empty list instead of throwing
      expect(tags, isEmpty);
    });
  });

  group('getEffectiveTags', () {
    test('should return own tags only when no parent', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      final tag = createTestTag('tag-1', 'Tag 1');

      await taskRepository.create(task);
      tagRepository.registerTag(tag);
      await tagRepository.assignTags(task.id, [tag.id]);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      final effectiveTags = await service.getEffectiveTags(
        task.id,
        taskFetcher: taskFetcher,
      );

      // Assert
      expect(effectiveTags, hasLength(1));
      expect(effectiveTags.first.id, equals(tag.id));
    });

    test('should return own tags plus parent tags', () async {
      // Arrange
      final parent = Task.create(documentId: 'doc-1', title: 'Parent');
      await taskRepository.create(parent);

      final child = Task(
        id: 'child-1',
        documentId: 'doc-1',
        parentTaskId: parent.id,
        title: 'Child',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await taskRepository.create(child);

      final parentTag = createTestTag('parent-tag', 'Parent Tag');
      final childTag = createTestTag('child-tag', 'Child Tag');

      tagRepository.registerTag(parentTag);
      tagRepository.registerTag(childTag);
      await tagRepository.assignTags(parent.id, [parentTag.id]);
      await tagRepository.assignTags(child.id, [childTag.id]);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      final effectiveTags = await service.getEffectiveTags(
        child.id,
        taskFetcher: taskFetcher,
      );

      // Assert
      expect(effectiveTags, hasLength(2));
      expect(effectiveTags.map((t) => t.id), containsAll([parentTag.id, childTag.id]));
    });

    test('should avoid duplicate tags', () async {
      // Arrange
      final parent = Task.create(documentId: 'doc-1', title: 'Parent');
      await taskRepository.create(parent);

      final child = Task(
        id: 'child-1',
        documentId: 'doc-1',
        parentTaskId: parent.id,
        title: 'Child',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await taskRepository.create(child);

      final sharedTag = createTestTag('shared-tag', 'Shared Tag');

      tagRepository.registerTag(sharedTag);
      await tagRepository.assignTags(parent.id, [sharedTag.id]);
      await tagRepository.assignTags(child.id, [sharedTag.id]);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      final effectiveTags = await service.getEffectiveTags(
        child.id,
        taskFetcher: taskFetcher,
      );

      // Assert - Should only have one instance of the shared tag
      expect(effectiveTags, hasLength(1));
      expect(effectiveTags.first.id, equals(sharedTag.id));
    });

    test('should handle task with no tags', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      await taskRepository.create(task);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      final effectiveTags = await service.getEffectiveTags(
        task.id,
        taskFetcher: taskFetcher,
      );

      // Assert
      expect(effectiveTags, isEmpty);
    });

    test('should return empty for non-existent task', () async {
      // Arrange
      Future<Task?> taskFetcher(String id) async => null;

      // Act
      final effectiveTags = await service.getEffectiveTags(
        'non-existent',
        taskFetcher: taskFetcher,
      );

      // Assert
      expect(effectiveTags, isEmpty);
    });
  });

  group('getEffectiveTagsForTasks', () {
    test('should batch load tags for multiple tasks', () async {
      // Arrange
      final task1 = Task.create(documentId: 'doc-1', title: 'Task 1');
      final task2 = Task.create(documentId: 'doc-1', title: 'Task 2');
      final tag1 = createTestTag('tag-1', 'Tag 1');
      final tag2 = createTestTag('tag-2', 'Tag 2');

      tagRepository.registerTag(tag1);
      tagRepository.registerTag(tag2);
      await tagRepository.assignTags(task1.id, [tag1.id]);
      await tagRepository.assignTags(task2.id, [tag2.id]);

      // Act
      final result = await service.getEffectiveTagsForTasks([task1.id, task2.id]);

      // Assert
      expect(result, hasLength(2));
      expect(result[task1.id], hasLength(1));
      expect(result[task1.id]!.first.id, equals(tag1.id));
      expect(result[task2.id], hasLength(1));
      expect(result[task2.id]!.first.id, equals(tag2.id));
    });

    test('should return empty map for empty input', () async {
      // Act
      final result = await service.getEffectiveTagsForTasks([]);

      // Assert
      expect(result, isEmpty);
    });

    test('should handle tasks with no tags', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Task');

      // Act
      final result = await service.getEffectiveTagsForTasks([task.id]);

      // Assert
      expect(result[task.id], isEmpty);
    });

    test('should handle shared tags efficiently', () async {
      // Arrange
      final task1 = Task.create(documentId: 'doc-1', title: 'Task 1');
      final task2 = Task.create(documentId: 'doc-1', title: 'Task 2');
      final sharedTag = createTestTag('shared-tag', 'Shared');

      tagRepository.registerTag(sharedTag);
      await tagRepository.assignTags(task1.id, [sharedTag.id]);
      await tagRepository.assignTags(task2.id, [sharedTag.id]);

      // Act
      final result = await service.getEffectiveTagsForTasks([task1.id, task2.id]);

      // Assert - Both tasks should have the shared tag
      expect(result[task1.id]!.first.id, equals(sharedTag.id));
      expect(result[task2.id]!.first.id, equals(sharedTag.id));
    });
  });

  group('assignTags', () {
    test('should replace all tags', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      await taskRepository.create(task);

      final oldTag = createTestTag('old-tag', 'Old Tag');
      final newTag = createTestTag('new-tag', 'New Tag');

      tagRepository.registerTag(oldTag);
      tagRepository.registerTag(newTag);
      await tagRepository.assignTags(task.id, [oldTag.id]);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      await service.assignTags(task.id, [newTag.id], taskFetcher: taskFetcher);

      // Assert
      final tags = await tagRepository.getTaskTagIds(task.id);
      expect(tags, hasLength(1));
      expect(tags.first, equals(newTag.id));
    });

    test('should clear tags if empty list provided', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      await taskRepository.create(task);

      final tag = createTestTag('tag-1', 'Tag 1');

      tagRepository.registerTag(tag);
      await tagRepository.assignTags(task.id, [tag.id]);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      await service.assignTags(task.id, [], taskFetcher: taskFetcher);

      // Assert
      final tags = await tagRepository.getTaskTagIds(task.id);
      expect(tags, isEmpty);
    });
  });

  group('addTag', () {
    test('should add single tag', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      await taskRepository.create(task);

      final tag = createTestTag('tag-1', 'Tag 1');

      tagRepository.registerTag(tag);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      await service.addTag(task.id, tag.id, taskFetcher: taskFetcher);

      // Assert
      final tags = await tagRepository.getTaskTagIds(task.id);
      expect(tags, hasLength(1));
      expect(tags.first, equals(tag.id));
    });

    test('should add multiple tags sequentially', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      await taskRepository.create(task);

      final tag1 = createTestTag('tag-1', 'Tag 1');
      final tag2 = createTestTag('tag-2', 'Tag 2');

      tagRepository.registerTag(tag1);
      tagRepository.registerTag(tag2);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      await service.addTag(task.id, tag1.id, taskFetcher: taskFetcher);
      await service.addTag(task.id, tag2.id, taskFetcher: taskFetcher);

      // Assert
      final tags = await tagRepository.getTaskTagIds(task.id);
      expect(tags, hasLength(2));
      expect(tags, containsAll([tag1.id, tag2.id]));
    });
  });

  group('removeTag', () {
    test('should remove single tag', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      await taskRepository.create(task);

      final tag1 = createTestTag('tag-1', 'Tag 1');
      final tag2 = createTestTag('tag-2', 'Tag 2');

      tagRepository.registerTag(tag1);
      tagRepository.registerTag(tag2);
      await tagRepository.assignTags(task.id, [tag1.id, tag2.id]);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act
      await service.removeTag(task.id, tag1.id, taskFetcher: taskFetcher);

      // Assert
      final tags = await tagRepository.getTaskTagIds(task.id);
      expect(tags, hasLength(1));
      expect(tags.first, equals(tag2.id));
    });

    test('should handle removing non-existent tag gracefully', () async {
      // Arrange
      final task = Task.create(documentId: 'doc-1', title: 'Test Task');
      await taskRepository.create(task);

      final tag = createTestTag('tag-1', 'Tag 1');
      tagRepository.registerTag(tag);
      await tagRepository.assignTags(task.id, [tag.id]);

      Future<Task?> taskFetcher(String id) async => await taskRepository.getById(id);

      // Act - Remove non-existent tag
      await service.removeTag(task.id, 'non-existent', taskFetcher: taskFetcher);

      // Assert - Original tag should still be there
      final tags = await tagRepository.getTaskTagIds(task.id);
      expect(tags, hasLength(1));
      expect(tags.first, equals(tag.id));
    });
  });

  group('getTasksByTag', () {
    test('should return tasks with specific tag', () async {
      // Arrange
      final task1 = Task.create(documentId: 'doc-1', title: 'Task 1');
      final task2 = Task.create(documentId: 'doc-1', title: 'Task 2');
      await taskRepository.create(task1);
      await taskRepository.create(task2);

      final tag = createTestTag('tag-1', 'Tag 1');

      tagRepository.registerTask(task1);
      tagRepository.registerTask(task2);
      tagRepository.registerTag(tag);
      await tagRepository.assignTags(task1.id, [tag.id]);

      Future<List<Task>> childrenFetcher(String parentId) async => [];

      // Act
      final tasks = await service.getTasksByTag(
        tag.id,
        childrenFetcher: childrenFetcher,
      );

      // Assert
      expect(tasks, hasLength(1));
      expect(tasks.first.id, equals(task1.id));
    });

    test('should exclude completed tasks by default', () async {
      // Arrange
      final pendingTask = Task.create(documentId: 'doc-1', title: 'Pending');
      final completedTask = Task(
        id: 'completed-1',
        documentId: 'doc-1',
        title: 'Completed',
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        position: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskRepository.create(pendingTask);
      await taskRepository.create(completedTask);

      final tag = createTestTag('tag-1', 'Tag 1');

      tagRepository.registerTask(pendingTask);
      tagRepository.registerTask(completedTask);
      tagRepository.registerTag(tag);
      await tagRepository.assignTags(pendingTask.id, [tag.id]);
      await tagRepository.assignTags(completedTask.id, [tag.id]);

      Future<List<Task>> childrenFetcher(String parentId) async => [];

      // Act
      final tasks = await service.getTasksByTag(
        tag.id,
        includeCompleted: false,
        childrenFetcher: childrenFetcher,
      );

      // Assert
      expect(tasks, hasLength(1));
      expect(tasks.first.id, equals(pendingTask.id));
    });

    test('should include completed tasks when requested', () async {
      // Arrange
      final pendingTask = Task.create(documentId: 'doc-1', title: 'Pending');
      final completedTask = Task(
        id: 'completed-1',
        documentId: 'doc-1',
        title: 'Completed',
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        position: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskRepository.create(pendingTask);
      await taskRepository.create(completedTask);

      final tag = createTestTag('tag-1', 'Tag 1');

      tagRepository.registerTask(pendingTask);
      tagRepository.registerTask(completedTask);
      tagRepository.registerTag(tag);
      await tagRepository.assignTags(pendingTask.id, [tag.id]);
      await tagRepository.assignTags(completedTask.id, [tag.id]);

      Future<List<Task>> childrenFetcher(String parentId) async => [];

      // Act
      final tasks = await service.getTasksByTag(
        tag.id,
        includeCompleted: true,
        childrenFetcher: childrenFetcher,
      );

      // Assert
      expect(tasks, hasLength(2));
      expect(tasks.map((t) => t.id), containsAll([pendingTask.id, completedTask.id]));
    });

    test('should return empty list for tag with no tasks', () async {
      // Arrange
      final tag = createTestTag('tag-1', 'Tag 1');
      tagRepository.registerTag(tag);

      Future<List<Task>> childrenFetcher(String parentId) async => [];

      // Act
      final tasks = await service.getTasksByTag(
        tag.id,
        childrenFetcher: childrenFetcher,
      );

      // Assert
      expect(tasks, isEmpty);
    });
  });
}
