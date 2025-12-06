import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';

/// Widget for displaying a task in a list with checkbox, dismissible actions, and expandable subtasks
class TaskListItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final int depth; // For indentation of subtasks

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.depth = 0,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isExpanded = false;
  final _taskService = TaskService();

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.task.id),
      background: _buildDeleteBackground(),
      secondaryBackground: _buildDuplicateBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Duplicate
          await _duplicateTask();
          return false;
        } else {
          // Delete
          return await _showDeleteConfirmation();
        }
      },
      child: Card(
        margin: EdgeInsets.only(
          left: 8.0 + (widget.depth * 16.0),
          right: 8.0,
          top: 4.0,
          bottom: 4.0,
        ),
        elevation: 2,
        child: Column(
          children: [
            ListTile(
              leading: Checkbox(
                value: widget.task.isCompleted,
                onChanged: (_) => _toggleComplete(),
                activeColor: Colors.green,
              ),
              title: Text(
                widget.task.title,
                style: widget.task.isCompleted
                    ? const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      )
                    : null,
              ),
              subtitle: _buildSubtitle(),
              trailing: widget.task.hasSubtasks
                  ? IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    )
                  : null,
              onTap: widget.onTap,
            ),

            // Subtasks (expandable)
            if (_isExpanded && widget.task.hasSubtasks)
              Column(
                children: widget.task.subtasks!
                    .map((subtask) => TaskListItem(
                          task: subtask,
                          depth: widget.depth + 1,
                          onTap: widget.onTap,
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final chips = <Widget>[];

    // Priority indicator
    if (widget.task.priority != null) {
      chips.add(
        Chip(
          label: Text(
            widget.task.priority!.label,
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: widget.task.priority!.color.withAlpha(100),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    // Due date
    if (widget.task.dueDate != null) {
      final isOverdue = widget.task.isOverdue;
      chips.add(
        Chip(
          avatar: Icon(
            Icons.calendar_today,
            size: 14,
            color: isOverdue ? Colors.red : Colors.blue,
          ),
          label: Text(
            DateFormat('dd/MM').format(widget.task.dueDate!),
            style: TextStyle(
              fontSize: 10,
              color: isOverdue ? Colors.red : null,
            ),
          ),
          backgroundColor:
              isOverdue ? Colors.red.withAlpha(50) : Colors.blue.withAlpha(50),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    // T-shirt size
    if (widget.task.tShirtSize != null) {
      chips.add(
        Chip(
          label: Text(
            widget.task.tShirtSize!.label,
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: Colors.grey.withAlpha(50),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    // Subtasks count
    if (widget.task.hasSubtasks) {
      final completedCount = widget.task.subtasks!
          .where((t) => t.status == TaskStatus.completed)
          .length;
      final totalCount = widget.task.subtasks!.length;

      chips.add(
        Chip(
          avatar: const Icon(Icons.list, size: 14),
          label: Text(
            '$completedCount/$totalCount',
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: Colors.purple.withAlpha(50),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    if (chips.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildDuplicateBackground() {
    return Container(
      color: Colors.blue,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.content_copy, color: Colors.white),
    );
  }

  Future<void> _toggleComplete() async {
    try {
      if (widget.task.isCompleted) {
        await _taskService.uncompleteTask(widget.task.id);
      } else {
        await _taskService.completeTask(widget.task.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task.isCompleted
                  ? 'Task ripristinata'
                  : 'Task completata',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina task'),
        content: Text(
          'Vuoi davvero eliminare "${widget.task.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _taskService.deleteTask(widget.task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task eliminata')),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')),
          );
        }
        return false;
      }
    }

    return false;
  }

  Future<void> _duplicateTask() async {
    try {
      await _taskService.duplicateTask(widget.task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task duplicata')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }
}
