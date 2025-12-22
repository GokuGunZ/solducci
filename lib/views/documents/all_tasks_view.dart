import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
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

    // Listen to list changes (add/remove/reorder) to manually fetch and emit new data
    _listChangesSubscription = _stateManager.listChanges
        .where((docId) => docId == widget.document.id)
        .listen((_) async {
      print('🔄 List change detected, refreshing tasks');
      await _refreshTasks();
    });

    // Pass the inline creation callback to parent
    widget.onInlineCreationCallbackChanged?.call(startInlineCreation);
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

  Future<void> _refreshTasks() async {
    try {
      // CRITICAL: Add small delay to ensure DB write is fully committed
      // Supabase might have eventual consistency or connection pooling delays
      await Future.delayed(const Duration(milliseconds: 100));

      // Fetch fresh data directly from Supabase
      final tasks = await _taskService.fetchTasksForDocument(widget.document.id);
      print('✅ Fetched ${tasks.length} tasks');

      // Emit through our controller - StreamBuilder will rebuild WITHOUT setState
      if (!_taskStreamController.isClosed) {
        _taskStreamController.add(tasks);
      }
    } catch (e) {
      print('❌ Error fetching tasks: $e');
      if (!_taskStreamController.isClosed) {
        _taskStreamController.addError(e);
      }
    }
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
            onTaskCreated: () {
              // Simply close the creation row immediately
              // The task has been created in Supabase, it will appear when stream updates
              print('✅ Task created, closing creation row');
              _isCreatingTaskNotifier.value = false;
            },
            onShowTaskDetails: _showTaskDetails,
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
  final VoidCallback onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;

  const _TaskListSection({
    required this.taskStream,
    required this.filterConfigNotifier,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.isCreatingTaskNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to filter changes - only this widget rebuilds!
    return ValueListenableBuilder<FilterSortConfig>(
      valueListenable: filterConfigNotifier,
      builder: (context, filterConfig, _) {
        return _AnimatedTaskListBuilder(
          taskStream: taskStream,
          filterConfig: filterConfig,
          document: document,
          showAllPropertiesNotifier: showAllPropertiesNotifier,
          isCreatingTaskNotifier: isCreatingTaskNotifier,
          onCancelCreation: onCancelCreation,
          onTaskCreated: onTaskCreated,
          onShowTaskDetails: onShowTaskDetails,
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
  final VoidCallback onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;

  const _AnimatedTaskListBuilder({
    required this.taskStream,
    required this.filterConfig,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.isCreatingTaskNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
  });

  @override
  State<_AnimatedTaskListBuilder> createState() => _AnimatedTaskListBuilderState();
}

class _AnimatedTaskListBuilderState extends State<_AnimatedTaskListBuilder> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Task> _displayedTasks = [];
  List<Task>? _rawTasks; // Cache raw unfiltered data for re-filtering
  bool _isFirstLoad = true;
  StreamSubscription<List<Task>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _streamSubscription = widget.taskStream?.listen(_onNewData);
  }

  @override
  void didUpdateWidget(_AnimatedTaskListBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect filter or sort config changes
    if (widget.filterConfig != oldWidget.filterConfig) {
      print('🔄 Filter config changed, re-applying filters');
      print('   Old config: priorities=${oldWidget.filterConfig.priorities.length}, '
            'statuses=${oldWidget.filterConfig.statuses.length}, '
            'sortBy=${oldWidget.filterConfig.sortBy}');
      print('   New config: priorities=${widget.filterConfig.priorities.length}, '
            'statuses=${widget.filterConfig.statuses.length}, '
            'sortBy=${widget.filterConfig.sortBy}');

      // Re-apply filters to cached raw data with isFilterChange=true
      // This ensures batch update instead of incremental changes
      if (_rawTasks != null) {
        _applyFiltersToRawData(_rawTasks!, isFilterChange: true);
      }
    }
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

  void _applyFiltersToRawData(List<Task> allTasks, {bool isFilterChange = false}) {
    print('🔍 Applying filters to ${allTasks.length} tasks (isFilterChange: $isFilterChange)');
    print('   Filter config: priorities=${widget.filterConfig.priorities}, '
          'statuses=${widget.filterConfig.statuses}, '
          'sizes=${widget.filterConfig.sizes}, '
          'dateFilter=${widget.filterConfig.dateFilter}, '
          'sortBy=${widget.filterConfig.sortBy}');

    var tasks = allTasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();

    print('   After completion filter: ${tasks.length} tasks');

    if (widget.filterConfig.tagIds.isNotEmpty) {
      print('   Applying async filter (tags: ${widget.filterConfig.tagIds.length})');
      tasks.applyFilterSortAsync(widget.filterConfig).then((filteredTasks) {
        print('   Async filter result: ${filteredTasks.length} tasks');
        _updateDisplayedTasks(filteredTasks, isFilterChange: isFilterChange);
      });
    } else {
      tasks = tasks.applyFilterSort(widget.filterConfig);
      print('   After sync filter+sort: ${tasks.length} tasks');
      _updateDisplayedTasks(tasks, isFilterChange: isFilterChange);
    }
  }

  void _updateDisplayedTasks(List<Task> newTasks, {bool isFilterChange = false}) {
    if (_isFirstLoad) {
      setState(() {
        _displayedTasks = newTasks;
        _isFirstLoad = false;
      });
      return;
    }

    // CRITICAL FIX: When filter/sort changes, do batch update without incremental animations
    // This prevents the "one task at a time" removal issue and handles reordering
    if (isFilterChange) {
      print('📋 Batch update for filter/sort change: ${_displayedTasks.length} → ${newTasks.length} tasks');
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

  @override
  Widget build(BuildContext context) {
    if (_isFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }

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
  final VoidCallback onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;

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
  });

  @override
  Widget build(BuildContext context) {
    final taskService = TaskService();

    // Preload tags for all visible tasks
    return FutureBuilder<Map<String, List<Tag>>>(
      future: taskService.getEffectiveTagsForTasksWithSubtasks(tasks),
      builder: (context, tagsSnapshot) {
        if (tagsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final taskTagsMap = tagsSnapshot.data ?? {};

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
        );
      },
    );
  }
}

/// Final widget that renders the actual list using AnimatedList
/// Uses ValueListenableBuilder to rebuild ONLY when creation state changes
class _TaskList extends StatelessWidget {
  final GlobalKey<AnimatedListState> listKey;
  final List<Task> tasks;
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final ValueNotifier<bool> isCreatingTaskNotifier;
  final VoidCallback onCancelCreation;
  final VoidCallback onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final Map<String, List<Tag>> taskTagsMap;

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
  });

  @override
  Widget build(BuildContext context) {
    // Listen to creation state changes - only rebuilds when creating/canceling
    return ValueListenableBuilder<bool>(
      valueListenable: isCreatingTaskNotifier,
      builder: (context, isCreatingTask, _) {
        // Empty state
        if (tasks.isEmpty && !isCreatingTask) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filterConfig.hasFilters
                      ? Icons.filter_alt_off
                      : Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  filterConfig.hasFilters
                      ? 'Nessuna task trovata'
                      : 'Nessuna task',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  filterConfig.hasFilters
                      ? 'Prova a cambiare i filtri'
                      : 'Aggiungi la tua prima task!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // AnimatedList for smooth insertions/deletions
        return Container(
          color: Colors.transparent,
          child: AnimatedList(
            key: listKey,
            padding: const EdgeInsets.all(8),
            initialItemCount: tasks.length + (isCreatingTask ? 1 : 0),
            itemBuilder: (context, index, animation) {
              // Show creation row at the top
              if (isCreatingTask && index == 0) {
                return TaskCreationRow(
                  key: const ValueKey('task_creation'),
                  document: document,
                  showAllPropertiesNotifier: showAllPropertiesNotifier,
                  onCancel: onCancelCreation,
                  onTaskCreated: onTaskCreated,
                );
              }

              final taskIndex = isCreatingTask ? index - 1 : index;
              if (taskIndex < 0 || taskIndex >= tasks.length) {
                return const SizedBox.shrink();
              }

              final task = tasks[taskIndex];

              // Animate new items
              return SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: _GranularTaskListItem(
                    key: ValueKey('task_${task.id}'),
                    task: task,
                    document: document,
                    onShowTaskDetails: onShowTaskDetails,
                    showAllPropertiesNotifier: showAllPropertiesNotifier,
                    taskTagsMap: taskTagsMap,
                  ),
                ),
              );
            },
          ),
        );
      },
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

  const _GranularTaskListItem({
    super.key,
    required this.task,
    required this.document,
    required this.onShowTaskDetails,
    this.showAllPropertiesNotifier,
    required this.taskTagsMap,
  });

  @override
  State<_GranularTaskListItem> createState() => _GranularTaskListItemState();
}

class _GranularTaskListItemState extends State<_GranularTaskListItem> {
  late final AlwaysNotifyValueNotifier<Task> _taskNotifier;

  @override
  void initState() {
    super.initState();
    // Initialize notifier ONCE - never call this again in build()!
    final stateManager = TaskStateManager();
    _taskNotifier = stateManager.getOrCreateTaskNotifier(widget.task.id, widget.task);
  }

  @override
  Widget build(BuildContext context) {
    // Only this widget rebuilds when the task changes!
    return ValueListenableBuilder<Task>(
      valueListenable: _taskNotifier,
      builder: (context, updatedTask, _) {
        return TaskListItem(
          task: updatedTask,
          document: widget.document,
          onTap: () => widget.onShowTaskDetails(context, updatedTask),
          showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
          preloadedTags: widget.taskTagsMap[updatedTask.id],
          taskTagsMap: widget.taskTagsMap,
        );
      },
    );
  }
}
