import 'package:flutter/material.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/quick_edit_dialogs.dart';
import 'package:solducci/theme/todo_theme.dart';
import 'package:solducci/core/widgets/safe_tooltip.dart';

/// Widget for displaying and managing task tags
///
/// Shows tags as compact circular chips in trailing position.
/// Supports tap-to-edit with tag picker bottom sheet.
class TaskTagsRow extends StatefulWidget {
  final String taskId;
  final List<Tag>? preloadedTags;
  final bool compact; // Compact mode for trailing (no label, smaller)

  const TaskTagsRow({
    super.key,
    required this.taskId,
    this.preloadedTags,
    this.compact = false,
  });

  @override
  State<TaskTagsRow> createState() => _TaskTagsRowState();
}

class _TaskTagsRowState extends State<TaskTagsRow> {
  final _taskService = TaskService();
  List<Tag> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use preloaded tags if available, otherwise load asynchronously
    if (widget.preloadedTags != null) {
      _tags = widget.preloadedTags!;
      _isLoading = false;
    } else {
      _loadTags();
    }
  }

  @override
  void didUpdateWidget(TaskTagsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // CRITICAL: Reload tags when parent rebuilds (triggered by TaskStateManager)
    // This ensures tags are always fresh when task state changes
    if (!_isLoading) {
      _loadTags();
    }
  }

  Future<void> _loadTags() async {
    final tags = await _taskService.getEffectiveTags(widget.taskId);
    if (mounted) {
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    }
  }

  Future<void> _showTagPicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickTagPicker(
        taskId: widget.taskId,
        currentTags: _tags,
        onSelected: (newTags) async {
          try {
            final currentTagIds = _tags.map((t) => t.id).toSet();
            final newTagIds = newTags.map((t) => t.id).toSet();

            final tagsToAdd = newTagIds.difference(currentTagIds);
            final tagsToRemove = currentTagIds.difference(newTagIds);

            for (final tagId in tagsToAdd) {
              await _taskService.addTag(widget.taskId, tagId);
            }

            for (final tagId in tagsToRemove) {
              await _taskService.removeTag(widget.taskId, tagId);
            }

            await _loadTags();
            // Stream will update automatically
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Tag aggiornati')));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Errore: $e')));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Compact mode (for trailing)
    if (widget.compact) {
      return _buildCompactMode();
    }

    // Old inline mode (deprecated, should not be used anymore)
    return const SizedBox.shrink();
  }

  /// Build compact mode for trailing actions
  Widget _buildCompactMode() {
    // Has tags - show them with spacing after
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add tag button
        _buildAddTagButton(),
        const SizedBox(width: 8),
        // Tag chips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: _tags.map((tag) {
            final color = tag.colorObject ?? Colors.grey;
            final borderColor =
                Color.lerp(color, Colors.white, 0.3)!.withValues(alpha: 0.7);
            final highlightColor =
                Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: 0.5);

            return GestureDetector(
              onTap: _showTagPicker,
              child: SafeTooltip(
                message: tag.name,
                waitDuration: const Duration(milliseconds: 800),
                preferBelow: false,
                enableFeedback: false,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.9),
                        color.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: highlightColor,
                        blurRadius: 1,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                  child: Icon(
                    tag.iconData ?? Icons.label,
                    size: 16,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 8), // Space before subtask button
      ],
    );
  }

  InkWell _buildAddTagButton() {
    return InkWell(
      onTap: _showTagPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TodoTheme.primaryPurple.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: Color.lerp(
              TodoTheme.primaryPurple,
              Colors.white,
              0.4,
            )!
                .withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: TodoTheme.primaryPurple.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.new_label,
          size: 16,
          color: TodoTheme.primaryPurple,
          shadows: const [
            Shadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}
