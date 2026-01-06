import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/blocs/unified_task_list/unified_task_list_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/features/documents/presentation/components/granular_task_item.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// Unified task list view component
///
/// This component replaces the duplicated logic between AllTasksView and TagView.
/// It works with any TaskListDataSource (document, tag, search, etc.) via UnifiedTaskListBloc.
///
/// Features:
/// - Granular rebuild system (TaskStateManager + ValueListenableBuilder)
/// - Highlight animations for new/repositioned tasks
/// - Inline task creation
/// - Filtering and sorting
/// - Optional drag-and-drop reordering
/// - Empty/loading/error states
///
/// Usage:
/// ```dart
/// TaskListView(
///   document: document,
///   dataSource: DocumentTaskDataSource(...),
///   supportsReordering: true,
/// )
/// ```
class TaskListView extends StatelessWidget {
  final TodoDocument document;
  final TaskListDataSource dataSource;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;
  final List<Tag>? initialTags; // For tag-filtered views
  final bool showCompletedSection; // For tag views with separate completed section

  const TaskListView({
    super.key,
    required this.document,
    required this.dataSource,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
    this.initialTags,
    this.showCompletedSection = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<UnifiedTaskListBloc>();
        bloc.add(TaskListLoadRequested(dataSource));
        return bloc;
      },
      child: _TaskListViewContent(
        document: document,
        showAllPropertiesNotifier: showAllPropertiesNotifier,
        onInlineCreationCallbackChanged: onInlineCreationCallbackChanged,
        availableTags: availableTags,
        initialTags: initialTags,
        showCompletedSection: showCompletedSection,
      ),
    );
  }
}

/// Content widget with AutomaticKeepAliveClientMixin
class _TaskListViewContent extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags;
  final List<Tag>? initialTags;
  final bool showCompletedSection;

  const _TaskListViewContent({
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
    this.initialTags,
    required this.showCompletedSection,
  });

  @override
  State<_TaskListViewContent> createState() => _TaskListViewContentState();
}

class _TaskListViewContentState extends State<_TaskListViewContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Pass inline creation callback to parent
    widget.onInlineCreationCallbackChanged?.call(startInlineCreation);
  }

  void startInlineCreation() {
    context.read<UnifiedTaskListBloc>().add(const TaskListTaskCreationStarted());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Filter bar
        BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
          builder: (context, state) {
            final filterConfig = state is TaskListLoaded
                ? state.filterConfig
                : const FilterSortConfig();

            return CompactFilterSortBar(
              key: const ValueKey('compact_filter_sort_bar'),
              filterConfig: filterConfig,
              onFilterChanged: (newConfig) {
                context.read<UnifiedTaskListBloc>().add(
                      TaskListFilterChanged(newConfig),
                    );
              },
              availableTags: widget.availableTags,
            );
          },
        ),

        // Task list section
        Expanded(
          child: BlocBuilder<UnifiedTaskListBloc, UnifiedTaskListState>(
            builder: (context, state) {
              return switch (state) {
                TaskListInitial() => const SizedBox.shrink(),

                TaskListLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),

                TaskListError(:final message) => _buildErrorState(context, message),

                TaskListLoaded(
                  :final tasks,
                  :final isCreatingTask,
                  :final supportsReordering,
                ) =>
                  _TaskListSection(
                    document: widget.document,
                    tasks: tasks,
                    isCreatingTask: isCreatingTask,
                    supportsReordering: supportsReordering,
                    showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                    initialTags: widget.initialTags,
                    showCompletedSection: widget.showCompletedSection,
                    onTaskCreated: _onTaskCreated,
                    onCancelCreation: _onCancelCreation,
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
          const Text('Errore nel caricamento'),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<UnifiedTaskListBloc>().add(
                  const TaskListRefreshRequested(),
                ),
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Future<void> _onTaskCreated() async {
    AppLogger.debug('🎯 TaskListView: onTaskCreated callback START');
    context.read<UnifiedTaskListBloc>().add(const TaskListTaskCreationCompleted());
    AppLogger.debug('🎯 TaskListView: onTaskCreated callback END');
  }

  void _onCancelCreation() {
    context.read<UnifiedTaskListBloc>().add(const TaskListTaskCreationCompleted());
  }
}

/// Task list section with inline creation row
class _TaskListSection extends StatefulWidget {
  final TodoDocument document;
  final List<Task> tasks;
  final bool isCreatingTask;
  final bool supportsReordering;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final List<Tag>? initialTags;
  final bool showCompletedSection;
  final Future<void> Function() onTaskCreated;
  final VoidCallback onCancelCreation;

  const _TaskListSection({
    required this.document,
    required this.tasks,
    required this.isCreatingTask,
    required this.supportsReordering,
    this.showAllPropertiesNotifier,
    this.initialTags,
    required this.showCompletedSection,
    required this.onTaskCreated,
    required this.onCancelCreation,
  });

  @override
  State<_TaskListSection> createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<_TaskListSection> {
  final _taskService = TaskService();
  Map<String, List<Tag>> _taskTagsMap = {};

  @override
  void initState() {
    super.initState();
    _preloadTagsForTasks(widget.tasks);
  }

  @override
  void didUpdateWidget(_TaskListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _preloadTagsForTasks(widget.tasks);
    }
  }

  Future<void> _preloadTagsForTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    _taskTagsMap = await _taskService.getEffectiveTagsForTasksWithSubtasks(tasks);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Separate completed and non-completed tasks
    final activeTasks = widget.tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();
    final completedTasks = widget.tasks
        .where((t) => t.status == TaskStatus.completed)
        .toList();

    // Empty state
    if (widget.tasks.isEmpty && !widget.isCreatingTask) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna task',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi la tua prima task!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Inline task creation row (appears at top when creating)
        if (widget.isCreatingTask)
          TaskCreationRow(
            document: widget.document,
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            initialTags: widget.initialTags,
            onCancel: widget.onCancelCreation,
            onTaskCreated: widget.onTaskCreated,
          ),

        // Main task list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<UnifiedTaskListBloc>().add(
                    const TaskListRefreshRequested(),
                  );
            },
            child: widget.supportsReordering
                ? ReorderableListView.builder(
                    padding: const EdgeInsets.all(8),
                    buildDefaultDragHandles: false,
                    itemCount: activeTasks.length,
                    onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex, activeTasks),
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final task = activeTasks[index];
                      return ReorderableDragStartListener(
                        key: ValueKey('task_${task.id}'),
                        index: index,
                        child: GranularTaskItem(
                          task: task,
                          document: widget.document,
                          onShowTaskDetails: _showTaskDetails,
                          showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                          taskTagsMap: _taskTagsMap,
                          animateIfNew: true,
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: activeTasks.length,
                    itemBuilder: (context, index) {
                      final task = activeTasks[index];
                      return GranularTaskItem(
                        key: ValueKey('task_${task.id}'),
                        task: task,
                        document: widget.document,
                        onShowTaskDetails: _showTaskDetails,
                        showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                        taskTagsMap: _taskTagsMap,
                        animateIfNew: true,
                      );
                    },
                  ),
          ),
        ),

        // Completed tasks section (for tag views)
        if (widget.showCompletedSection && completedTasks.isNotEmpty)
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
                ...completedTasks.map(
                  (task) => TaskListItem(
                    key: ValueKey('task_${task.id}'),
                    task: task,
                    document: widget.document,
                    onTap: () => _showTaskDetails(context, task),
                    showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                    preloadedTags: _taskTagsMap[task.id],
                    taskTagsMap: _taskTagsMap,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _handleReorder(int oldIndex, int newIndex, List<Task> tasks) {
    // Adjust newIndex if moving down (ReorderableListView behavior)
    // When moving an item down, ReorderableListView provides newIndex as if
    // the item hasn't been removed yet, so we need to subtract 1
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Dispatch reorder event to BLoC
    context.read<UnifiedTaskListBloc>().add(
          TaskListTaskReordered(
            oldIndex: oldIndex,
            newIndex: newIndex,
          ),
        );
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
