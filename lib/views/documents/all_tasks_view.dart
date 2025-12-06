import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_form.dart';

/// View showing all tasks (pending + in progress + assigned) for a document
class AllTasksView extends StatefulWidget {
  final TodoDocument document;

  const AllTasksView({
    super.key,
    required this.document,
  });

  @override
  State<AllTasksView> createState() => _AllTasksViewState();
}

class _AllTasksViewState extends State<AllTasksView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final taskService = TaskService();

    return StreamBuilder<List<Task>>(
      stream: taskService.getTasksForDocument(widget.document.id),
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
        final tasks = allTasks
            .where((t) => t.status != TaskStatus.completed)
            .toList();

        // Empty state
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.grey[400]),
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

        // Task list
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskListItem(
              task: task,
              onTap: () => _showTaskDetails(context, task),
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
        builder: (context) => TaskForm(
          document: widget.document,
          task: task,
        ),
      ),
    );
  }
}
