import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/quick_edit_dialogs.dart';
import 'package:solducci/widgets/documents/recurrence_form_dialog.dart';
import 'package:solducci/widgets/documents/_subtask_animated_list.dart';
import 'package:solducci/theme/todo_theme.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/widgets/documents/task_list_item/task_item_config.dart';
import 'package:solducci/widgets/documents/task_list_item/task_item_callbacks.dart';
import 'package:solducci/widgets/documents/task_list_item/components/task_checkbox.dart';
import 'package:solducci/widgets/documents/task_list_item/components/task_properties_bar.dart';
import 'package:solducci/widgets/documents/task_list_item/components/task_swipe_actions.dart';
import 'package:solducci/widgets/documents/task_list_item/components/task_title.dart';
import 'package:solducci/widgets/documents/task_list_item/components/task_description.dart';
import 'package:solducci/widgets/documents/task_list_item/components/task_tags_row.dart';
import 'package:solducci/widgets/documents/task_list_item/components/drag_handle.dart';
import 'package:solducci/widgets/documents/task_list_item/handlers/task_completion_handler.dart';

/// Widget for displaying a task in a list with checkbox, dismissible actions, and expandable subtasks
///
/// This widget supports both the old parameter-based constructor
/// and the new config-based constructor for better maintainability.
class TaskListItem extends StatefulWidget {
  final Task task;
  final TaskItemConfig config;
  final TaskItemCallbacks? callbacks;

  // Legacy fields for backward compatibility (will be removed in Phase 7)
  final TodoDocument? document; // Use config.document instead
  final VoidCallback? onTap; // Use callbacks.onTap instead
  @Deprecated('No longer needed - stream updates automatically')
  final VoidCallback? onTaskChanged; // Use TaskStateManager instead
  final int depth; // Use config.depth instead
  final ValueNotifier<bool>? showAllPropertiesNotifier; // Use config.showAllPropertiesNotifier instead
  final List<Tag>? preloadedTags; // Use config.preloadedTags instead
  final Map<String, List<Tag>>? taskTagsMap; // Use config.taskTagsMap instead
  final bool dismissibleEnabled; // Use config.dismissibleEnabled instead
  final int? reorderIndex; // Index for drag-on-tap functionality

  /// Legacy constructor for backward compatibility (default)
  ///
  /// This constructor will be migrated in Phase 7. For new code, use TaskListItem.withConfig().
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
    this.reorderIndex,
  })  : config = const TaskItemConfig(),
        callbacks = null;

  /// New constructor using config objects (recommended for new code)
  ///
  /// Use this constructor for cleaner code with fewer parameters.
  const TaskListItem.withConfig({
    super.key,
    required this.task,
    required this.config,
    this.callbacks,
  })  : document = null,
        onTap = null,
        onTaskChanged = null,
        depth = 0,
        showAllPropertiesNotifier = null,
        preloadedTags = null,
        taskTagsMap = null,
        dismissibleEnabled = true,
        reorderIndex = null;

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isExpanded = false;
  final _taskService = TaskService();
  late final _completionHandler = TaskCompletionHandler(taskService: _taskService);
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
    // CRITICAL FIX: Do NOT dispose _taskNotifier here!
    //
    // The TaskStateManager uses reference counting, but there's a design flaw:
    // - getOrCreateTaskNotifier() increments count and returns THE SAME notifier
    // - Multiple widgets (TaskListItem + SubtaskAnimatedList) share the notifier
    // - If we dispose here, SubtaskAnimatedList may still have an active listener
    // - This causes: "A _ReferenceCountedNotifier<Task> was used after being disposed"
    //
    // The notifier will be cleaned up when SubtaskAnimatedList.dispose() is called
    // and removes its listener. The reference counting will then trigger cleanup.
    //
    // TODO: Refactor TaskStateManager to use proxy wrappers for proper ref counting
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

  // Backward-compatible getters that work with both old and new constructors
  TodoDocument? get _document => widget.config.document ?? widget.document;
  int get _depth => widget.config.depth != 0 ? widget.config.depth : widget.depth;
  ValueNotifier<bool>? get _showAllPropertiesNotifier =>
      widget.config.showAllPropertiesNotifier ?? widget.showAllPropertiesNotifier;
  List<Tag>? get _preloadedTags => widget.config.preloadedTags ?? widget.preloadedTags;
  Map<String, List<Tag>>? get _taskTagsMap => widget.config.taskTagsMap ?? widget.taskTagsMap;
  bool get _dismissibleEnabled =>
      widget.config.dismissibleEnabled && widget.dismissibleEnabled;
  VoidCallback? get _onTap => widget.callbacks?.onTap ?? widget.onTap;

  @override
  Widget build(BuildContext context) {
    // Build the main content widget
    final contentWidget = Container(
        color: Colors.transparent, // CRITICAL: Prevent white background
        margin: EdgeInsets.only(
          left: (_depth * 16.0),
          top: _depth > 0 ? 5.0 : 2.0,
          bottom: _depth > 0 ? 5.0 : 2.0,
          right: _depth > 0 ? 2.0 : 0.0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_depth > 0 ? 12 : 16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ), // Increased blur for stronger glass effect
            child: Container(
              decoration: _depth > 0
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
                padding: EdgeInsets.all(_depth > 0 ? 0.0 : 6.0),
                child: Column(
                  children: [
                    // iOS-style drag handle (only for root-level tasks)
                    DragHandle(
                      visible: _depth == 0,
                      widthFraction: 0.15,
                      index: widget.reorderIndex,
                    ),
                    InkWell(
                      onTap: () => _showTaskDetails(context),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      child: Padding(
                        // Reduce padding for subtasks
                        padding: EdgeInsets.only(
                          top: _depth > 0 ? 6.0 : 4.0,
                          right: _depth > 0 ? 0.0 : 6.0,
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
                                      TaskTitle(
                                        key: ValueKey(
                                          'title_${widget.task.id}',
                                        ),
                                        task: widget.task,
                                      ),
                                      // Description (inline editable) - Hidden for subtasks
                                      if (_depth == 0)
                                        TaskDescription(
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
                            TaskPropertiesBar(
                              task: widget.task,
                              recurrence: _recurrence,
                              showAllPropertiesNotifier: _showAllPropertiesNotifier,
                              onPriorityTap: _showPriorityPicker,
                              onDueDateTap: _showDueDatePicker,
                              onSizeTap: _showSizePicker,
                              onRecurrenceTap: _showRecurrencePicker,
                              onRecurrenceRemove: _removeRecurrence,
                            ),
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
                      document: _document!,
                      depth: _depth,
                      showAllPropertiesNotifier: _showAllPropertiesNotifier,
                      taskTagsMap: _taskTagsMap,
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

    // Wrap with swipe actions
    return TaskSwipeActions(
      task: widget.task,
      enabled: _dismissibleEnabled,
      onDelete: _showDeleteConfirmation,
      onDuplicate: _duplicateTask,
      child: contentWidget,
    );
  }

  Widget? _buildTrailingActions() {
    // Always include tags row widget that manages its own state
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tags - always shown here now, manages empty state internally
        TaskTagsRow(
          key: ValueKey('tags_${widget.task.id}'),
          taskId: widget.task.id,
          preloadedTags: _preloadedTags,
          compact: true, // Compact mode for trailing
        ),
        // Spacing between tags and subtask button (if tags present)
        // Space handled by _TaskTagsRow internally
        // Subtask button or chip
        if (!widget.task.hasSubtasks)
          Padding(
            padding: EdgeInsets.only(right: _depth > 0 ? 15.0 : 0.0),
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
        right: _depth > 0 ? 20.0 : 0.0,
        bottom: _depth > 0 ? 6.0 : 0.0,
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
    if (_document == null) {
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

  // ========== WIDGET BUILDING METHODS ==========
  // NOTE: Swipe action backgrounds extracted to TaskSwipeActions component

  /// Improved checkbox with hierarchy indicator
  Widget _buildCheckbox() {
    return TaskCheckbox(
      task: widget.task,
      isToggling: _isTogglingComplete,
      onToggle: (_) => _toggleComplete(),
      depth: _depth,
    );
  }

  // ========== QUICK-EDIT METHODS FOR PROPERTIES ==========
  // NOTE: Property rendering methods (_buildPropertyIconsRow, _buildPropertyIcon, etc.)
  // have been extracted to TaskPropertiesBar component

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

    // Set toggling state for immediate visual feedback
    setState(() {
      _isTogglingComplete = true;
    });

    // Use handler for completion logic
    await _completionHandler.toggleComplete(
      context: context,
      task: widget.task,
      isMounted: () => mounted,
    );

    // Reset toggling state
    if (mounted) {
      setState(() {
        _isTogglingComplete = false;
      });
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await _completionHandler.deleteTask(
      context: context,
      taskId: widget.task.id,
      taskTitle: widget.task.title,
      isMounted: () => mounted,
    );
  }

  Future<void> _duplicateTask() async {
    await _completionHandler.duplicateTask(
      context: context,
      taskId: widget.task.id,
      isMounted: () => mounted,
    );
  }

  void _showTaskDetails(BuildContext context) {
    // If onTap is provided, use it (for parent compatibility)
    // Otherwise, open TaskDetailPage for this task
    if (_onTap != null) {
      _onTap!();
    } else if (_document != null) {
      // Open TaskDetailPage for this specific task
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailPage(
            document: _document!,
            task: widget.task,
            showAllPropertiesNotifier: _showAllPropertiesNotifier,
          ),
        ),
      );
    }
  }
}

// ========== INTERNAL WIDGETS EXTRACTED ==========
// TaskTitle, TaskDescription, and TaskTagsRow have been extracted to:
// - components/task_title.dart
// - components/task_description.dart
// - components/task_tags_row.dart
