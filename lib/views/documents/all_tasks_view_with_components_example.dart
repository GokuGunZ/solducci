import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

// Import dei componenti astratti creati
import 'package:solducci/features/documents/presentation/utils/task_list_helpers.dart';
import 'package:solducci/core/components/animations/highlight_animation_mixin.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

/// ESEMPIO DI MIGRAZIONE USANDO I COMPONENTI ASTRATTI
///
/// Questo file dimostra come una nuova view può utilizzare i componenti
/// astratti creati per ridurre il codice duplicato.
///
/// IMPORTANTE: Questa è una view DI ESEMPIO che può essere usata come
/// riferimento per future migrazioni o nuove features. NON sostituisce
/// AllTasksView esistente.
///
/// Componenti utilizzati:
/// - buildTaskEmptyState() - Empty state riutilizzabile
/// - buildTaskLoadingState() - Loading state riutilizzabile
/// - buildTaskErrorState() - Error state riutilizzabile
/// - filterTasksByCompletion() - Pure function per filtering
/// - HighlightAnimationMixin - Animation riutilizzabile
///
/// Comportamento identico a AllTasksView originale:
/// - BLoC per state management
/// - TaskStateManager per granular rebuilds
/// - AnimatedReorderableListView per drag-and-drop
/// - Highlight animation al reorder
/// - Inline task creation
///
/// Riduzione codice stimata: ~40% rispetto all'originale
class AllTasksViewWithComponentsExample extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

  const AllTasksViewWithComponentsExample({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AllTasksView con Componenti (Example)'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: BlocProvider(
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
      ),
    );
  }
}

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
  List<String>? _customOrder;
  List<Task> _displayedTasks = [];
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    widget.onInlineCreationCallbackChanged?.call(startInlineCreation);
    _loadCustomOrder();
  }

  Future<void> _loadCustomOrder() async {
    final order = await _orderPersistenceService.loadCustomOrder(widget.document.id);
    if (order != null && mounted) {
      setState(() => _customOrder = order);
    }
  }

  void _handleManualReorder(int oldIndex, int newIndex) {
    AppLogger.debug('🔄 Manual reorder: $oldIndex → $newIndex');

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final task = _displayedTasks.removeAt(oldIndex);
      _displayedTasks.insert(newIndex, task);
    });

    final taskIds = _displayedTasks.map((task) => task.id).toList();
    _orderPersistenceService.saveCustomOrder(
      documentId: widget.document.id,
      taskIds: taskIds,
    );

    setState(() => _customOrder = taskIds);
    AppLogger.debug('✅ Custom order saved: ${taskIds.length} tasks');
  }

  void _updateDisplayedTasks(List<Task> tasks, FilterSortConfig config) async {
    AppLogger.debug('📦 Updating displayed tasks: ${tasks.length}');

    // ✅ USA UTILITY: filterTasksByCompletion invece di logica inline
    var filteredTasks = filterTasksByCompletion(
      tasks,
      showCompleted: false,
    );

    // Applica filtri e sorting (BLoC già lo fa, ma dobbiamo applicare custom order)
    if (config.tagIds.isNotEmpty) {
      filteredTasks = await filteredTasks.applyFilterSortAsync(config);
    } else {
      filteredTasks = filteredTasks.applyFilterSort(config);
    }

    // Applica custom order se necessario
    if (config.sortBy == TaskSortOption.custom && _customOrder != null) {
      filteredTasks = filteredTasks.applyCustomOrder(_customOrder!);
    }

    setState(() {
      _displayedTasks = filteredTasks;
      _isFirstLoad = false;
    });

    // Update TaskStateManager per granular rebuilds
    final stateManager = TaskStateManager();
    for (final task in filteredTasks) {
      stateManager.updateTaskRecursively(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Filter bar
        BlocBuilder<TaskListBloc, TaskListState>(
          builder: (context, state) {
            final filterConfig = state is TaskListLoaded
                ? state.filterConfig
                : const FilterSortConfig();

            return CompactFilterSortBar(
              key: const ValueKey('compact_filter_sort_bar'),
              filterConfig: filterConfig,
              onFilterChanged: (newConfig) {
                context.read<TaskListBloc>().add(TaskListFilterChanged(newConfig));
              },
              availableTags: widget.availableTags,
            );
          },
        ),

        // Task list
        Expanded(
          child: BlocConsumer<TaskListBloc, TaskListState>(
            listener: (context, state) {
              if (state is TaskListLoaded) {
                _updateDisplayedTasks(state.tasks, state.filterConfig);
              }
            },
            builder: (context, state) {
              return switch (state) {
                TaskListInitial() => const SizedBox.shrink(),

                // ✅ USA UTILITY: buildTaskLoadingState invece di widget custom
                TaskListLoading() => _isFirstLoad
                    ? buildTaskLoadingState(context: context)
                    : const SizedBox.shrink(),

                // ✅ USA UTILITY: buildTaskErrorState invece di widget custom
                TaskListError(:final message) => buildTaskErrorState(
                    context: context,
                    message: message,
                    onRetry: () => context
                        .read<TaskListBloc>()
                        .add(const TaskListRefreshRequested()),
                  ),

                TaskListLoaded(:final filterConfig, :final isCreatingTask) =>
                  _buildTaskList(
                    context,
                    filterConfig: filterConfig,
                    isCreatingTask: isCreatingTask,
                  ),
              };
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(
    BuildContext context, {
    required FilterSortConfig filterConfig,
    required bool isCreatingTask,
  }) {
    // ✅ USA UTILITY: buildTaskEmptyState invece di widget custom
    if (_displayedTasks.isEmpty && !isCreatingTask) {
      return buildTaskEmptyState(
        context: context,
        filterConfig: filterConfig,
        showCompletedTasks: false,
        onClearFilters: () {
          context.read<TaskListBloc>().add(
                const TaskListFilterChanged(FilterSortConfig()),
              );
        },
      );
    }

    final isReorderable = filterConfig.sortBy == TaskSortOption.custom;

    return Column(
      children: [
        // Inline task creation
        if (isCreatingTask)
          TaskCreationRow(
            document: widget.document,
            onCancel: () {
              context.read<TaskListBloc>().add(
                    const TaskListTaskCreationCompleted(),
                  );
            },
            onTaskCreated: () async {
              AppLogger.debug('🎯 Task created, refreshing list');
              context.read<TaskListBloc>().add(const TaskListRefreshRequested());
              context.read<TaskListBloc>().add(
                    const TaskListTaskCreationCompleted(),
                  );
            },
          ),

        // Task list con drag-and-drop
        Expanded(
          child: isReorderable
              ? _buildReorderableList()
              : _buildStaticList(),
        ),
      ],
    );
  }

  Widget _buildReorderableList() {
    return AnimatedReorderableListView<Task>(
      items: _displayedTasks,
      padding: const EdgeInsets.all(8),
      buildDefaultDragHandles: true,
      longPressDraggable: false,
      insertDuration: const Duration(milliseconds: 0),
      removeDuration: const Duration(milliseconds: 0),
      isSameItem: (a, b) => a.id == b.id,
      onReorder: _handleManualReorder,
      itemBuilder: (context, index) {
        final task = _displayedTasks[index];

        // ✅ USA COMPONENTE: _GranularHighlightedTaskItem con mixin
        return KeyedSubtree(
          key: ValueKey('task_${task.id}'),
          child: _GranularHighlightedTaskItem(
            task: task,
            document: widget.document,
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            onShowTaskDetails: _showTaskDetails,
          ),
        );
      },
    );
  }

  Widget _buildStaticList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _displayedTasks.length,
      itemBuilder: (context, index) {
        final task = _displayedTasks[index];

        // ✅ USA COMPONENTE: _GranularHighlightedTaskItem con mixin
        return _GranularHighlightedTaskItem(
          key: ValueKey('task_${task.id}'),
          task: task,
          document: widget.document,
          showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
          onShowTaskDetails: _showTaskDetails,
        );
      },
    );
  }

  void startInlineCreation() {
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

/// ✅ USA MIXIN: HighlightAnimationMixin invece di codice duplicato
///
/// Granular task item con highlight animation riutilizzabile
class _GranularHighlightedTaskItem extends StatefulWidget {
  final Task task;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(BuildContext, Task) onShowTaskDetails;

  const _GranularHighlightedTaskItem({
    super.key,
    required this.task,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.onShowTaskDetails,
  });

  @override
  State<_GranularHighlightedTaskItem> createState() =>
      _GranularHighlightedTaskItemState();
}

class _GranularHighlightedTaskItemState
    extends State<_GranularHighlightedTaskItem>
    with SingleTickerProviderStateMixin, HighlightAnimationMixin {
  late final AlwaysNotifyValueNotifier<Task> _taskNotifier;

  @override
  void initState() {
    super.initState();

    // Granular rebuild con TaskStateManager
    final stateManager = TaskStateManager();
    _taskNotifier = stateManager.getOrCreateTaskNotifier(
      widget.task.id,
      widget.task,
    );

    // ✅ USA MIXIN: initHighlightAnimation dal mixin
    initHighlightAnimation();
    startHighlightAnimation();
  }

  @override
  void dispose() {
    // ✅ USA MIXIN: disposeHighlightAnimation dal mixin
    disposeHighlightAnimation();
    _taskNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Granular rebuild: solo questo task si ricostruisce
    return ValueListenableBuilder<Task>(
      valueListenable: _taskNotifier,
      builder: (context, updatedTask, _) {
        // ✅ USA MIXIN: buildWithHighlight dal mixin
        return buildWithHighlight(
          context,
          child: TaskListItem(
            task: updatedTask,
            document: widget.document,
            onTap: () => widget.onShowTaskDetails(context, updatedTask),
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            dismissibleEnabled: true,
          ),
        );
      },
    );
  }
}
