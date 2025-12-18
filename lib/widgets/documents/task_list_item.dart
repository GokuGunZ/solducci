import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_form.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Widget for displaying a task in a list with checkbox, dismissible actions, and expandable subtasks
class TaskListItem extends StatefulWidget {
  final Task task;
  final TodoDocument? document; // Optional: needed for creating subtasks
  final VoidCallback? onTap;
  final VoidCallback?
  onTaskChanged; // Callback when task is modified/deleted/duplicated
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
  List<Tag> _tags = [];
  bool _isTogglingComplete = false; // Track if toggle is in progress

  @override
  void initState() {
    super.initState();
    _checkRecurrence();
    _loadTags();
  }

  Future<void> _checkRecurrence() async {
    final recurrence = await _taskService.getEffectiveRecurrence(
      widget.task.id,
    );
    if (mounted && recurrence != null && recurrence.isActive) {
      setState(() {
        _isRecurring = true;
      });
    }
  }

  Future<void> _loadTags() async {
    final tags = await _taskService.getEffectiveTags(widget.task.id);
    if (mounted) {
      setState(() {
        _tags = tags;
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
            InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Checkbox, Title, and Subtask chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        Checkbox(
                          value: _isTogglingComplete
                              ? !widget.task.isCompleted
                              : widget.task.isCompleted,
                          onChanged: _isTogglingComplete
                              ? null
                              : (_) => _toggleComplete(),
                          activeColor: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        // Title
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              widget.task.title,
                              style: widget.task.isCompleted
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 16,
                                    )
                                  : const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Trailing actions (subtask chip or add button)
                        if (_buildTrailingActions() != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildTrailingActions()!,
                          ),
                      ],
                    ),
                    // Bottom section: Description, chips, and tags
                    if (_buildSubtitle() != null) _buildSubtitle()!,
                  ],
                ),
              ),
            ),

            // Subtasks (expandable)
            if (_isExpanded && widget.task.hasSubtasks)
              Column(
                children: widget.task.subtasks!
                    .map(
                      (subtask) => TaskListItem(
                        task: subtask,
                        document: widget.document,
                        depth: widget.depth + 1,
                        onTap: widget.onTap,
                        onTaskChanged:
                            widget.onTaskChanged, // Propagate callback
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildTrailingActions() {
    if (!widget.task.hasSubtasks) {
      // No subtasks: show only "add subtask" icon button
      return IconButton(
        icon: const Icon(Icons.add_circle_outline, size: 20),
        onPressed: _showAddSubtaskDialog,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Aggiungi sub-task',
      );
    }

    // Has subtasks: show interactive chip with counter and actions
    return _buildSubtaskChip();
  }

  Widget _buildSubtaskChip() {
    final completedCount = widget.task.subtasks!
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final totalCount = widget.task.subtasks!.length;

    return Container(
      decoration: BoxDecoration(
        color: TodoTheme.primaryPurple.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TodoTheme.primaryPurple.withAlpha(100),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Counter (tappable to expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$completedCount/$totalCount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: TodoTheme.primaryPurple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Divider
          Container(
            width: 1.5,
            height: 20,
            color: TodoTheme.primaryPurple.withAlpha(80),
          ),
          const SizedBox(width: 6),
          // Add subtask button
          InkWell(
            onTap: _showAddSubtaskDialog,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.add_circle_outline,
                size: 20,
                color: TodoTheme.primaryPurple,
              ),
            ),
          ),
        ],
      ),
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
        builder: (context) =>
            TaskForm(document: widget.document!, parentTaskId: widget.task.id),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final hasDescription =
        widget.task.description != null && widget.task.description!.isNotEmpty;
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
          avatar: Icon(Icons.flag, size: 14, color: statusColor),
          label: Text(statusLabel, style: const TextStyle(fontSize: 10)),
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
          avatar: const Icon(Icons.repeat, size: 14, color: Colors.orange),
          label: const Text('Ricorrente', style: TextStyle(fontSize: 10)),
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
          backgroundColor: isOverdue
              ? Colors.red.withAlpha(50)
              : Colors.blue.withAlpha(50),
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

    // Note: Subtasks count is now shown in the trailing chip, not here

    // Return null if no description, no chips, and no tags
    if (!hasDescription && chips.isEmpty && _tags.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description text
          if (hasDescription) ...[
            Text(
              widget.task.description!,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (chips.isNotEmpty || _tags.isNotEmpty) const SizedBox(height: 8),
          ],

          // Row with chips on left and tag indicators on right
          if (chips.isNotEmpty || _tags.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Chips (indicators) on the left
                if (chips.isNotEmpty)
                  Expanded(
                    child: Wrap(spacing: 4, runSpacing: 4, children: chips),
                  ),

                // Spacer to push tags to the right
                if (chips.isNotEmpty && _tags.isNotEmpty)
                  const SizedBox(width: 8),

                // Tag indicators (colored circles with icons) on the bottom right
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: _tags.map((tag) {
                      final color = tag.colorObject ?? Colors.grey;
                      return Tooltip(
                        message: tag.name,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withAlpha(100),
                                blurRadius: 3,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: Icon(
                            tag.iconData ?? Icons.label,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
        ],
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
    if (_isTogglingComplete) return; // Prevent double-tap

    final wasCompleted = widget.task.isCompleted;

    // Set toggling state for immediate visual feedback
    setState(() {
      _isTogglingComplete = true;
    });

    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasCompleted ? 'Task ripristinata' : 'Task completata'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Update database
    try {
      if (wasCompleted) {
        await _taskService.uncompleteTask(widget.task.id);
      } else {
        await _taskService.completeTask(widget.task.id);
      }

      // Trigger refresh to update all views (this will reload from DB)
      if (mounted) {
        widget.onTaskChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      // Reset toggling state
      if (mounted) {
        setState(() {
          _isTogglingComplete = false;
        });
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina task'),
        content: Text('Vuoi davvero eliminare "${widget.task.title}"?'),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Task eliminata')));
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Errore: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task duplicata')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }
}
