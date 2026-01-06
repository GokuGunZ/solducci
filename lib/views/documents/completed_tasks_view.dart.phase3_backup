import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/blocs/task_list/task_list_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// View showing only completed tasks for a document
class CompletedTasksView extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const CompletedTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<TaskListBloc>();
        // Load tasks and filter to only show completed
        bloc.add(TaskListLoadRequested(document.id));
        bloc.add(TaskListFilterChanged(
          FilterSortConfig(statuses: {TaskStatus.completed}),
        ));
        return bloc;
      },
      child: _CompletedTasksViewContent(
        document: document,
        showAllPropertiesNotifier: showAllPropertiesNotifier,
      ),
    );
  }
}

class _CompletedTasksViewContent extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const _CompletedTasksViewContent({
    required this.document,
    this.showAllPropertiesNotifier,
  });

  @override
  State<_CompletedTasksViewContent> createState() => _CompletedTasksViewContentState();
}

class _CompletedTasksViewContentState extends State<_CompletedTasksViewContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _taskService = TaskService();
  Map<String, List<Tag>> _taskTagsMap = {}; // Cache for preloaded tags

  Future<void> _preloadTagsForTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    // Use the new method that includes subtasks
    _taskTagsMap = await _taskService.getEffectiveTagsForTasksWithSubtasks(tasks);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return BlocBuilder<TaskListBloc, TaskListState>(
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
                const Text('Errore nel caricamento'),
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
          ),

          TaskListLoaded(:final tasks) => tasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Nessuna task completata',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completa qualche task per vederla qui',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : FutureBuilder<void>(
                future: _preloadTagsForTasks(tasks),
                builder: (context, tagsSnapshot) {
                  if (tagsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Container(
                    color: Colors.transparent,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskListItem(
                          key: ValueKey('task_${task.id}'),
                          task: task,
                          document: widget.document,
                          onTap: () => _showTaskDetails(context, task),
                          showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                          preloadedTags: _taskTagsMap[task.id],
                          taskTagsMap: _taskTagsMap,
                        );
                      },
                    ),
                  );
                },
              ),
        };
      },
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
