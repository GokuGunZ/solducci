import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/data/repositories/in_memory_task_repository.dart';
import 'package:solducci/domain/repositories/task_repository.dart';

/// Test suite for InMemoryTaskRepository
///
/// Tests the in-memory implementation used for testing.
/// Verifies CRUD operations, validation, and streaming capabilities.
void main() {
  late InMemoryTaskRepository repository;

  setUp(() {
    // Create repository with no delays for faster tests
    repository = InMemoryTaskRepository(
      delay: Duration.zero,
      enableDelays: false,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  group('InMemoryTaskRepository - Basic CRUD', () {
    test('should create a task with generated ID', () async {
      // Arrange
      final task = Task.create(
        documentId: 'doc-1',
        title: 'Test Task',
      );

      // Act
      final created = await repository.create(task);

      // Assert
      expect(created.id, isNotEmpty);
      expect(created.title, equals('Test Task'));
      expect(created.documentId, equals('doc-1'));
      expect(repository.taskCount, equals(1));
    });

    test('should create a task with provided ID', () async {
      // Arrange
      final task = Task(
        id: 'custom-id',
        documentId: 'doc-1',
        title: 'Test Task',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final created = await repository.create(task);

      // Assert
      expect(created.id, equals('custom-id'));
      expect(repository.containsTask('custom-id'), isTrue);
    });

    test('should retrieve task by ID', () async {
      // Arrange
      final task = Task.create(
        documentId: 'doc-1',
        title: 'Test Task',
      );
      final created = await repository.create(task);

      // Act
      final retrieved = await repository.getById(created.id);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(created.id));
      expect(retrieved.title, equals('Test Task'));
    });

    test('should return null for nonexistent task', () async {
      // Act
      final result = await repository.getById('nonexistent-id');

      // Assert
      expect(result, isNull);
    });

    test('should update a task', () async {
      // Arrange
      final task = Task.create(
        documentId: 'doc-1',
        title: 'Original Title',
      );
      final created = await repository.create(task);

      // Act
      final updated = await repository.update(
        created.copyWith(title: 'Updated Title'),
      );

      // Assert
      expect(updated.title, equals('Updated Title'));
      expect(updated.id, equals(created.id));

      final retrieved = await repository.getById(created.id);
      expect(retrieved!.title, equals('Updated Title'));
    });

    test('should delete a task', () async {
      // Arrange
      final task = Task.create(
        documentId: 'doc-1',
        title: 'Test Task',
      );
      final created = await repository.create(task);

      // Act
      await repository.delete(created.id);

      // Assert
      expect(repository.taskCount, equals(0));
      expect(repository.containsTask(created.id), isFalse);
      final retrieved = await repository.getById(created.id);
      expect(retrieved, isNull);
    });

    test('should delete task with subtasks (cascade)', () async {
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

      expect(repository.taskCount, equals(2));

      // Act
      await repository.delete(parent.id);

      // Assert
      expect(repository.taskCount, equals(0));
      expect(repository.containsTask(parent.id), isFalse);
      expect(repository.containsTask(child.id), isFalse);
    });
  });

  group('InMemoryTaskRepository - Validation', () {
    test('should throw ValidationException for empty title', () async {
      // Arrange
      final task = Task.create(
        documentId: 'doc-1',
        title: '',
      );

      // Act & Assert
      expect(
        () => repository.create(task),
        throwsA(isA<ValidationException>().having(
          (e) => e.fieldErrors?['title'],
          'title error',
          'Title is required',
        )),
      );
    });

    test('should throw ValidationException for empty documentId', () async {
      // Arrange
      final task = Task.create(
        documentId: '',
        title: 'Test Task',
      );

      // Act & Assert
      expect(
        () => repository.create(task),
        throwsA(isA<ValidationException>().having(
          (e) => e.fieldErrors?['documentId'],
          'documentId error',
          'Document ID is required',
        )),
      );
    });

    test('should throw ValidationException for empty task ID in getById', () async {
      // Act & Assert
      expect(
        () => repository.getById(''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should throw ValidationException for empty task ID in delete', () async {
      // Act & Assert
      expect(
        () => repository.delete(''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should throw NotFoundException when updating nonexistent task', () async {
      // Arrange
      final task = Task(
        id: 'nonexistent',
        documentId: 'doc-1',
        title: 'Test',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => repository.update(task),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('should throw NotFoundException when deleting nonexistent task', () async {
      // Act & Assert
      expect(
        () => repository.delete('nonexistent-id'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('should throw ValidationException for nonexistent parent', () async {
      // Arrange
      final task = Task.create(
        documentId: 'doc-1',
        title: 'Child Task',
        parentTaskId: 'nonexistent-parent',
      );

      // Act & Assert
      expect(
        () => repository.create(task),
        throwsA(isA<ValidationException>().having(
          (e) => e.fieldErrors?['parentTaskId'],
          'parentTaskId error',
          contains('Parent task does not exist'),
        )),
      );
    });

    test('should prevent circular reference', () async {
      // Arrange
      final task1 = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Task 1',
      ));

      final task2 = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Task 2',
        parentTaskId: task1.id,
      ));

      // Act & Assert - Try to set task1's parent to task2 (circular)
      final task1WithCircular = Task(
        id: task1.id,
        documentId: task1.documentId,
        parentTaskId: task2.id, // This would create a circular reference
        title: task1.title,
        status: task1.status,
        position: task1.position,
        createdAt: task1.createdAt,
        updatedAt: DateTime.now(),
      );

      expect(
        () => repository.update(task1WithCircular),
        throwsA(isA<ValidationException>().having(
          (e) => e.fieldErrors?['parentTaskId'],
          'circular reference error',
          contains('circular reference'),
        )),
      );
    });
  });

  group('InMemoryTaskRepository - Hierarchy', () {
    test('should build task tree with subtasks', () async {
      // Arrange
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
      final tasks = await repository.getAll(documentId: 'doc-1');

      // Assert
      expect(tasks.length, equals(1)); // Only root task
      expect(tasks[0].id, equals(parent.id));
      expect(tasks[0].subtasks?.length, equals(2));
    });

    test('should get task with all subtasks recursively', () async {
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

      // Act
      final retrieved = await repository.getWithSubtasks(grandparent.id);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.subtasks?.length, equals(1));
      expect(retrieved.subtasks![0].id, equals(parent.id));
      expect(retrieved.subtasks![0].subtasks?.length, equals(1));
      expect(retrieved.subtasks![0].subtasks![0].id, equals(child.id));
    });

    test('should handle orphaned tasks', () async {
      // Arrange - Create task with nonexistent parent (simulating orphan)
      final parent = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Parent',
      ));

      final child = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Child',
        parentTaskId: parent.id,
      ));

      // Delete parent directly from storage to create orphan
      await repository.delete(parent.id);

      // Manually add orphaned task
      repository.seed([
        Task(
          id: child.id,
          documentId: 'doc-1',
          parentTaskId: 'nonexistent',
          title: 'Orphaned Child',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      // Act
      final tasks = await repository.getAll(documentId: 'doc-1');

      // Assert - Orphaned task should be treated as root
      expect(tasks.length, equals(1));
      expect(tasks[0].title, equals('Orphaned Child'));
    });
  });

  group('InMemoryTaskRepository - Batch Operations', () {
    test('should get multiple tasks by IDs', () async {
      // Arrange
      final task1 = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Task 1',
      ));

      final task2 = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Task 2',
      ));

      final task3 = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Task 3',
      ));

      // Act
      final tasks = await repository.getByIds([task1.id, task2.id, task3.id]);

      // Assert
      expect(tasks.length, equals(3));
      expect(tasks[0].id, equals(task1.id));
      expect(tasks[1].id, equals(task2.id));
      expect(tasks[2].id, equals(task3.id));
    });

    test('should handle missing tasks in batch get', () async {
      // Arrange
      final task1 = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Task 1',
      ));

      // Act
      final tasks = await repository.getByIds([task1.id, 'nonexistent']);

      // Assert
      expect(tasks.length, equals(1)); // Only found task
      expect(tasks[0].id, equals(task1.id));
    });

    test('should return empty list for empty IDs', () async {
      // Act
      final tasks = await repository.getByIds([]);

      // Assert
      expect(tasks, isEmpty);
    });
  });

  group('InMemoryTaskRepository - Filtering', () {
    test('should filter by document ID', () async {
      // Arrange
      await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Task 1',
      ));

      await repository.create(Task.create(
        documentId: 'doc-2',
        title: 'Task 2',
      ));

      // Act
      final doc1Tasks = await repository.getAll(documentId: 'doc-1');
      final doc2Tasks = await repository.getAll(documentId: 'doc-2');

      // Assert
      expect(doc1Tasks.length, equals(1));
      expect(doc1Tasks[0].title, equals('Task 1'));
      expect(doc2Tasks.length, equals(1));
      expect(doc2Tasks[0].title, equals('Task 2'));
    });

    test('should filter by status', () async {
      // Arrange
      await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Pending Task',
      )..status = TaskStatus.pending);

      await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Completed Task',
      )
        ..status = TaskStatus.completed
        ..completedAt = DateTime.now());

      // Act
      final pendingTasks = await repository.getByStatus('doc-1', TaskStatus.pending);
      final completedTasks = await repository.getByStatus('doc-1', TaskStatus.completed);

      // Assert
      expect(pendingTasks.length, equals(1));
      expect(pendingTasks[0].title, equals('Pending Task'));
      expect(completedTasks.length, equals(1));
      expect(completedTasks[0].title, equals('Completed Task'));
    });

    test('should get all tasks when no document filter', () async {
      // Arrange
      await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Task 1',
      ));

      await repository.create(Task.create(
        documentId: 'doc-2',
        title: 'Task 2',
      ));

      // Act
      final allTasks = await repository.getAll();

      // Assert
      expect(allTasks.length, equals(2));
    });
  });

  group('InMemoryTaskRepository - Streaming', () {
    test('should emit changes on create', () async {
      // Arrange
      final stream = repository.watchAll(documentId: 'doc-1');
      final emissions = <List<Task>>[];

      // Listen to stream
      final subscription = stream.listen(emissions.add);

      // Wait a bit for stream to be ready
      await Future.delayed(const Duration(milliseconds: 10));

      // Act
      await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Test Task',
      ));

      // Wait for emission
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(emissions.length, greaterThan(0));
      expect(emissions.last.length, equals(1));
      expect(emissions.last[0].title, equals('Test Task'));

      await subscription.cancel();
    });

    test('should emit changes on update', () async {
      // Arrange
      final task = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Original',
      ));

      final stream = repository.watchAll(documentId: 'doc-1');
      final emissions = <List<Task>>[];
      final subscription = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 10));

      // Act
      await repository.update(task.copyWith(title: 'Updated'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(emissions.length, greaterThan(0));
      expect(emissions.last[0].title, equals('Updated'));

      await subscription.cancel();
    });

    test('should emit changes on delete', () async {
      // Arrange
      final task = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Test',
      ));

      final stream = repository.watchAll(documentId: 'doc-1');
      final emissions = <List<Task>>[];
      final subscription = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 10));

      // Act
      await repository.delete(task.id);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(emissions.length, greaterThan(0));
      expect(emissions.last, isEmpty);

      await subscription.cancel();
    });
  });

  group('InMemoryTaskRepository - Helper Methods', () {
    test('should clear all tasks', () async {
      // Arrange
      await repository.create(Task.create(documentId: 'doc-1', title: 'Task 1'));
      await repository.create(Task.create(documentId: 'doc-1', title: 'Task 2'));
      expect(repository.taskCount, equals(2));

      // Act
      repository.clear();

      // Assert
      expect(repository.taskCount, equals(0));
    });

    test('should seed with initial tasks', () {
      // Arrange
      final tasks = [
        Task(
          id: 'task-1',
          documentId: 'doc-1',
          title: 'Task 1',
          status: TaskStatus.pending,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: 'task-2',
          documentId: 'doc-1',
          title: 'Task 2',
          status: TaskStatus.pending,
          position: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      repository.seed(tasks);

      // Assert
      expect(repository.taskCount, equals(2));
      expect(repository.containsTask('task-1'), isTrue);
      expect(repository.containsTask('task-2'), isTrue);
    });

    test('should check if task exists', () async {
      // Arrange
      final task = await repository.create(Task.create(
        documentId: 'doc-1',
        title: 'Test',
      ));

      // Assert
      expect(repository.containsTask(task.id), isTrue);
      expect(repository.containsTask('nonexistent'), isFalse);
    });
  });

  group('InMemoryTaskRepository - Interface Contract', () {
    test('should implement TaskRepository', () {
      expect(repository, isA<TaskRepository>());
    });

    test('should support delays when enabled', () async {
      // Arrange
      final delayedRepo = InMemoryTaskRepository(
        delay: const Duration(milliseconds: 100),
        enableDelays: true,
      );

      final task = Task.create(
        documentId: 'doc-1',
        title: 'Test',
      );

      // Act
      final stopwatch = Stopwatch()..start();
      await delayedRepo.create(task);
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90)); // Allow some variance

      delayedRepo.dispose();
    });
  });
}
