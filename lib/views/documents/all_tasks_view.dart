import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/utils/task_filter_sort.dart';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/blocs/task_list/task_list_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';

/// View showing all tasks (pending + in progress + assigned) for a document
///
/// Architecture - Granular Rebuild System:
/// - Uses TaskStateManager with individual ValueNotifiers per task
/// - When a task is updated, ONLY that specific TaskListItem rebuilds
/// - List-level changes (add/remove) trigger stream recreation
/// - Filter UI updates instantly without affecting task rendering
/// - Each task wrapped in _GranularTaskListItem with ValueListenableBuilder
/// - Result: Maximum performance, minimal unnecessary rebuilds
class AllTasksView extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags; // Optional: tags for filtering

  const AllTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<TaskListBloc>();
        bloc.add(TaskListLoadRequested(document.id));
        return bloc;
      },
      child: _AllTasksViewContent(
        document: document,
        showAllPropertiesNotifier: showAllPropertiesNotifier,
        onInlineCreationCallbackChanged: onInlineCreationCallbackChanged,
        availableTags: availableTags,
      ),
    );
  }
}

// New wrapper widget for content
class _AllTasksViewContent extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

  const _AllTasksViewContent({
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  State<_AllTasksViewContent> createState() => _AllTasksViewContentState();
}

class _AllTasksViewContentState extends State<_AllTasksViewContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _orderPersistenceService = TaskOrderPersistenceService();

  @override
  void initState() {
    super.initState();
    // Stream management removed - BLoC handles data loading

    // Pass the inline creation callback to parent
    widget.onInlineCreationCallbackChanged?.call(startInlineCreation);
  }

  // Stream management methods removed - BLoC handles all data loading and refreshing

  /// Handle manual reordering via drag-and-drop
  void _handleManualReorder(List<Task> newOrder) async {
    AppLogger.debug('🔄 Manual reorder detected');

    // Persist custom order locally (no UI update needed, list already reordered)
    final taskIds = newOrder.map((task) => task.id).toList();
    await _orderPersistenceService.saveCustomOrder(
      documentId: widget.document.id,
      taskIds: taskIds,
    );

    AppLogger.debug('✅ Custom order saved: ${taskIds.length} tasks');
  }

  @override
  void dispose() {
    // BLoC handles all cleanup automatically
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Filter bar - reads from BLoC state
        BlocBuilder<TaskListBloc, TaskListState>(
          builder: (context, state) {
            final filterConfig = state is TaskListLoaded
                ? state.filterConfig
                : const FilterSortConfig();

            return CompactFilterSortBar(
              key: const ValueKey('compact_filter_sort_bar'),
              filterConfig: filterConfig,
              onFilterChanged: (newConfig) {
                // Dispatch filter change event to BLoC
                context.read<TaskListBloc>().add(TaskListFilterChanged(newConfig));
              },
              availableTags: widget.availableTags,
            );
          },
        ),

        // Task list section - rebuilds independently when filter changes
        Expanded(
          child: _TaskListSection(
            document: widget.document,
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            onCancelCreation: () {
              // Dispatch event to BLoC to cancel creation
              context.read<TaskListBloc>().add(const TaskListTaskCreationCompleted());
            },
            onTaskCreated: () async {
              AppLogger.debug('🎯 onTaskCreated callback START');

              // Dispatch refresh event to BLoC to reload tasks
              AppLogger.debug('🔄 Dispatching TaskListRefreshRequested to BLoC');
              context.read<TaskListBloc>().add(const TaskListRefreshRequested());

              // Close the creation row via BLoC
              AppLogger.debug('✅ Dispatching TaskListTaskCreationCompleted');
              context.read<TaskListBloc>().add(const TaskListTaskCreationCompleted());

              AppLogger.debug('🎯 onTaskCreated callback END');
            },
            onShowTaskDetails: _showTaskDetails,
            onManualReorder: _handleManualReorder,
          ),
        ),
      ],
    );
  }

  void startInlineCreation() {
    // Dispatch event to BLoC to start task creation
    context.read<TaskListBloc>().add(const TaskListTaskCreationStarted());
  }

  void _showTaskDetails(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(
          document: widget.document,
          task: task,
          showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
        ),
      ),
    );
  }
}

/// Separate widget for task list that reads filter config from BLoC
class _TaskListSection extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final void Function(List<Task> newOrder)? onManualReorder;

  const _TaskListSection({
    required this.document,
    this.showAllPropertiesNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
    this.onManualReorder,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ [1] _TaskListSection.build() called');
    // Read filter config from BLoC state
    return BlocBuilder<TaskListBloc, TaskListState>(
      buildWhen: (previous, current) {
        // Only rebuild when filter config changes
        if (previous is TaskListLoaded && current is TaskListLoaded) {
          return previous.filterConfig != current.filterConfig;
        }
        return true;
      },
      builder: (context, state) {
        final filterConfig = state is TaskListLoaded
            ? state.filterConfig
            : const FilterSortConfig();

        AppLogger.debug('🏗️ [2] BlocBuilder for filter - sortBy: ${filterConfig.sortBy}, hasFilters: ${filterConfig.hasFilters}');
        return _AnimatedTaskListBuilder(
          // Use a constant key to preserve state when filterConfig changes
          // This prevents the widget from being recreated and losing _isFirstLoad state
          key: ValueKey('animated_task_list_builder_${document.id}'),
          filterConfig: filterConfig,
          document: document,
          showAllPropertiesNotifier: showAllPropertiesNotifier,
          onCancelCreation: onCancelCreation,
          onTaskCreated: onTaskCreated,
          onShowTaskDetails: onShowTaskDetails,
          onManualReorder: onManualReorder,
        );
      },
    );
  }
}

/// StatefulWidget that manages AnimatedList and BLoC state synchronization
class _AnimatedTaskListBuilder extends StatefulWidget {
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final void Function(List<Task> newOrder)? onManualReorder; // Callback for drag-and-drop reorder

  const _AnimatedTaskListBuilder({
    super.key,
    required this.filterConfig,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
    this.onManualReorder,
  });

  @override
  State<_AnimatedTaskListBuilder> createState() => _AnimatedTaskListBuilderState();
}

class _AnimatedTaskListBuilderState extends State<_AnimatedTaskListBuilder> {
  late GlobalKey<AnimatedListState> _listKey; // Kept constant for AnimatedReorderableListView
  List<Task> _displayedTasks = [];
  List<Task>? _rawTasks; // Cache raw unfiltered data for re-filtering
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('🎬 [INIT] _AnimatedTaskListBuilderState.initState() - Creating new instance!');
    _listKey = GlobalKey<AnimatedListState>(); // Initialize GlobalKey
    // Stream subscription replaced with BLocListener in build method
  }

  @override
  void didUpdateWidget(_AnimatedTaskListBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect filter or sort config changes
    if (widget.filterConfig != oldWidget.filterConfig) {
      final filterChanged = _hasFilterChanged(oldWidget.filterConfig, widget.filterConfig);
      final sortChanged = _hasSortChanged(oldWidget.filterConfig, widget.filterConfig);

      AppLogger.debug('🔄 Filter config changed');
      AppLogger.debug('   Filter changed: $filterChanged, Sort changed: $sortChanged');
      AppLogger.debug('   Old config: priorities=${oldWidget.filterConfig.priorities.length}, '
            'statuses=${oldWidget.filterConfig.statuses.length}, '
            'sortBy=${oldWidget.filterConfig.sortBy}');
      AppLogger.debug('   New config: priorities=${widget.filterConfig.priorities.length}, '
            'statuses=${widget.filterConfig.statuses.length}, '
            'sortBy=${widget.filterConfig.sortBy}');

      // Re-apply filters to cached raw data
      if (_rawTasks != null) {
        _applyFiltersToRawData(
          _rawTasks!,
          isFilterChange: filterChanged,
          isSortOnlyChange: sortChanged && !filterChanged,
        );
      }
    }
  }

  /// Detects if filter configuration changed (excluding sort)
  bool _hasFilterChanged(FilterSortConfig old, FilterSortConfig newConfig) {
    return old.priorities != newConfig.priorities ||
           old.statuses != newConfig.statuses ||
           old.sizes != newConfig.sizes ||
           old.tagIds != newConfig.tagIds ||
           old.dateFilter != newConfig.dateFilter ||
           old.showOverdueOnly != newConfig.showOverdueOnly;
  }

  /// Detects if only sort configuration changed
  bool _hasSortChanged(FilterSortConfig old, FilterSortConfig newConfig) {
    return old.sortBy != newConfig.sortBy ||
           old.sortAscending != newConfig.sortAscending;
  }

  @override
  void dispose() {
    // Stream subscription removed - BLoC handles cleanup automatically
    _rawTasks = null; // Clear cache
    super.dispose();
  }

  void _onNewData(List<Task> allTasks) {
    AppLogger.debug('📦 _onNewData received ${allTasks.length} tasks');
    _rawTasks = allTasks; // Cache raw data for re-filtering
    _applyFiltersToRawData(allTasks);
  }

  void _applyFiltersToRawData(
    List<Task> allTasks, {
    bool isFilterChange = false,
    bool isSortOnlyChange = false,
  }) async {
    AppLogger.debug('🔍 Applying filters to ${allTasks.length} tasks');
    AppLogger.debug('   isFilterChange: $isFilterChange, isSortOnlyChange: $isSortOnlyChange');
    AppLogger.debug('   Filter config: priorities=${widget.filterConfig.priorities}, '
          'statuses=${widget.filterConfig.statuses}, '
          'sizes=${widget.filterConfig.sizes}, '
          'dateFilter=${widget.filterConfig.dateFilter}, '
          'sortBy=${widget.filterConfig.sortBy}');

    var tasks = allTasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();

    AppLogger.debug('   After completion filter: ${tasks.length} tasks');

    // Apply filters and sorting
    if (widget.filterConfig.tagIds.isNotEmpty) {
      AppLogger.debug('   Applying async filter (tags: ${widget.filterConfig.tagIds.length})');
      tasks = await tasks.applyFilterSortAsync(widget.filterConfig);
      AppLogger.debug('   Async filter result: ${tasks.length} tasks');
    } else {
      tasks = tasks.applyFilterSort(widget.filterConfig);
      AppLogger.debug('   After sync filter+sort: ${tasks.length} tasks');
    }

    // Apply custom order if selected
    if (widget.filterConfig.sortBy == TaskSortOption.custom) {
      final orderPersistenceService = TaskOrderPersistenceService();
      final savedOrder = await orderPersistenceService.loadCustomOrder(widget.document.id);

      if (savedOrder != null && savedOrder.isNotEmpty) {
        tasks = tasks.applyCustomOrder(savedOrder);
        AppLogger.debug('   Applied custom order: ${savedOrder.length} task IDs');
      } else {
        AppLogger.debug('   No custom order found, using default order');
      }
    }

    _updateDisplayedTasks(
      tasks,
      isFilterChange: isFilterChange,
      isSortOnlyChange: isSortOnlyChange,
    );
  }

  void _updateDisplayedTasks(
    List<Task> newTasks, {
    bool isFilterChange = false,
    bool isSortOnlyChange = false,
  }) {
    if (_isFirstLoad) {
      AppLogger.debug('🎯 [FIRST LOAD] Setting _isFirstLoad = false, tasks=${newTasks.length}');
      setState(() {
        _displayedTasks = newTasks;
        _isFirstLoad = false;
      });
      AppLogger.debug('✅ [FIRST LOAD] First load complete, _isFirstLoad=$_isFirstLoad');
      return;
    }

    // SORT-ONLY CHANGE: Animate reorder with AnimatedSwitcher
    if (isSortOnlyChange && !isFilterChange) {
      AppLogger.debug('🔄 Animating reorder: ${_displayedTasks.length} tasks');
      _animateReorder(newTasks);
      return;
    }

    // FILTER CHANGE: Batch update without incremental animations
    // This prevents the "one task at a time" removal issue
    if (isFilterChange) {
      AppLogger.debug('📋 Batch update for filter change: ${_displayedTasks.length} → ${newTasks.length} tasks');
      setState(() {
        _displayedTasks = newTasks;
      });

      // Update all task notifiers recursively
      final stateManager = TaskStateManager();
      for (final task in newTasks) {
        stateManager.updateTaskRecursively(task);
      }
      return;
    }

    // Existing incremental logic for stream updates (single task add/remove)
    // Granular diff - find exact changes
    final newTaskIds = newTasks.map((t) => t.id).toList();
    final oldTaskIds = _displayedTasks.map((t) => t.id).toList();

    // Find insertions
    for (int i = 0; i < newTasks.length; i++) {
      if (i >= _displayedTasks.length || newTasks[i].id != _displayedTasks[i].id) {
        final taskId = newTasks[i].id;
        if (!oldTaskIds.contains(taskId)) {
          // New task - insert with animation
          _displayedTasks.insert(i, newTasks[i]);
          _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 400));

          // CRITICAL: Ensure all OTHER tasks have updated notifiers too
          // (the new task will get its notifier in initState)
          final stateManager = TaskStateManager();
          for (final task in newTasks) {
            if (task.id != taskId) {
              stateManager.updateTask(task);
            }
          }

          return; // Handle one change at a time
        }
      }
    }

    // Find deletions
    for (int i = _displayedTasks.length - 1; i >= 0; i--) {
      final taskId = _displayedTasks[i].id;
      if (!newTaskIds.contains(taskId)) {
        _displayedTasks.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: Container(), // Placeholder for removed item
            ),
          ),
          duration: const Duration(milliseconds: 300),
        );
        return; // Handle one change at a time
      }
    }

    // No structural changes - but we still need to update task notifiers!
    // OPTIMIZED: Only update tasks that actually changed (prevents unnecessary rebuilds)
    final stateManager = TaskStateManager();
    final changedTaskIds = <String>{};

    for (final newTask in newTasks) {
      // Check if task exists and has changed
      final existingValue = stateManager.getTaskValue(newTask.id);
      if (existingValue == null || existingValue != newTask) {
        // Task is new or changed - update it
        stateManager.updateTask(newTask);
        changedTaskIds.add(newTask.id);
      }
    }

    // Only recursively update subtasks of changed parents
    for (final taskId in changedTaskIds) {
      final task = newTasks.firstWhere((t) => t.id == taskId);
      if (task.subtasks != null && task.subtasks!.isNotEmpty) {
        // Update subtasks recursively only for changed parents
        stateManager.updateTaskRecursively(task);
      }
    }
  }

  /// Animates reorder by updating the list and letting AnimatedReorderableListView handle it
  /// Similar to TagView approach - update list with setState but WITHOUT recreating keys
  void _animateReorder(List<Task> newTasks) {
    AppLogger.debug('🎬 Smooth reorder animation: ${_displayedTasks.length} → ${newTasks.length} tasks');

    // Update the list with setState - this triggers rebuild but AnimatedReorderableListView
    // detects the change and animates items from old position to new position
    // CRITICAL: We do NOT recreate _listKey, keeping the same AnimatedList instance
    setState(() {
      _displayedTasks = newTasks;
    });

    // Update task notifiers AFTER build completes to avoid setState during build
    // OPTIMIZED: Only update changed tasks to prevent unnecessary rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateManager = TaskStateManager();
      final changedTaskIds = <String>{};

      for (final task in newTasks) {
        final existingValue = stateManager.getTaskValue(task.id);
        if (existingValue == null || existingValue != task) {
          stateManager.updateTask(task);
          changedTaskIds.add(task.id);
        }
      }

      // Only recursively update subtasks of changed parents
      for (final taskId in changedTaskIds) {
        final task = newTasks.firstWhere((t) => t.id == taskId);
        if (task.subtasks != null && task.subtasks!.isNotEmpty) {
          stateManager.updateTaskRecursively(task);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ [3] _AnimatedTaskListBuilderState.build() - _isFirstLoad=$_isFirstLoad, tasks=${_displayedTasks.length}');

    // Use BlocListener to listen for state changes (replaces stream subscription)
    return BlocListener<TaskListBloc, TaskListState>(
      listener: (context, state) {
        // When BLoC emits TaskListLoaded, update displayed tasks
        if (state is TaskListLoaded) {
          _onNewData(state.tasks);
        }
      },
      child: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) {
          return switch (state) {
            TaskListInitial() => const SizedBox.shrink(),

            TaskListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),

            TaskListError(:final message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading tasks'),
                  const SizedBox(height: 8),
                  Text(message, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TaskListBloc>()
                        .add(const TaskListRefreshRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

            TaskListLoaded() => _isFirstLoad
              ? const Center(child: CircularProgressIndicator())
              : _TaskListContent(
                  listKey: _listKey,
                  tasks: _displayedTasks,
                  filterConfig: widget.filterConfig,
                  document: widget.document,
                  showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                  onCancelCreation: widget.onCancelCreation,
                  onTaskCreated: widget.onTaskCreated,
                  onShowTaskDetails: widget.onShowTaskDetails,
                  onManualReorder: widget.onManualReorder,
                ),
          };
        },
      ),
    );
  }
}

/// Content widget with preloaded tags
class _TaskListContent extends StatelessWidget {
  final GlobalKey<AnimatedListState> listKey;
  final List<Task> tasks;
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final void Function(List<Task> newOrder)? onManualReorder;

  const _TaskListContent({
    required this.listKey,
    required this.tasks,
    required this.filterConfig,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
    this.onManualReorder,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ [4] _TaskListContent.build() - tasks=${tasks.length}');

    // CRITICAL FIX: Tags are already preloaded in TaskStateManager
    // We don't need to fetch them again here - that was causing the CircularProgressIndicator!
    // Just use an empty map for now - tags will be loaded by TaskListItem if needed
    final taskTagsMap = <String, List<Tag>>{};

    AppLogger.debug('✅ [4a] Building _TaskList with ${tasks.length} tasks');
    return _TaskList(
      listKey: listKey,
      tasks: tasks,
      filterConfig: filterConfig,
      document: document,
      showAllPropertiesNotifier: showAllPropertiesNotifier,
      onCancelCreation: onCancelCreation,
      onTaskCreated: onTaskCreated,
      onShowTaskDetails: onShowTaskDetails,
      taskTagsMap: taskTagsMap,
      onManualReorder: onManualReorder,
    );
  }
}

/// Final widget that renders the actual list using AnimatedReorderableListView
/// Reads creation state from BLoC to rebuild when creation state changes
class _TaskList extends StatefulWidget {
  final GlobalKey<AnimatedListState> listKey;
  final List<Task> tasks;
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final Map<String, List<Tag>> taskTagsMap;
  final void Function(List<Task> newOrder)? onManualReorder;

  const _TaskList({
    required this.listKey,
    required this.tasks,
    required this.filterConfig,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
    required this.taskTagsMap,
    this.onManualReorder,
  });

  @override
  State<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<_TaskList> {
  // Local copy of tasks for immediate reordering without waiting for parent rebuild
  late List<Task> _displayedTasks;

  @override
  void initState() {
    super.initState();
    _displayedTasks = widget.tasks;
  }

  @override
  void didUpdateWidget(_TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local tasks when parent provides new task list
    // AnimatedReorderableListView will automatically detect changes and animate
    _displayedTasks = widget.tasks;
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ [5] _TaskListState.build() - _displayedTasks.length=${_displayedTasks.length}');
    // Read creation state from BLoC - only rebuilds when creation state changes
    return BlocBuilder<TaskListBloc, TaskListState>(
      buildWhen: (previous, current) {
        // Only rebuild when isCreatingTask changes
        if (previous is TaskListLoaded && current is TaskListLoaded) {
          return previous.isCreatingTask != current.isCreatingTask;
        }
        return true;
      },
      builder: (context, state) {
        final isCreatingTask = state is TaskListLoaded ? state.isCreatingTask : false;
        AppLogger.debug('🏗️ [6] BlocBuilder for isCreatingTask - value=$isCreatingTask');
        // Empty state
        if (_displayedTasks.isEmpty && !isCreatingTask) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.filterConfig.hasFilters
                      ? Icons.filter_alt_off
                      : Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.filterConfig.hasFilters
                      ? 'Nessuna task trovata'
                      : 'Nessuna task',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.filterConfig.hasFilters
                      ? 'Prova a cambiare i filtri'
                      : 'Aggiungi la tua prima task!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Use AnimatedReorderableListView for smooth tile-sliding animations
        // Items slide from old position → new position when sorting changes
        // Also supports manual drag-and-drop reordering with long-press
        return Column(
          children: [
            // Inline task creation row (appears at top when creating)
            if (isCreatingTask)
              TaskCreationRow(
                document: widget.document,
                onCancel: widget.onCancelCreation,
                onTaskCreated: widget.onTaskCreated,
              ),

            // Task list
            Expanded(
              child: AnimatedReorderableListView<Task>(
          items: _displayedTasks,
          padding: const EdgeInsets.all(8),
          // Comparator to identify same items across list updates
          isSameItem: (a, b) => a.id == b.id,
          // Disable insert/remove animations (we only want reorder sliding)
          insertDuration: const Duration(milliseconds: 0),
          removeDuration: const Duration(milliseconds: 0),
          // Empty transitions for insert/remove
          enterTransition: const [],
          exitTransition: const [],
          // Enable default drag handles with long-press activation
          // This allows Dismissible swipes to work while long-press triggers reorder
          buildDefaultDragHandles: false,
          longPressDraggable: true,
          // Custom proxy decorator to fix Material widget error during drag
          proxyDecorator: (child, index, animation) {
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: child,
            );
          },
          // Handle manual reordering via drag-and-drop
          onReorder: (oldIndex, newIndex) {
            // Immediately update local state for smooth reordering
            setState(() {
              final task = _displayedTasks.removeAt(oldIndex);
              _displayedTasks.insert(newIndex, task);
            });

            // Notify parent to switch to custom sort and persist order
            widget.onManualReorder?.call(_displayedTasks);
          },
          // Item builder - no animation parameter in this API
          itemBuilder: (context, index) {
            final task = _displayedTasks[index];

            // Always wrap with ReorderableDragStartListener for drag-and-drop
            // Long-press activates drag, swipe still works for Dismissible
            return ReorderableDragStartListener(
              key: ValueKey('task_${task.id}'),
              index: index,
              child: _HighlightedGranularTaskItem(
                key: ValueKey('highlighted_${task.id}'),
                task: task,
                document: widget.document,
                onShowTaskDetails: widget.onShowTaskDetails,
                showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                taskTagsMap: widget.taskTagsMap,
              ),
            );
          },
        ),
              ),
            ],
          );
      },
    );
  }
}

/// Wrapper widget that adds a highlight effect when the task item is repositioned
/// This provides visual feedback when items are reordered via sorting or drag-and-drop
class _HighlightedGranularTaskItem extends StatefulWidget {
  final Task task;
  final TodoDocument document;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final Map<String, List<Tag>> taskTagsMap;

  const _HighlightedGranularTaskItem({
    super.key,
    required this.task,
    required this.document,
    required this.onShowTaskDetails,
    this.showAllPropertiesNotifier,
    required this.taskTagsMap,
  });

  @override
  State<_HighlightedGranularTaskItem> createState() => _HighlightedGranularTaskItemState();
}

class _HighlightedGranularTaskItemState extends State<_HighlightedGranularTaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();

    // Setup highlight animation controller
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    // Trigger highlight animation on init (when item appears during reorder)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _highlightController.forward().then((_) => _highlightController.reverse());
    });
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        // Calculate highlight opacity (fade in, then fade out)
        final highlightOpacity = _highlightAnimation.value <= 0.5
            ? _highlightAnimation.value * 2  // 0.0 -> 1.0 in first half
            : (1.0 - _highlightAnimation.value) * 2;  // 1.0 -> 0.0 in second half

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16), // Match TaskListItem borderRadius
            boxShadow: highlightOpacity > 0.05 ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: highlightOpacity * 0.3),
                blurRadius: 12 * highlightOpacity,
                spreadRadius: 2 * highlightOpacity,
              ),
            ] : null,
          ),
          child: child,
        );
      },
      child: _GranularTaskListItem(
        task: widget.task,
        document: widget.document,
        onShowTaskDetails: widget.onShowTaskDetails,
        showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
        taskTagsMap: widget.taskTagsMap,
        dismissibleEnabled: true,
      ),
    );
  }
}

/// Wrapper that enables granular rebuilds for individual tasks
/// Only this specific task rebuilds when its state changes
///
/// CRITICAL: This is a StatefulWidget to initialize the notifier ONCE
/// If it was StatelessWidget, build() would be called every time and
/// getOrCreateTaskNotifier would overwrite the value
class _GranularTaskListItem extends StatefulWidget {
  final Task task;
  final TodoDocument document;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final Map<String, List<Tag>> taskTagsMap;
  final bool dismissibleEnabled;

  const _GranularTaskListItem({
    super.key,
    required this.task,
    required this.document,
    required this.onShowTaskDetails,
    this.showAllPropertiesNotifier,
    required this.taskTagsMap,
    this.dismissibleEnabled = true,
  });

  @override
  State<_GranularTaskListItem> createState() => _GranularTaskListItemState();
}

class _GranularTaskListItemState extends State<_GranularTaskListItem>
    with SingleTickerProviderStateMixin {
  late final AlwaysNotifyValueNotifier<Task> _taskNotifier;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize notifier ONCE - never call this again in build()!
    final stateManager = TaskStateManager();
    _taskNotifier = stateManager.getOrCreateTaskNotifier(widget.task.id, widget.task);

    // Setup highlight animation controller
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    // Trigger highlight animation on init (when item appears during reorder)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _highlightController.forward().then((_) => _highlightController.reverse());
    });
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only this widget rebuilds when the task changes!
    return ValueListenableBuilder<Task>(
      valueListenable: _taskNotifier,
      builder: (context, updatedTask, _) {
        return AnimatedBuilder(
          animation: _highlightAnimation,
          builder: (context, child) {
            // Calculate highlight opacity (fade in, then fade out)
            final highlightOpacity = _highlightAnimation.value <= 0.5
                ? _highlightAnimation.value * 2  // 0.0 -> 1.0 in first half
                : (1.0 - _highlightAnimation.value) * 2;  // 1.0 -> 0.0 in second half

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: highlightOpacity > 0.05 ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(highlightOpacity * 0.3),
                    blurRadius: 12 * highlightOpacity,
                    spreadRadius: 2 * highlightOpacity,
                  ),
                ] : null,
              ),
              child: child,
            );
          },
          child: TaskListItem(
            task: updatedTask,
            document: widget.document,
            onTap: () => widget.onShowTaskDetails(context, updatedTask),
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            preloadedTags: widget.taskTagsMap[updatedTask.id],
            taskTagsMap: widget.taskTagsMap,
            dismissibleEnabled: widget.dismissibleEnabled,
          ),
        );
      },
    );
  }
}
