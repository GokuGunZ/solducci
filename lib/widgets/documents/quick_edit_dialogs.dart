import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Quick edit dialog for task priority
class QuickPriorityPicker extends StatelessWidget {
  final TaskPriority? currentPriority;
  final Function(TaskPriority?) onSelected;

  const QuickPriorityPicker({
    super.key,
    required this.currentPriority,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleziona Priorità',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TodoTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          // Clear priority option
          ListTile(
            leading: const Icon(Icons.clear, color: Colors.grey),
            title: const Text('Nessuna priorità'),
            selected: currentPriority == null,
            selectedTileColor: Colors.grey.withAlpha(30),
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // Priority options
          ...TaskPriority.values.map((priority) {
            return ListTile(
              leading: Icon(Icons.flag, color: priority.color),
              title: Text(priority.label),
              selected: currentPriority == priority,
              selectedTileColor: priority.color.withAlpha(30),
              onTap: () {
                onSelected(priority);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

/// Quick edit dialog for task due date
class QuickDueDatePicker extends StatelessWidget {
  final DateTime? currentDueDate;
  final Function(DateTime?) onSelected;

  const QuickDueDatePicker({
    super.key,
    required this.currentDueDate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleziona Scadenza',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TodoTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          // Clear due date option
          ListTile(
            leading: const Icon(Icons.clear, color: Colors.grey),
            title: const Text('Nessuna scadenza'),
            selected: currentDueDate == null,
            selectedTileColor: Colors.grey.withAlpha(30),
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // Quick options
          ListTile(
            leading: const Icon(Icons.today, color: Colors.blue),
            title: const Text('Oggi'),
            onTap: () {
              onSelected(DateTime.now());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny, color: Colors.orange),
            title: const Text('Domani'),
            onTap: () {
              onSelected(DateTime.now().add(const Duration(days: 1)));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.green),
            title: const Text('Tra una settimana'),
            onTap: () {
              onSelected(DateTime.now().add(const Duration(days: 7)));
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // Custom date picker
          ListTile(
            leading: const Icon(Icons.event, color: Colors.purple),
            title: const Text('Scegli data personalizzata'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: currentDueDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (date != null) {
                onSelected(date);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Quick edit dialog for t-shirt size
class QuickSizePicker extends StatelessWidget {
  final TShirtSize? currentSize;
  final Function(TShirtSize?) onSelected;

  const QuickSizePicker({
    super.key,
    required this.currentSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleziona Dimensione',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TodoTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          // Clear size option
          ListTile(
            leading: const Icon(Icons.clear, color: Colors.grey),
            title: const Text('Nessuna dimensione'),
            selected: currentSize == null,
            selectedTileColor: Colors.grey.withAlpha(30),
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // Size options
          ...TShirtSize.values.map((size) {
            return ListTile(
              leading: Icon(
                Icons.straighten,
                color: TodoTheme.primaryPurple,
              ),
              title: Text(size.label),
              selected: currentSize == size,
              selectedTileColor: TodoTheme.primaryPurple.withAlpha(30),
              onTap: () {
                onSelected(size);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

/// Quick edit dialog for tags
class QuickTagPicker extends StatefulWidget {
  final String taskId;
  final List<Tag> currentTags;
  final Function(List<Tag>) onSelected;

  const QuickTagPicker({
    super.key,
    required this.taskId,
    required this.currentTags,
    required this.onSelected,
  });

  @override
  State<QuickTagPicker> createState() => _QuickTagPickerState();
}

class _QuickTagPickerState extends State<QuickTagPicker> {
  final _tagService = TagService();
  List<Tag> _allTags = [];
  List<String> _selectedTagIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = widget.currentTags.map((t) => t.id).toList();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _tagService.getRootTags();
      if (mounted) {
        setState(() {
          _allTags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleTag(Tag tag) {
    setState(() {
      if (_selectedTagIds.contains(tag.id)) {
        _selectedTagIds.remove(tag.id);
      } else {
        _selectedTagIds.add(tag.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seleziona Tag',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TodoTheme.primaryPurple,
                ),
              ),
              TextButton(
                onPressed: () {
                  final selectedTags = _allTags
                      .where((tag) => _selectedTagIds.contains(tag.id))
                      .toList();
                  widget.onSelected(selectedTags);
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_allTags.isEmpty)
            const Center(
              child: Text('Nessun tag disponibile'),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _allTags.map((tag) {
                    final isSelected = _selectedTagIds.contains(tag.id);
                    final color = tag.colorObject ?? Colors.grey;
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggleTag(tag),
                      title: Text(tag.name),
                      secondary: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tag.iconData ?? Icons.label,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      activeColor: TodoTheme.primaryPurple,
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quick edit dialog for title
class QuickTitleEditor extends StatefulWidget {
  final String currentTitle;
  final Function(String) onSaved;

  const QuickTitleEditor({
    super.key,
    required this.currentTitle,
    required this.onSaved,
  });

  @override
  State<QuickTitleEditor> createState() => _QuickTitleEditorState();
}

class _QuickTitleEditorState extends State<QuickTitleEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifica Titolo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TodoTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Titolo',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onSaved(value);
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    widget.onSaved(_controller.text);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TodoTheme.primaryPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salva'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick edit dialog for description
class QuickDescriptionEditor extends StatefulWidget {
  final String? currentDescription;
  final Function(String?) onSaved;

  const QuickDescriptionEditor({
    super.key,
    required this.currentDescription,
    required this.onSaved,
  });

  @override
  State<QuickDescriptionEditor> createState() => _QuickDescriptionEditorState();
}

class _QuickDescriptionEditorState extends State<QuickDescriptionEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifica Descrizione',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TodoTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descrizione',
              border: OutlineInputBorder(),
              hintText: 'Aggiungi una descrizione...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  widget.onSaved(null);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Rimuovi'),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSaved(
                        _controller.text.isEmpty ? null : _controller.text,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TodoTheme.primaryPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Salva'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper function to show bottom sheet with any widget
Future<void> showQuickEditBottomSheet({
  required BuildContext context,
  required Widget child,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    ),
  );
}
