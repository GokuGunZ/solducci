import 'package:flutter/material.dart';

/// A Tooltip wrapper that handles exceptions during reordering/transitions
///
/// During drag-and-drop reordering, widgets can be in transitional states where
/// Tooltip's position calculation fails. This widget catches those exceptions
/// and falls back to rendering without the tooltip overlay.
class SafeTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Duration? waitDuration;
  final bool? preferBelow;
  final bool? enableFeedback;

  const SafeTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration,
    this.preferBelow,
    this.enableFeedback,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in Builder to catch position calculation errors
    return Builder(
      builder: (context) {
        try {
          return Tooltip(
            message: message,
            waitDuration: waitDuration ?? const Duration(milliseconds: 800),
            preferBelow: preferBelow ?? false,
            enableFeedback: enableFeedback ?? false,
            child: child,
          );
        } catch (e) {
          // If tooltip fails to render (e.g., during reorder), just show child
          return child;
        }
      },
    );
  }
}
