import 'package:flutter/material.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/models/project_scope_context.dart';
import 'package:solducci/features/life_os/domain/services/project_hierarchy_service.dart';
import 'package:solducci/features/life_os/presentation/widgets/living_block_card.dart';
import 'package:solducci/theme/app_theme.dart';

/// Progressive Modular Dashboard for a Project.
/// Dynamically self-assembles its modules based on structural depth
/// computed by [ProjectScopeContext].
class ProjectDashboardView extends StatefulWidget {
  final LifeEntity rootProject;
  final VoidCallback onSwitchToFolders;
  final VoidCallback onSwitchToGraph;
  final void Function(String text)? onAddThought;
  final void Function(String blockId, String text)? onUpdateThought;
  final void Function(String blockId)? onDeleteThought;

  const ProjectDashboardView({
    super.key,
    required this.rootProject,
    required this.onSwitchToFolders,
    required this.onSwitchToGraph,
    this.onAddThought,
    this.onUpdateThought,
    this.onDeleteThought,
  });

  @override
  State<ProjectDashboardView> createState() => _ProjectDashboardViewState();
}

class _ProjectDashboardViewState extends State<ProjectDashboardView> {
  ProjectHierarchyService? _hierarchyService;
  final TextEditingController _thoughtController = TextEditingController();

  ProjectScopeContext? _context;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _hierarchyService = getIt.isRegistered<ProjectHierarchyService>()
        ? getIt<ProjectHierarchyService>()
        : null;
    _evaluateContext();
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    super.dispose();
  }

  Future<void> _evaluateContext() async {
    setState(() => _isLoading = true);

    try {
      List<ProjectHierarchyNode> tree = [];
      List<LifeEntity> descendants = [];
      if (_hierarchyService != null) {
        tree = await _hierarchyService!.buildHierarchyTree(widget.rootProject.id);
        descendants = await _hierarchyService!.getRecursiveDescendants(widget.rootProject.id);
      }

      final modules = ProjectScopeContext.evaluateModules(
        directChildrenCount: tree.length,
        totalDescendantCount: descendants.length,
        blockCount: widget.rootProject.blocks.length,
      );

      if (mounted) {
        setState(() {
          _context = ProjectScopeContext(
            rootEntity: widget.rootProject,
            hierarchyTree: tree,
            descendants: descendants,
            activeModules: modules,
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitThought() {
    final text = _thoughtController.text.trim();
    if (text.isEmpty) return;
    widget.onAddThought?.call(text);
    _thoughtController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final scope = _context;
    final modules = scope?.activeModules ?? {
      ProjectModuleType.heroHeader,
      ProjectModuleType.thoughtStream,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // 1. Hero Header
        if (modules.contains(ProjectModuleType.heroHeader)) ...[
          _buildHeroHeader(scope),
          const SizedBox(height: 16),
        ],

        // 2. Continuity Pulse
        if (modules.contains(ProjectModuleType.continuityPulse)) ...[
          _buildContinuityPulse(),
          const SizedBox(height: 16),
        ],

        // 3. Folder Tree Preview
        if (modules.contains(ProjectModuleType.folderTreePreview)) ...[
          _buildFolderPreview(scope),
          const SizedBox(height: 16),
        ],

        // 4. Ego Graph Radar Preview
        if (modules.contains(ProjectModuleType.egoGraphRadar)) ...[
          _buildGraphRadarPreview(scope),
          const SizedBox(height: 16),
        ],

        // 5. Thought Stream & Quick Add Composer
        if (modules.contains(ProjectModuleType.thoughtStream)) ...[
          _buildThoughtStream(),
        ],
      ],
    );
  }

  Widget _buildHeroHeader(ProjectScopeContext? scope) {
    final totalItems = scope?.descendants.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_tree_outlined, color: AppTheme.primary, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'PROGETTO RADICE',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalItems ${totalItems == 1 ? "elemento" : "elementi"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.rootProject.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),
          if (widget.rootProject.description != null &&
              widget.rootProject.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.rootProject.description!,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinuityPulse() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Flusso attivo: aggiungi pensieri in coda per approfondire il contesto senza perdere il filo.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderPreview(ProjectScopeContext? scope) {
    final direct = scope?.hierarchyTree ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Struttura Cartelle',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: widget.onSwitchToFolders,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Vedi tutte', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, color: AppTheme.primary, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in direct.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.entity.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.totalDescendantCount > 0)
                    Text(
                      '(${item.totalDescendantCount})',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGraphRadarPreview(ProjectScopeContext? scope) {
    final count = scope?.descendants.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hub_outlined, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Costellazione Grafo Attiva',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$count nodi interconnessi · Navigazione radiale',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.onSwitchToGraph,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27272A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Apri Grafo', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildThoughtStream() {
    final blocks = widget.rootProject.blocks;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: AppTheme.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Filo dei Pensieri & Note',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (blocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Ancora nessun pensiero aggiunto. Inizia a scrivere qui sotto.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            )
          else
            for (final block in blocks)
              LivingBlockCard(
                block: block,
                onUpdate: (newText) => widget.onUpdateThought?.call(block.id, newText),
                onDelete: () => widget.onDeleteThought?.call(block.id),
              ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _thoughtController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onSubmitted: (_) => _submitThought(),
                  decoration: InputDecoration(
                    hintText: 'Aggiungi pensiero in coda al progetto...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF202024),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: _submitThought,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
