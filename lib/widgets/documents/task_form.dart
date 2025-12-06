import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/tag_selector.dart';

/// Form for creating or editing a task
/// Handles all task fields: title, description, tags, priority, due date, size
class TaskForm extends StatefulWidget {
  final TodoDocument document;
  final Task? task; // null = create, non-null = edit
  final String? parentTaskId; // For creating sub-tasks

  const TaskForm({
    super.key,
    required this.document,
    this.task,
    this.parentTaskId,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = TaskService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  List<Tag> _selectedTags = [];
  TaskPriority? _selectedPriority;
  TShirtSize? _selectedSize;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');

    // Initialize values for edit mode
    if (widget.task != null) {
      _selectedPriority = widget.task!.priority;
      _selectedSize = widget.task!.tShirtSize;
      _selectedDueDate = widget.task!.dueDate;
      _loadTaskTags();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskTags() async {
    if (widget.task == null) return;

    try {
      final tags = await _taskService.getTaskTags(widget.task!.id);
      if (mounted) {
        setState(() {
          _selectedTags = tags;
        });
      }
    } catch (e) {
      // Error loading tags
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nuova Task' : 'Modifica Task'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTask,
              tooltip: 'Salva',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                hintText: 'Es: Comprare il latte',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Il titolo è obbligatorio';
                }
                return null;
              },
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                hintText: 'Aggiungi dettagli...',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 500,
            ),

            const SizedBox(height: 24),

            // Tags section
            _buildTagsSection(),

            const SizedBox(height: 24),

            // Priority selector
            _buildPrioritySelector(),

            const SizedBox(height: 16),

            // Due date picker
            _buildDueDatePicker(),

            const SizedBox(height: 16),

            // T-shirt size selector
            _buildSizeSelector(),

            const SizedBox(height: 24),

            // Info about parent task
            if (widget.parentTaskId != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Questa sarà una sub-task',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.label, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Tag',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _selectTags,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedTags.isEmpty)
              Text(
                'Nessun tag selezionato',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTags
                    .map((tag) => tag.getChip(
                          onDelete: () {
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                          },
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Priorità',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityChip(null, 'Nessuna', Colors.grey),
                ...TaskPriority.values.map((priority) =>
                    _buildPriorityChip(priority, priority.label, priority.color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority? priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      backgroundColor: color.withAlpha(50),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedPriority = selected ? priority : null;
        });
      },
    );
  }

  Widget _buildDueDatePicker() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _pickDueDate,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: _selectedDueDate != null ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scadenza',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDueDate == null
                          ? 'Nessuna scadenza'
                          : DateFormat('EEEE, dd MMMM yyyy', 'it_IT')
                              .format(_selectedDueDate!),
                      style: TextStyle(
                        color: _selectedDueDate == null
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedDueDate != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedDueDate = null;
                    });
                  },
                  tooltip: 'Rimuovi scadenza',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.straighten, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Dimensione (T-shirt)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSizeChip(null, 'Nessuna'),
                ...TShirtSize.values.map((size) => _buildSizeChip(size, size.label)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeChip(TShirtSize? size, String label) {
    final isSelected = _selectedSize == size;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.green,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedSize = selected ? size : null;
        });
      },
    );
  }

  Future<void> _selectTags() async {
    final result = await showModalBottomSheet<List<Tag>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TagSelector(
        selectedTags: _selectedTags,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDueDate ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('it', 'IT'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.task == null) {
        // Create new task
        final newTask = Task.create(
          documentId: widget.document.id,
          parentTaskId: widget.parentTaskId,
          title: title,
          description: description.isEmpty ? null : description,
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
        );

        final tagIds = _selectedTags.map((t) => t.id).toList();
        await _taskService.createTask(newTask, tagIds: tagIds);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task creata con successo!')),
          );
        }
      } else {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          title: title,
          description: description.isEmpty ? null : description,
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
        );

        await _taskService.updateTask(updatedTask);

        // Update tags
        final tagIds = _selectedTags.map((t) => t.id).toList();
        await _taskService.assignTags(widget.task!.id, tagIds);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task aggiornata con successo!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
