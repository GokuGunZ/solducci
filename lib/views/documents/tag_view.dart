import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/blocs/tag/tag_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/utils/task_filter_sort.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// View showing tasks filtered by a specific tag
///
/// Architecture mirrors AllTasksView:
/// - Uses BLoC for state management
/// - Granular rebuild system with TaskStateManager
/// - Multi-layer widget structure for optimal performance
/// - Smooth inline animations for task creation
class TagView extends StatelessWidget {
  final TodoDocument document;
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;

  const TagView({
    super.key,
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<TagBloc>();
        bloc.add(TagLoadRequested(
          tagId: tag.id,
          documentId: document.id,
          includeCompleted: tag.showCompleted,
        ));
        return bloc;
      },
      child: _TagViewContent(
        document: document,
        tag: tag,
        showAllPropertiesNotifier: showAllPropertiesNotifier,
        onInlineCreationCallbackChanged: onInlineCreationCallbackChanged,
      ),
    );
  }
}

class _TagViewContent extends StatefulWidget {
  final TodoDocument document;
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;

  const _TagViewContent({
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
  });

  @override
  State<_TagViewContent> createState() => _TagViewContentState();
}

class _TagViewContentState extends State<_TagViewContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('🏷️ TagView initialized with tag: ${widget.tag.name} (ID: "${widget.tag.id}")');
    // Pass the inline creation callback to parent
    widget.onInlineCreationCallbackChanged?.call(startInlineCreation);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Filter bar - reads from BLoC state
        BlocBuilder<TagBloc, TagState>(
          builder: (context, state) {
            final filterConfig = state is TagLoaded
                ? state.filterConfig
                : const FilterSortConfig();

            return CompactFilterSortBar(
              key: const ValueKey('compact_filter_sort_bar'),
              filterConfig: filterConfig,
              onFilterChanged: (newConfig) {
                // Dispatch filter change event to BLoC
                context.read<TagBloc>().add(TagFilterChanged(newConfig));
              },
            );
          },
        ),

        // Task list section - rebuilds independently when filter changes
        Expanded(
          child: _TaskListSection(
            document: widget.document,
            tag: widget.tag,
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            onCancelCreation: () {
              // Dispatch event to BLoC to cancel creation
              context.read<TagBloc>().add(const TagTaskCreationCompleted());
            },
            onTaskCreated: () async {
              AppLogger.debug('🎯 TagView: onTaskCreated callback START');

              // Close the creation row via BLoC
              // The stream subscription will automatically refresh when the task is created
              AppLogger.debug('✅ Dispatching TagTaskCreationCompleted');
              context.read<TagBloc>().add(const TagTaskCreationCompleted());

              AppLogger.debug('🎯 TagView: onTaskCreated callback END');
            },
            onShowTaskDetails: _showTaskDetails,
          ),
        ),
      ],
    );
  }

  void startInlineCreation() {
    // Dispatch event to BLoC to start task creation
    context.read<TagBloc>().add(const TagTaskCreationStarted());
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
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;

  const _TaskListSection({
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ [1] _TaskListSection.build() called');
    // Read filter config from BLoC state
    return BlocBuilder<TagBloc, TagState>(
      buildWhen: (previous, current) {
        // Only rebuild when filter config changes
        if (previous is TagLoaded && current is TagLoaded) {
          return previous.filterConfig != current.filterConfig;
        }
        return true;
      },
      builder: (context, state) {
        final filterConfig = state is TagLoaded
            ? state.filterConfig
            : const FilterSortConfig();

        AppLogger.debug('🏗️ [2] BlocBuilder for filter - sortBy: ${filterConfig.sortBy}, hasFilters: ${filterConfig.hasFilters}');
        return _AnimatedTaskListBuilder(
          // Use a constant key to preserve state when filterConfig changes
          key: ValueKey('animated_task_list_builder_${document.id}_${tag.id}'),
          filterConfig: filterConfig,
          document: document,
          tag: tag,
          showAllPropertiesNotifier: showAllPropertiesNotifier,
          onCancelCreation: onCancelCreation,
          onTaskCreated: onTaskCreated,
          onShowTaskDetails: onShowTaskDetails,
        );
      },
    );
  }
}

/// StatefulWidget that manages AnimatedList and BLoC state synchronization
class _AnimatedTaskListBuilder extends StatefulWidget {
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;

  const _AnimatedTaskListBuilder({
    super.key,
    required this.filterConfig,
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
  });

  @override
  State<_AnimatedTaskListBuilder> createState() => _AnimatedTaskListBuilderState();
}

class _AnimatedTaskListBuilderState extends State<_AnimatedTaskListBuilder> {
  late GlobalKey<AnimatedListState> _listKey;
  List<Task> _displayedTasks = [];
  List<Task>? _rawTasks; // Cache raw unfiltered data for re-filtering
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('🎬 [INIT] _AnimatedTaskListBuilderState.initState() - Creating new instance!');
    _listKey = GlobalKey<AnimatedListState>();
  }

  @override
  void didUpdateWidget(_AnimatedTaskListBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect filter or sort config changes
    if (widget.filterConfig != oldWidget.filterConfig) {
      AppLogger.debug('🔄 Filter config changed');

      // Re-apply filters to cached raw data
      if (_rawTasks != null) {
        _applyFiltersToRawData(_rawTasks!);
      }
    }
  }

  @override
  void dispose() {
    _rawTasks = null; // Clear cache
    super.dispose();
  }

  void _onNewData(List<Task> allTasks) {
    AppLogger.debug('📦 _onNewData received ${allTasks.length} tasks');
    _rawTasks = allTasks; // Cache raw data for re-filtering
    _applyFiltersToRawData(allTasks);
  }

  void _applyFiltersToRawData(List<Task> allTasks) async {
    AppLogger.debug('🔍 Applying filters to ${allTasks.length} tasks');

    // Apply filters and sorting
    var filteredTasks = allTasks.applyFilterSort(widget.filterConfig);

    AppLogger.debug('✅ Filtered to ${filteredTasks.length} tasks');

    if (_isFirstLoad) {
      // Initial load - set tasks directly without animation
      setState(() {
        _displayedTasks = filteredTasks;
        _isFirstLoad = false;
      });

      // Update task notifiers after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final stateManager = TaskStateManager();
        for (final task in filteredTasks) {
          stateManager.updateTask(task);
        }
      });
    } else {
      // Subsequent updates - animate changes
      _animateReorder(filteredTasks);
    }
  }

  void _animateReorder(List<Task> newTasks) {
    AppLogger.debug('🎬 Smooth reorder animation: ${_displayedTasks.length} → ${newTasks.length} tasks');

    // Update the list with setState - triggers rebuild with animation
    setState(() {
      _displayedTasks = newTasks;
    });

    // Update task notifiers AFTER build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateManager = TaskStateManager();
      for (final task in newTasks) {
        stateManager.updateTask(task);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ [3] _AnimatedTaskListBuilderState.build() - _isFirstLoad=$_isFirstLoad, tasks=${_displayedTasks.length}');

    // Use BlocListener to listen for state changes
    return BlocListener<TagBloc, TagState>(
      listener: (context, state) {
        AppLogger.debug('🔔 BlocListener triggered - state type: ${state.runtimeType}');
        // When BLoC emits TagLoaded, update displayed tasks
        if (state is TagLoaded) {
          AppLogger.debug('🔔 BlocListener: TagLoaded with ${state.tasks.length} tasks');
          _onNewData(state.tasks);
        }
      },
      child: BlocBuilder<TagBloc, TagState>(
        builder: (context, state) {
          return switch (state) {
            TagInitial() => const SizedBox.shrink(),

            TagLoading() => const Center(
              child: CircularProgressIndicator(),
            ),

            TagError(:final message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Errore nel caricamento'),
                  const SizedBox(height: 8),
                  Text(message, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TagBloc>()
                        .add(const TagRefreshRequested()),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),

            TagLoaded() => _isFirstLoad
              ? const Center(child: CircularProgressIndicator())
              : _TaskListContent(
                  listKey: _listKey,
                  tasks: _displayedTasks,
                  filterConfig: widget.filterConfig,
                  document: widget.document,
                  tag: widget.tag,
                  showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                  onCancelCreation: widget.onCancelCreation,
                  onTaskCreated: widget.onTaskCreated,
                  onShowTaskDetails: widget.onShowTaskDetails,
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
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;

  const _TaskListContent({
    required this.listKey,
    required this.tasks,
    required this.filterConfig,
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ [4] _TaskListContent.build() - tasks=${tasks.length}');

    // Tags will be loaded by TaskListItem if needed
    final taskTagsMap = <String, List<Tag>>{};

    AppLogger.debug('✅ [4a] Building _TaskList with ${tasks.length} tasks');
    return _TaskList(
      listKey: listKey,
      tasks: tasks,
      filterConfig: filterConfig,
      document: document,
      tag: tag,
      showAllPropertiesNotifier: showAllPropertiesNotifier,
      onCancelCreation: onCancelCreation,
      onTaskCreated: onTaskCreated,
      onShowTaskDetails: onShowTaskDetails,
      taskTagsMap: taskTagsMap,
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
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancelCreation;
  final Future<void> Function() onTaskCreated;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final Map<String, List<Tag>> taskTagsMap;

  const _TaskList({
    required this.listKey,
    required this.tasks,
    required this.filterConfig,
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onShowTaskDetails,
    required this.taskTagsMap,
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
    _displayedTasks = widget.tasks;
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ [5] _TaskListState.build() - _displayedTasks.length=${_displayedTasks.length}');

    // Read creation state from BLoC - only rebuilds when creation state changes
    return BlocBuilder<TagBloc, TagState>(
      buildWhen: (previous, current) {
        // Only rebuild when isCreatingTask changes
        if (previous is TagLoaded && current is TagLoaded) {
          final shouldRebuild = previous.isCreatingTask != current.isCreatingTask;
          AppLogger.debug('🔨 buildWhen for isCreatingTask: prev=${previous.isCreatingTask}, curr=${current.isCreatingTask}, shouldRebuild=$shouldRebuild');
          return shouldRebuild;
        }
        return true;
      },
      builder: (context, state) {
        final isCreatingTask = state is TagLoaded ? state.isCreatingTask : false;
        AppLogger.debug('🏗️ [6] BlocBuilder for isCreatingTask - value=$isCreatingTask');

        // Separate completed and non-completed tasks
        final activeTasks = _displayedTasks
            .where((t) => t.status != TaskStatus.completed)
            .toList();
        final completedTasks = _displayedTasks
            .where((t) => t.status == TaskStatus.completed)
            .toList();

        // Empty state
        if (_displayedTasks.isEmpty && !isCreatingTask) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.filterConfig.hasFilters
                      ? Icons.filter_alt_off
                      : Icons.label_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.filterConfig.hasFilters
                      ? 'Nessuna task trovata'
                      : 'Nessuna task con questo tag',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.filterConfig.hasFilters
                      ? 'Prova a cambiare i filtri'
                      : 'Aggiungi una task con questo tag!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Inline task creation row (appears at top when creating)
            if (isCreatingTask)
              TaskCreationRow(
                document: widget.document,
                showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                initialTags: widget.tag.id.isNotEmpty ? [widget.tag] : null,
                onCancel: widget.onCancelCreation,
                onTaskCreated: widget.onTaskCreated,
              ),

            // Task list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<TagBloc>().add(const TagRefreshRequested());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: activeTasks.length,
                  itemBuilder: (context, index) {
                    final task = activeTasks[index];
                    return _HighlightedGranularTaskItem(
                      key: ValueKey('task_${task.id}'),
                      task: task,
                      document: widget.document,
                      onShowTaskDetails: widget.onShowTaskDetails,
                      showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                      taskTagsMap: widget.taskTagsMap,
                    );
                  },
                ),
              ),
            ),

            // Completed tasks section
            if (widget.tag.showCompleted && completedTasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Completate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    ...completedTasks.map((task) => TaskListItem(
                          key: ValueKey('task_${task.id}'),
                          task: task,
                          document: widget.document,
                          onTap: () => widget.onShowTaskDetails(context, task),
                          showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                          preloadedTags: widget.taskTagsMap[task.id],
                          taskTagsMap: widget.taskTagsMap,
                        )),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Wrapper widget that adds a highlight effect when the task item is repositioned
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
  late AlwaysNotifyValueNotifier<Task> _taskNotifier;

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

    // Initialize granular rebuild notifier
    final stateManager = TaskStateManager();
    _taskNotifier = stateManager.getOrCreateTaskNotifier(
      widget.task.id,
      widget.task,
    );

    // Start highlight animation only for newly created tasks (within last 2 seconds)
    final taskAge = DateTime.now().difference(widget.task.createdAt);
    final isNewTask = taskAge.inSeconds < 2;

    if (isNewTask) {
      AppLogger.debug('🎨 Starting highlight animation for new task: ${widget.task.id}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _highlightController.forward().then((_) {
            if (mounted) {
              _highlightController.reverse();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();

    // Release reference to task notifier
    final stateManager = TaskStateManager();
    stateManager.releaseTaskNotifier(widget.task.id);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use granular rebuild with ValueListenableBuilder
    return ValueListenableBuilder<Task>(
      valueListenable: _taskNotifier,
      builder: (context, updatedTask, _) {
        // Wrap with highlight animation
        return AnimatedBuilder(
          animation: _highlightAnimation,
          builder: (context, child) {
            final highlightOpacity = _highlightAnimation.value <= 0.5
                ? _highlightAnimation.value * 2
                : (1.0 - _highlightAnimation.value) * 2;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
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
          child: TaskListItem(
            task: updatedTask,
            document: widget.document,
            onTap: () => widget.onShowTaskDetails(context, updatedTask),
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            dismissibleEnabled: true,
            preloadedTags: widget.taskTagsMap[updatedTask.id],
            taskTagsMap: widget.taskTagsMap,
          ),
        );
      },
    );
  }
}
