import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';

/// View showing only completed tasks for a document
class CompletedTasksView extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const CompletedTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
  });

  @override
  State<CompletedTasksView> createState() => _CompletedTasksViewState();
}

class _CompletedTasksViewState extends State<CompletedTasksView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _taskService = TaskService();
  late final Stream<List<Task>> _taskStream;
  Map<String, List<Tag>> _taskTagsMap = {}; // Cache for preloaded tags

  @override
  void initState() {
    super.initState();
    // Initialize stream once - Supabase realtime will handle updates automatically
    _taskStream = _taskService.getTasksForDocument(widget.document.id)
        .map((tasks) => tasks.where((t) => t.status == TaskStatus.completed).toList());
  }

  Future<void> _preloadTagsForTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    // Use the new method that includes subtasks
    _taskTagsMap = await _taskService.getEffectiveTagsForTasksWithSubtasks(tasks);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return StreamBuilder<List<Task>>(
      stream: _taskStream,
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

        final tasks = snapshot.data ?? [];

        // Empty state
        if (tasks.isEmpty) {
          return Center(
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
          );
        }

        // Preload tags for all tasks
        return FutureBuilder<void>(
          future: _preloadTagsForTasks(tasks),
          builder: (context, tagsSnapshot) {
            if (tagsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Task list - no refresh needed, stream updates automatically
            return Container(
              color: Colors.transparent, // CRITICAL: Prevent ListView default white background
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                final task = tasks[index];
                // Use unique key based on task id to optimize rebuilds
                return TaskListItem(
                  key: ValueKey('task_${task.id}'),
                  task: task,
                  document: widget.document,
                  onTap: () => _showTaskDetails(context, task),
                  // No onTaskChanged - stream will update automatically
                  showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                  preloadedTags: _taskTagsMap[task.id],
                  taskTagsMap: _taskTagsMap, // Pass full map for subtasks
                );
              },
              ),
            );
          },
        );
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
