import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/core/templates/canvas_template_registry.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/controllers/canvas_tree_controller.dart';
import 'package:solducci/features/space/services/canvas_sync_service.dart';
import 'package:solducci/features/space/repositories/canvas_local_repository.dart';
import 'package:solducci/features/space/widgets/nodes/markdown_node_widget.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfiniteCanvasView extends StatefulWidget {
  final String? groupId;
  final String? userId;

  const InfiniteCanvasView({super.key, this.groupId, this.userId});

  @override
  State<InfiniteCanvasView> createState() => _InfiniteCanvasViewState();
}

class _InfiniteCanvasViewState extends State<InfiniteCanvasView> {
  late final CanvasTreeController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCanvas();
  }

  Future<void> _initCanvas() async {
    await CanvasSyncService().initialize();
    
    // Esegui la Cache Eviction policy (pulisci payload più vecchi di 90 giorni)
    await CanvasLocalRepository().clearEvictedPayloads();
    
    String? gId = widget.groupId;
    String? uId = widget.userId;
    
    if (gId == null && uId == null) {
      final ctx = ContextManager().currentContext;
      if (ctx.isGroup) {
        gId = ctx.groupId;
      } else {
        uId = Supabase.instance.client.auth.currentUser?.id;
      }
    }
    
    _controller = CanvasTreeController(groupId: gId, userId: uId);
    _controller.addListener(_onTreeUpdated);
    
    // Ensure Sync Service is running
    CanvasSyncService().startSync();
    
    // Inject Welcome Canvas if this is a fresh empty space
    final prefs = await SharedPreferences.getInstance();
    final templateKey = 'template_injected_${uId ?? gId ?? 'default'}';
    final hasInjected = prefs.getBool(templateKey) ?? false;
    
    if (!hasInjected && _controller.rootNodes.isEmpty) {
      await _controller.injectTemplate(CanvasTemplateRegistry.welcomeCanvas);
      await prefs.setBool(templateKey, true);
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onTreeUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.removeListener(_onTreeUpdated);
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _showOmniAddSheet(String? parentId) async {
    final TextEditingController titleController = TextEditingController();
    String selectedType = 'markdown'; // default to markdown

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aggiungi al Canvas', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Type Selectors
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = 'markdown'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedType == 'markdown' ? const Color(0xFF6366F1).withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedType == 'markdown' ? const Color(0xFF6366F1) : Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.edit_note, color: selectedType == 'markdown' ? const Color(0xFF6366F1) : Colors.white54, size: 32),
                                const SizedBox(height: 8),
                                Text('Appunto', style: TextStyle(color: selectedType == 'markdown' ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = 'folder'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedType == 'folder' ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedType == 'folder' ? const Color(0xFF10B981) : Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.folder, color: selectedType == 'folder' ? const Color(0xFF10B981) : Colors.white54, size: 32),
                                const SizedBox(height: 8),
                                Text('Cartella', style: TextStyle(color: selectedType == 'folder' ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title input
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: selectedType == 'folder' ? 'Nome della cartella...' : 'Titolo dell\'appunto...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _controller.createNode(
                          title: val.trim(),
                          type: selectedType,
                          parentId: parentId,
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedType == 'folder' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          _controller.createNode(
                            title: titleController.text.trim(),
                            type: selectedType,
                            parentId: parentId,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Crea', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubNavbar() {
    final path = _controller.navigationPath;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _controller.jumpToFolder(null),
                    child: const Text('Root', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                  for (var node in path) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('/', style: TextStyle(color: Colors.white30)),
                    ),
                    GestureDetector(
                      onTap: () => _controller.jumpToFolder(node.id),
                      child: Text(node.title, style: TextStyle(color: node.id == _controller.currentCanvasRootId ? const Color(0xFF6366F1) : Colors.white70, fontWeight: node.id == _controller.currentCanvasRootId ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ]
                ],
              ),
            ),
          ),
          // Depth controller
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18, color: Colors.white54),
                onPressed: () => _controller.setGlobalDepthLimit(_controller.globalDepthLimit - 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text('Livelli: ${_controller.globalDepthLimit}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: Colors.white54),
                onPressed: () => _controller.setGlobalDepthLimit(_controller.globalDepthLimit + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // OLED black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Infinite Canvas', style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold)),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF6366F1)),
                tooltip: 'Reimposta viste custom',
                onPressed: _controller.resetAllOverrides,
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF10B981)),
                tooltip: 'Genera Template di Test',
                onPressed: () {
                  _controller.injectTemplate(CanvasTemplateRegistry.welcomeCanvas);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSubNavbar(),
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                if (details.data == 'omni-plus') {
                  _showOmniAddSheet(_controller.currentCanvasRootId);
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                final isNested = _controller.currentCanvasRootId != null;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isHovering ? const Color(0xFF6366F1).withValues(alpha: 0.05) : Colors.transparent,
                    border: isNested 
                        ? Border(
                            left: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 2),
                            right: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 2),
                            bottom: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 2),
                          )
                        : null,
                    boxShadow: isNested 
                        ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 0)] 
                        : null,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: CustomScrollView(
                      key: ValueKey(_controller.currentCanvasRootId ?? 'root'),
                      // Viewport-aware overscanning
                      cacheExtent: 1500, // Pre-render 1500px outside viewport
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final node = _controller.currentCanvasNodes[index];
                                if (node.type == 'folder') {
                                  return _FolderNodeWidget(
                                    node: node,
                                    controller: _controller,
                                    depth: 0,
                                    forceExpandLevelsRemaining: _controller.globalDepthLimit,
                                    onAddChild: _showOmniAddSheet,
                                  );
                                } else if (node.type == 'markdown') {
                                  return MarkdownNodeWidget(
                                    node: node,
                                    controller: _controller,
                                    depth: 0,
                                    limit: _controller.globalDepthLimit,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              childCount: _controller.currentCanvasNodes.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: LongPressDraggable<String>(
        data: 'omni-plus',
        feedback: FloatingActionButton(
          onPressed: null,
          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.8),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        child: FloatingActionButton(
          onPressed: () => _showOmniAddSheet(null),
          backgroundColor: const Color(0xFF6366F1),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

typedef AddChildCallback = void Function(String parentId);

class _FolderNodeWidget extends StatefulWidget {
  final CanvasNode node;
  final CanvasTreeController controller;
  final int depth;
  final int forceExpandLevelsRemaining;
  final AddChildCallback onAddChild;

  const _FolderNodeWidget({
    required this.node,
    required this.controller,
    required this.depth,
    required this.forceExpandLevelsRemaining,
    required this.onAddChild,
  });

  @override
  State<_FolderNodeWidget> createState() => _FolderNodeWidgetState();
}

class _FolderNodeWidgetState extends State<_FolderNodeWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final double leftPadding = widget.depth == 0 ? 0.0 : 16.0;
    
    final bool? explicitState = widget.controller.getFolderState(widget.node.id);
    final int? localLimitOverride = widget.controller.getDepthLimit(widget.node.id);
    
    final int effectiveLimit = localLimitOverride ?? widget.forceExpandLevelsRemaining;
    
    // Specific state overrides parent inherited state
    final bool visuallyExpanded = explicitState ?? (effectiveLimit > 1);
    
    int nextForceLevels = 0;
    if (visuallyExpanded) {
      nextForceLevels = effectiveLimit > 0 ? effectiveLimit - 1 : 0;
    }

    final children = visuallyExpanded ? widget.controller.getChildren(widget.node.id) : <CanvasNode>[];

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 8.0),
      child: GestureDetector(
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2) {
            setState(() {
              _scale = details.scale.clamp(0.8, 1.5);
            });
          }
        },
        onScaleEnd: (details) {
          if (_scale > 1.2) {
            widget.controller.enterFolder(widget.node.id);
          }
          setState(() {
            _scale = 1.0;
          });
        },
        child: Transform.scale(
          scale: _scale,
          child: DragTarget<String>(
            onAcceptWithDetails: (details) {
              if (details.data == 'omni-plus') {
                widget.onAddChild(widget.node.id);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return Container(
                decoration: BoxDecoration(
                  color: isHovering 
                      ? const Color(0xFF6366F1).withValues(alpha: 0.2) 
                      : const Color(0xFF1E1E1E).withValues(alpha: 0.5),
                  border: Border.all(
                    color: isHovering 
                        ? const Color(0xFF6366F1) 
                        : const Color(0xFF6366F1).withValues(alpha: 0.3), 
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            ListTile(
              leading: Icon(
                visuallyExpanded ? Icons.folder_open : Icons.folder,
                color: const Color(0xFF6366F1),
              ),
              title: Text(widget.node.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in_map, size: 20, color: Color(0xFF10B981)),
                    tooltip: 'Entra nella cartella',
                    onPressed: () => widget.controller.enterFolder(widget.node.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box, size: 20, color: Color(0xFF6366F1)),
                    onPressed: () => widget.onAddChild(widget.node.id),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16, color: Colors.white54),
                    onPressed: () => widget.controller.setDepthLimit(widget.node.id, effectiveLimit - 1),
                  ),
                  Text('$effectiveLimit', style: const TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16, color: Colors.white54),
                    onPressed: () => widget.controller.setDepthLimit(widget.node.id, effectiveLimit + 1),
                  ),
                ],
              ),
              onTap: () {
                widget.controller.toggleExpand(widget.node.id, visuallyExpanded);
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuart,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: visuallyExpanded && children.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children.map((child) {
                        if (child.type == 'folder') {
                          return _FolderNodeWidget(
                            node: child, 
                            controller: widget.controller, 
                            depth: widget.depth + 1, 
                            forceExpandLevelsRemaining: nextForceLevels,
                            onAddChild: widget.onAddChild,
                          );
                        } else if (child.type == 'markdown') {
                          return MarkdownNodeWidget(
                            node: child,
                            controller: widget.controller,
                            depth: widget.depth + 1,
                            limit: nextForceLevels,
                          );
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      );
      },
      ),
      ),
      ),
    );
  }
}
