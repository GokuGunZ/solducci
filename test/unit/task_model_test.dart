import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/task.dart';

/// Basic tests for Task model
///
/// These tests verify the core functionality of the Task model
/// including creation, status, priority, and basic properties.
void main() {
  group('Task Model Tests', () {
    test('should create a task with required fields', () {
      // Arrange & Act
      final task = Task.create(
        documentId: 'doc-123',
        title: 'Test Task',
      );

      // Assert
      expect(task.documentId, equals('doc-123'));
      expect(task.title, equals('Test Task'));
      expect(task.status, equals(TaskStatus.pending)); // Default status
      expect(task.id, isNotNull); // ID should be set (even if empty string initially)
    });

    test('should create task with optional fields', () {
      // Arrange & Act
      final dueDate = DateTime(2025, 1, 15);
      final task = Task.create(
        documentId: 'doc-123',
        title: 'Test Task',
        priority: TaskPriority.high,
        dueDate: dueDate,
      );

      // Assert
      expect(task.priority, equals(TaskPriority.high));
      expect(task.dueDate, equals(dueDate));
    });

    test('should detect overdue tasks', () {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final task = Task.create(
        documentId: 'doc-123',
        title: 'Overdue Task',
      )..dueDate = yesterday;

      // Act & Assert
      expect(task.isOverdue, isTrue);
    });

    test('should not be overdue if no due date', () {
      // Arrange
      final task = Task.create(
        documentId: 'doc-123',
        title: 'Task without due date',
      );

      // Act & Assert
      expect(task.isOverdue, isFalse);
    });

    test('should not be overdue if due date is in future', () {
      // Arrange
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = Task.create(
        documentId: 'doc-123',
        title: 'Future Task',
      )..dueDate = tomorrow;

      // Act & Assert
      expect(task.isOverdue, isFalse);
    });

    test('should mark task as completed', () {
      // Arrange
      final task = Task.create(
        documentId: 'doc-123',
        title: 'Test Task',
      );

      // Act
      task.status = TaskStatus.completed;
      task.completedAt = DateTime.now();

      // Assert
      expect(task.status, equals(TaskStatus.completed));
      expect(task.isCompleted, isTrue);
      expect(task.completedAt, isNotNull);
    });

    test('should handle t-shirt sizes', () {
      // Arrange
      final task = Task.create(
        documentId: 'doc-123',
        title: 'Test Task',
      );

      // Act
      task.tShirtSize = TShirtSize.xl;

      // Assert
      expect(task.tShirtSize, equals(TShirtSize.xl));
      expect(task.tShirtSize?.label, equals('XL'));
    });

    test('should support subtasks', () {
      // Arrange
      final parentTask = Task.create(
        documentId: 'doc-123',
        title: 'Parent Task',
      );

      final subtask = Task.create(
        documentId: 'doc-123',
        title: 'Subtask',
        parentTaskId: parentTask.id,
      );

      // Act
      parentTask.subtasks = [subtask];

      // Assert
      expect(parentTask.hasSubtasks, isTrue);
      expect(parentTask.subtasks?.length, equals(1));
      expect(subtask.parentTaskId, equals(parentTask.id));
    });
  });

  group('TaskStatus Tests', () {
    test('should have correct status values', () {
      expect(TaskStatus.pending.value, equals('pending'));
      expect(TaskStatus.completed.value, equals('completed'));
      expect(TaskStatus.inProgress.value, equals('in_progress'));
      expect(TaskStatus.assigned.value, equals('assigned'));
    });

    test('should convert from string value', () {
      expect(TaskStatus.fromValue('pending'), equals(TaskStatus.pending));
      expect(TaskStatus.fromValue('completed'), equals(TaskStatus.completed));
      expect(TaskStatus.fromValue('in_progress'), equals(TaskStatus.inProgress));
    });

    test('should have Italian labels', () {
      expect(TaskStatus.pending.label, equals('Da fare'));
      expect(TaskStatus.completed.label, equals('Completata'));
      expect(TaskStatus.inProgress.label, equals('In corso'));
    });
  });

  group('TaskPriority Tests', () {
    test('should have correct priority values', () {
      expect(TaskPriority.low.value, equals('low'));
      expect(TaskPriority.medium.value, equals('medium'));
      expect(TaskPriority.high.value, equals('high'));
      expect(TaskPriority.urgent.value, equals('urgent'));
    });

    test('should convert from string value', () {
      expect(TaskPriority.fromValue('low'), equals(TaskPriority.low));
      expect(TaskPriority.fromValue('high'), equals(TaskPriority.high));
      expect(TaskPriority.fromValue('urgent'), equals(TaskPriority.urgent));
    });

    test('should have correct colors', () {
      expect(TaskPriority.low.color, isNotNull);
      expect(TaskPriority.urgent.color, isNotNull);
    });
  });

  group('TShirtSize Tests', () {
    test('should have correct size values', () {
      expect(TShirtSize.xs.label, equals('XS'));
      expect(TShirtSize.s.label, equals('S'));
      expect(TShirtSize.m.label, equals('M'));
      expect(TShirtSize.l.label, equals('L'));
      expect(TShirtSize.xl.label, equals('XL'));
    });

    test('should have correct index order', () {
      // Index represents order from smallest to largest
      expect(TShirtSize.xs.index, equals(0));
      expect(TShirtSize.s.index, equals(1));
      expect(TShirtSize.m.index, equals(2));
      expect(TShirtSize.l.index, equals(3));
      expect(TShirtSize.xl.index, equals(4));
    });
  });
}
