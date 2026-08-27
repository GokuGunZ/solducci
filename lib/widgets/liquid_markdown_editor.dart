import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LiquidMarkdownEditor extends StatefulWidget {
  final String initialText;
  final String initialTitle;
  final ValueChanged<String>? onTextChanged;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onSave;
  final double markdownFontSize;
  final bool autoOpenEditor;
  final bool isSelected;
  final String? selectionMode;
  final ValueChanged<bool>? onSelect;
  final int depth;
  final int limit;
  final double maxWidth;

  const LiquidMarkdownEditor({
    super.key,
    required this.initialText,
    required this.initialTitle,
    this.onTextChanged,
    this.onTitleChanged,
    this.onSave,
    this.markdownFontSize = 14.0,
    this.autoOpenEditor = false,
    this.isSelected = false,
    this.selectionMode,
    this.onSelect,
    this.depth = 0,
    this.limit = 0,
    this.maxWidth = 340.0,
  });

  @override
  State<LiquidMarkdownEditor> createState() => _LiquidMarkdownEditorState();
}

class _LiquidMarkdownEditorState extends State<LiquidMarkdownEditor> with TickerProviderStateMixin {
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
  
  late double _currentMaxWidth;
  String _lastSavedText = '';
  int _previousTextLength = 0;
  
  @override
  void initState() {
    super.initState();
    _currentMaxWidth = widget.maxWidth;
    _lastSavedText = widget.initialText;
    _previousTextLength = _lastSavedText.length;
    
    _textController = TextEditingController(text: _lastSavedText);
    _titleController = TextEditingController(text: widget.initialTitle);
    _focusNode = FocusNode();
    _readerScrollController = ScrollController();
    _editorScrollController = ScrollController();
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _saveContent();
      }
    });

    _controller = AnimationController(vsync: this, lowerBound: -double.infinity, upperBound: double.infinity);
    _controller.addListener(() {
      setState(() {
        _dragExtent = _controller.value;
        _updateWaveControllerState();
      });
    });
    
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
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

    if (widget.autoOpenEditor) {
      _isEditing = true;
      _dragExtent = -1000.0;
      _controller.value = _dragExtent;
      _waveController.repeat();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(LiquidMarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.initialText != widget.initialText && !_focusNode.hasFocus) {
      if (widget.initialText != _lastSavedText) {
        _textController.text = widget.initialText;
        _lastSavedText = widget.initialText;
      }
    }
    
    if (oldWidget.initialTitle != widget.initialTitle && !_focusNode.hasFocus) {
      _titleController.text = widget.initialTitle;
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
    
    if (isInsertion && value.endsWith('\n')) {
      final lines = value.split('\n');
      if (lines.length >= 2) {
        final previousLine = lines[lines.length - 2];
        if (previousLine.trimLeft().startsWith('- ')) {
          final indentMatch = RegExp(r'^\s*').firstMatch(previousLine);
          final indent = indentMatch?.group(0) ?? '';
          final injection = '$indent- ';
          
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

    widget.onTextChanged?.call(_textController.text);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _saveContent();
    });
  }
  
  void _onTitleChanged(String value) {
    widget.onTitleChanged?.call(value);
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _saveContent();
    });
  }

  void _saveContent() {
    if (_textController.text != _lastSavedText) {
      _lastSavedText = _textController.text;
    }
    widget.onSave?.call();
  }

  void _updateHeightState(bool editing) {
    if (_isEditing == editing) return;
    
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
      if (_dragExtent < -_currentMaxWidth) _dragExtent = -_currentMaxWidth;
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
        target = -_currentMaxWidth; 
        _updateHeightState(true);
      }
    } else {
      if (_dragExtent > -_currentMaxWidth + _flipThreshold || velocity > 500) {
        target = 0.0;
        _updateHeightState(false);
      } else {
        target = -_currentMaxWidth;
      }
    }

    final spring = SpringDescription(mass: 1.0, stiffness: 150.0, damping: 15.0);
    final simulation = SpringSimulation(spring, _dragExtent, target, velocity);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final double leftPadding = widget.depth == 0 ? 0.0 : 0.0;
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
                    onChanged: _onTitleChanged,
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
                style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: widget.markdownFontSize, height: 1.5),
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

    Color cardColor = const Color(0xFF94A3B8).withValues(alpha: 0.10); 
    if (widget.selectionMode != null && widget.isSelected) {
      if (widget.selectionMode == 'move') cardColor = const Color(0xFF3B82F6).withValues(alpha: 0.4);
      if (widget.selectionMode == 'delete') cardColor = const Color(0xFFEF4444).withValues(alpha: 0.4);
    }

    final Widget readerContent = GestureDetector(
      onTap: widget.selectionMode != null ? () {
        widget.onSelect?.call(!widget.isSelected);
      } : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor, 
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_titleController.text.isNotEmpty ? _titleController.text : widget.initialTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                          p: TextStyle(color: const Color(0xFFE0E0E0), fontSize: widget.markdownFontSize, height: 1.5),
                          h1: TextStyle(color: Colors.white, fontSize: widget.markdownFontSize + 9, fontWeight: FontWeight.bold, height: 1.2),
                          h2: TextStyle(color: Colors.white, fontSize: widget.markdownFontSize + 5, fontWeight: FontWeight.bold, height: 1.2),
                          h3: TextStyle(color: Colors.white, fontSize: widget.markdownFontSize + 3, fontWeight: FontWeight.bold, height: 1.2),
                          h4: TextStyle(color: Colors.white, fontSize: widget.markdownFontSize + 1, fontWeight: FontWeight.bold, height: 1.2),
                          h5: TextStyle(color: Colors.white, fontSize: widget.markdownFontSize, fontWeight: FontWeight.bold, height: 1.2),
                          h6: TextStyle(color: Colors.white, fontSize: widget.markdownFontSize - 2, fontWeight: FontWeight.bold, height: 1.2),
                          em: const TextStyle(fontStyle: FontStyle.italic),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          blockquote: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                          blockquoteDecoration: BoxDecoration(
                            border: const Border(left: BorderSide(color: Color(0xFF6366F1), width: 4)),
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          ),
                          code: TextStyle(color: const Color(0xFF10B981), backgroundColor: Colors.transparent, fontFamily: 'monospace', fontSize: widget.markdownFontSize - 1),
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
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding, top: 4, bottom: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _currentMaxWidth = constraints.maxWidth > 0 ? constraints.maxWidth : widget.maxWidth;
          
          return AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: Stack(
              children: [
                Opacity(
                  opacity: 0,
                  child: IgnorePointer(
                    child: _isEditing ? editorContent : readerContent,
                  ),
                ),

                if (_isEditing || _dragExtent < -1.0)
                  _isEditing 
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: editorContent,
                        ) 
                      : Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: editorContent,
                          ),
                        ),
                
                _isEditing
                  ? Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
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
