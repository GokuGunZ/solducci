import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/theme/todo_theme.dart';
import 'package:solducci/widgets/common/todo_app_bar.dart';

/// Date filter options
enum DateFilterOption {
  today('Oggi'),
  thisWeek('Questa settimana'),
  thisMonth('Questo mese'),
  overdue('In ritardo'),
  noDueDate('Senza scadenza');

  final String label;
  const DateFilterOption(this.label);
}

/// Configuration for filtering and sorting tasks
class FilterSortConfig {
  final Set<TaskPriority> priorities;
  final Set<TaskStatus> statuses;
  final Set<TShirtSize> sizes; // Filter by t-shirt size
  final Set<String> tagIds; // Filter by tag IDs
  final DateFilterOption? dateFilter; // Filter by due date
  final bool showOverdueOnly; // Deprecated - use dateFilter instead
  final TaskSortOption? sortBy;
  final bool sortAscending;

  const FilterSortConfig({
    this.priorities = const {},
    this.statuses = const {},
    this.sizes = const {},
    this.tagIds = const {},
    this.dateFilter,
    this.showOverdueOnly = false,
    this.sortBy,
    this.sortAscending = true,
  });

  FilterSortConfig copyWith({
    Set<TaskPriority>? priorities,
    Set<TaskStatus>? statuses,
    Set<TShirtSize>? sizes,
    Set<String>? tagIds,
    DateFilterOption? dateFilter,
    bool? showOverdueOnly,
    TaskSortOption? sortBy,
    bool? sortAscending,
    bool clearSortBy = false, // Explicit flag to clear sortBy
    bool clearDateFilter = false, // Explicit flag to clear dateFilter
  }) {
    return FilterSortConfig(
      priorities: priorities ?? this.priorities,
      statuses: statuses ?? this.statuses,
      sizes: sizes ?? this.sizes,
      tagIds: tagIds ?? this.tagIds,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      showOverdueOnly: showOverdueOnly ?? this.showOverdueOnly,
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasFilters =>
      priorities.isNotEmpty ||
      statuses.isNotEmpty ||
      sizes.isNotEmpty ||
      tagIds.isNotEmpty ||
      dateFilter != null ||
      showOverdueOnly;

  int get activeFiltersCount {
    int count = 0;
    if (priorities.isNotEmpty) count++;
    if (statuses.isNotEmpty) count++;
    if (sizes.isNotEmpty) count++;
    if (tagIds.isNotEmpty) count++;
    if (dateFilter != null) count++;
    if (showOverdueOnly) count++;
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FilterSortConfig) return false;

    return _setEquals(priorities, other.priorities) &&
           _setEquals(statuses, other.statuses) &&
           _setEquals(sizes, other.sizes) &&
           _setEquals(tagIds, other.tagIds) &&
           dateFilter == other.dateFilter &&
           showOverdueOnly == other.showOverdueOnly &&
           sortBy == other.sortBy &&
           sortAscending == other.sortAscending;
  }

  @override
  int get hashCode {
    return Object.hash(
      _setHashCode(priorities),
      _setHashCode(statuses),
      _setHashCode(sizes),
      _setHashCode(tagIds),
      dateFilter,
      showOverdueOnly,
      sortBy,
      sortAscending,
    );
  }

  // Helper methods for Set comparison
  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  static int _setHashCode<T>(Set<T> set) {
    // Order-independent hash for sets
    return set.fold(0, (hash, element) => hash ^ element.hashCode);
  }
}

enum TaskSortOption {
  dueDate('Data scadenza'),
  priority('Priorità'),
  size('Dimensione'),
  title('Titolo'),
  createdAt('Data creazione'),
  custom('Ordine personalizzato'); // Manual drag-and-drop order

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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Scaffold(
          appBar: TodoAppBar(
            title: 'Filtri e Ordinamento',
            leading: IconButton(
              icon: const Icon(Icons.close),
              color: TodoTheme.primaryPurple,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                activeColor: TodoTheme.primaryPurple,
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
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              top: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Row(
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
                style: TodoTheme.elevatedButtonStyle,
                child: const Text('Applica'),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: TodoTheme.primaryPurple),
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
      selectedColor: TodoTheme.primaryPurple,
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
