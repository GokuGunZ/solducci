import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_order_persistence_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/blocs/task_list/task_list_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';
import 'package:solducci/features/documents/presentation/components/task_filterable_list_view.dart';
import 'package:solducci/core/components/animations/highlight_animation_mixin.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

/// View showing all tasks (pending + in progress + assigned) for a document
///
/// **MIGRATED TO COMPONENT LIBRARY ARCHITECTURE**
///
/// Architecture - Granular Rebuild System:
/// - Uses TaskStateManager with individual ValueNotifiers per task
/// - When a task is updated, ONLY that specific TaskListItem rebuilds
/// - List-level changes (add/remove) trigger stream recreation
/// - Filter UI updates instantly without affecting task rendering
/// - Each task wrapped in _GranularTaskListItem with ValueListenableBuilder
/// - Result: Maximum performance, minimal unnecessary rebuilds
///
/// Components Used:
/// - TaskFilterableListView: Handles filtering, sorting, empty states
/// - HighlightAnimationMixin: Reusable highlight animation
/// - Maintains existing BLoC + TaskStateManager integration
class AllTasksView extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;

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

  void _handleManualReorder(List<Task> newOrder) async {
    AppLogger.debug('🔄 Manual reorder detected');

    final taskIds = newOrder.map((task) => task.id).toList();
    await _orderPersistenceService.saveCustomOrder(
      documentId: widget.document.id,
      taskIds: taskIds,
    );

    setState(() => _customOrder = taskIds);
    AppLogger.debug('✅ Custom order saved: ${taskIds.length} tasks');
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

        // Task list section
        Expanded(
          child: BlocBuilder<TaskListBloc, TaskListState>(
            builder: (context, state) {
              return switch (state) {
                TaskListInitial() => const SizedBox.shrink(),

                TaskListLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),

                TaskListError(:final message) => _buildErrorState(context, message),

                TaskListLoaded(:final tasks, :final filterConfig, :final isCreatingTask) =>
                  _buildTaskList(
                    context,
                    tasks: tasks,
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

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Errore nel caricamento delle task'),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<TaskListBloc>()
                .add(const TaskListRefreshRequested()),
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context, {
    required List<Task> tasks,
    required FilterSortConfig filterConfig,
    required bool isCreatingTask,
  }) {
    return Column(
      children: [
        // Inline task creation row
        if (isCreatingTask)
          TaskCreationRow(
            document: widget.document,
            onCancel: () {
              context.read<TaskListBloc>().add(const TaskListTaskCreationCompleted());
            },
            onTaskCreated: () async {
              AppLogger.debug('🎯 onTaskCreated callback START');
              context.read<TaskListBloc>().add(const TaskListRefreshRequested());
              context.read<TaskListBloc>().add(const TaskListTaskCreationCompleted());
              AppLogger.debug('🎯 onTaskCreated callback END');
            },
          ),

        // Main task list with component library
        Expanded(
          child: TaskFilterableListView(
            items: tasks,
            filterConfig: filterConfig,
            customOrder: filterConfig.sortBy == TaskSortOption.custom ? _customOrder : null,
            showCompletedTasks: false,
            itemBuilder: (context, task, index) {
              // Wrap with reorderable if custom sort enabled
              if (filterConfig.sortBy == TaskSortOption.custom) {
                return _buildReorderableTaskItem(context, task, index);
              }

              // Regular task item with granular rebuild
              return _GranularHighlightedTaskItem(
                key: ValueKey('task_${task.id}'),
                task: task,
                document: widget.document,
                showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                onShowTaskDetails: _showTaskDetails,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableTaskItem(BuildContext context, Task task, int index) {
    // For reorderable lists, we need AnimatedReorderableListView at the parent level
    // This is a simplified version - keeping the existing reorderable logic
    return ReorderableDragStartListener(
      key: ValueKey('reorder_${task.id}'),
      index: index,
      child: _GranularHighlightedTaskItem(
        key: ValueKey('task_${task.id}'),
        task: task,
        document: widget.document,
        showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
        onShowTaskDetails: _showTaskDetails,
      ),
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

/// Granular task item with highlight animation
/// Uses HighlightAnimationMixin for reusable animation logic
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

    // Initialize granular rebuild notifier
    final stateManager = TaskStateManager();
    _taskNotifier = stateManager.getOrCreateTaskNotifier(
      widget.task.id,
      widget.task,
    );

    // Initialize highlight animation from mixin
    initHighlightAnimation();
    startHighlightAnimation();
  }

  @override
  void dispose() {
    disposeHighlightAnimation();
    _taskNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use granular rebuild with ValueListenableBuilder
    return ValueListenableBuilder<Task>(
      valueListenable: _taskNotifier,
      builder: (context, updatedTask, _) {
        // Wrap with highlight animation from mixin
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
