import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/blocs/tag/tag_event.dart';
import 'package:solducci/blocs/tag/tag_state.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/utils/task_filter_sort.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// BLoC for managing tag-filtered task lists
class TagBloc extends Bloc<TagEvent, TagState> {
  final TaskService _taskService;
  final TaskStateManager _stateManager;

  String? _currentTagId;
  String? _currentDocumentId;
  bool _includeCompleted = false;
  StreamSubscription? _listChangesSubscription;

  TagBloc({
    required TaskService taskService,
    required TaskStateManager stateManager,
  })  : _taskService = taskService,
        _stateManager = stateManager,
        super(const TagInitial()) {
    on<TagLoadRequested>(_onLoadRequested);
    on<TagFilterChanged>(_onFilterChanged);
    on<TagRefreshRequested>(_onRefreshRequested);
    on<TagTaskCreationStarted>(_onTaskCreationStarted);
    on<TagTaskCreationCompleted>(_onTaskCreationCompleted);
  }

  Future<void> _onLoadRequested(
    TagLoadRequested event,
    Emitter<TagState> emit,
  ) async {
    emit(const TagLoading());

    try {
      _currentTagId = event.tagId;
      _currentDocumentId = event.documentId;
      _includeCompleted = event.includeCompleted;

      AppLogger.debug('📦 TagBloc: Loading tasks for tag ${event.tagId} in document ${event.documentId}');

      // Subscribe to list-level changes (add/remove/reorder)
      await _listChangesSubscription?.cancel();
      _listChangesSubscription = _stateManager.listChanges
          .where((docId) => docId == event.documentId)
          .listen((_) {
        AppLogger.debug('🔔 TagBloc: List change detected, refreshing tag view');
        add(const TagRefreshRequested());
      });

      final tasks = await _taskService.getTasksByTag(
        event.tagId,
        includeCompleted: event.includeCompleted,
      );

      AppLogger.debug('✅ TagBloc: Loaded ${tasks.length} tasks');

      emit(TagLoaded(
        tasks: tasks,
        rawTasks: tasks,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('❌ TagBloc: Error loading tasks', e, stackTrace);
      emit(TagError('Failed to load tasks: $e', e));
    }
  }

  Future<void> _onFilterChanged(
    TagFilterChanged event,
    Emitter<TagState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TagLoaded) return;

    AppLogger.debug('🔍 TagBloc: Applying filter/sort - ${event.config}');

    try {
      // Apply filters and sorting to raw tasks
      var filteredTasks = currentState.rawTasks.applyFilterSort(event.config);

      AppLogger.debug('✅ TagBloc: Filtered to ${filteredTasks.length} tasks');

      emit(currentState.copyWith(
        tasks: filteredTasks,
        filterConfig: event.config,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('❌ TagBloc: Error applying filter', e, stackTrace);
      // Keep current state on filter error
    }
  }

  Future<void> _onRefreshRequested(
    TagRefreshRequested event,
    Emitter<TagState> emit,
  ) async {
    if (_currentTagId == null) return;

    final currentState = state;

    try {
      AppLogger.debug('🔄 TagBloc: Refreshing tasks for tag $_currentTagId');

      final tasks = await _taskService.getTasksByTag(
        _currentTagId!,
        includeCompleted: _includeCompleted,
      );

      if (currentState is TagLoaded) {
        // Re-apply current filter config to refreshed tasks
        var filteredTasks = tasks.applyFilterSort(currentState.filterConfig);

        AppLogger.debug('✅ TagBloc: Refreshed ${filteredTasks.length} tasks');
        AppLogger.debug('   Current isCreatingTask: ${currentState.isCreatingTask}');

        emit(currentState.copyWith(
          tasks: filteredTasks,
          rawTasks: tasks,
          // CRITICAL: Preserve isCreatingTask state during refresh
        ));
      } else {
        emit(TagLoaded(
          tasks: tasks,
          rawTasks: tasks,
        ));
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ TagBloc: Error refreshing tasks', e, stackTrace);
      emit(TagError('Failed to refresh tasks: $e', e));
    }
  }

  void _onTaskCreationStarted(
    TagTaskCreationStarted event,
    Emitter<TagState> emit,
  ) {
    final currentState = state;
    if (currentState is! TagLoaded) return;

    AppLogger.debug('➕ TagBloc: Starting inline task creation');

    emit(currentState.copyWith(isCreatingTask: true));
  }

  void _onTaskCreationCompleted(
    TagTaskCreationCompleted event,
    Emitter<TagState> emit,
  ) {
    final currentState = state;
    if (currentState is! TagLoaded) return;

    AppLogger.debug('✅ TagBloc: Task creation completed');
    AppLogger.debug('   Current isCreatingTask: ${currentState.isCreatingTask}');
    AppLogger.debug('   Setting isCreatingTask to FALSE');

    // Hide creation row immediately for responsive UI
    emit(currentState.copyWith(isCreatingTask: false));

    AppLogger.debug('   Emitted new state with isCreatingTask=false');
  }

  @override
  Future<void> close() {
    _listChangesSubscription?.cancel();
    return super.close();
  }
}
