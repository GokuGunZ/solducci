import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_form.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';
import 'package:solducci/utils/task_filter_sort.dart';

/// View showing all tasks (pending + in progress + assigned) for a document
///
/// Architecture:
/// - Uses ValueNotifier for filter/sort config to enable granular rebuilds
/// - Filter UI updates instantly without affecting the task list
/// - Task list rebuilds independently only when filters actually change
/// - Prevents unnecessary CircularProgressIndicator during filter changes
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
  Stream<List<Task>>? _taskStream;

  // Use ValueNotifier for granular rebuilds
  final ValueNotifier<FilterSortConfig> _filterConfigNotifier =
      ValueNotifier(const FilterSortConfig());

  bool _isCreatingTask = false;

  @override
  void initState() {
    super.initState();
    _taskStream = _taskService.getTasksForDocument(widget.document.id);
    // Pass the inline creation callback to parent
    widget.onInlineCreationCallbackChanged?.call(startInlineCreation);
  }

  @override
  void dispose() {
    _filterConfigNotifier.dispose();
    super.dispose();
  }

  void _refreshTasks() {
    setState(() {
      _taskStream = _taskService.getTasksForDocument(widget.document.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.withValues(alpha: 0.03),
            Colors.blue.withValues(alpha: 0.02),
            Colors.white,
          ],
        ),
      ),
      child: Column(
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
              isCreatingTask: _isCreatingTask,
              onCancelCreation: () {
                setState(() {
                  _isCreatingTask = false;
                });
              },
              onTaskCreated: () {
                setState(() {
                  _isCreatingTask = false;
                });
                _refreshTasks();
              },
              onRefresh: _refreshTasks,
              onShowTaskDetails: _showTaskDetails,
            ),
          ),
        ],
      ),
    );
  }

  void startInlineCreation() {
    setState(() {
      _isCreatingTask = true;
    });
  }

  void _showTaskDetails(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskForm(
          document: widget.document,
          task: task,
          onTaskSaved: _refreshTasks, // Refresh after task is saved
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
  final bool isCreatingTask;
  final VoidCallback onCancelCreation;
  final VoidCallback onTaskCreated;
  final VoidCallback onRefresh;
  final void Function(BuildContext, Task) onShowTaskDetails;

  const _TaskListSection({
    required this.taskStream,
    required this.filterConfigNotifier,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.isCreatingTask,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onRefresh,
    required this.onShowTaskDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to filter changes - only this widget rebuilds!
    return ValueListenableBuilder<FilterSortConfig>(
      valueListenable: filterConfigNotifier,
      builder: (context, filterConfig, _) {
        return StreamBuilder<List<Task>>(
          stream: taskStream,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Errore: ${snapshot.error}'),
                  ],
                ),
              );
            }

            // Get tasks and filter out completed ones
            final allTasks = snapshot.data ?? [];
            var tasks = allTasks
                .where((t) => t.status != TaskStatus.completed)
                .toList();

            // If tag filter is active, use async filtering
            if (filterConfig.tagIds.isNotEmpty) {
              return FutureBuilder<List<Task>>(
                future: tasks.applyFilterSortAsync(filterConfig),
                builder: (context, asyncSnapshot) {
                  if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (asyncSnapshot.hasError) {
                    return Center(child: Text('Errore: ${asyncSnapshot.error}'));
                  }
                  return _TaskListContent(
                    tasks: asyncSnapshot.data ?? [],
                    filterConfig: filterConfig,
                    document: document,
                    showAllPropertiesNotifier: showAllPropertiesNotifier,
                    isCreatingTask: isCreatingTask,
                    onCancelCreation: onCancelCreation,
                    onTaskCreated: onTaskCreated,
                    onRefresh: onRefresh,
                    onShowTaskDetails: onShowTaskDetails,
                  );
                },
              );
            }

            // Apply filters and sorting (synchronous)
            tasks = tasks.applyFilterSort(filterConfig);

            return _TaskListContent(
              tasks: tasks,
              filterConfig: filterConfig,
              document: document,
              showAllPropertiesNotifier: showAllPropertiesNotifier,
              isCreatingTask: isCreatingTask,
              onCancelCreation: onCancelCreation,
              onTaskCreated: onTaskCreated,
              onRefresh: onRefresh,
              onShowTaskDetails: onShowTaskDetails,
            );
          },
        );
      },
    );
  }
}

/// Content widget with preloaded tags
class _TaskListContent extends StatelessWidget {
  final List<Task> tasks;
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final bool isCreatingTask;
  final VoidCallback onCancelCreation;
  final VoidCallback onTaskCreated;
  final VoidCallback onRefresh;
  final void Function(BuildContext, Task) onShowTaskDetails;

  const _TaskListContent({
    required this.tasks,
    required this.filterConfig,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.isCreatingTask,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onRefresh,
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
          tasks: tasks,
          filterConfig: filterConfig,
          document: document,
          showAllPropertiesNotifier: showAllPropertiesNotifier,
          isCreatingTask: isCreatingTask,
          onCancelCreation: onCancelCreation,
          onTaskCreated: onTaskCreated,
          onRefresh: onRefresh,
          onShowTaskDetails: onShowTaskDetails,
          taskTagsMap: taskTagsMap,
        );
      },
    );
  }
}

/// Final widget that renders the actual list
class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final FilterSortConfig filterConfig;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final bool isCreatingTask;
  final VoidCallback onCancelCreation;
  final VoidCallback onTaskCreated;
  final VoidCallback onRefresh;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final Map<String, List<Tag>> taskTagsMap;

  const _TaskList({
    required this.tasks,
    required this.filterConfig,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.isCreatingTask,
    required this.onCancelCreation,
    required this.onTaskCreated,
    required this.onRefresh,
    required this.onShowTaskDetails,
    required this.taskTagsMap,
  });

  @override
  Widget build(BuildContext context) {
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

    // Task list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: tasks.length + (isCreatingTask ? 1 : 0),
        itemBuilder: (context, index) {
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
          final task = tasks[taskIndex];
          return TaskListItem(
            task: task,
            document: document,
            onTap: () => onShowTaskDetails(context, task),
            onTaskChanged: onRefresh,
            showAllPropertiesNotifier: showAllPropertiesNotifier,
            preloadedTags: taskTagsMap[task.id],
            taskTagsMap: taskTagsMap,
          );
        },
      ),
    );
  }
}
