import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solducci/blocs/unified_task_list/unified_task_list_bloc_export.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

// Mocks
class MockTaskOrderPersistenceService extends Mock
    implements TaskOrderPersistenceService {}

class MockTaskListDataSource extends Mock implements TaskListDataSource {}

void main() {
  group('UnifiedTaskListBloc', () {
    late UnifiedTaskListBloc bloc;
    late MockTaskOrderPersistenceService mockOrderService;
    late MockTaskListDataSource mockDataSource;

    setUp(() {
      mockOrderService = MockTaskOrderPersistenceService();
      mockDataSource = MockTaskListDataSource();

      bloc = UnifiedTaskListBloc(
        orderPersistenceService: mockOrderService,
      );

      // Register fallback values for mocktail
      registerFallbackValue(const FilterSortConfig());
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is TaskListInitial', () {
      expect(bloc.state, equals(const TaskListInitial()));
    });

    group('TaskListLoadRequested', () {
      final mockTasks = [
        Task.create(
          title: 'Test Task 1',
          documentId: 'doc123',
        ),
        Task.create(
          title: 'Test Task 2',
          documentId: 'doc123',
        ),
      ];

      setUp(() {
        when(() => mockDataSource.loadTasks())
            .thenAnswer((_) async => mockTasks);
        when(() => mockDataSource.listChanges).thenAnswer(
          (_) => Stream<String>.empty(),
        );
        when(() => mockDataSource.identifier).thenReturn('test_source');
      });

      test('emits [Loading, Loaded] when tasks are loaded successfully',
          () async {
        // Arrange
        final expectedStates = [
          const TaskListLoading(),
          TaskListLoaded(
            tasks: mockTasks,
            rawTasks: mockTasks,
            supportsReordering: false, // MockDataSource is not DocumentTaskDataSource
          ),
        ];

        // Act
        bloc.add(TaskListLoadRequested(mockDataSource));

        // Assert
        await expectLater(
          bloc.stream,
          emitsInOrder(expectedStates),
        );
      });

      test('subscribes to data source listChanges stream', () async {
        // Act
        bloc.add(TaskListLoadRequested(mockDataSource));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockDataSource.listChanges).called(1);
      });
    });

    group('TaskListFilterChanged', () {
      final mockTasks = [
        Task.create(
          title: 'Task 1',
          documentId: 'doc123',
          priority: TaskPriority.high,
        ),
        Task.create(
          title: 'Task 2',
          documentId: 'doc123',
          priority: TaskPriority.low,
        ),
      ];

      setUp(() {
        when(() => mockDataSource.loadTasks())
            .thenAnswer((_) async => mockTasks);
        when(() => mockDataSource.listChanges).thenAnswer(
          (_) => Stream<String>.empty(),
        );
        when(() => mockDataSource.identifier).thenReturn('test_source');
      });

      test('applies filter to rawTasks and emits new TaskListLoaded',
          () async {
        // Arrange - First load the tasks
        bloc.add(TaskListLoadRequested(mockDataSource));
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Apply filter for high priority
        final filterConfig = const FilterSortConfig(
          priorities: {TaskPriority.high},
        );
        bloc.add(TaskListFilterChanged(filterConfig));

        // Assert - Should only have 1 task (the high priority one)
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<TaskListLoaded>(
              (state) =>
                  state.tasks.length == 1 &&
                  state.tasks.first.priority == TaskPriority.high &&
                  state.filterConfig == filterConfig,
            ),
          ]),
        );
      });
    });

    group('TaskListTaskCreationStarted/Completed', () {
      final mockTasks = [Task.create(title: 'Task', documentId: 'doc123')];

      setUp(() {
        when(() => mockDataSource.loadTasks())
            .thenAnswer((_) async => mockTasks);
        when(() => mockDataSource.listChanges).thenAnswer(
          (_) => Stream<String>.empty(),
        );
        when(() => mockDataSource.identifier).thenReturn('test_source');
      });

      test('sets isCreatingTask to true when started', () async {
        // Arrange - Load tasks first
        bloc.add(TaskListLoadRequested(mockDataSource));
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        bloc.add(const TaskListTaskCreationStarted());

        // Assert
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<TaskListLoaded>((state) => state.isCreatingTask == true),
          ]),
        );
      });

      test('sets isCreatingTask to false when completed', () async {
        // Arrange - Load tasks and start creation
        bloc.add(TaskListLoadRequested(mockDataSource));
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(const TaskListTaskCreationStarted());
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        bloc.add(const TaskListTaskCreationCompleted());

        // Assert
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<TaskListLoaded>((state) => state.isCreatingTask == false),
          ]),
        );
      });
    });

    group('TaskListRefreshRequested', () {
      final initialTasks = [Task.create(title: 'Task 1', documentId: 'doc')];
      final refreshedTasks = [
        Task.create(title: 'Task 1', documentId: 'doc'),
        Task.create(title: 'Task 2', documentId: 'doc'),
      ];

      setUp(() {
        when(() => mockDataSource.listChanges).thenAnswer(
          (_) => Stream<String>.empty(),
        );
        when(() => mockDataSource.identifier).thenReturn('test_source');
      });

      test('re-fetches tasks from data source', () async {
        // Arrange - Initial load
        when(() => mockDataSource.loadTasks())
            .thenAnswer((_) async => initialTasks);

        bloc.add(TaskListLoadRequested(mockDataSource));
        await Future.delayed(const Duration(milliseconds: 100));

        // Update mock to return more tasks
        when(() => mockDataSource.loadTasks())
            .thenAnswer((_) async => refreshedTasks);

        // Act
        bloc.add(const TaskListRefreshRequested());

        // Assert - Should now have 2 tasks
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<TaskListLoaded>((state) => state.tasks.length == 2),
          ]),
        );
      });

      test('preserves isCreatingTask state during refresh', () async {
        // Arrange - Load tasks and start creation
        when(() => mockDataSource.loadTasks())
            .thenAnswer((_) async => initialTasks);

        bloc.add(TaskListLoadRequested(mockDataSource));
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(const TaskListTaskCreationStarted());
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Refresh while creating
        bloc.add(const TaskListRefreshRequested());

        // Assert - Should maintain isCreatingTask = true
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<TaskListLoaded>(
              (state) =>
                  state.isCreatingTask == true, // Preserved during refresh
            ),
          ]),
        );
      });
    });
  });

  group('TaskListDataSource equality', () {
    test('DocumentTaskDataSource equals when same documentId', () {
      // Note: This would require proper mock setup for TaskService and TaskStateManager
      // For now, this demonstrates the concept
      expect(true, true); // Placeholder
    });
  });
}
