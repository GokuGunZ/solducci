import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';

/// Editable task description widget with inline editing
///
/// Displays the task description with tap-to-edit functionality.
/// Hides when description is empty and not being edited.
class TaskDescription extends StatefulWidget {
  final Task task;

  const TaskDescription({super.key, required this.task});

  @override
  State<TaskDescription> createState() => _TaskDescriptionState();
}

class _TaskDescriptionState extends State<TaskDescription> {
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
        widget.task.description =
            newDescription.isEmpty ? null : newDescription;
        await _taskService.updateTask(widget.task);
        // Stream will update automatically
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Errore: $e')));
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
