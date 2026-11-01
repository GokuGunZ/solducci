import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/domain/services/project_hierarchy_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Interactive Hierarchical Folder View for a Project entity.
/// Displays multi-level nested structures with folding/unfolding chevrons,
/// indentation indicators, leaf inspection, and inline child creation.
class ProjectFolderView extends StatefulWidget {
  final LifeEntity rootProject;
  final ProjectHierarchyService? hierarchyService;
  final LifeEntityRepository? entityRepository;
  final EntityRelationRepository? relationRepository;
  final void Function(LifeEntity entity)? onEntitySelected;

  const ProjectFolderView({
    super.key,
    required this.rootProject,
    this.hierarchyService,
    this.entityRepository,
    this.relationRepository,
    this.onEntitySelected,
  });

  @override
  State<ProjectFolderView> createState() => _ProjectFolderViewState();
}

class _ProjectFolderViewState extends State<ProjectFolderView> {
  final _uuid = const Uuid();
  late final ProjectHierarchyService _hierarchyService;
  late final LifeEntityRepository _entityRepo;
  late final EntityRelationRepository _relationRepo;

  List<ProjectHierarchyNode> _tree = [];
  final Set<String> _collapsedNodeIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _hierarchyService = widget.hierarchyService ?? getIt<ProjectHierarchyService>();
    _entityRepo = widget.entityRepository ?? getIt<LifeEntityRepository>();
    _relationRepo = widget.relationRepository ?? getIt<EntityRelationRepository>();
    _loadTree();
  }

  Future<void> _loadTree() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nodes = await _hierarchyService.buildHierarchyTree(widget.rootProject.id);
      if (mounted) {
        setState(() {
          _tree = nodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Errore durante il caricamento della gerarchia: $e';
        });
      }
    }
  }

  void _toggleCollapse(String nodeId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_collapsedNodeIds.contains(nodeId)) {
        _collapsedNodeIds.remove(nodeId);
      } else {
        _collapsedNodeIds.add(nodeId);
      }
    });
  }

  Future<void> _showAddChildDialog(String parentId, String parentTitle) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.create_new_folder_outlined, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aggiungi in "$parentTitle"',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Titolo del nuovo elemento...',
            hintStyle: TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Color(0xFF27272A),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _createChildUnder(parentId, result);
    }
  }

  Future<void> _createChildUnder(String parentId, String title) async {
    String userId = 'local-user';
    try {
      final currentId = Supabase.instance.client.auth.currentUser?.id;
      if (currentId != null) userId = currentId;
    } catch (_) {}

    final now = DateTime.now();
    final childId = _uuid.v4();

    final child = LifeEntity(
      id: childId,
      userId: userId,
      title: title,
      semanticRole: SemanticRole.seed,
      lifecycleState: LifecycleState.active,
      createdAt: now,
      updatedAt: now,
    );

    final createdChild = await _entityRepo.createEntity(child);

    final relation = EntityRelation(
      id: _uuid.v4(),
      userId: userId,
      sourceId: createdChild.id,
      targetType: TargetType.entity,
      targetId: parentId,
      relationType: RelationType.partOf,
      createdAt: now,
    );

    await _relationRepo.createRelation(relation);
    await _loadTree();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 32),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadTree, child: const Text('Ricarica')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // Root Folder Header
        _buildRootHeader(),
        const SizedBox(height: 8),

        // Children Tree
        if (_tree.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                const Icon(Icons.folder_open_rounded, color: Colors.white24, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Nessun elemento collegato',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Aggiungi sotto-idee o collezioni per strutturare il progetto.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Aggiungi Primo Elemento'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                  onPressed: () => _showAddChildDialog(widget.rootProject.id, widget.rootProject.title),
                ),
              ],
            ),
          )
        else ...[
          for (final node in _tree) _buildHierarchyNodeTile(node),
          const SizedBox(height: 12),
          // Add button at root level
          InkWell(
            onTap: () => _showAddChildDialog(widget.rootProject.id, widget.rootProject.title),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08), style: BorderStyle.solid),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Aggiungi elemento alla radice',
                    style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRootHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_special_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.rootProject.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Radice Progetto · ${_tree.length} rami principali',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyNodeTile(ProjectHierarchyNode node) {
    final hasChildren = node.children.isNotEmpty;
    final isCollapsed = _collapsedNodeIds.contains(node.entity.id);
    final indent = (node.depthLevel - 1) * 20.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: InkWell(
              onTap: () {
                if (widget.onEntitySelected != null) {
                  widget.onEntitySelected!(node.entity);
                } else {
                  context.push('/life_os/entity/${node.entity.id}');
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Expand/collapse chevron
                    if (hasChildren)
                      GestureDetector(
                        onTap: () => _toggleCollapse(node.entity.id),
                        child: AnimatedRotation(
                          turns: isCollapsed ? 0.0 : 0.25,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 18),
                        ),
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 6),

                    // Icon based on semantic role or children
                    Icon(
                      hasChildren ? Icons.folder_rounded : _getRoleIcon(node.entity.semanticRole),
                      color: hasChildren ? AppTheme.primary : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),

                    // Title
                    Expanded(
                      child: Text(
                        node.entity.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: hasChildren ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Descendant count badge if folder
                    if (hasChildren) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${node.totalDescendantCount}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Inline add sub-element button
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white38),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Aggiungi sotto-elemento',
                      onPressed: () => _showAddChildDialog(node.entity.id, node.entity.title),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Render children recursively if not collapsed
          if (hasChildren && !isCollapsed) ...[
            const SizedBox(height: 4),
            for (final childNode in node.children)
              _buildHierarchyNodeTile(childNode),
          ],
        ],
      ),
    );
  }

  IconData _getRoleIcon(SemanticRole role) {
    switch (role) {
      case SemanticRole.seed:
        return Icons.eco_outlined;
      case SemanticRole.idea:
        return Icons.lightbulb_outline_rounded;
      case SemanticRole.project:
        return Icons.account_tree_outlined;
      case SemanticRole.practice:
        return Icons.repeat_rounded;
      case SemanticRole.concept:
        return Icons.hub_outlined;
    }
  }
}
