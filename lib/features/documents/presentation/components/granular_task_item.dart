import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// Reusable task item component with granular rebuild and highlight animation
///
/// Features:
/// - Granular rebuild: Only this task rebuilds when its state changes (via TaskStateManager)
/// - Highlight animation: Visual feedback when task is created/repositioned (800ms fade)
/// - ValueListenableBuilder: Listens only to this specific task's notifier
/// - Optional new task detection: Animates only for recently created tasks
///
/// Usage:
/// ```dart
/// GranularTaskItem(
///   task: task,
///   document: document,
///   onShowTaskDetails: (context, task) => navigateToDetails(task),
///   animateIfNew: true, // Animate only if created < 2 seconds ago
/// )
/// ```
class GranularTaskItem extends StatefulWidget {
  final Task task;
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(BuildContext, Task) onShowTaskDetails;
  final Map<String, List<Tag>>? taskTagsMap;
  final bool dismissibleEnabled;

  /// If true, only animates highlight for tasks created < 2 seconds ago
  /// If false, always animates on init (useful for reordering)
  final bool animateIfNew;

  const GranularTaskItem({
    super.key,
    required this.task,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.onShowTaskDetails,
    this.taskTagsMap,
    this.dismissibleEnabled = true,
    this.animateIfNew = false,
  });

  @override
  State<GranularTaskItem> createState() => _GranularTaskItemState();
}

class _GranularTaskItemState extends State<GranularTaskItem>
    with SingleTickerProviderStateMixin {
  late final AlwaysNotifyValueNotifier<Task> _taskNotifier;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize TaskStateManager notifier ONCE
    // CRITICAL: Never call this in build()! Would overwrite the value
    final stateManager = TaskStateManager();
    _taskNotifier = stateManager.getOrCreateTaskNotifier(
      widget.task.id,
      widget.task,
    );

    // Setup highlight animation controller
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    // Determine if we should animate
    bool shouldAnimate = !widget.animateIfNew;

    if (widget.animateIfNew) {
      // Only animate if task is newly created (< 2 seconds ago)
      final taskAge = DateTime.now().difference(widget.task.createdAt);
      shouldAnimate = taskAge.inSeconds < 2;

      if (shouldAnimate) {
        AppLogger.debug('🎨 GranularTaskItem: Animating new task ${widget.task.id}');
      }
    }

    // Trigger highlight animation if needed
    if (shouldAnimate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _highlightController.forward().then((_) {
            if (mounted) {
              _highlightController.reverse();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();

    // Release reference to task notifier to prevent memory leaks
    final stateManager = TaskStateManager();
    stateManager.releaseTaskNotifier(widget.task.id);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Granular rebuild: Only this widget rebuilds when this specific task changes
    return ValueListenableBuilder<Task>(
      valueListenable: _taskNotifier,
      builder: (context, updatedTask, _) {
        // Wrap with highlight animation
        return AnimatedBuilder(
          animation: _highlightAnimation,
          builder: (context, child) {
            // Calculate highlight opacity (fade in first half, fade out second half)
            final highlightOpacity = _highlightAnimation.value <= 0.5
                ? _highlightAnimation.value * 2       // 0.0 -> 1.0
                : (1.0 - _highlightAnimation.value) * 2; // 1.0 -> 0.0

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // Match TaskListItem
                boxShadow: highlightOpacity > 0.05
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: highlightOpacity * 0.3),
                          blurRadius: 12 * highlightOpacity,
                          spreadRadius: 2 * highlightOpacity,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: TaskListItem(
            task: updatedTask,
            document: widget.document,
            onTap: () => widget.onShowTaskDetails(context, updatedTask),
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
            dismissibleEnabled: widget.dismissibleEnabled,
            preloadedTags: widget.taskTagsMap?[updatedTask.id],
            taskTagsMap: widget.taskTagsMap ?? {},
          ),
        );
      },
    );
  }
}
