import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/blocs/task_list/task_list_bloc.dart';
import 'package:solducci/blocs/task_list/task_list_event.dart';
import 'package:solducci/blocs/task_list/task_list_state.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

void main() {
  group('TaskListBloc', () {
    late TaskService mockTaskService;
    late TaskStateManager mockStateManager;
    late TaskOrderPersistenceService mockOrderPersistenceService;

    setUp(() {
      mockTaskService = TaskService();
      mockStateManager = TaskStateManager();
      mockOrderPersistenceService = TaskOrderPersistenceService();
    });

    tearDown(() {
      // Clean up any resources if needed
    });

    TaskListBloc createBloc() {
      return TaskListBloc(
        taskService: mockTaskService,
        stateManager: mockStateManager,
        orderPersistenceService: mockOrderPersistenceService,
      );
    }

    group('Initial State', () {
      test('should have TaskListInitial as initial state', () {
        final bloc = createBloc();
        expect(bloc.state, equals(const TaskListInitial()));
        bloc.close();
      });
    });

    group('TaskListLoadRequested', () {
      blocTest<TaskListBloc, TaskListState>(
        'emits [Loading, Loaded] when loading tasks successfully',
        build: createBloc,
        act: (bloc) => bloc.add(const TaskListLoadRequested('test-doc-id')),
        expect: () => [
          const TaskListLoading(),
          isA<TaskListLoaded>(),
        ],
      );

      blocTest<TaskListBloc, TaskListState>(
        'emits [Loading, Loaded] with correct document tasks',
        build: createBloc,
        act: (bloc) => bloc.add(const TaskListLoadRequested('test-doc-id')),
        expect: () => [
          const TaskListLoading(),
          isA<TaskListLoaded>()
              .having((state) => state.tasks, 'tasks', isA<List<Task>>())
              .having((state) => state.rawTasks, 'rawTasks', isA<List<Task>>())
              .having(
                  (state) => state.filterConfig, 'filterConfig', isNotNull),
        ],
      );
    });

    group('TaskListFilterChanged', () {
      blocTest<TaskListBloc, TaskListState>(
        'emits new state with updated filter config',
        build: createBloc,
        seed: () => TaskListLoaded(
          tasks: [],
          rawTasks: [],
          filterConfig: const FilterSortConfig(),
        ),
        act: (bloc) => bloc.add(
          TaskListFilterChanged(
            FilterSortConfig(
              priorities: {TaskPriority.high},
            ),
          ),
        ),
        expect: () => [
          isA<TaskListLoaded>().having(
            (state) => state.filterConfig.priorities,
            'priorities',
            {TaskPriority.high},
          ),
        ],
      );

      blocTest<TaskListBloc, TaskListState>(
        'filters tasks based on priority',
        build: createBloc,
        seed: () {
          final now = DateTime.now();
          return TaskListLoaded(
            tasks: [
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
            ],
            rawTasks: [
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
            ],
          );
        },
        act: (bloc) => bloc.add(
          TaskListFilterChanged(
            FilterSortConfig(
              priorities: {TaskPriority.high},
            ),
          ),
        ),
        expect: () => [
          isA<TaskListLoaded>()
              .having((state) => state.tasks.length, 'filtered tasks', 1)
              .having(
                  (state) => state.tasks.first.priority, 'priority', TaskPriority.high),
        ],
      );
    });

    group('TaskListTaskCreationStarted', () {
      blocTest<TaskListBloc, TaskListState>(
        'sets isCreatingTask to true',
        build: createBloc,
        seed: () => TaskListLoaded(
          tasks: [],
          rawTasks: [],
          isCreatingTask: false,
        ),
        act: (bloc) => bloc.add(const TaskListTaskCreationStarted()),
        expect: () => [
          isA<TaskListLoaded>().having(
            (state) => state.isCreatingTask,
            'isCreatingTask',
            true,
          ),
        ],
      );
    });

    group('TaskListTaskCreationCompleted', () {
      blocTest<TaskListBloc, TaskListState>(
        'sets isCreatingTask to false',
        build: createBloc,
        seed: () => TaskListLoaded(
          tasks: [],
          rawTasks: [],
          isCreatingTask: true,
        ),
        act: (bloc) => bloc.add(const TaskListTaskCreationCompleted()),
        expect: () => [
          isA<TaskListLoaded>().having(
            (state) => state.isCreatingTask,
            'isCreatingTask',
            false,
          ),
        ],
      );
    });

    group('TaskListReorderModeToggled', () {
      blocTest<TaskListBloc, TaskListState>(
        'toggles reorder mode on',
        build: createBloc,
        seed: () => TaskListLoaded(
          tasks: [],
          rawTasks: [],
          isReorderMode: false,
        ),
        act: (bloc) => bloc.add(const TaskListReorderModeToggled(true)),
        expect: () => [
          isA<TaskListLoaded>().having(
            (state) => state.isReorderMode,
            'isReorderMode',
            true,
          ),
        ],
      );

      blocTest<TaskListBloc, TaskListState>(
        'toggles reorder mode off',
        build: createBloc,
        seed: () => TaskListLoaded(
          tasks: [],
          rawTasks: [],
          isReorderMode: true,
        ),
        act: (bloc) => bloc.add(const TaskListReorderModeToggled(false)),
        expect: () => [
          isA<TaskListLoaded>().having(
            (state) => state.isReorderMode,
            'isReorderMode',
            false,
          ),
        ],
      );
    });

    group('TaskListTaskReordered', () {
      blocTest<TaskListBloc, TaskListState>(
        'reorders tasks correctly',
        build: createBloc,
        seed: () {
          final now = DateTime.now();
          return TaskListLoaded(
            tasks: [
              Task(
                id: 'task-1',
                documentId: 'doc-1',
                title: 'First task',
                status: TaskStatus.pending,
                priority: TaskPriority.medium,
                position: 0,
                createdAt: now,
                updatedAt: now,
              ),
              Task(
                id: 'task-2',
                documentId: 'doc-1',
                title: 'Second task',
                status: TaskStatus.pending,
                priority: TaskPriority.medium,
                position: 1,
                createdAt: now,
                updatedAt: now,
              ),
              Task(
                id: 'task-3',
                documentId: 'doc-1',
                title: 'Third task',
                status: TaskStatus.pending,
                priority: TaskPriority.medium,
                position: 2,
                createdAt: now,
                updatedAt: now,
              ),
            ],
            rawTasks: [],
          );
        },
        act: (bloc) =>
            bloc.add(const TaskListTaskReordered(oldIndex: 0, newIndex: 2)),
        expect: () => [
          isA<TaskListLoaded>()
              .having((state) => state.tasks.length, 'task count', 3)
              .having((state) => state.tasks[0].id, 'first task id', 'task-2')
              .having((state) => state.tasks[1].id, 'second task id', 'task-3')
              .having((state) => state.tasks[2].id, 'third task id', 'task-1'),
        ],
      );
    });

    group('TaskListRefreshRequested', () {
      blocTest<TaskListBloc, TaskListState>(
        'refreshes tasks from service',
        build: createBloc,
        seed: () => TaskListLoaded(
          tasks: [],
          rawTasks: [],
        ),
        act: (bloc) {
          // First load to set document ID
          bloc.add(const TaskListLoadRequested('test-doc-id'));
          return bloc.stream.first.then((_) {
            bloc.add(const TaskListRefreshRequested());
          });
        },
        skip: 2, // Skip Loading and first Loaded state
        expect: () => [
          isA<TaskListLoaded>(),
        ],
      );
    });

    group('Edge Cases', () {
      blocTest<TaskListBloc, TaskListState>(
        'handles empty task list',
        build: createBloc,
        act: (bloc) => bloc.add(const TaskListLoadRequested('empty-doc-id')),
        expect: () => [
          const TaskListLoading(),
          isA<TaskListLoaded>().having(
            (state) => state.tasks,
            'tasks',
            isEmpty,
          ),
        ],
      );

      blocTest<TaskListBloc, TaskListState>(
        'handles filter with no matching tasks',
        build: createBloc,
        seed: () {
          final now = DateTime.now();
          return TaskListLoaded(
            tasks: [
              Task(
                id: 'task-1',
                documentId: 'doc-1',
                title: 'Low priority task',
                status: TaskStatus.pending,
                priority: TaskPriority.low,
                position: 0,
                createdAt: now,
                updatedAt: now,
              ),
            ],
            rawTasks: [
              Task(
                id: 'task-1',
                documentId: 'doc-1',
                title: 'Low priority task',
                status: TaskStatus.pending,
                priority: TaskPriority.low,
                position: 0,
                createdAt: now,
                updatedAt: now,
              ),
            ],
          );
        },
        act: (bloc) => bloc.add(
          TaskListFilterChanged(
            FilterSortConfig(
              priorities: {TaskPriority.high},
            ),
          ),
        ),
        expect: () => [
          isA<TaskListLoaded>().having(
            (state) => state.tasks,
            'filtered tasks',
            isEmpty,
          ),
        ],
      );
    });

    group('State Persistence', () {
      test('TaskListLoaded copyWith preserves unmodified fields', () {
        final now = DateTime.now();
        final original = TaskListLoaded(
          tasks: [
            Task(
              id: 'task-1',
              documentId: 'doc-1',
              title: 'Test task',
              status: TaskStatus.pending,
              priority: TaskPriority.medium,
              position: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          rawTasks: [],
          filterConfig: const FilterSortConfig(),
          isReorderMode: true,
          isCreatingTask: false,
        );

        final copied = original.copyWith(isCreatingTask: true);

        expect(copied.tasks, equals(original.tasks));
        expect(copied.rawTasks, equals(original.rawTasks));
        expect(copied.filterConfig, equals(original.filterConfig));
        expect(copied.isReorderMode, equals(original.isReorderMode));
        expect(copied.isCreatingTask, isTrue);
      });
    });
  });
}
