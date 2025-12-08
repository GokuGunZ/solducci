import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_form.dart';

/// View showing only completed tasks for a document
class CompletedTasksView extends StatefulWidget {
  final TodoDocument document;

  const CompletedTasksView({
    super.key,
    required this.document,
  });

  @override
  State<CompletedTasksView> createState() => _CompletedTasksViewState();
}

class _CompletedTasksViewState extends State<CompletedTasksView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _taskService = TaskService();
  Stream<List<Task>>? _taskStream;

  @override
  void initState() {
    super.initState();
    _taskStream = _taskService.getTasksForDocument(widget.document.id)
        .map((tasks) => tasks.where((t) => t.status == TaskStatus.completed).toList());
  }

  void _refreshTasks() {
    setState(() {
      _taskStream = _taskService.getTasksForDocument(widget.document.id)
          .map((tasks) => tasks.where((t) => t.status == TaskStatus.completed).toList());
    });
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

        // Task list with pull-to-refresh
        return RefreshIndicator(
          onRefresh: () async {
            _refreshTasks();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskListItem(
                task: task,
                document: widget.document,
                onTap: () => _showTaskDetails(context, task),
                onTaskChanged: _refreshTasks, // Refresh on task change
              );
            },
          ),
        );
      },
    );
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
