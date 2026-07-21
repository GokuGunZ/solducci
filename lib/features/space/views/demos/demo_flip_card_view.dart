import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DemoFlipCardView extends StatefulWidget {
  const DemoFlipCardView({super.key});

  @override
  State<DemoFlipCardView> createState() => _DemoFlipCardViewState();
}

class _DemoFlipCardViewState extends State<DemoFlipCardView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late TextEditingController _textController;
  double _dragExtent = 0.0;
  bool _isFlipped = false;
  final double _flipThreshold = 150.0;
  final double _maxDrag = 300.0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: '# Titolo Appunto\nQuesta è una prova di testo formattato.\n- [ ] Task 1\n- [ ] Task 2');
    _controller = AnimationController(vsync: this, lowerBound: -double.infinity, upperBound: double.infinity);
    _controller.addListener(() {
      setState(() {
        _dragExtent = _controller.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    double velocity = details.velocity.pixelsPerSecond.dx;
    _animateToTarget(velocity);
  }

  void _animateToTarget(double velocity) {
    double target = 0.0;

    if (!_isFlipped) {
      if (_dragExtent < -_flipThreshold || velocity < -500) {
        target = -_maxDrag;
        _isFlipped = true;
      } else if (_dragExtent > _flipThreshold || velocity > 500) {
        target = _maxDrag;
        _isFlipped = true;
      }
    } else {
      if (_dragExtent > -_flipThreshold && _dragExtent < 0 && velocity > -500) {
        target = 0;
        _isFlipped = false;
      } else if (_dragExtent < _flipThreshold && _dragExtent > 0 && velocity < 500) {
        target = 0;
        _isFlipped = false;
      } else {
        target = _dragExtent < 0 ? -_maxDrag : _maxDrag;
      }
    }

    final spring = SpringDescription(mass: 1.0, stiffness: 200.0, damping: 20.0);
    final simulation = SpringSimulation(spring, _dragExtent, target, velocity);
    _controller.animateWith(simulation);
  }

  void _triggerFlip() {
    _controller.stop();
    _isFlipped = !_isFlipped;
    double target = _isFlipped ? -_maxDrag : 0.0;
    
    // Smooth programmatic flip
    final spring = SpringDescription(mass: 1.0, stiffness: 120.0, damping: 15.0);
    final simulation = SpringSimulation(spring, _dragExtent, target, 0);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    double fraction = (_dragExtent / _maxDrag).clamp(-1.0, 1.0);
    double angle = fraction * pi;

    bool showFront = angle.abs() < pi / 2;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Soluzione 1: 3D Flip', style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015) 
              ..rotateY(angle),
            child: showFront 
              ? _buildFront() 
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildBack(),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: 340,
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 30, spreadRadius: -10),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Markdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                onPressed: _triggerFlip,
                tooltip: 'Modifica',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: _textController.text.isEmpty ? '*Appunto vuoto*' : _textController.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white70, fontSize: 15),
                  h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: Color(0xFF6366F1)),
                  checkbox: const TextStyle(color: Color(0xFF6366F1)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: 340,
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 30, spreadRadius: -10),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Modalità Codice', style: TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF10B981), size: 24),
                onPressed: _triggerFlip,
                tooltip: 'Fatto',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              autofocus: false,
              maxLines: null,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Scrivi qui il markdown...',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
