import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Properties bar displaying task metadata chips (priority, date, size, recurrence)
///
/// Shows property chips in a horizontal row with glassmorphic styling.
/// Supports conditional visibility based on property values and toggle state.
class TaskPropertiesBar extends StatelessWidget {
  final Task task;
  final Recurrence? recurrence;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onPriorityTap;
  final VoidCallback onDueDateTap;
  final VoidCallback onSizeTap;
  final VoidCallback onRecurrenceTap;
  final VoidCallback? onRecurrenceRemove;

  const TaskPropertiesBar({
    super.key,
    required this.task,
    this.recurrence,
    this.showAllPropertiesNotifier,
    required this.onPriorityTap,
    required this.onDueDateTap,
    required this.onSizeTap,
    required this.onRecurrenceTap,
    this.onRecurrenceRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPriority = task.priority != null;
    final hasDueDate = task.dueDate != null;
    final hasSize = task.tShirtSize != null;
    final hasRecurrence = recurrence != null;

    // If no notifier provided, show only filled properties
    if (showAllPropertiesNotifier == null) {
      return _buildContent(
        showAll: false,
        hasPriority: hasPriority,
        hasDueDate: hasDueDate,
        hasSize: hasSize,
        hasRecurrence: hasRecurrence,
      );
    }

    // Use ValueListenableBuilder for reactive visibility
    return ValueListenableBuilder<bool>(
      valueListenable: showAllPropertiesNotifier!,
      builder: (context, showAll, _) {
        return _buildContent(
          showAll: showAll,
          hasPriority: hasPriority,
          hasDueDate: hasDueDate,
          hasSize: hasSize,
          hasRecurrence: hasRecurrence,
        );
      },
    );
  }

  Widget _buildContent({
    required bool showAll,
    required bool hasPriority,
    required bool hasDueDate,
    required bool hasSize,
    required bool hasRecurrence,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 48.0, right: 8.0),
      child: Row(
        children: [
          // Priority chip
          if (showAll || hasPriority) ...[
            _PropertyChip(
              icon: Icons.flag_outlined,
              color: task.priority?.color ?? Colors.grey[400]!,
              label: task.priority?.label,
              onTap: onPriorityTap,
            ),
            const SizedBox(width: 8),
          ],
          // Due date chip
          if (showAll || hasDueDate) ...[
            _PropertyChip(
              icon: Icons.calendar_today_outlined,
              color: hasDueDate
                  ? (task.isOverdue ? Colors.red : Colors.blue)
                  : Colors.grey[400]!,
              label: hasDueDate
                  ? DateFormat('dd/MM').format(task.dueDate!)
                  : null,
              onTap: onDueDateTap,
            ),
            const SizedBox(width: 8),
          ],
          // Size chip
          if (showAll || hasSize) ...[
            _PropertyChip(
              icon: Icons.straighten,
              color: hasSize ? TodoTheme.primaryPurple : Colors.grey[400]!,
              label: task.tShirtSize?.label,
              onTap: onSizeTap,
            ),
            const SizedBox(width: 8),
          ],
          // Recurrence chip
          if (showAll || hasRecurrence) ...[
            _RecurrenceChip(
              recurrence: recurrence,
              onTap: onRecurrenceTap,
              onRemove: onRecurrenceRemove,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Internal widget for a single property chip
class _PropertyChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onTap;

  const _PropertyChip({
    required this.icon,
    required this.color,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = label != null;
    final chipColor = isSet ? color : Colors.grey[400]!;
    final iconColor = isSet ? color : Colors.black;

    final borderColor = Color.lerp(chipColor, Colors.white, 0.3)!
        .withValues(alpha: 0.7);
    final highlightColor = Color.lerp(chipColor, Colors.white, 0.5)!
        .withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              chipColor.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: chipColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: highlightColor,
              blurRadius: 1,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor,
              shadows: const [
                Shadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  shadows: const [
                    Shadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Internal widget for recurrence chip with remove option
class _RecurrenceChip extends StatelessWidget {
  final Recurrence? recurrence;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _RecurrenceChip({
    this.recurrence,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasRecurrence = recurrence != null;
    final isEnabled = recurrence?.isEnabled ?? true;

    final chipColor = hasRecurrence
        ? (isEnabled ? Colors.orange : Colors.grey[600]!)
        : Colors.grey[400]!;
    final iconColor = hasRecurrence
        ? (isEnabled ? Colors.orange : Colors.grey[600]!)
        : Colors.black;

    final borderColor = Color.lerp(chipColor, Colors.white, 0.3)!
        .withValues(alpha: 0.7);
    final highlightColor = Color.lerp(chipColor, Colors.white, 0.5)!
        .withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      onLongPress: hasRecurrence ? onRemove : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              chipColor.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: chipColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: highlightColor,
              blurRadius: 1,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.repeat,
              size: 16,
              color: iconColor,
              shadows: const [
                Shadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            if (hasRecurrence) ...[
              const SizedBox(width: 4),
              Text(
                'Ric.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  shadows: const [
                    Shadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: onRemove,
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.red,
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
