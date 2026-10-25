import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/service/markdown_inbox_service.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class MarkdownStackWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const MarkdownStackWidget({super.key, required this.def});

  @override
  State<MarkdownStackWidget> createState() => _MarkdownStackWidgetState();
}

class _MarkdownStackWidgetState extends State<MarkdownStackWidget> with SingleTickerProviderStateMixin {
  final _inboxService = MarkdownInboxService();
  List<CanvasNode> _nodes = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Swipe gesture physics state (exact match to NoteStackWidget)
  double _dragDx = 0.0;
  double _dragDy = 0.0;
  late AnimationController _animController;
  late Animation<double> _anim;
  double _animStartDx = 0.0;
  double _animEndDx = 0.0;
  double _animStartDy = 0.0;
  double _animEndDy = 0.0;
  int _targetIndex = 0;

  @override
  void initState() {
    super.initState();
    _inboxService.addListener(_onInboxChanged);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _anim.addListener(() {
      setState(() {
        _dragDx = _animStartDx + (_animEndDx - _animStartDx) * _anim.value;
        _dragDy = _animStartDy + (_animEndDy - _animStartDy) * _anim.value;
      });
    });
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_targetIndex != _currentIndex) {
          setState(() {
            _currentIndex = _targetIndex;
            _dragDx = 0.0;
            _dragDy = 0.0;
          });
        } else {
          setState(() {
            _dragDx = 0.0;
            _dragDy = 0.0;
          });
        }
      }
    });

    _loadInboxFiles();
  }

  @override
  void dispose() {
    _inboxService.removeListener(_onInboxChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onInboxChanged() {
    _loadInboxFiles();
  }

  Future<void> _loadInboxFiles() async {
    try {
      final nodes = await _inboxService.getInboxNodes();
      if (mounted) {
        setState(() {
          _nodes = nodes;
          _isLoading = false;
          if (_currentIndex >= _nodes.length) {
            _currentIndex = _nodes.isNotEmpty ? _nodes.length - 1 : 0;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading inbox markdown nodes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_nodes.length <= 1) {
      setState(() {
        _dragDx += (details.primaryDelta ?? 0) * 0.25;
      });
      return;
    }
    setState(() {
      _dragDx += details.primaryDelta ?? 0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_nodes.length <= 1) {
      _animateBack();
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;
    const threshold = 40.0;

    if (_dragDx < -threshold || velocity < -400) {
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex + 1) % _nodes.length;
      _animateDismiss(toLeft: true);
    } else if (_dragDx > threshold || velocity > 400) {
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex - 1 + _nodes.length) % _nodes.length;
      _animateDismiss(toLeft: false);
    } else {
      _animateBack();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_nodes.length <= 1) {
      setState(() {
        _dragDy += (details.primaryDelta ?? 0) * 0.25;
      });
      return;
    }
    setState(() {
      _dragDy += details.primaryDelta ?? 0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_nodes.length <= 1) {
      _animateBack();
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;
    const threshold = 40.0;

    if (_dragDy < -threshold || velocity < -400) {
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex + 1) % _nodes.length;
      _animateDismiss(toUp: true);
    } else if (_dragDy > threshold || velocity > 400) {
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex - 1 + _nodes.length) % _nodes.length;
      _animateDismiss(toDown: true);
    } else {
      _animateBack();
    }
  }

  void _animateDismiss({bool? toLeft, bool? toDown, bool? toUp}) {
    _animStartDx = _dragDx;
    _animStartDy = _dragDy;
    if (toDown == true) {
      _animEndDx = _dragDx;
      _animEndDy = 300.0;
    } else if (toUp == true) {
      _animEndDx = _dragDx;
      _animEndDy = -300.0;
    } else {
      _animEndDx = (toLeft ?? true) ? -250.0 : 250.0;
      _animEndDy = _dragDy;
    }
    _animController.forward(from: 0.0);
  }

  void _animateBack() {
    _targetIndex = _currentIndex;
    _animStartDx = _dragDx;
    _animStartDy = _dragDy;
    _animEndDx = 0.0;
    _animEndDy = 0.0;
    _animController.forward(from: 0.0);
  }

  Future<void> _importNewFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final content = await file.readAsString();
        final name = result.files.single.name;
        await _inboxService.registerFile(path, name, content);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _openActiveFile(CanvasNode node) {
    final filePath = node.payload['filePath'] as String?;
    if (filePath != null && File(filePath).existsSync()) {
      context.push('/markdown-viewer', extra: filePath);
    } else {
      context.push('/space/markdown_inbox');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Oggi, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BentoWidgetContainer(
        size: widget.def.size,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2),
        ),
      );
    }

    if (_nodes.isEmpty) {
      return BentoWidgetContainer(
        size: widget.def.size,
        child: InkWell(
          onTap: _importNewFile,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                  ),
                  child: const Icon(Icons.article_outlined, color: Color(0xFF6366F1), size: 28),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Inbox Markdown Vuota',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tocca per importare il tuo primo file .md',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeNode = _nodes[_currentIndex];
    final previewText = (activeNode.payload['text'] as String?) ?? '';

    return BentoWidgetContainer(
      size: widget.def.size,
      child: Column(
        children: [
          // Top widget toolbar (identical to NoteStackWidget)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers_rounded, color: Color(0xFF6366F1), size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Inbox MD',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Stack indicator pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35), width: 0.8),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${_nodes.length}',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Import quick action
                    InkWell(
                      onTap: _importNewFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4), width: 0.8),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFF818CF8), size: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Card Stack with Physics
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 2 behind (if 3 or more nodes)
                  if (_nodes.length >= 3)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 4.0),
                        child: Transform.translate(
                          offset: const Offset(0, 8),
                          child: Transform.scale(
                            scale: 0.90,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF141416),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.04)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Layer 1 behind (if 2 or more nodes)
                  if (_nodes.length >= 2)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 6.0, top: 2.0),
                        child: Transform.translate(
                          offset: const Offset(0, 4),
                          child: Transform.scale(
                            scale: 0.95,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E24),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Front active card (Swipable)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                        onVerticalDragUpdate: _onVerticalDragUpdate,
                        onVerticalDragEnd: _onVerticalDragEnd,
                        onDoubleTap: () => _openActiveFile(activeNode),
                        child: Transform.translate(
                          offset: Offset(_dragDx, _dragDy),
                          child: Transform.rotate(
                            angle: _dragDx * 0.0003,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181E),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Title & Date Row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.description, color: Color(0xFF818CF8), size: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              activeNode.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _formatDate(activeNode.lastAccessedAt),
                                              style: const TextStyle(color: Colors.white38, fontSize: 9),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new_rounded, color: Colors.white54, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Apri lettore',
                                        onPressed: () => _openActiveFile(activeNode),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Markdown Preview Body (with gradient fade at bottom to avoid gesture collision)
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: SingleChildScrollView(
                                            physics: const NeverScrollableScrollPhysics(),
                                            child: MarkdownBody(
                                              data: previewText.isEmpty ? '*Nessun contenuto nel file*' : previewText,
                                              selectable: false,
                                              styleSheet: MarkdownStyleSheet(
                                                p: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 12, height: 1.4),
                                                h1: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                h2: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                                h3: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                code: const TextStyle(color: Color(0xFF10B981), fontFamily: 'monospace', fontSize: 11),
                                                blockquote: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                                                listBullet: const TextStyle(color: Color(0xFF6366F1)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          height: 24,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  const Color(0xFF18181E).withOpacity(0.0),
                                                  const Color(0xFF18181E),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
