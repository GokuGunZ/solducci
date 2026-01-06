import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Preview page showing different inline filter/sort UI solutions
class FilterSortUIPreview extends StatefulWidget {
  const FilterSortUIPreview({super.key});

  @override
  State<FilterSortUIPreview> createState() => _FilterSortUIPreviewState();
}

class _FilterSortUIPreviewState extends State<FilterSortUIPreview> {
  // State for each solution
  Set<TaskPriority> _selectedPriorities1 = {};
  Set<TaskPriority> _selectedPriorities2 = {};
  Set<TaskPriority> _selectedPriorities3 = {};
  Set<TaskPriority> _selectedPriorities4 = {};
  Set<TaskPriority> _selectedPriorities5 = {};
  Set<TaskPriority> _selectedPriorities6 = {};
  Set<TaskPriority> _selectedPriorities7 = {};
  Set<TaskPriority> _selectedPriorities8 = {};

  String? _sortBy1;
  String? _sortBy2;
  String? _sortBy3;
  String? _sortBy4;
  String? _sortBy5;
  bool _sortAscending5 = true;
  String? _sortBy6;
  bool _sortAscending6 = true;
  String? _sortBy7;
  bool _sortAscending7 = true;
  String? _sortBy8;
  bool _sortAscending8 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter & Sort UI Solutions'),
        backgroundColor: TodoTheme.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader('Soluzioni per Filtri e Ordinamento Inline'),
          const SizedBox(height: 24),

          // Solution 1: Compact Icons (1 line)
          _buildSolutionCard(
            title: 'Soluzione 1: Compact - Icone su 1 linea',
            description: 'Pro: Minimo spazio, veloce da usare\nContro: Meno chiaro, può sembrare affollato',
            impact: 'Spazio: Minimo (40px) | Usabilità: Media | UX: 3/5',
            child: _buildSolution1(),
          ),

          // Solution 2: Two Lines with Labels
          _buildSolutionCard(
            title: 'Soluzione 2: Two Lines - Filtri e Ordinamento separati',
            description: 'Pro: Chiaro e organizzato, facile da capire\nContro: Usa più spazio verticale',
            impact: 'Spazio: Medio (80px) | Usabilità: Alta | UX: 5/5',
            child: _buildSolution2(),
          ),

          // Solution 3: Chips with Dropdown
          _buildSolutionCard(
            title: 'Soluzione 3: Chips eleganti con dropdown',
            description: 'Pro: Molto pulito, stile moderno\nContro: Richiede 2 tap per alcune azioni',
            impact: 'Spazio: Medio (60px) | Usabilità: Alta | UX: 4/5',
            child: _buildSolution3(),
          ),

          // Solution 4: Expandable Bar
          _buildSolutionCard(
            title: 'Soluzione 4: Barra espandibile',
            description: 'Pro: Nasconde complessità, spazio zero quando chiuso\nContro: Richiede espansione per usare',
            impact: 'Spazio: Minimo (48px) | Usabilità: Media | UX: 4/5',
            child: _buildSolution4(),
          ),

          // Solution 5: Interactive Chips with Dropdowns (USER REQUESTED)
          _buildSolutionCard(
            title: 'Soluzione 5: Chip interattivi con dropdown ⭐',
            description: 'Pro: Design premium, interazioni eleganti, feedback visivo eccellente\nContro: Richiede dropdown per selezionare valori',
            impact: 'Spazio: Medio (70px) | Usabilità: Alta | UX: 5/5',
            child: _buildSolution5(),
          ),

          // Solution 6: Compact Interactive Chips (Variant)
          _buildSolutionCard(
            title: 'Soluzione 6: Variant - Chip compatti su 1 linea',
            description: 'Pro: Versione compatta della 5, tutto su una riga\nContro: Può diventare affollato con molti filtri attivi',
            impact: 'Spazio: Minimo (45px) | Usabilità: Alta | UX: 4/5',
            child: _buildSolution6(),
          ),

          // Solution 7: Floating Pills (Premium Variant)
          _buildSolutionCard(
            title: 'Soluzione 7: Variant - Floating Pills stile premium',
            description: 'Pro: Design molto elegante, animazioni fluide\nContro: Usa più spazio, può sembrare "too much"',
            impact: 'Spazio: Alto (90px) | Usabilità: Alta | UX: 5/5',
            child: _buildSolution7(),
          ),

          // Solution 8: Compact Premium Pills Side-by-Side (FINAL SOLUTION)
          _buildSolutionCard(
            title: 'Soluzione 8: FINALE - Compact Premium Pills ⭐⭐⭐',
            description: 'Pro: Combina il meglio di tutte! Compatto, elegante, interattivo\nContro: Nessuno!',
            impact: 'Spazio: Minimo (50px) | Usabilità: Eccellente | UX: 5/5',
            child: _buildSolution8(),
          ),

          const SizedBox(height: 40),
          _buildRecommendation(),
        ],
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: TodoTheme.primaryPurple,
      ),
    );
  }

  Widget _buildSolutionCard({
    required String title,
    required String description,
    required String impact,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TodoTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TodoTheme.lightPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                impact,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: TodoTheme.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // Solution 1: Compact Icons (1 line)
  Widget _buildSolution1() {
    return Row(
      children: [
        // Filter icons
        _buildFilterIcon(
          Icons.flag,
          Colors.red,
          _selectedPriorities1.contains(TaskPriority.high),
          () => _togglePriority(_selectedPriorities1, TaskPriority.high, 1),
        ),
        _buildFilterIcon(
          Icons.flag,
          Colors.orange,
          _selectedPriorities1.contains(TaskPriority.medium),
          () => _togglePriority(_selectedPriorities1, TaskPriority.medium, 1),
        ),
        _buildFilterIcon(
          Icons.flag,
          Colors.blue,
          _selectedPriorities1.contains(TaskPriority.low),
          () => _togglePriority(_selectedPriorities1, TaskPriority.low, 1),
        ),
        Container(width: 1, height: 24, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 8)),
        // Sort icons
        _buildSortIcon(Icons.calendar_today, 'date', _sortBy1, (v) => setState(() => _sortBy1 = v)),
        _buildSortIcon(Icons.sort_by_alpha, 'name', _sortBy1, (v) => setState(() => _sortBy1 = v)),
        _buildSortIcon(Icons.priority_high, 'priority', _sortBy1, (v) => setState(() => _sortBy1 = v)),
        const Spacer(),
        if (_selectedPriorities1.isNotEmpty || _sortBy1 != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () => setState(() {
              _selectedPriorities1.clear();
              _sortBy1 = null;
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  // Solution 2: Two Lines with Labels
  Widget _buildSolution2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters row
        Row(
          children: [
            const Icon(Icons.filter_list, size: 16, color: TodoTheme.primaryPurple),
            const SizedBox(width: 8),
            const Text('Filtri:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _buildLabeledFilterChip('Alta', Icons.flag, Colors.red,
              _selectedPriorities2.contains(TaskPriority.high),
              () => _togglePriority(_selectedPriorities2, TaskPriority.high, 2)),
            const SizedBox(width: 4),
            _buildLabeledFilterChip('Media', Icons.flag, Colors.orange,
              _selectedPriorities2.contains(TaskPriority.medium),
              () => _togglePriority(_selectedPriorities2, TaskPriority.medium, 2)),
            const SizedBox(width: 4),
            _buildLabeledFilterChip('Bassa', Icons.flag, Colors.blue,
              _selectedPriorities2.contains(TaskPriority.low),
              () => _togglePriority(_selectedPriorities2, TaskPriority.low, 2)),
          ],
        ),
        const SizedBox(height: 8),
        // Sort row
        Row(
          children: [
            const Icon(Icons.sort, size: 16, color: TodoTheme.primaryPurple),
            const SizedBox(width: 8),
            const Text('Ordina:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _buildSortChip('Data', Icons.calendar_today, 'date', _sortBy2, (v) => setState(() => _sortBy2 = v)),
            const SizedBox(width: 4),
            _buildSortChip('Nome', Icons.sort_by_alpha, 'name', _sortBy2, (v) => setState(() => _sortBy2 = v)),
            const SizedBox(width: 4),
            _buildSortChip('Priorità', Icons.priority_high, 'priority', _sortBy2, (v) => setState(() => _sortBy2 = v)),
          ],
        ),
      ],
    );
  }

  // Solution 3: Chips with Dropdown
  Widget _buildSolution3() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDropdownChip(
          'Priorità',
          Icons.flag,
          _selectedPriorities3.isEmpty ? 'Tutte' : '${_selectedPriorities3.length}',
        ),
        _buildDropdownChip(
          'Ordinamento',
          Icons.sort,
          _sortBy3 == null ? 'Nessuno' : _sortBy3!,
        ),
        _buildDropdownChip('Data', Icons.calendar_today, 'Tutte'),
        _buildDropdownChip('Dimensione', Icons.straighten, 'Tutte'),
        if (_selectedPriorities3.isNotEmpty || _sortBy3 != null)
          ActionChip(
            label: const Text('Reset'),
            avatar: const Icon(Icons.clear, size: 16),
            onPressed: () => setState(() {
              _selectedPriorities3.clear();
              _sortBy3 = null;
            }),
          ),
      ],
    );
  }

  // Solution 4: Expandable Bar
  Widget _buildSolution4() {
    bool isExpanded = _selectedPriorities4.isNotEmpty || _sortBy4 != null;

    return ExpansionTile(
      leading: const Icon(Icons.tune, color: TodoTheme.primaryPurple),
      title: Text(
        isExpanded
          ? 'Filtri attivi (${_selectedPriorities4.length})'
          : 'Filtri e ordinamento',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Priorità:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('Alta', Colors.red, _selectedPriorities4.contains(TaskPriority.high),
                    () => _togglePriority(_selectedPriorities4, TaskPriority.high, 4)),
                  _buildFilterChip('Media', Colors.orange, _selectedPriorities4.contains(TaskPriority.medium),
                    () => _togglePriority(_selectedPriorities4, TaskPriority.medium, 4)),
                  _buildFilterChip('Bassa', Colors.blue, _selectedPriorities4.contains(TaskPriority.low),
                    () => _togglePriority(_selectedPriorities4, TaskPriority.low, 4)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Ordina per:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSortChip('Data', Icons.calendar_today, 'date', _sortBy4, (v) => setState(() => _sortBy4 = v)),
                  _buildSortChip('Nome', Icons.sort_by_alpha, 'name', _sortBy4, (v) => setState(() => _sortBy4 = v)),
                  _buildSortChip('Priorità', Icons.priority_high, 'priority', _sortBy4, (v) => setState(() => _sortBy4 = v)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Solution 5: Interactive Chips with Dropdowns (USER REQUESTED)
  Widget _buildSolution5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters row - Chip con dropdown
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Priority filter chip
            _buildInteractiveFilterChip(
              icon: Icons.flag,
              label: _selectedPriorities5.isEmpty ? null : '${_selectedPriorities5.length} selezionate',
              color: _selectedPriorities5.isEmpty ? null : Colors.deepPurple,
              onTap: () => _showPriorityDropdown(5),
            ),
            // Status filter chip (example)
            _buildInteractiveFilterChip(
              icon: Icons.check_circle,
              label: null,
              color: null,
              onTap: () {}, // Mock
            ),
            // Tag filter chip (example)
            _buildInteractiveFilterChip(
              icon: Icons.label,
              label: null,
              color: null,
              onTap: () {}, // Mock
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        // Sort row - Toggle con colore e freccia
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInteractiveSortChip(
              icon: Icons.calendar_today,
              label: 'Data',
              value: 'date',
              currentSort: _sortBy5,
              ascending: _sortAscending5,
              onTap: () {
                setState(() {
                  if (_sortBy5 == 'date') {
                    _sortAscending5 = !_sortAscending5;
                  } else {
                    _sortBy5 = 'date';
                    _sortAscending5 = true;
                  }
                });
              },
            ),
            _buildInteractiveSortChip(
              icon: Icons.sort_by_alpha,
              label: 'Nome',
              value: 'name',
              currentSort: _sortBy5,
              ascending: _sortAscending5,
              onTap: () {
                setState(() {
                  if (_sortBy5 == 'name') {
                    _sortAscending5 = !_sortAscending5;
                  } else {
                    _sortBy5 = 'name';
                    _sortAscending5 = true;
                  }
                });
              },
            ),
            _buildInteractiveSortChip(
              icon: Icons.priority_high,
              label: 'Priorità',
              value: 'priority',
              currentSort: _sortBy5,
              ascending: _sortAscending5,
              onTap: () {
                setState(() {
                  if (_sortBy5 == 'priority') {
                    _sortAscending5 = !_sortAscending5;
                  } else {
                    _sortBy5 = 'priority';
                    _sortAscending5 = true;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // Solution 6: Compact Interactive Chips (Variant - single line)
  Widget _buildSolution6() {
    return Row(
      children: [
        // Filter chips (icon only when inactive)
        _buildCompactFilterChip(
          icon: Icons.flag,
          color: Colors.red,
          hasSelection: _selectedPriorities6.contains(TaskPriority.high),
          label: _selectedPriorities6.contains(TaskPriority.high) ? 'Alta' : null,
          onTap: () => _togglePriority(_selectedPriorities6, TaskPriority.high, 6),
        ),
        const SizedBox(width: 6),
        _buildCompactFilterChip(
          icon: Icons.flag,
          color: Colors.orange,
          hasSelection: _selectedPriorities6.contains(TaskPriority.medium),
          label: _selectedPriorities6.contains(TaskPriority.medium) ? 'Media' : null,
          onTap: () => _togglePriority(_selectedPriorities6, TaskPriority.medium, 6),
        ),
        const SizedBox(width: 6),
        _buildCompactFilterChip(
          icon: Icons.label,
          color: Colors.blue,
          hasSelection: false,
          label: null,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        Container(width: 1, height: 28, color: Colors.grey[300]),
        const SizedBox(width: 12),
        // Sort chips
        _buildCompactSortChip(
          icon: Icons.calendar_today,
          label: 'Data',
          value: 'date',
          currentSort: _sortBy6,
          ascending: _sortAscending6,
          onTap: () {
            setState(() {
              if (_sortBy6 == 'date') {
                _sortAscending6 = !_sortAscending6;
              } else {
                _sortBy6 = 'date';
                _sortAscending6 = true;
              }
            });
          },
        ),
        const SizedBox(width: 6),
        _buildCompactSortChip(
          icon: Icons.sort_by_alpha,
          label: 'Nome',
          value: 'name',
          currentSort: _sortBy6,
          ascending: _sortAscending6,
          onTap: () {
            setState(() {
              if (_sortBy6 == 'name') {
                _sortAscending6 = !_sortAscending6;
              } else {
                _sortBy6 = 'name';
                _sortAscending6 = true;
              }
            });
          },
        ),
        const Spacer(),
        if (_selectedPriorities6.isNotEmpty || _sortBy6 != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => setState(() {
              _selectedPriorities6.clear();
              _sortBy6 = null;
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  // Solution 7: Floating Pills (Premium Design)
  Widget _buildSolution7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter section with floating pills
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.withValues(alpha: 0.05), Colors.blue.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: TodoTheme.primaryPurple),
                  const SizedBox(width: 6),
                  const Text('Filtri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TodoTheme.primaryPurple)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildFloatingPill(
                    icon: Icons.flag,
                    label: 'Alta',
                    color: Colors.red,
                    selected: _selectedPriorities7.contains(TaskPriority.high),
                    onTap: () => _togglePriority(_selectedPriorities7, TaskPriority.high, 7),
                  ),
                  _buildFloatingPill(
                    icon: Icons.flag,
                    label: 'Media',
                    color: Colors.orange,
                    selected: _selectedPriorities7.contains(TaskPriority.medium),
                    onTap: () => _togglePriority(_selectedPriorities7, TaskPriority.medium, 7),
                  ),
                  _buildFloatingPill(
                    icon: Icons.flag,
                    label: 'Bassa',
                    color: Colors.blue,
                    selected: _selectedPriorities7.contains(TaskPriority.low),
                    onTap: () => _togglePriority(_selectedPriorities7, TaskPriority.low, 7),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Sort section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.withValues(alpha: 0.05), Colors.teal.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sort, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  const Text('Ordinamento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildFloatingSortPill(
                    icon: Icons.calendar_today,
                    label: 'Data',
                    value: 'date',
                    currentSort: _sortBy7,
                    ascending: _sortAscending7,
                    onTap: () {
                      setState(() {
                        if (_sortBy7 == 'date') {
                          _sortAscending7 = !_sortAscending7;
                        } else {
                          _sortBy7 = 'date';
                          _sortAscending7 = true;
                        }
                      });
                    },
                  ),
                  _buildFloatingSortPill(
                    icon: Icons.sort_by_alpha,
                    label: 'Nome',
                    value: 'name',
                    currentSort: _sortBy7,
                    ascending: _sortAscending7,
                    onTap: () {
                      setState(() {
                        if (_sortBy7 == 'name') {
                          _sortAscending7 = !_sortAscending7;
                        } else {
                          _sortBy7 = 'name';
                          _sortAscending7 = true;
                        }
                      });
                    },
                  ),
                  _buildFloatingSortPill(
                    icon: Icons.priority_high,
                    label: 'Priorità',
                    value: 'priority',
                    currentSort: _sortBy7,
                    ascending: _sortAscending7,
                    onTap: () {
                      setState(() {
                        if (_sortBy7 == 'priority') {
                          _sortAscending7 = !_sortAscending7;
                        } else {
                          _sortBy7 = 'priority';
                          _sortAscending7 = true;
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Solution 8: Compact Premium Pills Side-by-Side (FINAL SOLUTION)
  Widget _buildSolution8() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter container (compact, icon only at top)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.withValues(alpha: 0.08), Colors.blue.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon only (no label)
                const Icon(Icons.filter_alt, size: 18, color: TodoTheme.primaryPurple),
                const SizedBox(height: 8),
                // Chips inline with icon
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildCompactInteractiveFilterChip(
                      icon: Icons.flag,
                      label: _selectedPriorities8.isEmpty ? null : '${_selectedPriorities8.length}',
                      color: _selectedPriorities8.isEmpty ? null : Colors.deepPurple,
                      onTap: () => _showPriorityDropdown(8),
                    ),
                    _buildCompactInteractiveFilterChip(
                      icon: Icons.check_circle,
                      label: null,
                      color: null,
                      onTap: () {}, // Mock
                    ),
                    _buildCompactInteractiveFilterChip(
                      icon: Icons.label,
                      label: null,
                      color: null,
                      onTap: () {}, // Mock
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Sort container (compact, icon only at top)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.withValues(alpha: 0.08), Colors.teal.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon only (no label)
                const Icon(Icons.sort, size: 18, color: Colors.green),
                const SizedBox(height: 8),
                // Chips inline with icon
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildCompactInteractiveSortChip(
                      icon: Icons.calendar_today,
                      label: 'Data',
                      value: 'date',
                      currentSort: _sortBy8,
                      ascending: _sortAscending8,
                      onTap: () {
                        setState(() {
                          if (_sortBy8 == 'date') {
                            _sortAscending8 = !_sortAscending8;
                          } else {
                            _sortBy8 = 'date';
                            _sortAscending8 = true;
                          }
                        });
                      },
                    ),
                    _buildCompactInteractiveSortChip(
                      icon: Icons.sort_by_alpha,
                      label: 'Nome',
                      value: 'name',
                      currentSort: _sortBy8,
                      ascending: _sortAscending8,
                      onTap: () {
                        setState(() {
                          if (_sortBy8 == 'name') {
                            _sortAscending8 = !_sortAscending8;
                          } else {
                            _sortBy8 = 'name';
                            _sortAscending8 = true;
                          }
                        });
                      },
                    ),
                    _buildCompactInteractiveSortChip(
                      icon: Icons.priority_high,
                      label: 'Priorità',
                      value: 'priority',
                      currentSort: _sortBy8,
                      ascending: _sortAscending8,
                      onTap: () {
                        setState(() {
                          if (_sortBy8 == 'priority') {
                            _sortAscending8 = !_sortAscending8;
                          } else {
                            _sortBy8 = 'priority';
                            _sortAscending8 = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TodoTheme.primaryPurple.withValues(alpha: 0.1), TodoTheme.lightPurple],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TodoTheme.primaryPurple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recommend, color: TodoTheme.primaryPurple, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Raccomandazioni',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TodoTheme.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recommendation 1 - SOLUTION 8 (FINAL)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.withValues(alpha: 0.2), Colors.orange.withValues(alpha: 0.15)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🏆 SOLUZIONE FINALE: Soluzione 8',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'La combinazione perfetta di tutte le migliori caratteristiche! '
                  'Premium pills compatti side-by-side con chip interattivi stile Soluzione 5, '
                  'animazioni fluide della Soluzione 6, e il design elegante della Soluzione 7. '
                  'Minimo spazio verticale, massima usabilità e feedback visivo eccellente.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[900], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                const Text(
                  '✓ Compattissimo: solo 50px di altezza\n'
                  '✓ Design premium con floating pills colorati\n'
                  '✓ Chip interattivi con dropdown\n'
                  '✓ Animazioni fluide e feedback visivo\n'
                  '✓ Layout side-by-side ottimizzato\n'
                  '✓ Combina il meglio di tutte le soluzioni!',
                  style: TextStyle(fontSize: 12, height: 1.6, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Recommendation 2 - Solution 5
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌟 Alternativa: Soluzione 5 (Chip Interattivi)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 6),
                Text(
                  'Se preferisci più spazio verticale e una separazione più marcata tra filtri e ordinamento.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildFilterIcon(IconData icon, Color color, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(icon, size: 18, color: selected ? color : Colors.grey[400]),
      ),
    );
  }

  Widget _buildSortIcon(IconData icon, String value, String? currentSort, Function(String?) onChanged) {
    bool selected = currentSort == value;
    return InkWell(
      onTap: () => onChanged(selected ? null : value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? TodoTheme.primaryPurple.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? TodoTheme.primaryPurple : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(icon, size: 18, color: selected ? TodoTheme.primaryPurple : Colors.grey[400]),
      ),
    );
  }

  Widget _buildLabeledFilterChip(String label, IconData icon, Color color, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, IconData icon, String value, String? currentSort, Function(String?) onChanged) {
    bool selected = currentSort == value;
    return InkWell(
      onTap: () => onChanged(selected ? null : value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? TodoTheme.primaryPurple.withValues(alpha: 0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? TodoTheme.primaryPurple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? TodoTheme.primaryPurple : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? TodoTheme.primaryPurple : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : Colors.grey[700],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildDropdownChip(String label, IconData icon, String value) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      onPressed: () {
        // Show dropdown dialog
      },
    );
  }

  // ========== NEW HELPER WIDGETS FOR SOLUTIONS 5, 6, 7 ==========

  // Solution 5: Interactive Filter Chip with dropdown
  Widget _buildInteractiveFilterChip({
    required IconData icon,
    String? label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final bool hasActiveFilter = label != null && color != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: hasActiveFilter ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: hasActiveFilter ? color.withValues(alpha: 0.15) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActiveFilter ? color : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: hasActiveFilter ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: hasActiveFilter ? color : Colors.grey[600],
            ),
            if (hasActiveFilter) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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

  // Solution 5: Interactive Sort Chip with direction indicator
  Widget _buildInteractiveSortChip({
    required IconData icon,
    required String label,
    required String value,
    String? currentSort,
    required bool ascending,
    required VoidCallback onTap,
  }) {
    final bool isActive = currentSort == value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? TodoTheme.primaryPurple.withValues(alpha: 0.15) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? TodoTheme.primaryPurple : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: TodoTheme.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? TodoTheme.primaryPurple : Colors.grey[600],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: TodoTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: TodoTheme.primaryPurple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Solution 6: Compact Filter Chip
  Widget _buildCompactFilterChip({
    required IconData icon,
    required Color color,
    required bool hasSelection,
    String? label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: hasSelection ? 10 : 6,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: hasSelection ? color.withValues(alpha: 0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelection ? color : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: hasSelection ? [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: hasSelection ? color : Colors.grey[500]),
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

  // Solution 6: Compact Sort Chip
  Widget _buildCompactSortChip({
    required IconData icon,
    required String label,
    required String value,
    String? currentSort,
    required bool ascending,
    required VoidCallback onTap,
  }) {
    final bool isActive = currentSort == value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 10 : 6,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? TodoTheme.primaryPurple.withValues(alpha: 0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? TodoTheme.primaryPurple : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: TodoTheme.primaryPurple.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? TodoTheme.primaryPurple : Colors.grey[500]),
            if (isActive) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: TodoTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: TodoTheme.primaryPurple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Solution 7: Floating Pill
  Widget _buildFloatingPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? color : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Solution 7: Floating Sort Pill
  Widget _buildFloatingSortPill({
    required IconData icon,
    required String label,
    required String value,
    String? currentSort,
    required bool ascending,
    required VoidCallback onTap,
  }) {
    final bool isActive = currentSort == value;
    final Color activeColor = Colors.green.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    activeColor.withValues(alpha: 0.25),
                    activeColor.withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey[700],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: activeColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Solution 8: Compact Interactive Filter Chip (combines Sol 5 look + Sol 6 animations)
  Widget _buildCompactInteractiveFilterChip({
    required IconData icon,
    String? label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final bool hasActiveFilter = label != null && color != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: hasActiveFilter ? 10 : 6,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: hasActiveFilter ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasActiveFilter ? color : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: hasActiveFilter ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: hasActiveFilter ? color : Colors.grey[600],
            ),
            if (hasActiveFilter) ...[
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

  // Solution 8: Compact Interactive Sort Chip (combines Sol 5 look + Sol 6 animations)
  Widget _buildCompactInteractiveSortChip({
    required IconData icon,
    required String label,
    required String value,
    String? currentSort,
    required bool ascending,
    required VoidCallback onTap,
  }) {
    final bool isActive = currentSort == value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 10 : 6,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.green : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.green : Colors.grey[600],
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Mock dropdown for priority selection
  Future<void> _showPriorityDropdown(int solution) async {
    // Determine which set to update based on solution number
    final Set<TaskPriority> targetSet = solution == 5 ? _selectedPriorities5 : _selectedPriorities8;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Priorità'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Alta'),
              value: targetSet.contains(TaskPriority.high),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    targetSet.add(TaskPriority.high);
                  } else {
                    targetSet.remove(TaskPriority.high);
                  }
                });
              },
              activeColor: Colors.red,
            ),
            CheckboxListTile(
              title: const Text('Media'),
              value: targetSet.contains(TaskPriority.medium),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    targetSet.add(TaskPriority.medium);
                  } else {
                    targetSet.remove(TaskPriority.medium);
                  }
                });
              },
              activeColor: Colors.orange,
            ),
            CheckboxListTile(
              title: const Text('Bassa'),
              value: targetSet.contains(TaskPriority.low),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    targetSet.add(TaskPriority.low);
                  } else {
                    targetSet.remove(TaskPriority.low);
                  }
                });
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _togglePriority(Set<TaskPriority> set, TaskPriority priority, int solution) {
    setState(() {
      if (set.contains(priority)) {
        set.remove(priority);
      } else {
        set.add(priority);
      }
    });
  }
}
