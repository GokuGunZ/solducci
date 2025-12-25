import 'package:flutter/material.dart';
import 'package:solducci/theme/todo_theme.dart';

/// iOS-style drag handle indicator for reorderable tasks
///
/// A horizontal line positioned at the top-center of the task tile,
/// with glassmorphic styling matching the app's aesthetic.
///
/// When [index] is provided, wraps the handle with ReorderableDragStartListener
/// to enable immediate drag-and-drop on tap (no long-press required).
class DragHandle extends StatelessWidget {
  /// Width as percentage of parent width (0.0 to 1.0)
  final double widthFraction;

  /// Whether to show the drag handle (e.g., hide for subtasks)
  final bool visible;

  /// Index for ReorderableDragStartListener (enables drag-on-tap)
  /// If null, drag handle is purely visual
  final int? index;

  const DragHandle({
    super.key,
    this.widthFraction = 0.15,
    this.visible = true,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final handleWidget = Center(
      child: Container(
        margin: const EdgeInsets.only(top: 1, bottom: 4),
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
                  const Color.fromARGB(
                    255,
                    174,
                    174,
                    174,
                  ).withValues(alpha: 0.4),
                  const Color.fromARGB(129, 177, 163, 184),
                  const Color.fromARGB(
                    255,
                    168,
                    168,
                    168,
                  ).withValues(alpha: 0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: TodoTheme.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  spreadRadius: -0.2,
                  blurRadius: 0.2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Return the visual handle
    // The entire item is wrapped with ReorderableDragStartListener in the list builder
    // so this is purely visual - user can drag from anywhere on the item
    return handleWidget;
  }
}
