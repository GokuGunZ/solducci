import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/controllers/canvas_tree_controller.dart';
import 'package:solducci/features/space/services/canvas_sync_service.dart';
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

  Future<void> _showAddNodeDialog(String? parentId) async {
    final TextEditingController titleController = TextEditingController();
    String selectedType = 'folder';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Aggiungi al Canvas', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Titolo',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF2C2C2E),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'folder', child: Text('Cartella 📁')),
                      DropdownMenuItem(value: 'markdown', child: Text('Testo / Appunto 📝')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
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
                  child: const Text('Crea', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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
      ),
      body: CustomScrollView(
        // Viewport-aware overscanning
        cacheExtent: 1500, // Pre-render 1500px outside viewport
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final node = _controller.rootNodes[index];
                  if (node.type == 'folder') {
                    return _FolderNodeWidget(
                      node: node,
                      controller: _controller,
                      depth: 0,
                      forceExpandLevelsRemaining: 0,
                      onAddChild: _showAddNodeDialog,
                    );
                  } else if (node.type == 'markdown') {
                    return _MarkdownNodeWidget(
                      node: node,
                      controller: _controller,
                      leftPadding: 0,
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: _controller.rootNodes.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNodeDialog(null),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

typedef AddChildCallback = void Function(String parentId);

class _FolderNodeWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final double leftPadding = depth == 0 ? 0.0 : 16.0;
    
    final bool isManuallyExpanded = controller.isExpanded(node.id);
    final int localLimit = controller.getDepthLimit(node.id);
    final bool visuallyExpanded = isManuallyExpanded || forceExpandLevelsRemaining > 0;
    
    int nextForceLevels = forceExpandLevelsRemaining > 0 ? forceExpandLevelsRemaining - 1 : 0;
    if (isManuallyExpanded && localLimit > 1) {
      if (localLimit - 1 > nextForceLevels) {
        nextForceLevels = localLimit - 1;
      }
    }

    final children = visuallyExpanded ? controller.getChildren(node.id) : <CanvasNode>[];

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: 0.5),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 1.5),
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
              title: Text(node.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_box, size: 20, color: Color(0xFF6366F1)),
                    onPressed: () => onAddChild(node.id),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16, color: Colors.white54),
                    onPressed: () => controller.setDepthLimit(node.id, localLimit - 1),
                  ),
                  Text('$localLimit', style: const TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16, color: Colors.white54),
                    onPressed: () => controller.setDepthLimit(node.id, localLimit + 1),
                  ),
                ],
              ),
              onTap: () {
                controller.toggleExpand(node.id);
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
                            controller: controller, 
                            depth: depth + 1, 
                            forceExpandLevelsRemaining: nextForceLevels,
                            onAddChild: onAddChild,
                          );
                        } else if (child.type == 'markdown') {
                          return _MarkdownNodeWidget(
                            node: child, 
                            controller: controller, 
                            leftPadding: 16.0,
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
      ),
    );
  }
}

class _MarkdownNodeWidget extends StatefulWidget {
  final CanvasNode node;
  final CanvasTreeController controller;
  final double leftPadding;

  const _MarkdownNodeWidget({required this.node, required this.controller, required this.leftPadding});

  @override
  State<_MarkdownNodeWidget> createState() => _MarkdownNodeWidgetState();
}

class _MarkdownNodeWidgetState extends State<_MarkdownNodeWidget> {
  late TextEditingController _textController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.node.payload['text'] ?? '');
  }

  @override
  void didUpdateWidget(covariant _MarkdownNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.payload['text'] != oldWidget.node.payload['text']) {
      final newText = widget.node.payload['text'] ?? '';
      if (_textController.text != newText) {
        _textController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.controller.updateNodeText(widget.node, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: widget.leftPadding, bottom: 8.0, top: 4.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.node.title, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              onChanged: _onTextChanged,
              maxLines: null,
              style: const TextStyle(color: Colors.white70, height: 1.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Scrivi qui...',
                hintStyle: TextStyle(color: Colors.white24),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
