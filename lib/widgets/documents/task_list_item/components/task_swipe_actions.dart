import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';

/// Wrapper widget providing swipe-to-delete and swipe-to-duplicate actions
///
/// Wraps a child widget with a Dismissible that handles:
/// - Swipe right: Delete with confirmation dialog
/// - Swipe left: Duplicate
class TaskSwipeActions extends StatelessWidget {
  final Widget child;
  final Task task;
  final bool enabled;
  final Future<bool> Function() onDelete;
  final Future<void> Function() onDuplicate;
  final Future<void> Function()? onDeleted; // Called after deletion completes

  const TaskSwipeActions({
    super.key,
    required this.child,
    required this.task,
    required this.enabled,
    required this.onDelete,
    required this.onDuplicate,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Dismissible(
      key: Key('dismissible_${task.id}'),
      direction: DismissDirection.horizontal, // Only respond to horizontal swipes
      background: _buildDeleteBackground(),
      secondaryBackground: _buildDuplicateBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left: Duplicate
          await onDuplicate();
          return false; // Don't dismiss after duplicate
        } else {
          // Swipe right: Delete with confirmation
          return await onDelete();
        }
      },
      onDismissed: (direction) {
        // Task has been dismissed and deleted
        // The actual deletion happened in confirmDismiss/onDelete
        debugPrint('Task ${task.id} dismissed');

        // Call the onDeleted callback if provided (e.g., to refresh parent task)
        // Do NOT await - let it run in background to avoid blocking the dismiss
        // The stream will update and remove the widget from the tree naturally
        if (onDeleted != null) {
          onDeleted!();
        }
      },
      child: child,
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
}
