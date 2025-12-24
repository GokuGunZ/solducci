import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/blocs/task_list/task_list_event.dart';
import 'package:solducci/blocs/task_list/task_list_state.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/utils/task_filter_sort.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// BLoC for managing task list state
///
/// Responsibilities:
/// - Load tasks from TaskService
/// - Apply filtering and sorting
/// - Handle task reordering
/// - Manage UI state (creation mode, reorder mode)
/// - Persist custom order
///
/// Integration with TaskStateManager:
/// - BLoC handles LIST-LEVEL operations (loading, filtering, sorting)
/// - TaskStateManager handles INDIVIDUAL task updates (title, status, etc.)
/// - This preserves Sprint 6's granular rebuild optimization
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final TaskService _taskService;
  final TaskStateManager _stateManager;
  final TaskOrderPersistenceService _orderPersistenceService;

  String? _currentDocumentId;
  StreamSubscription? _listChangesSubscription;

  TaskListBloc({
    required TaskService taskService,
    required TaskStateManager stateManager,
    required TaskOrderPersistenceService orderPersistenceService,
  })  : _taskService = taskService,
        _stateManager = stateManager,
        _orderPersistenceService = orderPersistenceService,
        super(const TaskListInitial()) {
    // Register event handlers
    on<TaskListLoadRequested>(_onLoadRequested);
    on<TaskListFilterChanged>(_onFilterChanged);
    on<TaskListTaskReordered>(_onTaskReordered);
    on<TaskListTaskCreationStarted>(_onTaskCreationStarted);
    on<TaskListTaskCreationCompleted>(_onTaskCreationCompleted);
    on<TaskListRefreshRequested>(_onRefreshRequested);
    on<TaskListReorderModeToggled>(_onReorderModeToggled);
  }

  /// Load tasks for a document
  Future<void> _onLoadRequested(
    TaskListLoadRequested event,
    Emitter<TaskListState> emit,
  ) async {
    AppLogger.debug('📋 TaskListBloc: Loading tasks for document ${event.documentId}');
    emit(const TaskListLoading());

    try {
      _currentDocumentId = event.documentId;

      // Subscribe to list-level changes (add/remove/reorder)
      await _listChangesSubscription?.cancel();
      _listChangesSubscription = _stateManager.listChanges
          .where((docId) => docId == event.documentId)
          .listen((_) {
        AppLogger.debug('🔔 TaskListBloc: List change detected, refreshing');
        add(const TaskListRefreshRequested());
      });

      // Fetch tasks from service
      final tasks = await _taskService.fetchTasksForDocument(event.documentId);

      AppLogger.debug('📋 TaskListBloc: Loaded ${tasks.length} root tasks');

      // Emit loaded state
      emit(TaskListLoaded(
        tasks: tasks,
        rawTasks: tasks,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('❌ TaskListBloc: Error loading tasks', e, stackTrace);
      emit(TaskListError('Failed to load tasks: $e', e));
    }
  }

  /// Apply filter/sort configuration
  Future<void> _onFilterChanged(
    TaskListFilterChanged event,
    Emitter<TaskListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskListLoaded) {
      AppLogger.warning('TaskListBloc: Cannot filter in non-loaded state');
      return;
    }

    AppLogger.debug('🔍 TaskListBloc: Applying filters');

    try {
      List<Task> filteredTasks = currentState.rawTasks;

      // Apply async filtering (with tags) if needed
      if (event.config.tagIds.isNotEmpty) {
        filteredTasks = await filteredTasks.applyFilterSortAsync(event.config);
      } else {
        // Sync filtering (no tags)
        filteredTasks = filteredTasks.applyFilterSort(event.config);
      }

      // Apply custom order if selected
      if (event.config.sortBy == TaskSortOption.custom && _currentDocumentId != null) {
        final savedOrder = await _orderPersistenceService.loadCustomOrder(_currentDocumentId!);
        if (savedOrder != null && savedOrder.isNotEmpty) {
          filteredTasks = filteredTasks.applyCustomOrder(savedOrder);
        }
      }

      AppLogger.debug('🔍 TaskListBloc: Filtered to ${filteredTasks.length} tasks');

      emit(currentState.copyWith(
        tasks: filteredTasks,
        filterConfig: event.config,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('❌ TaskListBloc: Error filtering tasks', e, stackTrace);
      emit(TaskListError('Failed to filter tasks: $e', e));
    }
  }

  /// Handle task reordering
  Future<void> _onTaskReordered(
    TaskListTaskReordered event,
    Emitter<TaskListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;

    AppLogger.debug('🔄 TaskListBloc: Reordering task from ${event.oldIndex} to ${event.newIndex}');

    try {
      // Create new list with reordered tasks
      final reorderedTasks = List<Task>.from(currentState.tasks);
      final task = reorderedTasks.removeAt(event.oldIndex);
      reorderedTasks.insert(event.newIndex, task);

      // Persist custom order
      if (_currentDocumentId != null) {
        final taskIds = reorderedTasks.map((t) => t.id).toList();
        await _orderPersistenceService.saveCustomOrder(
          documentId: _currentDocumentId!,
          taskIds: taskIds,
        );
      }

      emit(currentState.copyWith(tasks: reorderedTasks));
    } catch (e, stackTrace) {
      AppLogger.error('❌ TaskListBloc: Error reordering tasks', e, stackTrace);
    }
  }

  /// Start task creation
  void _onTaskCreationStarted(
    TaskListTaskCreationStarted event,
    Emitter<TaskListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;

    emit(currentState.copyWith(isCreatingTask: true));
  }

  /// Complete task creation
  void _onTaskCreationCompleted(
    TaskListTaskCreationCompleted event,
    Emitter<TaskListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;

    emit(currentState.copyWith(isCreatingTask: false));

    // Trigger refresh to show new task
    add(const TaskListRefreshRequested());
  }

  /// Manual refresh
  Future<void> _onRefreshRequested(
    TaskListRefreshRequested event,
    Emitter<TaskListState> emit,
  ) async {
    if (_currentDocumentId == null) return;

    AppLogger.debug('🔄 TaskListBloc: Manual refresh requested');

    try {
      // Fetch fresh data
      final tasks = await _taskService.fetchTasksForDocument(_currentDocumentId!);

      final currentState = state;
      if (currentState is TaskListLoaded) {
        // Preserve filter config and UI state
        List<Task> filteredTasks = tasks;

        // Re-apply current filters
        if (currentState.filterConfig.tagIds.isNotEmpty) {
          filteredTasks = await filteredTasks.applyFilterSortAsync(currentState.filterConfig);
        } else {
          filteredTasks = filteredTasks.applyFilterSort(currentState.filterConfig);
        }

        // Re-apply custom order if active
        if (currentState.filterConfig.sortBy == TaskSortOption.custom) {
          final savedOrder = await _orderPersistenceService.loadCustomOrder(_currentDocumentId!);
          if (savedOrder != null && savedOrder.isNotEmpty) {
            filteredTasks = filteredTasks.applyCustomOrder(savedOrder);
          }
        }

        emit(currentState.copyWith(
          tasks: filteredTasks,
          rawTasks: tasks,
        ));
      } else {
        // First load
        emit(TaskListLoaded(
          tasks: tasks,
          rawTasks: tasks,
        ));
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ TaskListBloc: Error refreshing tasks', e, stackTrace);
    }
  }

  /// Toggle reorder mode
  void _onReorderModeToggled(
    TaskListReorderModeToggled event,
    Emitter<TaskListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;

    AppLogger.debug('🔄 TaskListBloc: Reorder mode ${event.enabled ? "enabled" : "disabled"}');

    // Auto-switch to custom sort when enabling reorder mode
    FilterSortConfig newConfig = currentState.filterConfig;
    if (event.enabled && newConfig.sortBy != TaskSortOption.custom) {
      newConfig = newConfig.copyWith(sortBy: TaskSortOption.custom);
    }

    emit(currentState.copyWith(
      isReorderMode: event.enabled,
      filterConfig: newConfig,
    ));
  }

  @override
  Future<void> close() {
    _listChangesSubscription?.cancel();
    return super.close();
  }
}
