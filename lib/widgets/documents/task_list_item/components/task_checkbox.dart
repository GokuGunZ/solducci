import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Checkbox widget for task completion status
///
/// Features:
/// - Visual feedback during toggle operation
/// - Special styling for parent tasks (with subtasks)
/// - Circular shape for root-level tasks with subtasks
/// - Standard rounded rectangle for leaf tasks
class TaskCheckbox extends StatelessWidget {
  /// The task to display the checkbox for
  final Task task;

  /// Whether the checkbox is currently being toggled
  final bool isToggling;

  /// Callback when the checkbox is toggled
  final Future<void> Function(bool newValue) onToggle;

  /// Depth of the task in the hierarchy (0 = root level)
  final int depth;

  const TaskCheckbox({
    super.key,
    required this.task,
    required this.isToggling,
    required this.onToggle,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtasks = task.hasSubtasks;
    final isParent = depth == 0 && hasSubtasks;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle indicator for parent tasks
        if (isParent)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: TodoTheme.primaryPurple.withAlpha(50),
                width: 2,
              ),
            ),
          ),
        // Checkbox
        Checkbox(
          value: isToggling ? !task.isCompleted : task.isCompleted,
          onChanged: isToggling
              ? null // Disable during toggle to prevent double-tap
              : (newValue) => onToggle(newValue ?? false),
          activeColor: Colors.green,
          shape: isParent ? const CircleBorder() : null,
        ),
      ],
    );
  }
}
