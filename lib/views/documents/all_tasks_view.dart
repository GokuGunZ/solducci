import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';
import 'package:solducci/utils/task_filter_sort.dart';

/// View showing all tasks (pending + in progress + assigned) for a document
///
/// Architecture - Granular Rebuild System:
/// - Uses TaskStateManager with individual ValueNotifiers per task
/// - When a task is updated, ONLY that specific TaskListItem rebuilds
/// - List-level changes (add/remove) trigger stream recreation
/// - Filter UI updates instantly without affecting task rendering
/// - Each task wrapped in _GranularTaskListItem with ValueListenableBuilder
/// - Result: Maximum performance, minimal unnecessary rebuilds
class AllTasksView extends StatefulWidget {
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
  State<AllTasksView> createState() => _AllTasksViewState();
}

class _AllTasksViewState extends State<AllTasksView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _taskService = TaskService();
  final _stateManager = TaskStateManager();
  final _orderPersistenceService = TaskOrderPersistenceService();
  late Stream<List<Task>> _taskStream;
  StreamSubscription? _listChangesSubscription;
  final _taskStreamController = StreamController<List<Task>>.broadcast();

  // Use ValueNotifier for granular rebuilds
  final ValueNotifier<FilterSortConfig> _filterConfigNotifier =
      ValueNotifier(const FilterSortConfig());

  // ValueNotifier for task creation state (prevents full list rebuild)
  final ValueNotifier<bool> _isCreatingTaskNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initStream();
    _checkForCustomOrder();

    // Listen to list changes (add/remove/reorder) to manually fetch and emit new data
    _listChangesSubscription = _stateManager.listChanges
        .where((docId) => docId == widget.document.id)
        .listen((_) async {
      print('🔔 LISTENER: List change detected for document ${widget.document.id}');
      print('🔄 LISTENER: Calling _refreshTasks()');
      await _refreshTasks();
      print('🔔 LISTENER: _refreshTasks() completed');
    });

    // Pass the inline creation callback to parent
    widget.onInlineCreationCallbackChanged?.call(startInlineCreation);
  }

  /// Check if there's a saved custom order (for loading the order, NOT activating reorder mode)
  /// Reorder mode is only activated when user starts dragging
  void _checkForCustomOrder() async {
    // No need to activate reorder mode on load
    // The custom order will be loaded and applied in _applyFiltersToRawData
    // Reorder mode activates only when user actually drags a task
  }

  void _initStream() async {
    // Don't use Supabase realtime stream - it's unreliable and causes conflicts
    // Instead, use manual fetch with our own controller
    print('🎬 Initializing task stream for document ${widget.document.id}');

    // Use our controller's stream for the UI
    _taskStream = _taskStreamController.stream;

    // Initial data fetch
    await _refreshTasks();
  }

  bool _isRefreshing = false; // Flag to prevent concurrent refreshes

  Future<void> _refreshTasks() async {
    // Prevent concurrent refresh calls
    if (_isRefreshing) {
      print('⚠️ Already refreshing, skipping duplicate call');
      return;
    }

    _isRefreshing = true;
    print('🔄 _refreshTasks() START');
    try {
      // Small delay to ensure DB write is fully committed
      print('⏳ Waiting 300ms for DB commit...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Fetch fresh data directly from Supabase
      print('📡 Fetching tasks from database...');
      final tasks = await _taskService.fetchTasksForDocument(widget.document.id);
      print('✅ Fetched ${tasks.length} tasks from DB');
      print('   Task IDs: ${tasks.map((t) => t.id.substring(0, 8)).join(", ")}');

      // Emit through our controller - StreamBuilder will rebuild WITHOUT setState
      if (!_taskStreamController.isClosed) {
        print('📤 Emitting ${tasks.length} tasks to stream');
        _taskStreamController.add(tasks);
        print('✅ Tasks emitted successfully');
      } else {
        print('⚠️ Stream controller is CLOSED, cannot emit tasks!');
      }
    } catch (e) {
      print('❌ Error fetching tasks: $e');
      if (!_taskStreamController.isClosed) {
        _taskStreamController.addError(e);
      }
    } finally {
      _isRefreshing = false;
    }
    print('🔄 _refreshTasks() END');
  }

  /// Handle manual reordering via drag-and-drop
  void _handleManualReorder(List<Task> newOrder) async {
    print('🔄 Manual reorder detected');

    // Persist custom order locally (no UI update needed, list already reordered)
    final taskIds = newOrder.map((task) => task.id).toList();
    await _orderPersistenceService.saveCustomOrder(
      documentId: widget.document.id,
      taskIds: taskIds,
    );

    print('✅ Custom order saved: ${taskIds.length} tasks');
  }

  @override
  void dispose() {
    _listChangesSubscription?.cancel();
    _taskStreamController.close();
    _filterConfigNotifier.dispose();
    _isCreatingTaskNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Filter bar - rebuilds instantly and independently
        CompactFilterSortBar(
          key: const ValueKey('compact_filter_sort_bar'),
          filterConfig: _filterConfigNotifier.value,
          onFilterChanged: (newConfig) {
            // Update only the notifier - no setState!
            _filterConfigNotifier.value = newConfig;
          },
          availableTags: widget.availableTags,
        ),

        // Task list section - rebuilds independently when filter changes
        Expanded(
          child: _TaskListSection(
            taskStream: _taskStream,
            filterConfigNotifier: _filterConfigNotifier,
            document: widget.document,
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            isCreatingTaskNotifier: _isCreatingTaskNotifier,
            onCancelCreation: () {
              // No setState - just update the notifier!
              _isCreatingTaskNotifier.value = false;
            },
            onTaskCreated: () async {
              print('🎯 onTaskCreated callback START');

              // Force immediate refresh to show the new task BEFORE closing the row
              // This ensures the new task appears even if the listener hasn't fired yet
              print('🔄 Forcing immediate refresh after task creation');
              await _refreshTasks();

              // Close the creation row AFTER refresh completes
              print('✅ Refresh complete, closing creation row');
              _isCreatingTaskNotifier.value = false;

              print('🎯 onTaskCreated callback END');
            },
            onShowTaskDetails: _showTaskDetails,
            onManualReorder: _handleManualReorder,
          ),
        ),
      ],
    );
  }

  void startInlineCreation() {
    // No setState - just update the notifier!
    // This prevents full list rebuild, only the creation row appears
    _isCreatingTaskNotifier.value = true;
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

/// Separate widget for task list that rebuilds independently from filter UI
class _TaskListSection extends StatelessWidget {
  final Stream<List<Task>>? taskStream;
  final ValueNotifier<FilterSortConfig> filterConfigNotifier;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final ValueNotifier<bool> isCreatingTaskNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final void Function(List<Task> newOrder)? onManualReorder;

  const _TaskListSection({
    required this.taskStream,
    required this.filterConfigNotifier,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.isCreatingTaskNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
    this.onManualReorder,
  });

  @override
  Widget build(BuildContext context) {
    print('🏗️ [1] _TaskListSection.build() called');
    // Listen to filter changes - only this widget rebuilds!
    return ValueListenableBuilder<FilterSortConfig>(
      valueListenable: filterConfigNotifier,
      builder: (context, filterConfig, _) {
        print('🏗️ [2] ValueListenableBuilder.builder() for filter - sortBy: ${filterConfig.sortBy}, hasFilters: ${filterConfig.hasFilters}');
        return _AnimatedTaskListBuilder(
          // Use a constant key to preserve state when filterConfig changes
          // This prevents the widget from being recreated and losing _isFirstLoad state
          key: ValueKey('animated_task_list_builder_${document.id}'),
          taskStream: taskStream,
          filterConfig: filterConfig,
          document: document,
          showAllPropertiesNotifier: showAllPropertiesNotifier,
          isCreatingTaskNotifier: isCreatingTaskNotifier,
          onCancelCreation: onCancelCreation,
          onTaskCreated: onTaskCreated,
          onShowTaskDetails: onShowTaskDetails,
          onManualReorder: onManualReorder,
        );
      },
    );
  }
}

/// StatefulWidget that manages AnimatedList and stream synchronization
class _AnimatedTaskListBuilder extends StatefulWidget {
  final Stream<List<Task>>? taskStream;
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final ValueNotifier<bool> isCreatingTaskNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final void Function(List<Task> newOrder)? onManualReorder; // Callback for drag-and-drop reorder

  const _AnimatedTaskListBuilder({
    super.key,
    required this.taskStream,
    required this.filterConfig,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.isCreatingTaskNotifier,
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
  StreamSubscription<List<Task>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    print('🎬 [INIT] _AnimatedTaskListBuilderState.initState() - Creating new instance!');
    _listKey = GlobalKey<AnimatedListState>(); // Initialize GlobalKey
    _streamSubscription = widget.taskStream?.listen(_onNewData);
  }

  @override
  void didUpdateWidget(_AnimatedTaskListBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect filter or sort config changes
    if (widget.filterConfig != oldWidget.filterConfig) {
      final filterChanged = _hasFilterChanged(oldWidget.filterConfig, widget.filterConfig);
      final sortChanged = _hasSortChanged(oldWidget.filterConfig, widget.filterConfig);

      print('🔄 Filter config changed');
      print('   Filter changed: $filterChanged, Sort changed: $sortChanged');
      print('   Old config: priorities=${oldWidget.filterConfig.priorities.length}, '
            'statuses=${oldWidget.filterConfig.statuses.length}, '
            'sortBy=${oldWidget.filterConfig.sortBy}');
      print('   New config: priorities=${widget.filterConfig.priorities.length}, '
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
    _streamSubscription?.cancel();
    _rawTasks = null; // Clear cache
    super.dispose();
  }

  void _onNewData(List<Task> allTasks) {
    print('📦 _onNewData received ${allTasks.length} tasks');
    _rawTasks = allTasks; // Cache raw data for re-filtering
    _applyFiltersToRawData(allTasks);
  }

  void _applyFiltersToRawData(
    List<Task> allTasks, {
    bool isFilterChange = false,
    bool isSortOnlyChange = false,
  }) async {
    print('🔍 Applying filters to ${allTasks.length} tasks');
    print('   isFilterChange: $isFilterChange, isSortOnlyChange: $isSortOnlyChange');
    print('   Filter config: priorities=${widget.filterConfig.priorities}, '
          'statuses=${widget.filterConfig.statuses}, '
          'sizes=${widget.filterConfig.sizes}, '
          'dateFilter=${widget.filterConfig.dateFilter}, '
          'sortBy=${widget.filterConfig.sortBy}');

    var tasks = allTasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();

    print('   After completion filter: ${tasks.length} tasks');

    // Apply filters and sorting
    if (widget.filterConfig.tagIds.isNotEmpty) {
      print('   Applying async filter (tags: ${widget.filterConfig.tagIds.length})');
      tasks = await tasks.applyFilterSortAsync(widget.filterConfig);
      print('   Async filter result: ${tasks.length} tasks');
    } else {
      tasks = tasks.applyFilterSort(widget.filterConfig);
      print('   After sync filter+sort: ${tasks.length} tasks');
    }

    // Apply custom order if selected
    if (widget.filterConfig.sortBy == TaskSortOption.custom) {
      final orderPersistenceService = TaskOrderPersistenceService();
      final savedOrder = await orderPersistenceService.loadCustomOrder(widget.document.id);

      if (savedOrder != null && savedOrder.isNotEmpty) {
        tasks = tasks.applyCustomOrder(savedOrder);
        print('   Applied custom order: ${savedOrder.length} task IDs');
      } else {
        print('   No custom order found, using default order');
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
      print('🎯 [FIRST LOAD] Setting _isFirstLoad = false, tasks=${newTasks.length}');
      setState(() {
        _displayedTasks = newTasks;
        _isFirstLoad = false;
      });
      print('✅ [FIRST LOAD] First load complete, _isFirstLoad=$_isFirstLoad');
      return;
    }

    // SORT-ONLY CHANGE: Animate reorder with AnimatedSwitcher
    if (isSortOnlyChange && !isFilterChange) {
      print('🔄 Animating reorder: ${_displayedTasks.length} tasks');
      _animateReorder(newTasks);
      return;
    }

    // FILTER CHANGE: Batch update without incremental animations
    // This prevents the "one task at a time" removal issue
    if (isFilterChange) {
      print('📋 Batch update for filter change: ${_displayedTasks.length} → ${newTasks.length} tasks');
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
    // CRITICAL: Recursively update all task notifiers (including subtasks)
    // This ensures the entire task tree is synchronized with DB data
    final stateManager = TaskStateManager();
    for (final newTask in newTasks) {
      stateManager.updateTaskRecursively(newTask);
    }
  }

  /// Animates reorder by updating the list and letting AnimatedReorderableListView handle it
  /// Similar to TagView approach - update list with setState but WITHOUT recreating keys
  void _animateReorder(List<Task> newTasks) {
    print('🎬 Smooth reorder animation: ${_displayedTasks.length} → ${newTasks.length} tasks');

    // Update the list with setState - this triggers rebuild but AnimatedReorderableListView
    // detects the change and animates items from old position to new position
    // CRITICAL: We do NOT recreate _listKey, keeping the same AnimatedList instance
    setState(() {
      _displayedTasks = newTasks;
    });

    // Update task notifiers AFTER build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateManager = TaskStateManager();
      for (final task in newTasks) {
        stateManager.updateTaskRecursively(task);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ [3] _AnimatedTaskListBuilderState.build() - _isFirstLoad=$_isFirstLoad, tasks=${_displayedTasks.length}');
    if (_isFirstLoad) {
      print('⚠️ [3a] _isFirstLoad==true → Showing CircularProgressIndicator!');
      return const Center(child: CircularProgressIndicator());
    }

    print('✅ [3b] _isFirstLoad==false → Building _TaskListContent');
    return _TaskListContent(
      listKey: _listKey,
      tasks: _displayedTasks,
      filterConfig: widget.filterConfig,
      document: widget.document,
      showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
      isCreatingTaskNotifier: widget.isCreatingTaskNotifier,
      onCancelCreation: widget.onCancelCreation,
      onTaskCreated: widget.onTaskCreated,
      onShowTaskDetails: widget.onShowTaskDetails,
      onManualReorder: widget.onManualReorder,
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
  final ValueNotifier<bool> isCreatingTaskNotifier;
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
    required this.isCreatingTaskNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
    this.onManualReorder,
  });

  @override
  Widget build(BuildContext context) {
    print('🏗️ [4] _TaskListContent.build() - tasks=${tasks.length}');

    // CRITICAL FIX: Tags are already preloaded in TaskStateManager
    // We don't need to fetch them again here - that was causing the CircularProgressIndicator!
    // Just use an empty map for now - tags will be loaded by TaskListItem if needed
    final taskTagsMap = <String, List<Tag>>{};

    print('✅ [4a] Building _TaskList with ${tasks.length} tasks');
    return _TaskList(
      listKey: listKey,
      tasks: tasks,
      filterConfig: filterConfig,
      document: document,
      showAllPropertiesNotifier: showAllPropertiesNotifier,
      isCreatingTaskNotifier: isCreatingTaskNotifier,
      onCancelCreation: onCancelCreation,
      onTaskCreated: onTaskCreated,
      onShowTaskDetails: onShowTaskDetails,
      taskTagsMap: taskTagsMap,
      onManualReorder: onManualReorder,
    );
  }
}

/// Final widget that renders the actual list using AnimatedReorderableListView
/// Uses ValueListenableBuilder to rebuild ONLY when creation state changes
class _TaskList extends StatefulWidget {
  final GlobalKey<AnimatedListState> listKey;
  final List<Task> tasks;
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final ValueNotifier<bool> isCreatingTaskNotifier;
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
    required this.isCreatingTaskNotifier,
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
    print('🏗️ [5] _TaskListState.build() - _displayedTasks.length=${_displayedTasks.length}');
    // Listen to creation state changes - only rebuilds when creating/canceling
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isCreatingTaskNotifier,
      builder: (context, isCreatingTask, _) {
        print('🏗️ [6] ValueListenableBuilder.builder() for isCreatingTask - value=$isCreatingTask');
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
