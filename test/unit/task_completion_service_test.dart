import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/service/task/task_completion_service.dart';
import 'package:solducci/data/repositories/in_memory_task_completion_repository.dart';

void main() {
  group('TaskCompletionService', () {
    late InMemoryTaskCompletionRepository repository;
    late TaskCompletionService service;

    setUp(() {
      repository = InMemoryTaskCompletionRepository();
      service = TaskCompletionService(repository);
    });

    tearDown(() {
      repository.clear();
    });

    group('completeTask', () {
      test('should mark non-recurring task as completed', () async {
        // Arrange
        final task = Task.create(
          documentId: 'doc-1',
          title: 'Test Task',
        );
        repository.registerTask(task);

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);
        Future<List<Task>> childrenFetcher(String parentId) async => [];
        Future<Recurrence?> recurrenceFetcher(String taskId) async => null;
        Future<void> parentCompletionChecker(String parentId) async {}

        // Act
        await service.completeTask(
          task.id,
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          recurrenceFetcher: recurrenceFetcher,
          parentCompletionChecker: parentCompletionChecker,
        );

        // Assert
        final completedTask = repository.getTask(task.id);
        expect(completedTask, isNotNull);
        expect(completedTask!.status, equals(TaskStatus.completed));
        expect(completedTask.completedAt, isNotNull);
      });

      test('should throw if task not found', () async {
        // Arrange
        Future<Task?> taskFetcher(String id) async => null;
        Future<List<Task>> childrenFetcher(String parentId) async => [];
        Future<Recurrence?> recurrenceFetcher(String taskId) async => null;
        Future<void> parentCompletionChecker(String parentId) async {}

        // Act & Assert
        expect(
          () => service.completeTask(
            'non-existent-id',
            taskFetcher: taskFetcher,
            childrenFetcher: childrenFetcher,
            recurrenceFetcher: recurrenceFetcher,
            parentCompletionChecker: parentCompletionChecker,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Task not found'),
            ),
          ),
        );
      });

      test('should throw if task has incomplete subtasks', () async {
        // Arrange
        final parent = Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        );
        repository.registerTask(parent);

        final incompleteChild = Task.create(
          documentId: 'doc-1',
          title: 'Incomplete Child',
          parentTaskId: parent.id,
        );

        Future<Task?> taskFetcher(String id) async {
          if (id == parent.id) return parent;
          return null;
        }

        Future<List<Task>> childrenFetcher(String parentId) async {
          if (parentId == parent.id) return [incompleteChild];
          return [];
        }

        Future<Recurrence?> recurrenceFetcher(String taskId) async => null;
        Future<void> parentCompletionChecker(String parentId) async {}

        // Act & Assert
        expect(
          () => service.completeTask(
            parent.id,
            taskFetcher: taskFetcher,
            childrenFetcher: childrenFetcher,
            recurrenceFetcher: recurrenceFetcher,
            parentCompletionChecker: parentCompletionChecker,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('subtask incomplete'),
            ),
          ),
        );
      });

      test('should complete task if all subtasks are completed', () async {
        // Arrange
        final parent = Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        );
        repository.registerTask(parent);

        final completedChild1 = Task(
          id: 'child-1',
          documentId: 'doc-1',
          title: 'Completed Child 1',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final completedChild2 = Task(
          id: 'child-2',
          documentId: 'doc-1',
          title: 'Completed Child 2',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);

        Future<List<Task>> childrenFetcher(String parentId) async {
          if (parentId == parent.id) {
            return [completedChild1, completedChild2];
          }
          return [];
        }

        Future<Recurrence?> recurrenceFetcher(String taskId) async => null;
        Future<void> parentCompletionChecker(String parentId) async {}

        // Act
        await service.completeTask(
          parent.id,
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          recurrenceFetcher: recurrenceFetcher,
          parentCompletionChecker: parentCompletionChecker,
        );

        // Assert
        final completedParent = repository.getTask(parent.id);
        expect(completedParent, isNotNull);
        expect(completedParent!.status, equals(TaskStatus.completed));
      });

      test('should invoke parent completion checker when task has parent', () async {
        // Arrange
        final parent = Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        );
        repository.registerTask(parent);

        final child = Task.create(
          documentId: 'doc-1',
          title: 'Child',
          parentTaskId: parent.id,
        );
        repository.registerTask(child);

        bool parentCheckCalled = false;
        String? checkedParentId;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);
        Future<List<Task>> childrenFetcher(String parentId) async => [];
        Future<Recurrence?> recurrenceFetcher(String taskId) async => null;

        Future<void> parentCompletionChecker(String parentId) async {
          parentCheckCalled = true;
          checkedParentId = parentId;
        }

        // Act
        await service.completeTask(
          child.id,
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          recurrenceFetcher: recurrenceFetcher,
          parentCompletionChecker: parentCompletionChecker,
        );

        // Assert
        expect(parentCheckCalled, isTrue);
        expect(checkedParentId, equals(parent.id));
      });

      test('should not invoke parent checker when task has no parent', () async {
        // Arrange
        final task = Task.create(
          documentId: 'doc-1',
          title: 'Task Without Parent',
        );
        repository.registerTask(task);

        bool parentCheckCalled = false;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);
        Future<List<Task>> childrenFetcher(String parentId) async => [];
        Future<Recurrence?> recurrenceFetcher(String taskId) async => null;

        Future<void> parentCompletionChecker(String parentId) async {
          parentCheckCalled = true;
        }

        // Act
        await service.completeTask(
          task.id,
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          recurrenceFetcher: recurrenceFetcher,
          parentCompletionChecker: parentCompletionChecker,
        );

        // Assert
        expect(parentCheckCalled, isFalse);
      });

      test('should add to history and reset recurring task', () async {
        // Arrange
        final task = Task.create(
          documentId: 'doc-1',
          title: 'Recurring Task',
        );
        repository.registerTask(task);

        final recurrence = Recurrence(
          id: 'recurrence-1',
          taskId: task.id,
          dailyFrequency: 1, // Every day
          startDate: DateTime.now(),
          isEnabled: true,
          createdAt: DateTime.now(),
        );

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);
        Future<List<Task>> childrenFetcher(String parentId) async => [];

        Future<Recurrence?> recurrenceFetcher(String taskId) async {
          if (taskId == task.id) return recurrence;
          return null;
        }

        Future<void> parentCompletionChecker(String parentId) async {}

        // Act
        await service.completeTask(
          task.id,
          notes: 'Test completion',
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          recurrenceFetcher: recurrenceFetcher,
          parentCompletionChecker: parentCompletionChecker,
        );

        // Assert
        final history = await repository.getCompletionHistory(task.id);
        expect(history, isNotEmpty);
        expect(history[0].notes, equals('Test completion'));

        final resetTask = repository.getTask(task.id);
        expect(resetTask, isNotNull);
        expect(resetTask!.status, equals(TaskStatus.pending));
        expect(resetTask.completedAt, isNull);
      });
    });

    group('uncompleteTask', () {
      test('should set task back to pending', () async {
        // Arrange
        final completedTask = Task(
          id: 'completed-task',
          documentId: 'doc-1',
          title: 'Completed Task',
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        repository.registerTask(completedTask);

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);
        Future<void> uncompleteParent(String parentId) async {}

        // Act
        await service.uncompleteTask(
          completedTask.id,
          taskFetcher: taskFetcher,
          uncompleteParent: uncompleteParent,
        );

        // Assert
        final pendingTask = repository.getTask(completedTask.id);
        expect(pendingTask, isNotNull);
        expect(pendingTask!.status, equals(TaskStatus.pending));
        expect(pendingTask.completedAt, isNull);
      });

      test('should recursively uncomplete parent if completed', () async {
        // Arrange
        final completedParent = Task(
          id: 'completed-parent',
          documentId: 'doc-1',
          title: 'Completed Parent',
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        repository.registerTask(completedParent);

        final completedChild = Task(
          id: 'completed-child',
          documentId: 'doc-1',
          title: 'Completed Child',
          parentTaskId: completedParent.id,
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        repository.registerTask(completedChild);

        bool uncompleteParentCalled = false;
        String? uncompletedParentId;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);

        Future<void> uncompleteParent(String parentId) async {
          uncompleteParentCalled = true;
          uncompletedParentId = parentId;
        }

        // Act
        await service.uncompleteTask(
          completedChild.id,
          taskFetcher: taskFetcher,
          uncompleteParent: uncompleteParent,
        );

        // Assert
        expect(uncompleteParentCalled, isTrue);
        expect(uncompletedParentId, equals(completedParent.id));
      });

      test('should not uncomplete parent if not completed', () async {
        // Arrange
        final parent = Task.create(
          documentId: 'doc-1',
          title: 'Pending Parent',
        );
        repository.registerTask(parent);

        final completedChild = Task(
          id: 'completed-child',
          documentId: 'doc-1',
          title: 'Completed Child',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        repository.registerTask(completedChild);

        bool uncompleteParentCalled = false;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);

        Future<void> uncompleteParent(String parentId) async {
          uncompleteParentCalled = true;
        }

        // Act
        await service.uncompleteTask(
          completedChild.id,
          taskFetcher: taskFetcher,
          uncompleteParent: uncompleteParent,
        );

        // Assert
        expect(uncompleteParentCalled, isFalse);
      });

      test('should handle task with no parent', () async {
        // Arrange
        final completedTask = Task(
          id: 'completed-task',
          documentId: 'doc-1',
          title: 'Completed Task',
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        repository.registerTask(completedTask);

        bool uncompleteParentCalled = false;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);

        Future<void> uncompleteParent(String parentId) async {
          uncompleteParentCalled = true;
        }

        // Act
        await service.uncompleteTask(
          completedTask.id,
          taskFetcher: taskFetcher,
          uncompleteParent: uncompleteParent,
        );

        // Assert
        expect(uncompleteParentCalled, isFalse);
      });
    });

    group('checkParentCompletion', () {
      test('should complete parent if all subtasks completed', () async {
        // Arrange
        final parent = Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        );
        repository.registerTask(parent);

        final completedChild1 = Task(
          id: 'child-1',
          documentId: 'doc-1',
          title: 'Completed Child 1',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final completedChild2 = Task(
          id: 'child-2',
          documentId: 'doc-1',
          title: 'Completed Child 2',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        bool completeParentCalled = false;
        String? completedParentId;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);

        Future<List<Task>> childrenFetcher(String parentId) async {
          if (parentId == parent.id) {
            return [completedChild1, completedChild2];
          }
          return [];
        }

        Future<void> completeParent(String parentId) async {
          completeParentCalled = true;
          completedParentId = parentId;
        }

        // Act
        await service.checkParentCompletion(
          parent.id,
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          completeParent: completeParent,
        );

        // Assert
        expect(completeParentCalled, isTrue);
        expect(completedParentId, equals(parent.id));
      });

      test('should not complete parent if any subtask incomplete', () async {
        // Arrange
        final parent = Task.create(
          documentId: 'doc-1',
          title: 'Parent',
        );
        repository.registerTask(parent);

        final completedChild = Task(
          id: 'completed-child',
          documentId: 'doc-1',
          title: 'Completed Child',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final incompleteChild = Task.create(
          documentId: 'doc-1',
          title: 'Incomplete Child',
          parentTaskId: parent.id,
        );

        bool completeParentCalled = false;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);

        Future<List<Task>> childrenFetcher(String parentId) async {
          if (parentId == parent.id) {
            return [completedChild, incompleteChild];
          }
          return [];
        }

        Future<void> completeParent(String parentId) async {
          completeParentCalled = true;
        }

        // Act
        await service.checkParentCompletion(
          parent.id,
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          completeParent: completeParent,
        );

        // Assert
        expect(completeParentCalled, isFalse);
      });

      test('should handle parent with no subtasks', () async {
        // Arrange
        final parent = Task.create(
          documentId: 'doc-1',
          title: 'Parent Without Children',
        );
        repository.registerTask(parent);

        bool completeParentCalled = false;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);
        Future<List<Task>> childrenFetcher(String parentId) async => [];

        Future<void> completeParent(String parentId) async {
          completeParentCalled = true;
        }

        // Act
        await service.checkParentCompletion(
          parent.id,
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          completeParent: completeParent,
        );

        // Assert
        expect(completeParentCalled, isFalse);
      });

      test('should handle non-existent parent', () async {
        // Arrange
        Future<Task?> taskFetcher(String id) async => null;
        Future<List<Task>> childrenFetcher(String parentId) async => [];
        Future<void> completeParent(String parentId) async {}

        // Act & Assert - Should not throw
        await service.checkParentCompletion(
          'non-existent-id',
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          completeParent: completeParent,
        );
      });

      test('should not complete parent if already completed', () async {
        // Arrange
        final parent = Task(
          id: 'completed-parent',
          documentId: 'doc-1',
          title: 'Completed Parent',
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        repository.registerTask(parent);

        final completedChild = Task(
          id: 'completed-child',
          documentId: 'doc-1',
          title: 'Completed Child',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        bool completeParentCalled = false;

        Future<Task?> taskFetcher(String id) async => repository.getTask(id);

        Future<List<Task>> childrenFetcher(String parentId) async {
          if (parentId == parent.id) return [completedChild];
          return [];
        }

        Future<void> completeParent(String parentId) async {
          completeParentCalled = true;
        }

        // Act
        await service.checkParentCompletion(
          parent.id,
          taskFetcher: taskFetcher,
          childrenFetcher: childrenFetcher,
          completeParent: completeParent,
        );

        // Assert
        expect(completeParentCalled, isFalse);
      });
    });

    group('getCompletionHistory', () {
      test('should return empty list if no history', () async {
        // Act
        final history = await service.getCompletionHistory('non-existent-id');

        // Assert
        expect(history, isEmpty);
      });

      test('should return completion history ordered by date', () async {
        // Arrange
        final task = Task.create(
          documentId: 'doc-1',
          title: 'Recurring Task',
        );
        repository.registerTask(task);

        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        await repository.insertCompletion(
          taskId: task.id,
          completedAt: yesterday,
          notes: 'Second completion',
        );

        await repository.insertCompletion(
          taskId: task.id,
          completedAt: now,
          notes: 'Most recent',
        );

        await repository.insertCompletion(
          taskId: task.id,
          completedAt: twoDaysAgo,
          notes: 'First completion',
        );

        // Act
        final history = await service.getCompletionHistory(task.id);

        // Assert
        expect(history, hasLength(3));
        expect(history[0].notes, equals('Most recent')); // Most recent first
        expect(history[1].notes, equals('Second completion'));
        expect(history[2].notes, equals('First completion'));
      });
    });
  });
}
