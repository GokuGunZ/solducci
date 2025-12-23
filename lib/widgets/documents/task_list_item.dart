import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/quick_edit_dialogs.dart';
import 'package:solducci/widgets/documents/recurrence_form_dialog.dart';
import 'package:solducci/widgets/documents/_subtask_animated_list.dart';
import 'package:solducci/theme/todo_theme.dart';
import 'package:solducci/utils/task_state_manager.dart';

/// Widget for displaying a task in a list with checkbox, dismissible actions, and expandable subtasks
class TaskListItem extends StatefulWidget {
  final Task task;
  final TodoDocument? document; // Optional: needed for creating subtasks
  final VoidCallback? onTap;
  @Deprecated('No longer needed - stream updates automatically')
  final VoidCallback? onTaskChanged; // Deprecated: Supabase stream updates automatically
  final int depth; // For indentation of subtasks
  final ValueNotifier<bool>?
  showAllPropertiesNotifier; // Global toggle from parent
  final List<Tag>?
  preloadedTags; // Optional: preloaded tags to avoid async loading
  final Map<String, List<Tag>>?
  taskTagsMap; // Optional: map of all task tags (for subtasks)
  final bool dismissibleEnabled; // Control whether swipe-to-dismiss is enabled

  const TaskListItem({
    super.key,
    required this.task,
    this.document,
    this.onTap,
    this.onTaskChanged,
    this.depth = 0,
    this.showAllPropertiesNotifier,
    this.preloadedTags,
    this.taskTagsMap,
    this.dismissibleEnabled = true,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isExpanded = false;
  final _taskService = TaskService();
  Recurrence? _recurrence;
  bool _isTogglingComplete = false; // Track if toggle is in progress
  bool _isCreatingSubtask = false;

  // Task notifier for granular updates
  AlwaysNotifyValueNotifier<Task>? _taskNotifier;

  @override
  void initState() {
    super.initState();
    _checkRecurrence();

    // Get or create task notifier for this task
    final stateManager = TaskStateManager();
    _taskNotifier = stateManager.getOrCreateTaskNotifier(widget.task.id, widget.task);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-check recurrence when the widget updates
    if (oldWidget.task.id == widget.task.id) {
      _checkRecurrence();
    }
  }

  Future<void> _checkRecurrence() async {
    final recurrence = await _taskService.getEffectiveRecurrence(
      widget.task.id,
    );

    if (mounted) {
      setState(() {
        _recurrence = recurrence;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the main content widget
    final contentWidget = Container(
        color: Colors.transparent, // CRITICAL: Prevent white background
        margin: EdgeInsets.only(
          left: (widget.depth * 16.0),
          top: widget.depth > 0 ? 5.0 : 2.0,
          bottom: widget.depth > 0 ? 5.0 : 2.0,
          right: widget.depth > 0 ? 2.0 : 0.0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.depth > 0 ? 12 : 16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ), // Increased blur for stronger glass effect
            child: Container(
              decoration: widget.depth > 0
                  ? TodoTheme.glassDecoration(
                      opacity:
                          0.03, // Subtasks VERY transparent for true glass effect
                      borderOpacity: 0.35,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: TodoTheme.primaryPurple.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : TodoTheme.glassDecoration(
                      opacity:
                          0.05, // Main tasks VERY transparent - let gradient show through!
                      borderOpacity: 0.5,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: TodoTheme.primaryPurple.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 2,
                          offset: const Offset(-1, -1),
                        ),
                      ],
                    ),
              child: Padding(
                // Reduce padding for subtasks
                padding: EdgeInsets.all(widget.depth > 0 ? 0.0 : 6.0),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _showTaskDetails(context),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      child: Padding(
                        // Reduce padding for subtasks
                        padding: EdgeInsets.only(
                          top: widget.depth > 0 ? 6.0 : 4.0,
                          right: widget.depth > 0 ? 0.0 : 6.0,
                          left: 6.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: Checkbox, Title+Description Column, and Subtask chip
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Improved Checkbox with hierarchy indicator
                                _buildCheckbox(),
                                const SizedBox(width: 8),
                                // Title and Description in a Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title (inline editable)
                                      _TaskTitle(
                                        key: ValueKey(
                                          'title_${widget.task.id}',
                                        ),
                                        task: widget.task,
                                      ),
                                      // Description (inline editable) - Hidden for subtasks
                                      if (widget.depth == 0)
                                        _TaskDescription(
                                          key: ValueKey(
                                            'desc_${widget.task.id}',
                                          ),
                                          task: widget.task,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Trailing actions (subtask chip or add button)
                                if (_buildTrailingActions() != null)
                                  _buildTrailingActions()!,
                              ],
                            ),
                            // Property icons row (always visible)
                            _buildPropertyIconsRow(),
                            // Tags removed from here - now shown in trailing actions
                          ],
                        ),
                      ),
                    ),

                    // Subtasks (expandable) - NEW: Managed by dedicated SubtaskAnimatedList widget
                    SubtaskAnimatedList(
                      key: ValueKey('subtasks_${widget.task.id}'),
                      parentTaskId: widget.task.id,
                      parentNotifier: _taskNotifier!,
                      document: widget.document!,
                      depth: widget.depth,
                      showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                      taskTagsMap: widget.taskTagsMap,
                      isExpanded: _isExpanded,
                      isCreatingSubtask: _isCreatingSubtask,
                      onCancelCreation: () {
                        setState(() {
                          _isCreatingSubtask = false;
                        });
                      },
                      onSubtaskCreated: () async {
                        setState(() {
                          _isCreatingSubtask = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

    // Conditionally wrap with Dismissible based on dismissibleEnabled flag
    if (widget.dismissibleEnabled) {
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
        child: contentWidget,
      );
    } else {
      // In reorder mode: no dismissible, just the content
      return contentWidget;
    }
  }

  Widget? _buildTrailingActions() {
    // Always include tags row widget that manages its own state
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tags - always shown here now, manages empty state internally
        _TaskTagsRow(
          key: ValueKey('tags_${widget.task.id}'),
          taskId: widget.task.id,
          preloadedTags: widget.preloadedTags,
          compact: true, // Compact mode for trailing
        ),
        // Spacing between tags and subtask button (if tags present)
        // Space handled by _TaskTagsRow internally
        // Subtask button or chip
        if (!widget.task.hasSubtasks)
          Padding(
            padding: EdgeInsets.only(right: widget.depth > 0 ? 15.0 : 0.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: _showAddSubtaskDialog,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Aggiungi sub-task',
            ),
          )
        else
          _buildSubtaskChip(),
      ],
    );
  }

  Widget _buildSubtaskChip() {
    final completedCount = widget.task.subtasks!
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final totalCount = widget.task.subtasks!.length;

    return Padding(
      padding: EdgeInsets.only(
        right: widget.depth > 0 ? 20.0 : 0.0,
        bottom: widget.depth > 0 ? 6.0 : 0.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TodoTheme.primaryPurple.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color.lerp(
              TodoTheme.primaryPurple,
              Colors.white,
              0.3,
            )!.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: TodoTheme.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Color.lerp(
                TodoTheme.primaryPurple,
                Colors.white,
                0.5,
              )!.withValues(alpha: 0.5),
              blurRadius: 1,
              offset: const Offset(-1, -1),
            ),
          ],
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
                    shadows: const [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Divider with glass effect
            Container(
              width: 1.5,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TodoTheme.primaryPurple.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.3),
                  ],
                ),
              ),
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
                  shadows: const [
                    Shadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

    // Start inline subtask creation and expand the task
    setState(() {
      _isCreatingSubtask = true;
      _isExpanded = true;
    });
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

  // ========== NEW QUICK-EDIT METHODS ==========

  /// Improved checkbox with hierarchy indicator
  Widget _buildCheckbox() {
    final hasSubtasks = widget.task.hasSubtasks;
    final isParent = widget.depth == 0 && hasSubtasks;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle for parent tasks
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
          value: _isTogglingComplete
              ? !widget.task.isCompleted
              : widget.task.isCompleted,
          onChanged: _isTogglingComplete ? null : (_) => _toggleComplete(),
          activeColor: Colors.green,
          shape: isParent ? const CircleBorder() : null,
        ),
      ],
    );
  }

  /// Build property icons row (conditionally visible based on toggle)
  Widget _buildPropertyIconsRow() {
    // Check which properties have values
    final hasPriority = widget.task.priority != null;
    final hasDueDate = widget.task.dueDate != null;
    final hasSize = widget.task.tShirtSize != null;

    // If no notifier provided, use default behavior (show filled only)
    if (widget.showAllPropertiesNotifier == null) {
      return _buildPropertyIconsContent(
        false,
        hasPriority,
        hasDueDate,
        hasSize,
      );
    }

    // Use ValueListenableBuilder to only rebuild this section
    return ValueListenableBuilder<bool>(
      valueListenable: widget.showAllPropertiesNotifier!,
      builder: (context, showAll, child) {
        return _buildPropertyIconsContent(
          showAll,
          hasPriority,
          hasDueDate,
          hasSize,
        );
      },
    );
  }

  /// Build the actual property icons content
  Widget _buildPropertyIconsContent(
    bool showAll,
    bool hasPriority,
    bool hasDueDate,
    bool hasSize,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 48.0, right: 8.0),
      child: Row(
        children: [
          // Show filled properties or all properties if toggle is on
          if (showAll || hasPriority) ...[
            _buildPropertyIcon(
              icon: Icons.flag_outlined,
              color: widget.task.priority?.color ?? Colors.grey[400]!,
              label: widget.task.priority?.label,
              onTap: _showPriorityPicker,
            ),
            const SizedBox(width: 8),
          ],
          if (showAll || hasDueDate) ...[
            _buildPropertyIcon(
              icon: Icons.calendar_today_outlined,
              color: widget.task.dueDate != null
                  ? (widget.task.isOverdue ? Colors.red : Colors.blue)
                  : Colors.grey[400]!,
              label: widget.task.dueDate != null
                  ? DateFormat('dd/MM').format(widget.task.dueDate!)
                  : null,
              onTap: _showDueDatePicker,
            ),
            const SizedBox(width: 8),
          ],
          if (showAll || hasSize) ...[
            _buildPropertyIcon(
              icon: Icons.straighten,
              color: widget.task.tShirtSize != null
                  ? TodoTheme.primaryPurple
                  : Colors.grey[400]!,
              label: widget.task.tShirtSize?.label,
              onTap: _showSizePicker,
            ),
            const SizedBox(width: 8),
          ],
          if (showAll || _recurrence != null) ...[
            _buildRecurrenceIcon(),
            const SizedBox(width: 8),
          ],
          // Tag icon removed - now handled by _TaskTagsRow
        ],
      ),
    );
  }

  /// Build a single property icon with glassmorphic styling
  Widget _buildPropertyIcon({
    required IconData icon,
    required Color color,
    String? label,
    required VoidCallback onTap,
  }) {
    // Check if property is set (has a label)
    final isSet = label != null;

    // Use grey background for unset properties, colored for set ones
    final chipColor = isSet ? color : Colors.grey[400]!;
    final iconColor = isSet ? color : Colors.black;

    // Get a lighter version of the color for the border
    final borderColor = Color.lerp(
      chipColor,
      Colors.white,
      0.3,
    )!.withValues(alpha: 0.7);
    final highlightColor = Color.lerp(
      chipColor,
      Colors.white,
      0.5,
    )!.withValues(alpha: 0.5);

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
                label,
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

  /// Build recurrence icon with visual feedback and removal option
  Widget _buildRecurrenceIcon() {
    final hasRecurrence = _recurrence != null;
    final isEnabled = _recurrence?.isEnabled ?? true;

    // Chip background color: grey if not set, orange/grey if set
    final chipColor = hasRecurrence
        ? (isEnabled ? Colors.orange : Colors.grey[600]!)
        : Colors.grey[400]!;

    // Icon color: black if not set, same as chip color if set
    final iconColor = hasRecurrence
        ? (isEnabled ? Colors.orange : Colors.grey[600]!)
        : Colors.black;

    // Get a lighter version of the color for the border
    final borderColor = Color.lerp(
      chipColor,
      Colors.white,
      0.3,
    )!.withValues(alpha: 0.7);
    final highlightColor = Color.lerp(
      chipColor,
      Colors.white,
      0.5,
    )!.withValues(alpha: 0.5);

    return InkWell(
      onTap: _showRecurrencePicker,
      onLongPress: !hasRecurrence ? null : _removeRecurrence,
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
              const SizedBox(width: 2),
              InkWell(
                onTap: _removeRecurrence,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.red,
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

  // ========== QUICK-EDIT METHODS FOR PROPERTIES ==========

  Future<void> _showPriorityPicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickPriorityPicker(
        currentPriority: widget.task.priority,
        onSelected: (newPriority) async {
          try {
            widget.task.priority = newPriority;
            await _taskService.updateTask(widget.task);
            // Stream will update automatically
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Priorità aggiornata')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Errore: $e')));
            }
          }
        },
      ),
    );
  }

  Future<void> _showDueDatePicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickDueDatePicker(
        currentDueDate: widget.task.dueDate,
        onSelected: (newDueDate) async {
          try {
            widget.task.dueDate = newDueDate;
            await _taskService.updateTask(widget.task);
            // Stream will update automatically
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scadenza aggiornata')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Errore: $e')));
            }
          }
        },
      ),
    );
  }

  Future<void> _showSizePicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickSizePicker(
        currentSize: widget.task.tShirtSize,
        onSelected: (newSize) async {
          try {
            widget.task.tShirtSize = newSize;
            await _taskService.updateTask(widget.task);
            // Stream will update automatically
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dimensione aggiornata')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Errore: $e')));
            }
          }
        },
      ),
    );
  }

  Future<void> _showRecurrencePicker() async {
    // Get current recurrence if exists
    final recurrenceService = RecurrenceService();
    final currentRecurrence = await recurrenceService.getRecurrenceForTask(
      widget.task.id,
    );

    if (!mounted) return;

    final result = await showDialog<Recurrence>(
      context: context,
      builder: (context) => RecurrenceFormDialog(recurrence: currentRecurrence),
    );

    if (result != null) {
      try {
        // Create a new Recurrence with the taskId set
        final recurrenceWithTaskId = Recurrence(
          id: result.id,
          taskId: widget.task.id,
          tagId: null,
          hourlyFrequency: result.hourlyFrequency,
          specificTimes: result.specificTimes,
          dailyFrequency: result.dailyFrequency,
          weeklyDays: result.weeklyDays,
          monthlyDays: result.monthlyDays,
          yearlyDates: result.yearlyDates,
          startDate: result.startDate,
          endDate: result.endDate,
          isEnabled: result.isEnabled,
          createdAt: result.createdAt,
        );

        // Save or update the recurrence
        if (currentRecurrence == null) {
          await recurrenceService.createRecurrence(recurrenceWithTaskId);
        } else {
          await recurrenceService.updateRecurrence(recurrenceWithTaskId);
        }

        // Refresh the recurrence state
        await _checkRecurrence();
        // Stream will update automatically

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ricorrenza configurata')),
          );
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

  Future<void> _removeRecurrence() async {
    try {
      final recurrenceService = RecurrenceService();
      final currentRecurrence = await recurrenceService.getRecurrenceForTask(
        widget.task.id,
      );

      if (currentRecurrence != null) {
        await recurrenceService.deleteRecurrence(currentRecurrence.id);

        setState(() {
          _recurrence = null;
        });

        // Stream will update automatically

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ricorrenza rimossa')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  // ========== END OF QUICK-EDIT METHODS ==========
  // Note: Tag picker now handled by _TaskTagsRow

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

      // Stream will update automatically from DB
      if (mounted) {
        // No need to trigger refresh - stream handles it
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
        // Stream will update automatically
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
      // Stream will update automatically
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

  void _showTaskDetails(BuildContext context) {
    // If onTap is provided, use it (for parent compatibility)
    // Otherwise, open TaskDetailPage for this task
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.document != null) {
      // Open TaskDetailPage for this specific task
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailPage(
            document: widget.document!,
            task: widget.task,
            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
          ),
        ),
      );
    }
  }
}

// ========== SEPARATE WIDGETS FOR INDEPENDENT REBUILDS ==========

/// Stateful widget for task title editing
class _TaskTitle extends StatefulWidget {
  final Task task;

  const _TaskTitle({super.key, required this.task});

  @override
  State<_TaskTitle> createState() => _TaskTitleState();
}

class _TaskTitleState extends State<_TaskTitle> {
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _startTitleEdit() {
    setState(() {
      _isEditingTitle = true;
      _titleController.text = widget.task.title;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _titleController.text.length,
      );
    });
  }

  Future<void> _saveTitleEdit() async {
    if (!_isEditingTitle) return;

    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      _titleController.text = widget.task.title;
      setState(() {
        _isEditingTitle = false;
      });
      return;
    }

    if (newTitle != widget.task.title) {
      try {
        widget.task.title = newTitle;
        await _taskService.updateTask(widget.task);
        // Stream will update automatically
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
        _titleController.text = widget.task.title;
      }
    }

    setState(() {
      _isEditingTitle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditingTitle) {
      return Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(top: 4.0, left: 4.0),
        child: TextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onSubmitted: (_) => _saveTitleEdit(),
          onTapOutside: (_) => _saveTitleEdit(),
        ),
      );
    }

    return GestureDetector(
      onTap: _startTitleEdit,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(top: 4.0, left: 4.0),
        child: Text(
          widget.task.title,
          style: widget.task.isCompleted
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  fontSize: 18,
                )
              : const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Stateful widget for task description editing
class _TaskDescription extends StatefulWidget {
  final Task task;

  const _TaskDescription({super.key, required this.task});

  @override
  State<_TaskDescription> createState() => _TaskDescriptionState();
}

class _TaskDescriptionState extends State<_TaskDescription> {
  bool _isEditingDescription = false;
  late TextEditingController _descriptionController;
  final FocusNode _descriptionFocusNode = FocusNode();
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _startDescriptionEdit() {
    setState(() {
      _isEditingDescription = true;
      _descriptionController.text = widget.task.description ?? '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _descriptionFocusNode.requestFocus();
    });
  }

  Future<void> _saveDescriptionEdit() async {
    if (!_isEditingDescription) return;

    final newDescription = _descriptionController.text.trim();
    final hasChanged = newDescription != (widget.task.description ?? '');

    if (hasChanged) {
      try {
        widget.task.description = newDescription.isEmpty
            ? null
            : newDescription;
        await _taskService.updateTask(widget.task);
        // Stream will update automatically
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
        _descriptionController.text = widget.task.description ?? '';
      }
    }

    setState(() {
      _isEditingDescription = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditingDescription ||
        (widget.task.description != null &&
            widget.task.description!.isNotEmpty)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0, right: 8.0, left: 4.0),
        child: _isEditingDescription
            ? TextField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: 'Aggiungi descrizione...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                onSubmitted: (_) => _saveDescriptionEdit(),
                onTapOutside: (_) => _saveDescriptionEdit(),
              )
            : GestureDetector(
                onTap: _startDescriptionEdit,
                child: Container(
                  color: Colors.transparent,
                  child: Text(
                    widget.task.description!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Stateful widget for task tags display and editing
class _TaskTagsRow extends StatefulWidget {
  final String taskId;
  final List<Tag>? preloadedTags;
  final bool compact; // Compact mode for trailing (no label, smaller)

  const _TaskTagsRow({
    super.key,
    required this.taskId,
    this.preloadedTags,
    this.compact = false,
  });

  @override
  State<_TaskTagsRow> createState() => _TaskTagsRowState();
}

class _TaskTagsRowState extends State<_TaskTagsRow> {
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
  void didUpdateWidget(_TaskTagsRow oldWidget) {
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Tag aggiornati')));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Errore: $e')));
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
            final borderColor = Color.lerp(
              color,
              Colors.white,
              0.3,
            )!.withValues(alpha: 0.7);
            final highlightColor = Color.lerp(
              color,
              Colors.white,
              0.5,
            )!.withValues(alpha: 0.5);

            return GestureDetector(
              onTap: _showTagPicker,
              child: Tooltip(
                message: tag.name,
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
            )!.withValues(alpha: 0.6),
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
