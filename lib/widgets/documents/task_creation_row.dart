import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/widgets/documents/quick_edit_dialogs.dart';
import 'package:solducci/widgets/documents/recurrence_form_dialog.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Widget for inline task creation
class TaskCreationRow extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancel;
  final Future<void> Function() onTaskCreated;
  final String? parentTaskId;
  final List<Tag>? initialTags; // Pre-selected tags

  const TaskCreationRow({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.onCancel,
    required this.onTaskCreated,
    this.parentTaskId,
    this.initialTags,
  });

  @override
  State<TaskCreationRow> createState() => _TaskCreationRowState();
}

class _TaskCreationRowState extends State<TaskCreationRow> {
  late final TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();
  final _taskService = TaskService();
  bool _isSaving = false;

  // Task properties
  TaskPriority? _priority;
  DateTime? _dueDate;
  TShirtSize? _tShirtSize;
  Recurrence? _recurrence;
  List<Tag> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    // Initialize with pre-selected tags if provided
    if (widget.initialTags != null) {
      debugPrint('📝 TaskCreationRow: Received ${widget.initialTags!.length} initial tags');
      for (final tag in widget.initialTags!) {
        debugPrint('   - Tag: ${tag.name} (ID: "${tag.id}")');
      }
      _selectedTags = List.from(widget.initialTags!);
    }
    // Auto-focus the title field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il titolo è obbligatorio')),
      );
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      var task = Task.create(
        documentId: widget.document.id,
        title: title,
        priority: _priority,
        dueDate: _dueDate,
        parentTaskId: widget.parentTaskId,
      );

      // Set t-shirt size after creation (not in factory)
      task.tShirtSize = _tShirtSize;

      // CRITICAL: createTask returns the saved task with the database-generated ID
      task = await _taskService.createTask(task);
      debugPrint('✅ Task created with ID: ${task.id}');

      // Save recurrence if configured
      if (_recurrence != null) {
        final recurrenceService = RecurrenceService();
        final recurrenceWithTaskId = Recurrence(
          id: _recurrence!.id,
          taskId: task.id,
          tagId: null,
          hourlyFrequency: _recurrence!.hourlyFrequency,
          specificTimes: _recurrence!.specificTimes,
          dailyFrequency: _recurrence!.dailyFrequency,
          weeklyDays: _recurrence!.weeklyDays,
          monthlyDays: _recurrence!.monthlyDays,
          yearlyDates: _recurrence!.yearlyDates,
          startDate: _recurrence!.startDate,
          endDate: _recurrence!.endDate,
          isEnabled: _recurrence!.isEnabled,
          createdAt: _recurrence!.createdAt,
        );
        await recurrenceService.createRecurrence(recurrenceWithTaskId);
      }

      // Save tags if selected
      if (_selectedTags.isNotEmpty) {
        debugPrint('💾 Saving ${_selectedTags.length} tags for task ${task.id}');
        for (final tag in _selectedTags) {
          debugPrint('   - Attempting to save tag: ${tag.name} (ID: "${tag.id}")');
          // Skip tags with empty/null IDs
          if (tag.id.trim().isEmpty) {
            debugPrint('   ⚠️ SKIPPED: Tag has empty ID');
            continue;
          }
          try {
            await _taskService.addTag(task.id, tag.id);
            debugPrint('   ✅ Successfully saved tag');
          } catch (e) {
            debugPrint('   ❌ Error saving tag: $e');
            rethrow;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task creata')),
        );
        await widget.onTaskCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: 8.0 + (widget.parentTaskId != null ? 16.0 : 0),
        right: 8.0,
        top: 4.0,
        bottom: 4.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TodoTheme.primaryPurple.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: TodoTheme.primaryPurple.withValues(alpha: 0.15),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: X button, Title field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // X button (cancel)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _isSaving ? null : widget.onCancel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 24,
                      tooltip: 'Annulla',
                    ),
                    const SizedBox(width: 8),
                    // Title input field
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        enabled: !_isSaving,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Titolo task (obbligatorio)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _saveTask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Save button
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, color: Colors.green),
                      onPressed: _isSaving ? null : _saveTask,
                      iconSize: 24,
                      tooltip: 'Salva',
                    ),
                  ],
                ),
                // Property icons row (always visible)
                _buildPropertyIconsRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyIconsRow() {
    // Always show all properties during creation
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, left: 32.0, right: 8.0),
      child: Row(
        children: [
          _buildPropertyIcon(
            icon: Icons.flag_outlined,
            color: _priority?.color ?? Colors.grey[400]!,
            label: _priority?.label,
            onTap: _showPriorityPicker,
          ),
          const SizedBox(width: 8),
          _buildPropertyIcon(
            icon: Icons.calendar_today_outlined,
            color: _dueDate != null ? Colors.blue : Colors.grey[400]!,
            label: _dueDate != null
                ? DateFormat('dd/MM').format(_dueDate!)
                : null,
            onTap: _showDueDatePicker,
          ),
          const SizedBox(width: 8),
          _buildPropertyIcon(
            icon: Icons.straighten,
            color: _tShirtSize != null
                ? TodoTheme.primaryPurple
                : Colors.grey[400]!,
            label: _tShirtSize?.label,
            onTap: _showSizePicker,
          ),
          const SizedBox(width: 8),
          _buildRecurrenceIcon(),
          const SizedBox(width: 8),
          // Tag icon: only for depth 0 tasks (no parent)
          if (widget.parentTaskId == null) ...[
            _buildPropertyIcon(
              icon: Icons.label_outline,
              color: _selectedTags.isNotEmpty ? Colors.green : Colors.grey[400]!,
              label: _selectedTags.isNotEmpty ? '${_selectedTags.length}' : null,
              onTap: _showTagPicker,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurrenceIcon() {
    final hasRecurrence = _recurrence != null;
    final isEnabled = _recurrence?.isEnabled ?? true;

    // Determine color based on enabled state
    final iconColor = hasRecurrence
        ? (isEnabled ? Colors.orange : Colors.grey[600]!)
        : Colors.grey[400]!;
    final backgroundColor = hasRecurrence
        ? (isEnabled ? Colors.orange.withAlpha(30) : Colors.grey.withAlpha(30))
        : Colors.transparent;
    final borderColor = hasRecurrence
        ? (isEnabled ? Colors.orange.withAlpha(100) : Colors.grey.withAlpha(100))
        : Colors.orange.withAlpha(50);

    return InkWell(
      onTap: _isSaving ? null : _showRecurrencePicker,
      onLongPress: _isSaving || !hasRecurrence ? null : _removeRecurrence,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.repeat,
              size: 16,
              color: iconColor,
            ),
            if (hasRecurrence) ...[
              const SizedBox(width: 4),
              Text(
                'Ric.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: _isSaving ? null : _removeRecurrence,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyIcon({
    required IconData icon,
    required Color color,
    String? label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
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

  Future<void> _showPriorityPicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickPriorityPicker(
        currentPriority: _priority,
        onSelected: (newPriority) {
          setState(() {
            _priority = newPriority;
          });
        },
      ),
    );
  }

  Future<void> _showDueDatePicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickDueDatePicker(
        currentDueDate: _dueDate,
        onSelected: (newDueDate) {
          setState(() {
            _dueDate = newDueDate;
          });
        },
      ),
    );
  }

  Future<void> _showSizePicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickSizePicker(
        currentSize: _tShirtSize,
        onSelected: (newSize) {
          setState(() {
            _tShirtSize = newSize;
          });
        },
      ),
    );
  }

  Future<void> _showRecurrencePicker() async {
    final result = await showDialog<Recurrence>(
      context: context,
      builder: (context) => RecurrenceFormDialog(recurrence: _recurrence),
    );

    if (result != null) {
      setState(() {
        _recurrence = result;
      });
    }
  }

  void _removeRecurrence() {
    setState(() {
      _recurrence = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ricorrenza rimossa')),
    );
  }

  Future<void> _showTagPicker() async {
    await showQuickEditBottomSheet(
      context: context,
      child: QuickTagPicker(
        taskId: null, // No task ID yet since we're creating
        currentTags: _selectedTags,
        onSelected: (newTags) {
          setState(() {
            _selectedTags = newTags;
          });
        },
      ),
    );
  }
}
