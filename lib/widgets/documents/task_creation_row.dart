import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/quick_edit_dialogs.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Widget for inline task creation
class TaskCreationRow extends StatefulWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final VoidCallback onCancel;
  final VoidCallback onTaskCreated;
  final String? parentTaskId;

  const TaskCreationRow({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    required this.onCancel,
    required this.onTaskCreated,
    this.parentTaskId,
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
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
      final task = Task.create(
        documentId: widget.document.id,
        title: title,
        priority: _priority,
        dueDate: _dueDate,
        parentTaskId: widget.parentTaskId,
      );

      // Set t-shirt size after creation (not in factory)
      task.tShirtSize = _tShirtSize;

      await _taskService.createTask(task);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task creata')),
        );
        widget.onTaskCreated();
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
        ],
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
}
