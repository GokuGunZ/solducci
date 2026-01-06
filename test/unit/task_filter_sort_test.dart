import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/utils/task_filter_sort.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// Test suite for task filtering and sorting logic
///
/// This is a critical path test as filtering/sorting is used extensively
/// throughout the app and performance is important.
void main() {
  group('Task Filter Tests', () {
    late List<Task> testTasks;

    setUp(() {
      // CRITICAL FIX: Use Task() constructor directly with unique IDs
      // Previous bug: Task.create() sets id='' causing all tasks to share same ID
      // This caused map collisions in filtering logic where all tasks overwrote each other
      final now = DateTime.now();

      // Create a set of test tasks with various properties
      testTasks = [
        Task(
          id: 'task-1',
          documentId: 'doc-1',
          title: 'High priority task',
          status: TaskStatus.pending,
          priority: TaskPriority.high,
          position: 0,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 'task-2',
          documentId: 'doc-1',
          title: 'Low priority task',
          status: TaskStatus.pending,
          priority: TaskPriority.low,
          position: 1,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 'task-3',
          documentId: 'doc-1',
          title: 'Urgent task',
          status: TaskStatus.pending,
          priority: TaskPriority.urgent,
          position: 2,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 'task-4',
          documentId: 'doc-1',
          title: 'Task with due date',
          status: TaskStatus.pending,
          dueDate: DateTime.now().add(const Duration(days: 1)),
          position: 3,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 'task-5',
          documentId: 'doc-1',
          title: 'Overdue task',
          status: TaskStatus.pending,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          position: 4,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 'task-6',
          documentId: 'doc-1',
          title: 'Small task',
          status: TaskStatus.pending,
          tShirtSize: TShirtSize.s,
          position: 5,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 'task-7',
          documentId: 'doc-1',
          title: 'Large task',
          status: TaskStatus.pending,
          tShirtSize: TShirtSize.xl,
          position: 6,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    test('should filter by priority', () {
      // Arrange
      final config = FilterSortConfig(
        priorities: {TaskPriority.high, TaskPriority.urgent},
      );

      // Act
      final result = testTasks.applyFilters(config);

      // Assert
      // Should only include tasks with high or urgent priority (and non-null priority)
      expect(result.length, equals(2));
      expect(result.every((t) =>
        t.priority != null &&
        (t.priority == TaskPriority.high || t.priority == TaskPriority.urgent)
      ), isTrue);
    });

    test('should filter by multiple priorities', () {
      // Arrange
      final config = FilterSortConfig(
        priorities: {TaskPriority.low, TaskPriority.high},
      );

      // Act
      final result = testTasks.applyFilters(config);

      // Assert
      expect(result.length, equals(2));
      expect(result.any((t) => t.priority == TaskPriority.low), isTrue);
      expect(result.any((t) => t.priority == TaskPriority.high), isTrue);
    });

    test('should filter by status', () {
      // Arrange
      testTasks[0].status = TaskStatus.inProgress;
      testTasks[1].status = TaskStatus.completed;

      final config = FilterSortConfig(
        statuses: {TaskStatus.inProgress},
      );

      // Act
      final result = testTasks.applyFilters(config);

      // Assert
      expect(result.length, equals(1));
      expect(result[0].status, equals(TaskStatus.inProgress));
    });

    test('should filter by size', () {
      // Arrange
      final config = FilterSortConfig(
        sizes: {TShirtSize.s, TShirtSize.xl},
      );

      // Act
      final result = testTasks.applyFilters(config);

      // Assert
      expect(result.length, equals(2));
      expect(result.every((t) => t.tShirtSize == TShirtSize.s || t.tShirtSize == TShirtSize.xl), isTrue);
    });

    test('should filter by date - today', () {
      // Arrange
      final today = DateTime.now();
      testTasks[0].dueDate = DateTime(today.year, today.month, today.day);

      final config = FilterSortConfig(
        dateFilter: DateFilterOption.today,
      );

      // Act
      final result = testTasks.applyFilters(config);

      // Assert
      expect(result.length, equals(1));
      expect(result[0].dueDate?.day, equals(today.day));
    });

    test('should filter overdue tasks', () {
      // Arrange
      final config = FilterSortConfig(
        dateFilter: DateFilterOption.overdue,
      );

      // Act
      final result = testTasks.applyFilters(config);

      // Assert
      expect(result.length, greaterThan(0));
      expect(result.every((t) => t.isOverdue), isTrue);
    });

    test('should return all tasks when no filters applied', () {
      // Arrange
      final config = FilterSortConfig();

      // Act
      final result = testTasks.applyFilters(config);

      // Assert
      expect(result.length, equals(testTasks.length));
    });

    test('should handle empty task list', () {
      // Arrange
      final emptyList = <Task>[];
      final config = FilterSortConfig(
        priorities: {TaskPriority.high},
      );

      // Act
      final result = emptyList.applyFilters(config);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('Task Sort Tests', () {
    late List<Task> testTasks;

    setUp(() {
      testTasks = [
        Task.create(
          documentId: 'doc-1',
          title: 'C Task',
        )
          ..priority = TaskPriority.low
          ..dueDate = DateTime(2025, 1, 15),
        Task.create(
          documentId: 'doc-1',
          title: 'A Task',
        )
          ..priority = TaskPriority.urgent
          ..dueDate = DateTime(2025, 1, 10),
        Task.create(
          documentId: 'doc-1',
          title: 'B Task',
        )
          ..priority = TaskPriority.high
          ..dueDate = DateTime(2025, 1, 12),
      ];
    });

    test('should sort by due date ascending', () {
      // Arrange
      final config = FilterSortConfig(
        sortBy: TaskSortOption.dueDate,
        sortAscending: true,
      );

      // Act
      final result = testTasks.applySorting(config);

      // Assert
      expect(result[0].dueDate?.day, equals(10));
      expect(result[1].dueDate?.day, equals(12));
      expect(result[2].dueDate?.day, equals(15));
    });

    test('should sort by due date descending', () {
      // Arrange
      final config = FilterSortConfig(
        sortBy: TaskSortOption.dueDate,
        sortAscending: false,
      );

      // Act
      final result = testTasks.applySorting(config);

      // Assert
      expect(result[0].dueDate?.day, equals(15));
      expect(result[1].dueDate?.day, equals(12));
      expect(result[2].dueDate?.day, equals(10));
    });

    test('should sort by priority (urgent first)', () {
      // Arrange
      final config = FilterSortConfig(
        sortBy: TaskSortOption.priority,
        sortAscending: false, // Higher priority first
      );

      // Act
      final result = testTasks.applySorting(config);

      // Assert
      expect(result[0].priority, equals(TaskPriority.urgent));
      expect(result[1].priority, equals(TaskPriority.high));
      expect(result[2].priority, equals(TaskPriority.low));
    });

    test('should sort by title alphabetically', () {
      // Arrange
      final config = FilterSortConfig(
        sortBy: TaskSortOption.title,
        sortAscending: true,
      );

      // Act
      final result = testTasks.applySorting(config);

      // Assert
      expect(result[0].title, equals('A Task'));
      expect(result[1].title, equals('B Task'));
      expect(result[2].title, equals('C Task'));
    });

    test('should handle tasks with null values in sorting', () {
      // Arrange
      testTasks.add(Task.create(
        documentId: 'doc-1',
        title: 'Task without due date',
      ));

      final config = FilterSortConfig(
        sortBy: TaskSortOption.dueDate,
        sortAscending: true,
      );

      // Act
      final result = testTasks.applySorting(config);

      // Assert
      // Tasks with null due date should be at the end
      expect(result.last.dueDate, isNull);
    });

    test('should return unsorted list when no sort option specified', () {
      // Arrange
      final config = FilterSortConfig();

      // Act
      final result = testTasks.applySorting(config);

      // Assert
      expect(result.length, equals(testTasks.length));
      expect(result[0].title, equals('C Task')); // Original order preserved
    });
  });

  group('Combined Filter and Sort Tests', () {
    late List<Task> testTasks;

    setUp(() {
      testTasks = [
        Task.create(documentId: 'doc-1', title: 'Task 1')
          ..priority = TaskPriority.high
          ..dueDate = DateTime(2025, 1, 15),
        Task.create(documentId: 'doc-1', title: 'Task 2')
          ..priority = TaskPriority.high
          ..dueDate = DateTime(2025, 1, 10),
        Task.create(documentId: 'doc-1', title: 'Task 3')
          ..priority = TaskPriority.low
          ..dueDate = DateTime(2025, 1, 12),
        Task.create(documentId: 'doc-1', title: 'Task 4')
          ..priority = TaskPriority.urgent
          ..dueDate = DateTime(2025, 1, 8),
      ];
    });

    test('should filter and then sort', () {
      // Arrange
      final config = FilterSortConfig(
        priorities: {TaskPriority.high, TaskPriority.urgent},
        sortBy: TaskSortOption.dueDate,
        sortAscending: true,
      );

      // Act
      final result = testTasks.applyFilterSort(config);

      // Assert
      expect(result.length, equals(3)); // Only high and urgent
      expect(result[0].priority, equals(TaskPriority.urgent)); // Earliest date
      expect(result[0].dueDate?.day, equals(8));
      expect(result[1].dueDate?.day, equals(10));
      expect(result[2].dueDate?.day, equals(15));
    });

    test('should handle complex filtering with multiple criteria', () {
      // Arrange
      testTasks[0].tShirtSize = TShirtSize.xl;
      testTasks[1].tShirtSize = TShirtSize.s;

      final config = FilterSortConfig(
        priorities: {TaskPriority.high},
        sizes: {TShirtSize.s, TShirtSize.xl},
        sortBy: TaskSortOption.title,
        sortAscending: true,
      );

      // Act
      final result = testTasks.applyFilterSort(config);

      // Assert
      expect(result.length, equals(2)); // Only high priority with specified sizes
      expect(result.every((t) => t.priority == TaskPriority.high), isTrue);
    });
  });

  group('Custom Order Tests', () {
    test('should apply custom order', () {
      // Arrange
      final tasks = [
        Task.create(documentId: 'doc-1', title: 'Task A'),
        Task.create(documentId: 'doc-1', title: 'Task B'),
        Task.create(documentId: 'doc-1', title: 'Task C'),
      ];

      final customOrder = [tasks[2].id, tasks[0].id, tasks[1].id];

      // Act
      final result = tasks.applyCustomOrder(customOrder);

      // Assert
      expect(result[0].id, equals(tasks[2].id));
      expect(result[1].id, equals(tasks[0].id));
      expect(result[2].id, equals(tasks[1].id));
    });

    test('should append new tasks not in custom order', () {
      // Arrange
      final tasks = [
        Task.create(documentId: 'doc-1', title: 'Task A'),
        Task.create(documentId: 'doc-1', title: 'Task B'),
        Task.create(documentId: 'doc-1', title: 'Task C'),
      ];

      final customOrder = [tasks[0].id]; // Only first task

      // Act
      final result = tasks.applyCustomOrder(customOrder);

      // Assert
      expect(result[0].id, equals(tasks[0].id)); // First in custom order
      expect(result.length, equals(3)); // All tasks present
    });

    test('should handle empty custom order', () {
      // Arrange
      final tasks = [
        Task.create(documentId: 'doc-1', title: 'Task A'),
        Task.create(documentId: 'doc-1', title: 'Task B'),
      ];

      final customOrder = <String>[];

      // Act
      final result = tasks.applyCustomOrder(customOrder);

      // Assert
      expect(result.length, equals(2));
      expect(result, equals(tasks)); // Original order preserved
    });
  });

  group('Performance Tests', () {
    test('should handle large task lists efficiently', () {
      // Arrange - Create 1000 tasks
      final largeTasks = List.generate(
        1000,
        (i) => Task.create(
          documentId: 'doc-1',
          title: 'Task $i',
        )
          ..priority = TaskPriority.values[i % 4]
          ..dueDate = DateTime.now().add(Duration(days: i)),
      );

      final config = FilterSortConfig(
        priorities: {TaskPriority.high, TaskPriority.urgent},
        sortBy: TaskSortOption.dueDate,
        sortAscending: true,
      );

      // Act
      final stopwatch = Stopwatch()..start();
      final result = largeTasks.applyFilterSort(config);
      stopwatch.stop();

      // Assert
      expect(result.isNotEmpty, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be < 100ms
      // Performance metric: Should filter and sort 1000 tasks in < 100ms
    });
  });
}
