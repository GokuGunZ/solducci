import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_form.dart';

/// View showing tasks filtered by a specific tag
class TagView extends StatefulWidget {
  final TodoDocument document;
  final Tag tag;

  const TagView({
    super.key,
    required this.document,
    required this.tag,
  });

  @override
  State<TagView> createState() => _TagViewState();
}

class _TagViewState extends State<TagView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Task>? _tasks;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final taskService = TaskService();
      final tasks = await taskService.getTasksByTag(
        widget.tag.id,
        includeCompleted: widget.tag.showCompleted,
      );

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    // No header bar, just the task list
    return _buildTaskList();
  }

  Widget _buildTaskList() {
    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Errore: $_error'),
          ],
        ),
      );
    }

    final tasks = _tasks ?? [];

    // Separate completed and non-completed tasks
    final activeTasks = tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();
    final completedTasks = tasks
        .where((t) => t.status == TaskStatus.completed)
        .toList();

    // Empty state
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessuna task con questo tag',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Task list with completed at bottom
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Active tasks
        ...activeTasks.map((task) => TaskListItem(
              task: task,
              onTap: () => _showTaskDetails(context, task),
            )),

        // Completed tasks (if enabled)
        if (widget.tag.showCompleted && completedTasks.isNotEmpty) ...[
          const Divider(height: 32),
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
                task: task,
                onTap: () => _showTaskDetails(context, task),
              )),
        ],
      ],
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
