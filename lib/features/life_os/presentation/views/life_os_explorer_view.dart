import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

enum ExplorerSortOption {
  newest('Più recenti'),
  oldest('Meno recenti'),
  alphabetical('Alfabetico (A-Z)');

  final String label;
  const ExplorerSortOption(this.label);
}

class LifeOsExplorerView extends StatefulWidget {
  final SemanticRole? initialRole;
  final LifeEntityRepository? entityRepository;

  const LifeOsExplorerView({
    super.key,
    this.initialRole,
    this.entityRepository,
  });

  @override
  State<LifeOsExplorerView> createState() => _LifeOsExplorerViewState();
}

class _LifeOsExplorerViewState extends State<LifeOsExplorerView> {
  late final LifeEntityRepository _entityRepository;

  List<LifeEntity> _entities = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  SemanticRole? _selectedRole;
  OperationMode? _selectedMode;
  ExplorerSortOption _sortOption = ExplorerSortOption.newest;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entityRepository = widget.entityRepository ?? getIt<LifeEntityRepository>();
    _selectedRole = widget.initialRole;
    _loadEntities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _entityRepository.getEntities();
      if (mounted) {
        setState(() {
          _entities = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossibile caricare le entità: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<LifeEntity> get _filteredEntities {
    return _entities.where((entity) {
      // 1. Role Filter
      if (_selectedRole != null && entity.semanticRole != _selectedRole) {
        return false;
      }

      // 2. Mode Filter
      if (_selectedMode != null && entity.currentMode != _selectedMode) {
        return false;
      }

      // 3. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = entity.title.toLowerCase().contains(query);
        final descMatch = entity.description?.toLowerCase().contains(query) ?? false;
        final blocksMatch = entity.blocks.any((b) => b.content.toLowerCase().contains(query));
        if (!titleMatch && !descMatch && !blocksMatch) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        switch (_sortOption) {
          case ExplorerSortOption.newest:
            return b.createdAt.compareTo(a.createdAt);
          case ExplorerSortOption.oldest:
            return a.createdAt.compareTo(b.createdAt);
          case ExplorerSortOption.alphabetical:
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
      });
  }

  Color _roleColor(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return const Color(0xFF6366F1);
      case SemanticRole.practice:
        return const Color(0xFF10B981);
      case SemanticRole.concept:
        return const Color(0xFF3B82F6);
      case SemanticRole.idea:
        return const Color(0xFFF59E0B);
      case SemanticRole.seed:
        return const Color(0xFF10B981);
    }
  }

  String _roleLabel(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return 'Progetto';
      case SemanticRole.practice:
        return 'Pratica';
      case SemanticRole.concept:
        return 'Conoscenza';
      case SemanticRole.idea:
        return 'Idea';
      case SemanticRole.seed:
        return 'Seme';
    }
  }

  IconData _roleIcon(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return Icons.rocket_launch_rounded;
      case SemanticRole.practice:
        return Icons.repeat_rounded;
      case SemanticRole.concept:
        return Icons.menu_book_rounded;
      case SemanticRole.idea:
        return Icons.lightbulb_outline_rounded;
      case SemanticRole.seed:
        return Icons.eco_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return 'Poco fa';
    } else if (diff.inHours < 24 && date.day == now.day) {
      return 'Oggi';
    } else if (diff.inDays < 2) {
      return 'Ieri';
    } else if (diff.inDays < 30) {
      return '${diff.inDays} gg fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntities;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        showContextSwitcher: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esploratore LifeOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Esplora tutti i semi ed entità',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadEntities,
            tooltip: 'Ricarica',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Cerca per titolo, contenuto o pensieri...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Role Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildRoleFilterChip(label: 'Tutti', role: null),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(label: 'Semi', role: SemanticRole.seed),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(label: 'Progetti', role: SemanticRole.project),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(label: 'Pratiche', role: SemanticRole.practice),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(label: 'Conoscenza', role: SemanticRole.concept),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(label: 'Idee', role: SemanticRole.idea),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary Filter & Sort Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} ${filtered.length == 1 ? "risultato" : "risultati"}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<ExplorerSortOption>(
                        value: _sortOption,
                        dropdownColor: const Color(0xFF1E1E24),
                        icon: const Icon(Icons.sort_rounded, color: Colors.white54, size: 18),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        onChanged: (newSort) {
                          if (newSort != null) setState(() => _sortOption = newSort);
                        },
                        items: ExplorerSortOption.values.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(opt.label),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 36),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _loadEntities,
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                child: const Text('Riprova', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.inbox_outlined,
                                    color: Colors.white24,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Nessun elemento corrisponde a "$_searchQuery"'
                                        : 'Nessuna entità trovata per questa categoria.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEntities,
                            color: AppTheme.primary,
                            backgroundColor: const Color(0xFF18181B),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final entity = filtered[index];
                                return _buildEntityCard(entity);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip({required String label, required SemanticRole? role}) {
    final isSelected = _selectedRole == role;
    final color = role != null ? _roleColor(role) : AppTheme.primary;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (role != null) ...[
              Icon(_roleIcon(role), size: 12, color: isSelected ? color : Colors.white54),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityCard(LifeEntity entity) {
    final roleColor = _roleColor(entity.semanticRole);

    return InkWell(
      onTap: () {
        context.push('/life_os/entity/${entity.id}', extra: entity);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Role Badge + Mode + Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: roleColor.withOpacity(0.3), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_roleIcon(entity.semanticRole), size: 11, color: roleColor),
                      const SizedBox(width: 4),
                      Text(
                        _roleLabel(entity.semanticRole),
                        style: TextStyle(color: roleColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (entity.currentMode != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entity.currentMode!.value,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(entity.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              entity.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Optional Description
            if (entity.description != null && entity.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entity.description!,
                style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Living Blocks / Flow Indicator
            if (entity.blocks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.bubble_chart_outlined, color: Color(0xFF8B5CF6), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '${entity.blocks.length} ${entity.blocks.length == 1 ? "pensiero nel flusso" : "pensieri nel flusso"}',
                    style: TextStyle(color: const Color(0xFF8B5CF6).withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
