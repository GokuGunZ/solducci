import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_creation_row.dart';
import 'package:solducci/widgets/documents/quick_edit_dialogs.dart';
import 'package:solducci/widgets/documents/recurrence_form_dialog.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Task detail page with inline editing and seamless UI
/// - Editable title in AppBar
/// - Properties section with chips (same style as TodoList)
/// - Tags section with circular badges
/// - Seamless description editor
/// - Subtasks list with full TaskListItem UI
/// - FAB to add new subtasks
class TaskDetailPage extends StatefulWidget {
  final Task task;
  final TodoDocument document;
  final ValueNotifier<bool>?
      showAllPropertiesNotifier; // Shared with parent view

  const TaskDetailPage({
    super.key,
    required this.task,
    required this.document,
    this.showAllPropertiesNotifier,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _taskService = TaskService();
  final _recurrenceService = RecurrenceService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  bool _isEditingTitle = false;
  bool _isEditingDescription = false;
  bool _isCreatingSubtask = false;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  List<Tag> _tags = [];
  bool _isLoadingTags = true;
  Recurrence? _recurrence;

  // Local toggle if not provided by parent
  late ValueNotifier<bool> _localShowAllPropertiesNotifier;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );

    // Use parent notifier if available, otherwise create local
    _localShowAllPropertiesNotifier =
        widget.showAllPropertiesNotifier ?? ValueNotifier<bool>(false);

    _loadTaskData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();

    // Only dispose if we created it locally
    if (widget.showAllPropertiesNotifier == null) {
      _localShowAllPropertiesNotifier.dispose();
    }

    super.dispose();
  }

  Future<void> _loadTaskData() async {
    // Load tags
    _loadTaskTags();

    // Load recurrence
    _loadRecurrence();
  }

  Future<void> _loadTaskTags() async {
    try {
      final tags = await _taskService.getEffectiveTags(widget.task.id);
      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTags = false;
        });
      }
    }
  }

  Future<void> _loadRecurrence() async {
    try {
      final recurrence = await _taskService.getEffectiveRecurrence(
        widget.task.id,
      );
      if (mounted) {
        setState(() {
          _recurrence = recurrence;
        });
      }
    } catch (e) {
      // Error loading recurrence
    }
  }

  // ========== TITLE EDITING ==========

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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')),
          );
        }
        _titleController.text = widget.task.title;
      }
    }

    setState(() {
      _isEditingTitle = false;
    });
  }

  // ========== DESCRIPTION EDITING ==========

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
        widget.task.description =
            newDescription.isEmpty ? null : newDescription;
        await _taskService.updateTask(widget.task);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')),
          );
        }
        _descriptionController.text = widget.task.description ?? '';
      }
    }

    setState(() {
      _isEditingDescription = false;
    });
  }

  // ========== QUICK EDIT METHODS ==========

  Future<void> _showPriorityPicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickPriorityPicker(
        currentPriority: widget.task.priority,
        onSelected: (newPriority) async {
          try {
            widget.task.priority = newPriority;
            await _taskService.updateTask(widget.task);
            setState(() {}); // Rebuild to show updated chip
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Priorità aggiornata')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Errore: $e')),
              );
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
            setState(() {}); // Rebuild to show updated chip
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scadenza aggiornata')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Errore: $e')),
              );
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
            setState(() {}); // Rebuild to show updated chip
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dimensione aggiornata')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Errore: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showRecurrencePicker() async {
    final currentRecurrence = await _recurrenceService.getRecurrenceForTask(
      widget.task.id,
    );

    if (!mounted) return;

    final result = await showDialog<Recurrence>(
      context: context,
      builder: (context) => RecurrenceFormDialog(recurrence: currentRecurrence),
    );

    if (result != null) {
      try {
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

        if (currentRecurrence == null) {
          await _recurrenceService.createRecurrence(recurrenceWithTaskId);
        } else {
          await _recurrenceService.updateRecurrence(recurrenceWithTaskId);
        }

        await _loadRecurrence();
        setState(() {}); // Rebuild to show updated chip

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ricorrenza configurata')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeRecurrence() async {
    try {
      final currentRecurrence = await _recurrenceService.getRecurrenceForTask(
        widget.task.id,
      );

      if (currentRecurrence != null) {
        await _recurrenceService.deleteRecurrence(currentRecurrence.id);
        setState(() {
          _recurrence = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ricorrenza rimossa')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  Future<void> _showTagPicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickTagPicker(
        taskId: widget.task.id,
        currentTags: _tags,
        onSelected: (newTags) async {
          try {
            final currentTagIds = _tags.map((t) => t.id).toSet();
            final newTagIds = newTags.map((t) => t.id).toSet();

            final tagsToAdd = newTagIds.difference(currentTagIds);
            final tagsToRemove = currentTagIds.difference(newTagIds);

            for (final tagId in tagsToAdd) {
              await _taskService.addTag(widget.task.id, tagId);
            }

            for (final tagId in tagsToRemove) {
              await _taskService.removeTag(widget.task.id, tagId);
            }

            await _loadTaskTags();
            setState(() {}); // Rebuild tags section

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tag aggiornati')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Errore: $e')),
              );
            }
          }
        },
      ),
    );
  }

  // ========== UI BUILDERS ==========

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient - covers entire screen
        Positioned.fill(
          child: TodoTheme.customBackgroundGradient,
        ),
        // Scaffold on top
        Scaffold(
          backgroundColor: Colors.transparent, // CRITICAL: Allow background gradient to show through
          extendBodyBehindAppBar: true, // Extend body behind AppBar
          appBar: _buildEditableAppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: 80,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Properties section (centered)
                  _buildPropertiesSection(),

                  const SizedBox(height: 24),

                  // Tags section (centered, 70% width)
                  _buildTagsSection(),

                  const SizedBox(height: 24),

                  // Description section (seamless)
                  _buildDescriptionSection(),

                  const SizedBox(height: 32),

                  // Subtasks section
                  _buildSubtasksSection(),
                ],
              ),
            ),
          ),
          floatingActionButton: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple[700]!.withValues(alpha: 0.3),
                      Colors.purple[900]!.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.purple[400]!.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple[700]!.withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.purple[300]!.withValues(alpha: 0.4),
                      blurRadius: 3,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addSubtask,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.white.withValues(alpha: 0.3),
                    highlightColor: Colors.white.withValues(alpha: 0.2),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ), // Close Scaffold
      ], // Close Stack children
    ); // Close Stack
  }

  PreferredSizeWidget _buildEditableAppBar() {
    return AppBar(
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: TodoTheme.glassAppBarDecoration(),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: TodoTheme.primaryPurple),
      title: _isEditingTitle
          ? TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              style: const TextStyle(
                color: TodoTheme.primaryPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _saveTitleEdit(),
              onTapOutside: (_) => _saveTitleEdit(),
            )
          : GestureDetector(
              onTap: _startTitleEdit,
              child: Text(
                widget.task.title,
                style: const TextStyle(
                  color: TodoTheme.primaryPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TodoTheme.primaryPurple.withValues(alpha: 0.3),
                TodoTheme.primaryPurple,
                TodoTheme.primaryPurple.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesSection() {
    // Check which properties have values
    final hasPriority = widget.task.priority != null;
    final hasDueDate = widget.task.dueDate != null;
    final hasSize = widget.task.tShirtSize != null;
    final hasRecurrence = _recurrence != null;

    return ValueListenableBuilder<bool>(
      valueListenable: _localShowAllPropertiesNotifier,
      builder: (context, showAll, child) {
        // Determine which properties to show
        final shouldShowPriority = showAll || hasPriority;
        final shouldShowDueDate = showAll || hasDueDate;
        final shouldShowSize = showAll || hasSize;
        final shouldShowRecurrence = showAll || hasRecurrence;

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (shouldShowPriority)
                _buildPropertyChip(
                  icon: Icons.flag_outlined,
                  color: widget.task.priority?.color ?? Colors.grey[400]!,
                  label: widget.task.priority?.label,
                  onTap: _showPriorityPicker,
                ),
              if (shouldShowDueDate)
                _buildPropertyChip(
                  icon: Icons.calendar_today_outlined,
                  color: widget.task.dueDate != null
                      ? (widget.task.isOverdue ? Colors.red : Colors.blue)
                      : Colors.grey[400]!,
                  label: widget.task.dueDate != null
                      ? DateFormat('dd/MM').format(widget.task.dueDate!)
                      : null,
                  onTap: _showDueDatePicker,
                ),
              if (shouldShowSize)
                _buildPropertyChip(
                  icon: Icons.straighten,
                  color: widget.task.tShirtSize != null
                      ? TodoTheme.primaryPurple
                      : Colors.grey[400]!,
                  label: widget.task.tShirtSize?.label,
                  onTap: _showSizePicker,
                ),
              if (shouldShowRecurrence) _buildRecurrenceChip(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPropertyChip({
    required IconData icon,
    required Color color,
    String? label,
    required VoidCallback onTap,
  }) {
    // Get lighter version of color for border
    final borderColor = Color.lerp(color, Colors.white, 0.3)!.withValues(alpha: 0.7);
    final highlightColor = Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
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
                  size: 20,
                  color: color,
                  shadows: const [
                    Shadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
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
        ),
      ),
    );
  }

  Widget _buildRecurrenceChip() {
    final hasRecurrence = _recurrence != null;
    final isEnabled = _recurrence?.isEnabled ?? true;

    final iconColor = hasRecurrence
        ? (isEnabled ? Colors.orange : Colors.grey[600]!)
        : Colors.grey[400]!;

    final borderColor = Color.lerp(iconColor, Colors.white, 0.3)!.withValues(alpha: 0.7);
    final highlightColor = Color.lerp(iconColor, Colors.white, 0.5)!.withValues(alpha: 0.5);

    return InkWell(
      onTap: _showRecurrencePicker,
      onLongPress: hasRecurrence ? _removeRecurrence : null,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
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
                  size: 20,
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
                  const SizedBox(width: 8),
                  Text(
                    'Ric.',
                    style: TextStyle(
                      fontSize: 14,
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
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _removeRecurrence,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.red,
                      shadows: [
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
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    if (_isLoadingTags) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tags.isEmpty) {
      return Center(
        child: InkWell(
          onTap: _showTagPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: TodoTheme.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TodoTheme.primaryPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.label_outline,
                  color: TodoTheme.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aggiungi tag',
                  style: TextStyle(
                    color: TodoTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._tags.map((tag) => _buildTagBadge(tag)),
            // Add tag button
            InkWell(
              onTap: _showTagPicker,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TodoTheme.primaryPurple.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: TodoTheme.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagBadge(Tag tag) {
    final color = tag.colorObject ?? TodoTheme.primaryPurple;
    return GestureDetector(
      onTap: _showTagPicker,
      child: Tooltip(
        message: tag.name,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            tag.iconData ?? Icons.label,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    if (_isEditingDescription) {
      return TextField(
        controller: _descriptionController,
        focusNode: _descriptionFocusNode,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        maxLines: null,
        minLines: 3,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Inserisci una descrizione...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onTapOutside: (_) => _saveDescriptionEdit(),
      );
    }

    final hasDescription =
        widget.task.description != null && widget.task.description!.isNotEmpty;

    return GestureDetector(
      onTap: _startDescriptionEdit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          hasDescription
              ? widget.task.description!
              : 'Inserisci una descrizione...',
          style: TextStyle(
            fontSize: 15,
            color: hasDescription ? Colors.black87 : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtasksSection() {
    // Use subtasks from the task object (loaded via tree structure)
    final hasSubtasks = widget.task.subtasks != null && widget.task.subtasks!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        if (hasSubtasks || _isCreatingSubtask)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Subtask',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),

        // Creation row if creating
        if (_isCreatingSubtask)
          TaskCreationRow(
            key: ValueKey('subtask_creation_${widget.task.id}'),
            document: widget.document,
            showAllPropertiesNotifier: _localShowAllPropertiesNotifier,
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
              // Subtasks will auto-update via stream
            },
          ),

        // Subtasks list
        if (hasSubtasks)
          ...(widget.task.subtasks!.map((subtask) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskListItem(
                  key: ValueKey('subtask_${subtask.id}'),
                  task: subtask,
                  document: widget.document,
                  depth: 1,
                  showAllPropertiesNotifier: _localShowAllPropertiesNotifier,
                ),
              ))),
      ],
    );
  }

  void _addSubtask() {
    setState(() {
      _isCreatingSubtask = true;
    });
  }
}