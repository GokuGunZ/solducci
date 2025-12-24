import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/blocs/tag/tag_event.dart';
import 'package:solducci/blocs/tag/tag_state.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/utils/task_filter_sort.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// BLoC for managing tag-filtered task lists
class TagBloc extends Bloc<TagEvent, TagState> {
  final TaskService _taskService;

  String? _currentTagId;
  bool _includeCompleted = false;

  TagBloc({
    required TaskService taskService,
  })  : _taskService = taskService,
        super(const TagInitial()) {
    on<TagLoadRequested>(_onLoadRequested);
    on<TagFilterChanged>(_onFilterChanged);
    on<TagRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    TagLoadRequested event,
    Emitter<TagState> emit,
  ) async {
    emit(const TagLoading());

    try {
      _currentTagId = event.tagId;
      _includeCompleted = event.includeCompleted;

      AppLogger.debug('📦 TagBloc: Loading tasks for tag ${event.tagId}');

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

        emit(currentState.copyWith(
          tasks: filteredTasks,
          rawTasks: tasks,
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
}
