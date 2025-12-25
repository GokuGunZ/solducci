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

  const TaskSwipeActions({
    super.key,
    required this.child,
    required this.task,
    required this.enabled,
    required this.onDelete,
    required this.onDuplicate,
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
