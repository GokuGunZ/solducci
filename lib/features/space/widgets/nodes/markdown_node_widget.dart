import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/controllers/canvas_tree_controller.dart';
import 'package:solducci/features/space/services/canvas_sync_service.dart';

class MarkdownNodeWidget extends StatefulWidget {
  final CanvasNode node;
  final CanvasTreeController controller;
  final int depth;
  final int limit;

  const MarkdownNodeWidget({
    super.key,
    required this.node,
    required this.controller,
    required this.depth,
    required this.limit,
  });

  @override
  State<MarkdownNodeWidget> createState() => _MarkdownNodeWidgetState();
}

class _MarkdownNodeWidgetState extends State<MarkdownNodeWidget> with TickerProviderStateMixin {
  late TextEditingController _textController;
  late TextEditingController _titleController;
  late FocusNode _focusNode;
  late ScrollController _readerScrollController;
  late ScrollController _editorScrollController;
  Timer? _debounce;
  
  late AnimationController _controller;
  late AnimationController _waveController;
  
  double _dragExtent = 0.0;
  bool _isEditing = false;
  final double _flipThreshold = 150.0;
  double _dragY = 100.0; 
  
  DateTime? _lastTime;
  double _pullVelocity = 0.0;
  double _baseWavePhase = 0.0;
  double _rippleWavePhase = 0.0;
  double _currentRippleSpeed = 0.05;
  
  double _maxWidth = 340.0;

  String _lastSavedText = '';
  int _previousTextLength = 0;
  
  @override
  void initState() {
    super.initState();
    _lastSavedText = widget.node.payload['text'] ?? '';
    _previousTextLength = _lastSavedText.length;
    _textController = TextEditingController(text: _lastSavedText);
    _titleController = TextEditingController(text: widget.node.title);
    _focusNode = FocusNode();
    _readerScrollController = ScrollController();
    _editorScrollController = ScrollController();
    
    // Auto-save on blur
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _saveContent();
      }
    });

    if (widget.node.payload.isEmpty) {
      CanvasSyncService().loadPayload(widget.node.id);
    }
    
    _controller = AnimationController(vsync: this, lowerBound: -double.infinity, upperBound: double.infinity);
    _controller.addListener(() {
      setState(() {
        _dragExtent = _controller.value;
        _updateWaveControllerState();
      });
    });
    
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    // Start only if opened (though it defaults to 0, so it stays stopped)
    if (_dragExtent < 0) _waveController.repeat();
    
    _waveController.addListener(() {
      setState(() {
        double baseSpeed = 0.06;
        _baseWavePhase += baseSpeed;
        
        double minRippleSpeed = 0.03;
        double maxRippleSpeed = 0.12;
        
        double targetRippleSpeed = minRippleSpeed + (_pullVelocity / 1500.0) * (maxRippleSpeed - minRippleSpeed);
        targetRippleSpeed = targetRippleSpeed.clamp(minRippleSpeed, maxRippleSpeed);
        
        _currentRippleSpeed += (targetRippleSpeed - _currentRippleSpeed) * 0.05;
        _rippleWavePhase += _currentRippleSpeed;
        
        if (_pullVelocity > 0) {
          _pullVelocity *= 0.92; 
          if (_pullVelocity < 0.1) _pullVelocity = 0;
        }
      });
    });

    final isNew = DateTime.now().toUtc().difference(widget.node.createdAt).inSeconds.abs() < 5;
    if (isNew && _lastSavedText.isEmpty) {
      _dragExtent = -(_flipThreshold + 10);
      _isEditing = true;
      _controller.value = _dragExtent;
      _waveController.repeat();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
    }

    // Instant autofocus for new nodes
    if (widget.node.title.isEmpty || widget.node.title == 'Senza Titolo') {
      _isEditing = true;
      _dragExtent = -1000.0; // Ensure it's fully open
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(MarkdownNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final newText = widget.node.payload['text'] ?? '';
    // If the node changed from outside (e.g. sync from another device)
    // and it is DIFFERENT from what we last intentionally saved
    // AND we are not currently typing, then update the controller.
    if (newText != _lastSavedText && !_focusNode.hasFocus) {
      _textController.text = newText;
      _lastSavedText = newText;
    }
    
    if (oldWidget.node.title != widget.node.title && !_focusNode.hasFocus) {
      _titleController.text = widget.node.title;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    _readerScrollController.dispose();
    _editorScrollController.dispose();
    _controller.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _updateWaveControllerState() {
    if (_dragExtent < 0 && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (_dragExtent >= 0 && _waveController.isAnimating) {
      _waveController.stop();
    }
  }

  void _onTextChanged(String value) {
    final isInsertion = value.length > _previousTextLength;
    _previousTextLength = value.length;
    
    // Check for auto-list markdown on new line insertion
    if (isInsertion && value.endsWith('\n')) {
      final lines = value.split('\n');
      if (lines.length >= 2) {
        final previousLine = lines[lines.length - 2];
        if (previousLine.trimLeft().startsWith('- ')) {
          // Calculate indentation of the previous line
          final indentMatch = RegExp(r'^\s*').firstMatch(previousLine);
          final indent = indentMatch?.group(0) ?? '';
          
          // Inject "- " with same indentation
          final injection = '$indent- ';
          
          // Need a slight delay to let the controller finish its current cycle
          Future.microtask(() {
            final newText = value + injection;
            _textController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newText.length),
            );
          });
        }
      }
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _saveContent();
    });
  }

  void _saveContent() {
    if (_textController.text != _lastSavedText) {
      _lastSavedText = _textController.text;
      widget.controller.updateNodeText(
        widget.node, 
        _textController.text
      );
    }
    if (_titleController.text != widget.node.title) {
      final newTitle = _titleController.text.trim().isEmpty ? 'Senza Titolo' : _titleController.text.trim();
      widget.controller.updateNodeTitle(
        widget.node, 
        newTitle
      );
    }
  }

  void _updateHeightState(bool editing) {
    if (_isEditing == editing) return;
    
    // Delay setting isEditing to allow liquid to close or wait for smooth layout
    if (!editing) {
      FocusScope.of(context).unfocus();
      _saveContent();
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isEditing = false;
          });
        }
      });
    } else {
      setState(() {
        _isEditing = true;
      });
      
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOutCubic,
            alignment: 0.5,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _isEditing) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
    setState(() {
      _dragY = details.localPosition.dy;
      _lastTime = DateTime.now();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      if (_dragExtent > 0) _dragExtent = 0;
      if (_dragExtent < -_maxWidth) _dragExtent = -_maxWidth;
      _dragY = details.localPosition.dy;
      
      _updateWaveControllerState();
      
      final now = DateTime.now();
      if (_lastTime != null) {
        final dt = now.difference(_lastTime!).inMilliseconds;
        if (dt > 0) {
          _pullVelocity = (details.delta.dx.abs() / dt) * 1000.0;
        }
      }
      _lastTime = now;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    double velocity = details.velocity.pixelsPerSecond.dx;
    double target = 0.0;

    if (!_isEditing) {
      if (_dragExtent < -_flipThreshold || velocity < -500) {
        target = -_maxWidth; 
        _updateHeightState(true);
      }
    } else {
      if (_dragExtent > -_maxWidth + _flipThreshold || velocity > 500) {
        target = 0.0;
        _updateHeightState(false);
      } else {
        target = -_maxWidth;
      }
    }

    final spring = SpringDescription(mass: 1.0, stiffness: 150.0, damping: 15.0);
    final simulation = SpringSimulation(spring, _dragExtent, target, velocity);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final double leftPadding = widget.depth == 0 ? 0.0 : 12.0;
    final double rightPadding = widget.depth == 0 ? 0.0 : 6.0;
    
    final Widget editorContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.1), blurRadius: 30, spreadRadius: -10),
        ]
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          controller: _editorScrollController,
          padding: EdgeInsets.zero,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Color(0xFF6366F1), fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onTextChanged,
                  ),
                ),
                const Icon(Icons.arrow_back_ios, color: Colors.transparent, size: 16),
                const SizedBox(width: 6),
                const Icon(Icons.edit_note, color: Colors.transparent, size: 16),
              ],
            ),
            if (widget.limit > 0 || _isEditing) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: widget.controller.markdownFontSize, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Editor rivelato dall\'onda...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _onTextChanged,
              ),
            ],
          ],
        ),
      ),
    );

    final Widget readerContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C), // Match editor background so it hides the editor underneath
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.node.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.arrow_back_ios, color: Colors.white.withValues(alpha: 0.1), size: 16),
              const SizedBox(width: 6),
              Icon(Icons.edit_note, color: Colors.white.withValues(alpha: 0.1), size: 16),
            ],
          ),
          if (widget.limit > 0 || _isEditing) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: MarkdownBody(
              data: _textController.text.isEmpty ? '*Tocca e tira per scrivere un appunto...*' : _textController.text,
              selectable: false,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: const Color(0xFFE0E0E0), fontSize: widget.controller.markdownFontSize, height: 1.5),
                h1: TextStyle(color: Colors.white, fontSize: widget.controller.markdownFontSize + 9, fontWeight: FontWeight.bold, height: 1.2),
                h2: TextStyle(color: Colors.white, fontSize: widget.controller.markdownFontSize + 5, fontWeight: FontWeight.bold, height: 1.2),
                h3: TextStyle(color: Colors.white, fontSize: widget.controller.markdownFontSize + 3, fontWeight: FontWeight.bold, height: 1.2),
                h4: TextStyle(color: Colors.white, fontSize: widget.controller.markdownFontSize + 1, fontWeight: FontWeight.bold, height: 1.2),
                h5: TextStyle(color: Colors.white, fontSize: widget.controller.markdownFontSize, fontWeight: FontWeight.bold, height: 1.2),
                h6: TextStyle(color: Colors.white, fontSize: widget.controller.markdownFontSize - 2, fontWeight: FontWeight.bold, height: 1.2),
                em: const TextStyle(fontStyle: FontStyle.italic),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                blockquote: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                blockquoteDecoration: BoxDecoration(
                  border: const Border(left: BorderSide(color: Color(0xFF6366F1), width: 4)),
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                ),
                code: TextStyle(color: const Color(0xFF10B981), backgroundColor: Colors.transparent, fontFamily: 'monospace', fontSize: widget.controller.markdownFontSize - 1),
                codeblockDecoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                listBullet: const TextStyle(color: Color(0xFF6366F1)),
                checkbox: const TextStyle(color: Color(0xFF6366F1)),
              ),
            ),
            ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding, top: 4, bottom: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _maxWidth = constraints.maxWidth;
          
          return AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: Stack(
              children: [
                // Invisible Size Dictator
                Opacity(
                  opacity: 0,
                  child: IgnorePointer(
                    child: _isEditing ? editorContent : readerContent,
                  ),
                ),

                // Background (Editor)
                _isEditing ? editorContent : Positioned.fill(child: editorContent),
                
                // Foreground (Reader) wrapped in Liquid Clipper
                _isEditing
                  ? Positioned.fill(
                      child: IgnorePointer(
                        ignoring: _isEditing,
                        child: ClipPath(
                          clipper: LiquidClipper(
                            pullExtent: _dragExtent, 
                            pullY: _dragY,
                            baseWavePhase: _baseWavePhase,
                            rippleWavePhase: _rippleWavePhase,
                          ),
                          child: readerContent,
                        ),
                      ),
                    )
                  : IgnorePointer(
                      ignoring: _isEditing,
                      child: ClipPath(
                        clipper: LiquidClipper(
                          pullExtent: _dragExtent, 
                          pullY: _dragY,
                          baseWavePhase: _baseWavePhase,
                          rippleWavePhase: _rippleWavePhase,
                        ),
                        child: readerContent,
                      ),
                    ),
                
                // Right Drag Area (To Open)
                if (!_isEditing)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 60,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8),
                        child: const Icon(Icons.drag_indicator, color: Colors.white24),
                      ),
                    ),
                  ),
                  
                // Left Drag Area (To Close)
                if (_isEditing)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 60,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 8),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white24, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
}

class LiquidClipper extends CustomClipper<Path> {
  final double pullExtent;
  final double pullY;
  final double baseWavePhase;
  final double rippleWavePhase;

  LiquidClipper({
    required this.pullExtent, 
    required this.pullY,
    required this.baseWavePhase,
    required this.rippleWavePhase,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    
    if (pullExtent >= 0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    double pull = pullExtent.abs();
    if (pull >= size.width - 1) {
      return Path(); 
    }

    double dragCenterY = pullY.clamp(0.0, size.height);
    
    double maxLag = 60.0;
    double lag = (pull * 0.4).clamp(0.0, maxLag);
    double rightEdgeBase = size.width - pull + lag; 
    
    path.lineTo(rightEdgeBase, 0);

    int segments = 120; 
    double baseAmplitude = 6.0;
    double rippleAmp = 1.2;

    for (int i = 0; i <= segments; i++) {
      double t = i / segments; 
      double currentY = t * size.height;
      
      double dist = (currentY - dragCenterY).abs();
      
      double baseWave = sin(t * 5 * pi + baseWavePhase);
      double rippleWave = sin(t * 12 * pi - rippleWavePhase);
      
      double waveX = baseWave * (baseAmplitude + (rippleWave * rippleAmp));
      
      double stretch = 0;
      double influenceRadius = 90.0; 
      if (dist < influenceRadius) {
         double influence = cos((dist / influenceRadius) * (pi / 2));
         stretch = influence * lag;
      }
      
      double x = rightEdgeBase - stretch - waveX;
      path.lineTo(x, currentY);
    }

    path.lineTo(rightEdgeBase, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(LiquidClipper oldClipper) => true;
}
