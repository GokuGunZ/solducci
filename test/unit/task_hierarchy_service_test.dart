import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task/task_hierarchy_service.dart';
import 'package:solducci/data/repositories/in_memory_task_repository.dart';

void main() {
  group('TaskHierarchyService', () {
    late InMemoryTaskRepository repository;
    late TaskHierarchyService service;

    setUp(() {
      repository = InMemoryTaskRepository(enableDelays: false);
      service = TaskHierarchyService(repository);
    });

    tearDown(() {
      repository.dispose();
    });

    group('getTaskWithSubtasks', () {
      test('should return null for non-existent task', () async {
        // Act
        final result = await service.getTaskWithSubtasks('non-existent-id');

        // Assert
        expect(result, isNull);
      });

      test('should return task with subtasks loaded from repository', () async {
        // Arrange - Create parent with children
        final parent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Parent Task',
        ));

        await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Child 1',
          parentTaskId: parent.id,
        ));

        await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Child 2',
          parentTaskId: parent.id,
        ));

        // Act
        final result = await service.getTaskWithSubtasks(parent.id);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(parent.id));
        expect(result.subtasks, isNotNull);
        expect(result.subtasks!.length, equals(2));
      });

      test('should delegate to repository getWithSubtasks method', () async {
        // Arrange
        final task = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Test Task',
        ));

        // Act
        final result = await service.getTaskWithSubtasks(task.id);

        // Assert - Result should match repository's tree structure
        expect(result, isNotNull);
        expect(result!.id, equals(task.id));
      });
    });

    group('loadTaskWithSubtasks', () {
      test('should load task with filtered subtasks using childrenFetcher', () async {
        // Arrange
        final parent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        ));

        final child1 = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Child 1',
          parentTaskId: parent.id,
        ));

        final child2 = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Child 2',
          parentTaskId: parent.id,
        ));

        // Mock childrenFetcher
        Future<List<Task>> mockChildrenFetcher(String parentId) async {
          final all = await repository.getAll();
          final allFlat = <Task>[];
          void flatten(List<Task> tasks) {
            for (final t in tasks) {
              allFlat.add(t);
              if (t.subtasks != null) flatten(t.subtasks!);
            }
          }
          flatten(all);
          return allFlat.where((t) => t.parentTaskId == parentId).toList();
        }

        // Act
        final result = await service.loadTaskWithSubtasks(
          parent.id,
          childrenFetcher: mockChildrenFetcher,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.subtasks, isNotNull);
        expect(result.subtasks!.length, equals(2));
        expect(result.subtasks!.map((t) => t.id), containsAll([child1.id, child2.id]));
      });

      test('should filter out completed tasks when includeCompleted is false', () async {
        // Arrange
        final parent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        ));

        await repository.create(Task(
          id: 'completed-child',
          documentId: 'doc-1',
          title: 'Completed Child',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final pendingChild = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Pending Child',
          parentTaskId: parent.id,
        ));

        Future<List<Task>> mockChildrenFetcher(String parentId) async {
          final all = await repository.getAll();
          final allFlat = <Task>[];
          void flatten(List<Task> tasks) {
            for (final t in tasks) {
              allFlat.add(t);
              if (t.subtasks != null) flatten(t.subtasks!);
            }
          }
          flatten(all);
          return allFlat.where((t) => t.parentTaskId == parentId).toList();
        }

        // Act
        final result = await service.loadTaskWithSubtasks(
          parent.id,
          includeCompleted: false,
          childrenFetcher: mockChildrenFetcher,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.subtasks, isNotNull);
        expect(result.subtasks!.length, equals(1));
        expect(result.subtasks![0].id, equals(pendingChild.id));
      });

      test('should include completed tasks when includeCompleted is true', () async {
        // Arrange
        final parent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        ));

        await repository.create(Task(
          id: 'completed-child',
          documentId: 'doc-1',
          title: 'Completed Child',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Pending Child',
          parentTaskId: parent.id,
        ));

        Future<List<Task>> mockChildrenFetcher(String parentId) async {
          final all = await repository.getAll();
          final allFlat = <Task>[];
          void flatten(List<Task> tasks) {
            for (final t in tasks) {
              allFlat.add(t);
              if (t.subtasks != null) flatten(t.subtasks!);
            }
          }
          flatten(all);
          return allFlat.where((t) => t.parentTaskId == parentId).toList();
        }

        // Act
        final result = await service.loadTaskWithSubtasks(
          parent.id,
          includeCompleted: true,
          childrenFetcher: mockChildrenFetcher,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.subtasks, isNotNull);
        expect(result.subtasks!.length, equals(2));
      });

      test('should handle task with no subtasks', () async {
        // Arrange
        final task = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Lone Task',
        ));

        Future<List<Task>> mockChildrenFetcher(String parentId) async {
          return [];
        }

        // Act
        final result = await service.loadTaskWithSubtasks(
          task.id,
          childrenFetcher: mockChildrenFetcher,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.subtasks, isNull);
      });

      test('should work recursively for nested subtasks', () async {
        // Arrange - Create 3-level hierarchy
        final grandparent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Grandparent',
        ));

        final parent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Parent',
          parentTaskId: grandparent.id,
        ));

        final child = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Child',
          parentTaskId: parent.id,
        ));

        Future<List<Task>> mockChildrenFetcher(String parentId) async {
          final all = await repository.getAll();
          final allFlat = <Task>[];
          void flatten(List<Task> tasks) {
            for (final t in tasks) {
              allFlat.add(t);
              if (t.subtasks != null) flatten(t.subtasks!);
            }
          }
          flatten(all);
          return allFlat.where((t) => t.parentTaskId == parentId).toList();
        }

        // Act
        final result = await service.loadTaskWithSubtasks(
          grandparent.id,
          childrenFetcher: mockChildrenFetcher,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.subtasks, isNotNull);
        expect(result.subtasks!.length, equals(1));
        expect(result.subtasks![0].subtasks, isNotNull);
        expect(result.subtasks![0].subtasks!.length, equals(1));
        expect(result.subtasks![0].subtasks![0].id, equals(child.id));
      });
    });

    group('validateParentChange', () {
      test('should return true for null parent', () async {
        // Arrange
        final task = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Task',
        ));

        Future<List<Task>> mockDescendantsFetcher(String taskId) async => [];

        // Act
        final isValid = await service.validateParentChange(
          task.id,
          null,
          descendantsFetcher: mockDescendantsFetcher,
        );

        // Assert
        expect(isValid, isTrue);
      });

      test('should return true for valid parent (not a descendant)', () async {
        // Arrange
        final task1 = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Task 1',
        ));

        final task2 = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Task 2',
        ));

        Future<List<Task>> mockDescendantsFetcher(String taskId) async => [];

        // Act
        final isValid = await service.validateParentChange(
          task1.id,
          task2.id,
          descendantsFetcher: mockDescendantsFetcher,
        );

        // Assert
        expect(isValid, isTrue);
      });

      test('should return false for direct child as parent', () async {
        // Arrange
        final parent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        ));

        final child = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Child',
          parentTaskId: parent.id,
        ));

        Future<List<Task>> mockDescendantsFetcher(String taskId) async {
          if (taskId == parent.id) {
            return [child];
          }
          return [];
        }

        // Act - Try to set parent's parent to its child
        final isValid = await service.validateParentChange(
          parent.id,
          child.id,
          descendantsFetcher: mockDescendantsFetcher,
        );

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for indirect descendant as parent', () async {
        // Arrange
        final grandparent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Grandparent',
        ));

        final parent = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Parent',
          parentTaskId: grandparent.id,
        ));

        final child = await repository.create(Task.create(
          documentId: 'doc-1',
          title: 'Child',
          parentTaskId: parent.id,
        ));

        Future<List<Task>> mockDescendantsFetcher(String taskId) async {
          if (taskId == grandparent.id) {
            return [parent, child];
          }
          return [];
        }

        // Act - Try to set grandparent's parent to grandchild
        final isValid = await service.validateParentChange(
          grandparent.id,
          child.id,
          descendantsFetcher: mockDescendantsFetcher,
        );

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('markDescendantsAsProcessed', () {
      test('should mark all descendants in set', () {
        // Arrange
        final grandparent = Task(
          id: 'gp-id',
          documentId: 'doc-1',
          title: 'GP',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final parent = Task(
          id: 'p-id',
          documentId: 'doc-1',
          title: 'P',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final child = Task(
          id: 'c-id',
          documentId: 'doc-1',
          title: 'C',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        parent.subtasks = [child];
        grandparent.subtasks = [parent];

        final processedIds = <String>{};

        // Act
        service.markDescendantsAsProcessed(grandparent, processedIds);

        // Assert
        expect(processedIds.length, equals(2));
        expect(processedIds, containsAll(['p-id', 'c-id']));
        expect(processedIds, isNot(contains('gp-id')));
      });

      test('should handle task with no subtasks', () {
        // Arrange
        final task = Task.create(documentId: 'doc-1', title: 'Task');
        final processedIds = <String>{};

        // Act
        service.markDescendantsAsProcessed(task, processedIds);

        // Assert
        expect(processedIds, isEmpty);
      });

      test('should work recursively for deep hierarchies', () {
        // Arrange - Create a task with nested subtasks structure
        final child3 = Task(
          id: 'child3-id',
          documentId: 'doc-1',
          title: 'Child 3',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final child2 = Task(
          id: 'child2-id',
          documentId: 'doc-1',
          title: 'Child 2',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        child2.subtasks = [child3];

        final child1 = Task(
          id: 'child1-id',
          documentId: 'doc-1',
          title: 'Child 1',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        child1.subtasks = [child2];

        final parent = Task(
          id: 'parent-id',
          documentId: 'doc-1',
          title: 'Parent',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        parent.subtasks = [child1];

        final processedIds = <String>{};

        // Act
        service.markDescendantsAsProcessed(parent, processedIds);

        // Assert
        expect(processedIds.length, equals(3));
        expect(processedIds, containsAll(['child1-id', 'child2-id', 'child3-id']));
      });
    });
  });
}
