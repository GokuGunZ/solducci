import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('Task.fromMap should correctly deserialize', () {
      final map = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'document_id': 'doc-123',
        'parent_task_id': null,
        'title': 'Buy groceries',
        'description': 'Get milk and bread',
        'status': 'pending',
        'completed_at': null,
        'priority': 'high',
        't_shirt_size': 'm',
        'due_date': '2024-12-10T10:00:00.000Z',
        'position': 0,
        'created_at': '2024-12-04T10:00:00.000Z',
        'updated_at': '2024-12-04T10:00:00.000Z',
      };

      final task = Task.fromMap(map);

      expect(task.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(task.documentId, 'doc-123');
      expect(task.parentTaskId, null);
      expect(task.title, 'Buy groceries');
      expect(task.description, 'Get milk and bread');
      expect(task.status, TaskStatus.pending);
      expect(task.priority, TaskPriority.high);
      expect(task.tShirtSize, TShirtSize.m);
      expect(task.isCompleted, false);
      expect(task.isRoot, true);
    });

    test('Task.toMap should correctly serialize', () {
      final task = Task(
        id: '123e4567-e89b-12d3-a456-426614174000',
        documentId: 'doc-123',
        title: 'Buy groceries',
        description: 'Get milk and bread',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        tShirtSize: TShirtSize.m,
        position: 0,
        createdAt: DateTime(2024, 12, 4, 10, 0, 0),
        updatedAt: DateTime(2024, 12, 4, 10, 0, 0),
      );

      final map = task.toMap();

      expect(map['id'], '123e4567-e89b-12d3-a456-426614174000');
      expect(map['document_id'], 'doc-123');
      expect(map['title'], 'Buy groceries');
      expect(map['status'], 'pending');
      expect(map['priority'], 'high');
      expect(map['t_shirt_size'], 'm');
    });

    test('TaskStatus enum should have correct values and labels', () {
      expect(TaskStatus.pending.value, 'pending');
      expect(TaskStatus.completed.value, 'completed');
      expect(TaskStatus.assigned.value, 'assigned');
      expect(TaskStatus.inProgress.value, 'in_progress');

      expect(TaskStatus.pending.label, 'Da fare');
      expect(TaskStatus.completed.label, 'Completata');
    });

    test('TaskStatus.fromValue should parse correctly', () {
      expect(TaskStatus.fromValue('pending'), TaskStatus.pending);
      expect(TaskStatus.fromValue('completed'), TaskStatus.completed);
      expect(TaskStatus.fromValue('assigned'), TaskStatus.assigned);
      expect(TaskStatus.fromValue('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromValue('invalid'), TaskStatus.pending); // Default
    });

    test('TaskPriority enum should have correct values', () {
      expect(TaskPriority.low.value, 'low');
      expect(TaskPriority.medium.value, 'medium');
      expect(TaskPriority.high.value, 'high');
      expect(TaskPriority.urgent.value, 'urgent');
    });

    test('Task.isCompleted should return correct value', () {
      final pendingTask = Task(
        id: '123',
        documentId: 'doc-123',
        title: 'Test',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final completedTask = pendingTask.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );

      expect(pendingTask.isCompleted, false);
      expect(completedTask.isCompleted, true);
    });

    test('Task.isOverdue should return true for past due date', () {
      final overdueTask = Task(
        id: '123',
        documentId: 'doc-123',
        title: 'Overdue task',
        status: TaskStatus.pending,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final futureTask = overdueTask.copyWith(
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(overdueTask.isOverdue, true);
      expect(futureTask.isOverdue, false);
    });

    test('Task.isOverdue should return false for completed tasks', () {
      final completedTask = Task(
        id: '123',
        documentId: 'doc-123',
        title: 'Completed task',
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(completedTask.isOverdue, false);
    });

    test('Task.hasSubtasks should return correct value', () {
      final taskWithoutSubtasks = Task(
        id: '123',
        documentId: 'doc-123',
        title: 'Parent task',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final subtask = Task(
        id: '456',
        documentId: 'doc-123',
        parentTaskId: '123',
        title: 'Subtask',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final taskWithSubtasks = taskWithoutSubtasks.copyWith(
        subtasks: [subtask],
      );

      expect(taskWithoutSubtasks.hasSubtasks, false);
      expect(taskWithSubtasks.hasSubtasks, true);
    });

    test('Task.isRoot should be based on parentTaskId', () {
      final rootTask = Task(
        id: '123',
        documentId: 'doc-123',
        title: 'Root task',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final childTask = Task(
        id: '456',
        documentId: 'doc-123',
        parentTaskId: '123',
        title: 'Child task',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(rootTask.isRoot, true);
      expect(childTask.isRoot, false);
    });

    test('Task.create should create a new task with defaults', () {
      final task = Task.create(
        documentId: 'doc-123',
        title: 'New task',
        description: 'Test description',
        priority: TaskPriority.medium,
      );

      expect(task.id, '');
      expect(task.documentId, 'doc-123');
      expect(task.title, 'New task');
      expect(task.status, TaskStatus.pending);
      expect(task.priority, TaskPriority.medium);
      expect(task.position, 0);
    });

    test('Task.copyWith should update only specified fields', () {
      final original = Task(
        id: '123',
        documentId: 'doc-123',
        title: 'Original',
        description: 'Original description',
        status: TaskStatus.pending,
        position: 0,
        createdAt: DateTime(2024, 12, 4),
        updatedAt: DateTime(2024, 12, 4),
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        status: TaskStatus.completed,
      );

      expect(updated.id, original.id);
      expect(updated.title, 'Updated Title');
      expect(updated.status, TaskStatus.completed);
      expect(updated.description, 'Original description');
    });
  });
}
