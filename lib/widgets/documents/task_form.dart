import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/recurrence.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/service/recurrence_service.dart';
import 'package:solducci/widgets/documents/tag_form_dialog.dart';
import 'package:solducci/widgets/documents/recurrence_form_dialog.dart';

/// Form for creating or editing a task
/// Handles all task fields: title, description, tags, priority, due date, size
class TaskForm extends StatefulWidget {
  final TodoDocument document;
  final Task? task; // null = create, non-null = edit
  final String? parentTaskId; // For creating sub-tasks
  final VoidCallback? onTaskSaved; // Callback after successful save
  final List<Tag>? initialTags; // Pre-selected tags for new tasks

  const TaskForm({
    super.key,
    required this.document,
    this.task,
    this.parentTaskId,
    this.onTaskSaved,
    this.initialTags,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = TaskService();
  final _tagService = TagService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  List<Tag> _selectedTags = [];
  List<Tag> _availableTags = [];
  bool _isLoadingTags = true;
  TaskPriority? _selectedPriority;
  TShirtSize? _selectedSize;
  TaskStatus? _selectedStatus;
  DateTime? _selectedDueDate;
  Recurrence? _recurrence;
  bool _isLoading = false;
  final _recurrenceService = RecurrenceService();

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');

    // Load available tags
    _loadAvailableTags();

    // Initialize values for edit mode
    if (widget.task != null) {
      _selectedPriority = widget.task!.priority;
      _selectedSize = widget.task!.tShirtSize;
      _selectedStatus = widget.task!.status;
      _selectedDueDate = widget.task!.dueDate;
      _loadTaskTags();
      _loadRecurrence();
    } else if (widget.initialTags != null) {
      // Pre-select tags for new tasks
      _selectedTags = List.from(widget.initialTags!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTags() async {
    try {
      final tags = await _tagService.getRootTags();
      if (mounted) {
        setState(() {
          _availableTags = tags;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableTags = [];
          _isLoadingTags = false;
        });
      }
    }
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

  Future<void> _loadRecurrence() async {
    if (widget.task == null) return;

    try {
      final recurrence = await _recurrenceService.getRecurrenceForTask(widget.task!.id);
      if (mounted && recurrence != null) {
        setState(() {
          _recurrence = recurrence;
        });
      }
    } catch (e) {
      // Error loading recurrence
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nuova Task' : 'Modifica Task'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
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

            const SizedBox(height: 16),

            // Status selector (only if advanced states enabled)
            if (_shouldShowAdvancedStates())
              _buildStatusSelector(),

            if (_shouldShowAdvancedStates())
              const SizedBox(height: 16),

            // Recurrence section
            _buildRecurrenceSection(),

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
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _saveTask,
        backgroundColor: _isLoading ? Colors.grey : Colors.purple[700],
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check, color: Colors.white),
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
                  onPressed: _showCreateTagDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Crea Nuovo'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoadingTags
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _availableTags.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Nessun tag disponibile. Creane uno!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTags
                            .map((tag) => _buildTagChip(tag))
                            .toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(Tag tag) {
    final isSelected = _selectedTags.any((t) => t.id == tag.id);
    final color = tag.colorObject ?? Colors.purple;

    return FilterChip(
      selected: isSelected,
      avatar: Icon(
        tag.iconData ?? Icons.label,
        size: 18,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(tag.name),
      backgroundColor: color.withAlpha(50),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag);
          } else {
            _selectedTags.removeWhere((t) => t.id == tag.id);
          }
        });
      },
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

  /// Check if any selected tag has advanced states enabled
  bool _shouldShowAdvancedStates() {
    return _selectedTags.any((tag) => tag.useAdvancedStates);
  }

  Widget _buildStatusSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Stato',
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
                _buildStatusChip(TaskStatus.pending, 'In attesa', Colors.grey),
                _buildStatusChip(TaskStatus.assigned, 'Assegnata', Colors.blue),
                _buildStatusChip(TaskStatus.inProgress, 'In corso', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status, String label, Color color) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      backgroundColor: Colors.grey[200],
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : TaskStatus.pending;
        });
      },
    );
  }

  Widget _buildRecurrenceSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Ricorrenza',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_recurrence == null)
                  TextButton.icon(
                    onPressed: _configureRecurrence,
                    icon: const Icon(Icons.add),
                    label: const Text('Configura'),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _configureRecurrence,
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifica'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _recurrence = null;
                          });
                        },
                        tooltip: 'Rimuovi ricorrenza',
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recurrence == null)
              Text(
                'Nessuna ricorrenza configurata',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          _getRecurrenceIntraDayDescription(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          _getRecurrenceInterDayDescription(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_recurrence!.endDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event_busy, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Fino al ${DateFormat('dd/MM/yyyy').format(_recurrence!.endDate!)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRecurrenceIntraDayDescription() {
    if (_recurrence == null) return '';

    if (_recurrence!.hourlyFrequency != null) {
      return 'Ogni ${_recurrence!.hourlyFrequency} ore';
    } else if (_recurrence!.specificTimes != null && _recurrence!.specificTimes!.isNotEmpty) {
      final times = _recurrence!.specificTimes!
          .map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}')
          .join(', ');
      return 'Alle: $times';
    }
    return 'Una volta al giorno';
  }

  String _getRecurrenceInterDayDescription() {
    if (_recurrence == null) return '';

    if (_recurrence!.dailyFrequency != null) {
      return 'Ogni ${_recurrence!.dailyFrequency} giorni';
    } else if (_recurrence!.weeklyDays != null && _recurrence!.weeklyDays!.isNotEmpty) {
      const dayNames = ['Dom', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'];
      final days = _recurrence!.weeklyDays!.map((d) => dayNames[d]).join(', ');
      return 'Ogni: $days';
    } else if (_recurrence!.monthlyDays != null && _recurrence!.monthlyDays!.isNotEmpty) {
      final days = _recurrence!.monthlyDays!.join(', ');
      return 'Giorni del mese: $days';
    }
    return 'Ogni giorno';
  }

  Future<void> _configureRecurrence() async {
    final result = await showDialog<Recurrence>(
      context: context,
      builder: (context) => RecurrenceFormDialog(
        recurrence: _recurrence,
      ),
    );

    if (result != null) {
      setState(() {
        _recurrence = result;
      });
    }
  }

  Future<void> _showCreateTagDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const TagFormDialog(tag: null),
    );

    // Reload tags if a new tag was created
    if (result == true) {
      _loadAvailableTags();
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
      // locale: const Locale('it', 'IT'), // Removed - causing crashes if not configured
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
        var newTask = Task.create(
          documentId: widget.document.id,
          parentTaskId: widget.parentTaskId,
          title: title,
          description: description.isEmpty ? null : description,
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
        );

        // Set T-shirt size and status
        newTask = newTask.copyWith(tShirtSize: _selectedSize);

        // Set status if advanced states enabled
        if (_selectedStatus != null && _shouldShowAdvancedStates()) {
          newTask = newTask.copyWith(status: _selectedStatus);
        }

        final tagIds = _selectedTags.map((t) => t.id).toList();
        final createdTask = await _taskService.createTask(newTask, tagIds: tagIds);

        // Save recurrence if configured
        if (_recurrence != null) {
          final recurrenceWithTaskId = Recurrence(
            id: _recurrence!.id,
            taskId: createdTask.id,
            tagId: null,
            hourlyFrequency: _recurrence!.hourlyFrequency,
            specificTimes: _recurrence!.specificTimes,
            dailyFrequency: _recurrence!.dailyFrequency,
            weeklyDays: _recurrence!.weeklyDays,
            monthlyDays: _recurrence!.monthlyDays,
            yearlyDates: _recurrence!.yearlyDates,
            startDate: _recurrence!.startDate,
            endDate: _recurrence!.endDate,
            createdAt: _recurrence!.createdAt,
          );
          await _recurrenceService.createRecurrence(recurrenceWithTaskId);
        }

        if (mounted) {
          widget.onTaskSaved?.call(); // Trigger refresh callback
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task creata con successo!')),
          );
        }
      } else {
        // Update existing task
        var updatedTask = widget.task!.copyWith(
          title: title,
          description: description.isEmpty ? null : description,
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
          tShirtSize: _selectedSize,
        );

        // Set status if advanced states enabled
        if (_selectedStatus != null && _shouldShowAdvancedStates()) {
          updatedTask = updatedTask.copyWith(status: _selectedStatus);
        }

        await _taskService.updateTask(updatedTask);

        // Update tags
        final tagIds = _selectedTags.map((t) => t.id).toList();
        await _taskService.assignTags(widget.task!.id, tagIds);

        // Update recurrence
        final existingRecurrence = await _recurrenceService.getRecurrenceForTask(widget.task!.id);

        if (_recurrence != null) {
          // Create or update recurrence
          final recurrenceWithTaskId = Recurrence(
            id: existingRecurrence?.id ?? _recurrence!.id,
            taskId: widget.task!.id,
            tagId: null,
            hourlyFrequency: _recurrence!.hourlyFrequency,
            specificTimes: _recurrence!.specificTimes,
            dailyFrequency: _recurrence!.dailyFrequency,
            weeklyDays: _recurrence!.weeklyDays,
            monthlyDays: _recurrence!.monthlyDays,
            yearlyDates: _recurrence!.yearlyDates,
            startDate: _recurrence!.startDate,
            endDate: _recurrence!.endDate,
            createdAt: existingRecurrence?.createdAt ?? DateTime.now(),
          );

          if (existingRecurrence != null) {
            await _recurrenceService.updateRecurrence(recurrenceWithTaskId);
          } else {
            await _recurrenceService.createRecurrence(recurrenceWithTaskId);
          }
        } else if (existingRecurrence != null) {
          // Delete recurrence if it was removed
          await _recurrenceService.deleteRecurrence(existingRecurrence.id);
        }

        if (mounted) {
          widget.onTaskSaved?.call(); // Trigger refresh callback
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
