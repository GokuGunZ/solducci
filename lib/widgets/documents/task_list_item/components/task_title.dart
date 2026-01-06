import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';

/// Editable task title widget with inline editing
///
/// Displays the task title with tap-to-edit functionality.
/// Shows strike-through styling when task is completed.
class TaskTitle extends StatefulWidget {
  final Task task;

  const TaskTitle({super.key, required this.task});

  @override
  State<TaskTitle> createState() => _TaskTitleState();
}

class _TaskTitleState extends State<TaskTitle> {
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Errore: $e')));
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
