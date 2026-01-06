import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/blocs/unified_task_list/unified_task_list_event.dart';
import 'package:solducci/blocs/unified_task_list/unified_task_list_state.dart';
import 'package:solducci/blocs/unified_task_list/task_list_data_source.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/utils/task_filter_sort.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// Unified BLoC for managing task lists from any data source
///
/// This BLoC combines the logic from TaskListBloc and TagBloc into a single,
/// reusable component that works with different data sources via the Strategy pattern.
///
/// Responsibilities:
/// - Load tasks from polymorphic data source (document, tag, etc.)
/// - Apply filtering and sorting
/// - Handle task reordering (if supported by data source)
/// - Manage UI state (creation mode, reorder mode)
/// - Persist custom order (if reordering is enabled)
///
/// Integration with TaskStateManager:
/// - BLoC handles LIST-LEVEL operations (loading, filtering, sorting)
/// - TaskStateManager handles INDIVIDUAL task updates (title, status, etc.)
/// - This preserves granular rebuild optimization
class UnifiedTaskListBloc extends Bloc<UnifiedTaskListEvent, UnifiedTaskListState> {
  final TaskOrderPersistenceService _orderPersistenceService;

  TaskListDataSource? _currentDataSource;
  StreamSubscription? _listChangesSubscription;
  bool _isReordering = false; // Flag to prevent refresh during reorder

  UnifiedTaskListBloc({
    required TaskOrderPersistenceService orderPersistenceService,
  })  : _orderPersistenceService = orderPersistenceService,
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

  /// Load tasks from the specified data source
  Future<void> _onLoadRequested(
    TaskListLoadRequested event,
    Emitter<UnifiedTaskListState> emit,
  ) async {
    AppLogger.debug('📋 UnifiedTaskListBloc: Loading tasks from ${event.dataSource.identifier}');
    emit(const TaskListLoading());

    try {
      _currentDataSource = event.dataSource;

      // Subscribe to list-level changes (add/remove/reorder)
      await _listChangesSubscription?.cancel();
      _listChangesSubscription = event.dataSource.listChanges.listen((_) {
        // Ignore changes during manual reordering to prevent flash
        if (_isReordering) {
          AppLogger.debug('🔔 UnifiedTaskListBloc: List change detected during reorder, ignoring');
          return;
        }
        AppLogger.debug('🔔 UnifiedTaskListBloc: List change detected, refreshing');
        add(const TaskListRefreshRequested());
      });

      // Fetch tasks from data source
      final tasks = await event.dataSource.loadTasks();

      AppLogger.debug('📋 UnifiedTaskListBloc: Loaded ${tasks.length} tasks');

      // Determine if this data source supports reordering
      // Both DocumentTaskDataSource and TagTaskDataSource support reordering
      final supportsReordering = event.dataSource is DocumentTaskDataSource ||
          event.dataSource is TagTaskDataSource;

      // Emit loaded state
      emit(TaskListLoaded(
        tasks: tasks,
        rawTasks: tasks,
        supportsReordering: supportsReordering,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('❌ UnifiedTaskListBloc: Error loading tasks', e, stackTrace);
      emit(TaskListError('Failed to load tasks: $e', e));
    }
  }

  /// Apply filter/sort configuration
  Future<void> _onFilterChanged(
    TaskListFilterChanged event,
    Emitter<UnifiedTaskListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskListLoaded) {
      AppLogger.warning('UnifiedTaskListBloc: Cannot filter in non-loaded state');
      return;
    }

    AppLogger.debug('🔍 UnifiedTaskListBloc: Applying filters');

    try {
      List<Task> filteredTasks = currentState.rawTasks;

      // Apply async filtering (with tags) if needed
      if (event.config.tagIds.isNotEmpty) {
        filteredTasks = await filteredTasks.applyFilterSortAsync(event.config);
      } else {
        // Sync filtering (no tags)
        filteredTasks = filteredTasks.applyFilterSort(event.config);
      }

      // Apply custom order if selected and supported
      if (event.config.sortBy == TaskSortOption.custom &&
          currentState.supportsReordering) {
        final documentId = _getDocumentId();
        if (documentId != null) {
          final savedOrder = await _orderPersistenceService.loadCustomOrder(documentId);
          if (savedOrder != null && savedOrder.isNotEmpty) {
            filteredTasks = filteredTasks.applyCustomOrder(savedOrder);
          }
        }
      }

      AppLogger.debug('🔍 UnifiedTaskListBloc: Filtered to ${filteredTasks.length} tasks');

      emit(currentState.copyWith(
        tasks: filteredTasks,
        filterConfig: event.config,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('❌ UnifiedTaskListBloc: Error filtering tasks', e, stackTrace);
      emit(TaskListError('Failed to filter tasks: $e', e));
    }
  }

  /// Handle task reordering (drag-and-drop)
  Future<void> _onTaskReordered(
    TaskListTaskReordered event,
    Emitter<UnifiedTaskListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;
    if (!currentState.supportsReordering) {
      AppLogger.warning('UnifiedTaskListBloc: Reordering not supported for this data source');
      return;
    }

    AppLogger.debug('🔄 UnifiedTaskListBloc: Reordering task from ${event.oldIndex} to ${event.newIndex}');

    try {
      // Set flag to prevent refresh during reorder
      _isReordering = true;

      // Create new list with reordered tasks
      final reorderedTasks = List<Task>.from(currentState.tasks);
      final task = reorderedTasks.removeAt(event.oldIndex);
      reorderedTasks.insert(event.newIndex, task);

      // Persist custom order (for DocumentTaskDataSource and TagTaskDataSource)
      final documentId = _getDocumentId();
      if (documentId != null) {
        final taskIds = reorderedTasks.map((t) => t.id).toList();
        await _orderPersistenceService.saveCustomOrder(
          documentId: documentId,
          taskIds: taskIds,
        );
      }

      emit(currentState.copyWith(tasks: reorderedTasks));

      // Reset flag after a short delay to allow persistence to complete
      await Future.delayed(const Duration(milliseconds: 100));
      _isReordering = false;
    } catch (e, stackTrace) {
      _isReordering = false; // Reset flag on error
      AppLogger.error('❌ UnifiedTaskListBloc: Error reordering tasks', e, stackTrace);
    }
  }

  /// Start task creation
  void _onTaskCreationStarted(
    TaskListTaskCreationStarted event,
    Emitter<UnifiedTaskListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;

    AppLogger.debug('➕ UnifiedTaskListBloc: Starting inline task creation');
    emit(currentState.copyWith(isCreatingTask: true));
  }

  /// Complete task creation
  void _onTaskCreationCompleted(
    TaskListTaskCreationCompleted event,
    Emitter<UnifiedTaskListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;

    AppLogger.debug('✅ UnifiedTaskListBloc: Task creation completed');
    AppLogger.debug('   Current isCreatingTask: ${currentState.isCreatingTask}');
    AppLogger.debug('   Setting isCreatingTask to FALSE');

    emit(currentState.copyWith(isCreatingTask: false));

    AppLogger.debug('   Emitted new state with isCreatingTask=false');
  }

  /// Manual refresh
  Future<void> _onRefreshRequested(
    TaskListRefreshRequested event,
    Emitter<UnifiedTaskListState> emit,
  ) async {
    if (_currentDataSource == null) return;

    AppLogger.debug('🔄 UnifiedTaskListBloc: Manual refresh requested');

    try {
      // Fetch fresh data from current data source
      final tasks = await _currentDataSource!.loadTasks();

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
        if (currentState.filterConfig.sortBy == TaskSortOption.custom &&
            currentState.supportsReordering) {
          final documentId = _getDocumentId();
          if (documentId != null) {
            final savedOrder = await _orderPersistenceService.loadCustomOrder(documentId);
            if (savedOrder != null && savedOrder.isNotEmpty) {
              filteredTasks = filteredTasks.applyCustomOrder(savedOrder);
            }
          }
        }

        AppLogger.debug('✅ UnifiedTaskListBloc: Refreshed ${filteredTasks.length} tasks');
        AppLogger.debug('   Current isCreatingTask: ${currentState.isCreatingTask}');

        emit(currentState.copyWith(
          tasks: filteredTasks,
          rawTasks: tasks,
          // CRITICAL: Preserve isCreatingTask state during refresh
        ));
      } else {
        // First load
        emit(TaskListLoaded(
          tasks: tasks,
          rawTasks: tasks,
          supportsReordering: _currentDataSource is DocumentTaskDataSource ||
              _currentDataSource is TagTaskDataSource,
        ));
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ UnifiedTaskListBloc: Error refreshing tasks', e, stackTrace);
    }
  }

  /// Toggle reorder mode
  void _onReorderModeToggled(
    TaskListReorderModeToggled event,
    Emitter<UnifiedTaskListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TaskListLoaded) return;
    if (!currentState.supportsReordering) {
      AppLogger.warning('UnifiedTaskListBloc: Reorder mode not supported for this data source');
      return;
    }

    AppLogger.debug('🔄 UnifiedTaskListBloc: Reorder mode ${event.enabled ? "enabled" : "disabled"}');

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

  /// Helper to get document ID from current data source
  String? _getDocumentId() {
    if (_currentDataSource is DocumentTaskDataSource) {
      return (_currentDataSource as DocumentTaskDataSource).documentId;
    } else if (_currentDataSource is TagTaskDataSource) {
      return (_currentDataSource as TagTaskDataSource).documentId;
    }
    return null;
  }
}
