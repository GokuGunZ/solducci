import 'package:flutter/material.dart';
import 'package:solducci/theme/todo_theme.dart';

/// iOS-style drag handle indicator for reorderable tasks
///
/// A horizontal line positioned at the top-center of the task tile,
/// with glassmorphic styling matching the app's aesthetic.
class DragHandle extends StatelessWidget {
  /// Width as percentage of parent width (0.0 to 1.0)
  final double widthFraction;

  /// Whether to show the drag handle (e.g., hide for subtasks)
  final bool visible;

  const DragHandle({
    super.key,
    this.widthFraction = 0.15,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        child: FractionallySizedBox(
          widthFactor: widthFraction,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  TodoTheme.primaryPurple.withValues(alpha: 0.6),
                  TodoTheme.primaryPurple.withValues(alpha: 0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: TodoTheme.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
