import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/widgets/graph/ego_graph_painter.dart';
import 'package:solducci/features/life_os/presentation/widgets/graph/node_inspection_card.dart';
import 'package:solducci/theme/app_theme.dart';

/// Interactive Focused Ego-Graph View.
/// Renders an anti-clutter radial visualization centered on the current level,
/// maintaining ancestor cluster context and requiring explicit gestures
/// (double tap or swipe) to descend into deeper levels.
class ProjectGraphView extends StatefulWidget {
  final LifeEntity rootProject;
  final LifeEntityRepository? entityRepository;
  final EntityRelationRepository? relationRepository;

  const ProjectGraphView({
    super.key,
    required this.rootProject,
    this.entityRepository,
    this.relationRepository,
  });

  @override
  State<ProjectGraphView> createState() => _ProjectGraphViewState();
}

class _ProjectGraphViewState extends State<ProjectGraphView> {
  late final LifeEntityRepository _entityRepo;
  late final EntityRelationRepository _relationRepo;

  late LifeEntity _currentFocalEntity;
  final List<LifeEntity> _breadcrumbs = [];
  List<LifeEntity> _immediateChildren = [];
  final Map<String, int> _childCounts = {};
  LifeEntity? _parentContextEntity;

  LifeEntity? _selectedEntity;
  bool _isLoading = true;
  String? _errorMessage;

  // Gesture tracking
  Offset? _lastTapPosition;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _entityRepo = widget.entityRepository ?? getIt<LifeEntityRepository>();
    _relationRepo = widget.relationRepository ?? getIt<EntityRelationRepository>();

    _currentFocalEntity = widget.rootProject;
    _breadcrumbs.add(widget.rootProject);
    _loadFocalLevel();
  }

  Future<void> _loadFocalLevel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedEntity = null;
    });

    try {
      // 1. Fetch children of _currentFocalEntity
      final relations = await _relationRepo.getRelationsForTarget(
        _currentFocalEntity.id,
        TargetType.entity,
      );

      final childIds = relations
          .where((r) => r.relationType == RelationType.partOf)
          .map((r) => r.sourceId)
          .toList();

      final children = <LifeEntity>[];
      for (final cid in childIds) {
        final ent = await _entityRepo.getEntityById(cid);
        if (ent != null) {
          children.add(ent);
          // Pre-fetch count of children for each child
          final grandRel = await _relationRepo.getRelationsForTarget(cid, TargetType.entity);
          final gCount = grandRel.where((r) => r.relationType == RelationType.partOf).length;
          _childCounts[cid] = gCount;
        }
      }

      // 2. Fetch parent context if not at root
      LifeEntity? parent;
      if (_breadcrumbs.length > 1) {
        parent = _breadcrumbs[_breadcrumbs.length - 2];
      }

      if (mounted) {
        setState(() {
          _immediateChildren = children;
          _parentContextEntity = parent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Errore durante il caricamento del grafo: $e';
        });
      }
    }
  }

  void _descendIntoNode(LifeEntity child) {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentFocalEntity = child;
      _breadcrumbs.add(child);
    });
    _loadFocalLevel();
  }

  void _ascendToBreadcrumb(int index) {
    if (index >= _breadcrumbs.length - 1) return;
    HapticFeedback.lightImpact();
    setState(() {
      final target = _breadcrumbs[index];
      _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
      _currentFocalEntity = target;
    });
    _loadFocalLevel();
  }

  void _handleTapDown(TapDownDetails details, Size canvasSize) {
    final localPos = details.localPosition;
    final nodes = _computeVisualNodes(canvasSize);

    for (final node in nodes) {
      final hitRadius = node.isClusterPill ? 50.0 : (node.radius + 12.0);
      if ((node.position - localPos).distance <= hitRadius) {
        if (node.isClusterPill) {
          // Tapping parent cluster pill ascends
          _ascendToBreadcrumb(_breadcrumbs.length - 2);
          return;
        }

        // Check for double-tap detection
        final now = DateTime.now();
        if (_lastTapTime != null &&
            now.difference(_lastTapTime!).inMilliseconds < 350 &&
            _lastTapPosition != null &&
            (_lastTapPosition! - localPos).distance < 30) {
          // Double-tap confirmed!
          if (!node.isFocalRoot) {
            _descendIntoNode(node.entity);
          }
          _lastTapTime = null;
          return;
        }

        _lastTapTime = now;
        _lastTapPosition = localPos;

        HapticFeedback.selectionClick();
        setState(() {
          _selectedEntity = node.entity;
        });
        return;
      }
    }

    // Tap outside nodes dismisses selection
    if (_selectedEntity != null) {
      setState(() {
        _selectedEntity = null;
      });
    }
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;

    if (velocity < 0) {
      // Swiped Left: If a child node is selected, drill down
      if (_selectedEntity != null && _selectedEntity!.id != _currentFocalEntity.id) {
        _descendIntoNode(_selectedEntity!);
      }
    } else {
      // Swiped Right: Ascend one level up if available
      if (_breadcrumbs.length > 1) {
        _ascendToBreadcrumb(_breadcrumbs.length - 2);
      }
    }
  }

  List<VisualGraphNode> _computeVisualNodes(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final nodes = <VisualGraphNode>[];

    // 1. Focal Root Node
    nodes.add(VisualGraphNode(
      entity: _currentFocalEntity,
      position: center,
      radius: 36,
      isFocalRoot: true,
      isSelected: _selectedEntity?.id == _currentFocalEntity.id,
      childCount: _immediateChildren.length,
    ));

    // 2. Parent Cluster Pill (if applicable)
    if (_parentContextEntity != null) {
      nodes.add(VisualGraphNode(
        entity: _parentContextEntity!,
        position: Offset(center.dx, center.dy - 180),
        radius: 20,
        isClusterPill: true,
      ));
    }

    // 3. Immediate Children arranged orbitally
    final childCount = _immediateChildren.length;
    final orbitRadius = childCount > 5 ? 160.0 : 130.0;

    for (int i = 0; i < childCount; i++) {
      final child = _immediateChildren[i];
      final angle = (2 * math.pi / childCount) * i - (math.pi / 2);
      final childPos = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );

      nodes.add(VisualGraphNode(
        entity: child,
        position: childPos,
        radius: 24,
        childCount: _childCounts[child.id] ?? 0,
        isSelected: _selectedEntity?.id == child.id,
      ));
    }

    return nodes;
  }

  List<VisualGraphEdge> _computeVisualEdges(List<VisualGraphNode> nodes, Offset center) {
    final edges = <VisualGraphEdge>[];

    for (final node in nodes) {
      if (node.isFocalRoot) continue;
      edges.add(VisualGraphEdge(
        from: center,
        to: node.position,
        isHighlighted: node.isSelected,
      ));
    }

    return edges;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Breadcrumbs Trail Header
        _buildBreadcrumbBar(),

        // 2. Interactive Graph Canvas
        Expanded(
          child: Stack(
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              else if (_errorMessage != null)
                Center(
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error)),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    final center = Offset(size.width / 2, size.height / 2);
                    final nodes = _computeVisualNodes(size);
                    final edges = _computeVisualEdges(nodes, center);

                    return GestureDetector(
                      onTapDown: (details) => _handleTapDown(details, size),
                      onHorizontalDragEnd: _handleHorizontalSwipe,
                      child: Container(
                        color: const Color(0xFF09090B),
                        width: size.width,
                        height: size.height,
                        child: CustomPaint(
                          painter: EgoGraphPainter(
                            nodes: nodes,
                            edges: edges,
                            center: center,
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // 3. Floating gesture helper tip
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 12, color: Colors.white54),
                      SizedBox(width: 4),
                      Text(
                        '1 tap: Ispeziona · 2 tap: Entra',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Inspection Bottom Sheet Card (when a node is selected)
              if (_selectedEntity != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: NodeInspectionCard(
                    entity: _selectedEntity!,
                    childCount: _childCounts[_selectedEntity!.id] ?? 0,
                    onDescend: () => _descendIntoNode(_selectedEntity!),
                    onClose: () => setState(() => _selectedEntity = null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF141417),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < _breadcrumbs.length; i++) ...[
              InkWell(
                onTap: () => _ascendToBreadcrumb(i),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    _breadcrumbs[i].title,
                    style: TextStyle(
                      color: i == _breadcrumbs.length - 1 ? AppTheme.primary : Colors.white60,
                      fontWeight: i == _breadcrumbs.length - 1 ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (i < _breadcrumbs.length - 1)
                const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white30),
            ],
          ],
        ),
      ),
    );
  }
}
