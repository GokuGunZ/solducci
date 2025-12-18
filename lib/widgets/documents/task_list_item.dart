import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/widgets/documents/quick_edit_dialogs.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Widget for displaying a task in a list with checkbox, dismissible actions, and expandable subtasks
class TaskListItem extends StatefulWidget {
  final Task task;
  final TodoDocument? document; // Optional: needed for creating subtasks
  final VoidCallback? onTap;
  final VoidCallback?
  onTaskChanged; // Callback when task is modified/deleted/duplicated
  final int depth; // For indentation of subtasks
  final ValueNotifier<bool>?
  showAllPropertiesNotifier; // Global toggle from parent

  const TaskListItem({
    super.key,
    required this.task,
    this.document,
    this.onTap,
    this.onTaskChanged,
    this.depth = 0,
    this.showAllPropertiesNotifier,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isExpanded = false;
  final _taskService = TaskService();
  bool _isRecurring = false;
  bool _isTogglingComplete = false; // Track if toggle is in progress
  bool _isCreatingSubtask = false;

  @override
  void initState() {
    super.initState();
    _checkRecurrence();
  }

  Future<void> _checkRecurrence() async {
    final recurrence = await _taskService.getEffectiveRecurrence(
      widget.task.id,
    );
    if (mounted && recurrence != null && recurrence.isActive) {
      setState(() {
        _isRecurring = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Container(
        margin: EdgeInsets.only(
          left: 8.0 + (widget.depth * 16.0),
          right: 8.0,
          top: 4.0,
          bottom: 4.0,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: TodoTheme.primaryPurple.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  InkWell(
                    onTap: widget.onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Checkbox, Title, and Subtask chip
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Improved Checkbox with hierarchy indicator
                              _buildCheckbox(),
                              const SizedBox(width: 8),
                              // Title (inline editable) - Independent rebuild
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: _TaskTitle(
                                    key: ValueKey('title_${widget.task.id}'),
                                    task: widget.task,
                                    onTaskChanged: widget.onTaskChanged,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Trailing actions (subtask chip or add button)
                              if (_buildTrailingActions() != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: _buildTrailingActions()!,
                                ),
                            ],
                          ),
                          // Description (inline editable) - Independent rebuild
                          _TaskDescription(
                            key: ValueKey('desc_${widget.task.id}'),
                            task: widget.task,
                            onTaskChanged: widget.onTaskChanged,
                          ),
                          // Property icons row (always visible)
                          _buildPropertyIconsRow(),
                          // Tags row - Independent rebuild
                          _TaskTagsRow(
                            key: ValueKey('tags_${widget.task.id}'),
                            taskId: widget.task.id,
                            onTaskChanged: widget.onTaskChanged,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subtasks (expandable)
                  if (_isExpanded && (widget.task.hasSubtasks || _isCreatingSubtask))
                    Column(
                      children: [
                        // Show creation row if creating subtask
                        if (_isCreatingSubtask)
                          TaskCreationRow(
                            key: ValueKey('subtask_creation_${widget.task.id}'),
                            document: widget.document!,
                            showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                            parentTaskId: widget.task.id,
                            onCancel: () {
                              setState(() {
                                _isCreatingSubtask = false;
                              });
                            },
                            onTaskCreated: () {
                              setState(() {
                                _isCreatingSubtask = false;
                              });
                              widget.onTaskChanged?.call();
                            },
                          ),
                        // Existing subtasks
                        ...?widget.task.subtasks?.map(
                          (subtask) => TaskListItem(
                            task: subtask,
                            document: widget.document,
                            depth: widget.depth + 1,
                            onTap: widget.onTap,
                            onTaskChanged:
                                widget.onTaskChanged, // Propagate callback
                            showAllPropertiesNotifier:
                                widget.showAllPropertiesNotifier,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildTrailingActions() {
    if (!widget.task.hasSubtasks) {
      // No subtasks: show only "add subtask" icon button
      return IconButton(
        icon: const Icon(Icons.add_circle_outline, size: 20),
        onPressed: _showAddSubtaskDialog,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Aggiungi sub-task',
      );
    }

    // Has subtasks: show interactive chip with counter and actions
    return _buildSubtaskChip();
  }

  Widget _buildSubtaskChip() {
    final completedCount = widget.task.subtasks!
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final totalCount = widget.task.subtasks!.length;

    return Container(
      decoration: BoxDecoration(
        color: TodoTheme.primaryPurple.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TodoTheme.primaryPurple.withAlpha(100),
          width: 1.5,
        ),
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
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Divider
          Container(
            width: 1.5,
            height: 20,
            color: TodoTheme.primaryPurple.withAlpha(80),
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
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 12.0, left: 48.0, right: 8.0),
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
          if (showAll || _isRecurring) ...[
            _buildPropertyIcon(
              icon: Icons.repeat,
              color: _isRecurring ? Colors.orange : Colors.grey[400]!,
              label: _isRecurring ? 'Ric.' : null,
              onTap: () {
                // TODO: Add recurrence picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ricorrenza: funzionalità in arrivo'),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// Build a single property icon
  Widget _buildPropertyIcon({
    required IconData icon,
    required Color color,
    String? label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: label != null ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
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
            widget.onTaskChanged?.call();
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
            widget.onTaskChanged?.call();
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
            widget.onTaskChanged?.call();
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

  // ========== END OF QUICK-EDIT METHODS ==========

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

      // Trigger refresh to update all views (this will reload from DB)
      if (mounted) {
        widget.onTaskChanged?.call();
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
        widget.onTaskChanged?.call(); // Trigger refresh
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
      widget.onTaskChanged?.call(); // Trigger refresh
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
}

// ========== SEPARATE WIDGETS FOR INDEPENDENT REBUILDS ==========

/// Stateful widget for task title editing
class _TaskTitle extends StatefulWidget {
  final Task task;
  final VoidCallback? onTaskChanged;

  const _TaskTitle({super.key, required this.task, this.onTaskChanged});

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
        widget.onTaskChanged?.call();
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
      return TextField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        onSubmitted: (_) => _saveTitleEdit(),
        onTapOutside: (_) => _saveTitleEdit(),
      );
    }

    return GestureDetector(
      onTap: _startTitleEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        child: Text(
          widget.task.title,
          style: widget.task.isCompleted
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 16,
                )
              : const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

/// Stateful widget for task description editing
class _TaskDescription extends StatefulWidget {
  final Task task;
  final VoidCallback? onTaskChanged;

  const _TaskDescription({super.key, required this.task, this.onTaskChanged});

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
        widget.onTaskChanged?.call();
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
        padding: const EdgeInsets.only(top: 8.0, left: 48.0, right: 8.0),
        child: _isEditingDescription
            ? TextField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  hintText: 'Aggiungi descrizione...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, size: 20),
                    onPressed: _saveDescriptionEdit,
                    tooltip: 'Salva',
                  ),
                ),
                onSubmitted: (_) => _saveDescriptionEdit(),
                onTapOutside: (_) => _saveDescriptionEdit(),
              )
            : GestureDetector(
                onTap: _startDescriptionEdit,
                child: Container(
                  padding: const EdgeInsets.all(4.0),
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
  final VoidCallback? onTaskChanged;

  const _TaskTagsRow({super.key, required this.taskId, this.onTaskChanged});

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
    _loadTags();
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
            widget.onTaskChanged?.call();
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
    if (_isLoading || _tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 48.0, right: 8.0),
      child: Row(
        children: [
          Text(
            'Tag:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _tags.map((tag) {
                final color = tag.colorObject ?? Colors.grey;
                return GestureDetector(
                  onTap: _showTagPicker,
                  child: Tooltip(
                    message: tag.name,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(100),
                            blurRadius: 3,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: Icon(
                        tag.iconData ?? Icons.label,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          InkWell(
            onTap: _showTagPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: TodoTheme.primaryPurple.withAlpha(100),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.new_label,
                size: 20,
                color: TodoTheme.primaryPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
