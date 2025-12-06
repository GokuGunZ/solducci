import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_form.dart';

/// Widget for displaying a task in a list with checkbox, dismissible actions, and expandable subtasks
class TaskListItem extends StatefulWidget {
  final Task task;
  final TodoDocument? document; // Optional: needed for creating subtasks
  final VoidCallback? onTap;
  final VoidCallback? onTaskChanged; // Callback when task is modified/deleted/duplicated
  final int depth; // For indentation of subtasks

  const TaskListItem({
    super.key,
    required this.task,
    this.document,
    this.onTap,
    this.onTaskChanged,
    this.depth = 0,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isExpanded = false;
  final _taskService = TaskService();
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _checkRecurrence();
  }

  Future<void> _checkRecurrence() async {
    final recurrence = await _taskService.getEffectiveRecurrence(widget.task.id);
    if (mounted && recurrence != null && recurrence.isActive) {
      setState(() {
        _isRecurring = true;
      });
    }
  }

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
              trailing: _buildTrailingActions(),
              onTap: widget.onTap,
            ),

            // Subtasks (expandable)
            if (_isExpanded && widget.task.hasSubtasks)
              Column(
                children: widget.task.subtasks!
                    .map((subtask) => TaskListItem(
                          task: subtask,
                          document: widget.document,
                          depth: widget.depth + 1,
                          onTap: widget.onTap,
                          onTaskChanged: widget.onTaskChanged, // Propagate callback
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildTrailingActions() {
    if (!widget.task.hasSubtasks) {
      // No subtasks: show only "add subtask" button
      return IconButton(
        icon: const Icon(Icons.add_circle_outline, size: 20),
        onPressed: _showAddSubtaskDialog,
        tooltip: 'Aggiungi sub-task',
      );
    }

    // Has subtasks: show expand/collapse and "add subtask" buttons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: _showAddSubtaskDialog,
          tooltip: 'Aggiungi sub-task',
        ),
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          tooltip: _isExpanded ? 'Comprimi' : 'Espandi',
        ),
      ],
    );
  }

  void _showAddSubtaskDialog() {
    if (widget.document == null) {
      // Cannot create subtask without document
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile creare sub-task')),
      );
      return;
    }

    // Navigate to TaskForm with parentTaskId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskForm(
          document: widget.document!,
          parentTaskId: widget.task.id,
        ),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final chips = <Widget>[];

    // Status indicator (only for assigned/inProgress)
    if (widget.task.status == TaskStatus.assigned ||
        widget.task.status == TaskStatus.inProgress) {
      final statusColor = widget.task.status == TaskStatus.assigned
          ? Colors.blue
          : Colors.orange;
      final statusLabel = widget.task.status == TaskStatus.assigned
          ? 'Assegnata'
          : 'In corso';

      chips.add(
        Chip(
          avatar: Icon(
            Icons.flag,
            size: 14,
            color: statusColor,
          ),
          label: Text(
            statusLabel,
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: statusColor.withAlpha(50),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    // Recurrence indicator
    if (_isRecurring) {
      chips.add(
        Chip(
          avatar: const Icon(
            Icons.repeat,
            size: 14,
            color: Colors.orange,
          ),
          label: const Text(
            'Ricorrente',
            style: TextStyle(fontSize: 10),
          ),
          backgroundColor: Colors.orange.withAlpha(50),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

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

      widget.onTaskChanged?.call(); // Trigger refresh

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
        widget.onTaskChanged?.call(); // Trigger refresh
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
      widget.onTaskChanged?.call(); // Trigger refresh
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
