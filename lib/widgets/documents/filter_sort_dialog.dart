import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/tag_service.dart';

/// Configuration for filtering and sorting tasks
class FilterSortConfig {
  final Set<TaskPriority> priorities;
  final Set<TaskStatus> statuses;
  final bool showOverdueOnly;
  final Set<String> tagIds; // Filter by tag IDs
  final TaskSortOption? sortBy;
  final bool sortAscending;

  const FilterSortConfig({
    this.priorities = const {},
    this.statuses = const {},
    this.showOverdueOnly = false,
    this.tagIds = const {},
    this.sortBy,
    this.sortAscending = true,
  });

  FilterSortConfig copyWith({
    Set<TaskPriority>? priorities,
    Set<TaskStatus>? statuses,
    bool? showOverdueOnly,
    Set<String>? tagIds,
    TaskSortOption? sortBy,
    bool? sortAscending,
  }) {
    return FilterSortConfig(
      priorities: priorities ?? this.priorities,
      statuses: statuses ?? this.statuses,
      showOverdueOnly: showOverdueOnly ?? this.showOverdueOnly,
      tagIds: tagIds ?? this.tagIds,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasFilters =>
      priorities.isNotEmpty || statuses.isNotEmpty || showOverdueOnly || tagIds.isNotEmpty;

  int get activeFiltersCount {
    int count = 0;
    if (priorities.isNotEmpty) count++;
    if (statuses.isNotEmpty) count++;
    if (showOverdueOnly) count++;
    if (tagIds.isNotEmpty) count++;
    return count;
  }
}

enum TaskSortOption {
  dueDate('Data scadenza'),
  priority('Priorità'),
  title('Titolo'),
  createdAt('Data creazione');

  final String label;
  const TaskSortOption(this.label);
}

/// Dialog for configuring filters and sorting
class FilterSortDialog extends StatefulWidget {
  final FilterSortConfig initialConfig;

  const FilterSortDialog({
    super.key,
    required this.initialConfig,
  });

  @override
  State<FilterSortDialog> createState() => _FilterSortDialogState();
}

class _FilterSortDialogState extends State<FilterSortDialog> {
  late Set<TaskPriority> _selectedPriorities;
  late Set<TaskStatus> _selectedStatuses;
  late bool _showOverdueOnly;
  late Set<String> _selectedTagIds;
  TaskSortOption? _sortBy;
  late bool _sortAscending;

  final _tagService = TagService();
  List<Tag> _availableTags = [];
  bool _isLoadingTags = true;

  @override
  void initState() {
    super.initState();
    _selectedPriorities = Set.from(widget.initialConfig.priorities);
    _selectedStatuses = Set.from(widget.initialConfig.statuses);
    _showOverdueOnly = widget.initialConfig.showOverdueOnly;
    _selectedTagIds = Set.from(widget.initialConfig.tagIds);
    _sortBy = widget.initialConfig.sortBy;
    _sortAscending = widget.initialConfig.sortAscending;
    _loadTags();
  }

  Future<void> _loadTags() async {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.purple),
                  const SizedBox(width: 12),
                  const Text(
                    'Filtri e Ordinamento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Filters section
              const SizedBox(height: 16),
              _buildSectionTitle('Filtri', Icons.filter_alt),
              const SizedBox(height: 12),

              // Priority filter
              const Text(
                'Priorità',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskPriority.values
                    .map((priority) => _buildPriorityChip(priority))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Status filter
              const Text(
                'Stato',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(TaskStatus.pending, 'In attesa', Colors.grey),
                  _buildStatusChip(TaskStatus.assigned, 'Assegnata', Colors.blue),
                  _buildStatusChip(TaskStatus.inProgress, 'In corso', Colors.orange),
                ],
              ),

              const SizedBox(height: 16),

              // Tag filter
              const Text(
                'Tag',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
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
                            'Nessun tag disponibile',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
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

              const SizedBox(height: 16),

              // Overdue filter
              CheckboxListTile(
                title: const Text('Solo task in ritardo'),
                value: _showOverdueOnly,
                onChanged: (value) {
                  setState(() {
                    _showOverdueOnly = value ?? false;
                  });
                },
                activeColor: Colors.purple[700],
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(),

              // Sorting section
              const SizedBox(height: 16),
              _buildSectionTitle('Ordinamento', Icons.sort),
              const SizedBox(height: 12),

              // Sort by
              const Text(
                'Ordina per',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskSortOption.values
                    .map((option) => _buildSortChip(option))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Sort direction
              Row(
                children: [
                  const Text(
                    'Direzione',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Crescente'),
                        icon: Icon(Icons.arrow_upward, size: 16),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Decrescente'),
                        icon: Icon(Icons.arrow_downward, size: 16),
                      ),
                    ],
                    selected: {_sortAscending},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _sortAscending = newSelection.first;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Resetta'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Applica'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.purple[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(TaskPriority priority) {
    final isSelected = _selectedPriorities.contains(priority);
    return FilterChip(
      selected: isSelected,
      label: Text(priority.label),
      backgroundColor: priority.color.withAlpha(50),
      selectedColor: priority.color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedPriorities.add(priority);
          } else {
            _selectedPriorities.remove(priority);
          }
        });
      },
    );
  }

  Widget _buildStatusChip(TaskStatus status, String label, Color color) {
    final isSelected = _selectedStatuses.contains(status);
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
          if (selected) {
            _selectedStatuses.add(status);
          } else {
            _selectedStatuses.remove(status);
          }
        });
      },
    );
  }

  Widget _buildTagChip(Tag tag) {
    final isSelected = _selectedTagIds.contains(tag.id);
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
            _selectedTagIds.add(tag.id);
          } else {
            _selectedTagIds.remove(tag.id);
          }
        });
      },
    );
  }

  Widget _buildSortChip(TaskSortOption option) {
    final isSelected = _sortBy == option;
    return ChoiceChip(
      selected: isSelected,
      label: Text(option.label),
      selectedColor: Colors.purple[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          // Allow deselecting by tapping again
          _sortBy = selected ? option : null;
        });
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedPriorities.clear();
      _selectedStatuses.clear();
      _selectedTagIds.clear();
      _showOverdueOnly = false;
      _sortBy = null; // Also reset sorting
      _sortAscending = true;
    });
  }

  void _applyFilters() {
    final config = FilterSortConfig(
      priorities: _selectedPriorities,
      statuses: _selectedStatuses,
      showOverdueOnly: _showOverdueOnly,
      tagIds: _selectedTagIds,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
    );
    Navigator.pop(context, config);
  }
}
