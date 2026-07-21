import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class DemoFlipCardView extends StatefulWidget {
  const DemoFlipCardView({super.key});

  @override
  State<DemoFlipCardView> createState() => _DemoFlipCardViewState();
}

class _DemoFlipCardViewState extends State<DemoFlipCardView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  bool _isFlipped = false;
  final double _flipThreshold = 150.0;
  final double _maxDrag = 300.0;

  @override
  void initState() {
    super.initState();
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
      width: 320,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 30, spreadRadius: -10),
        ]
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note, color: Color(0xFF6366F1), size: 36),
          SizedBox(height: 16),
          Text('Architettura Pulita', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Swipe orizzontale sulla card per ruotare la visuale in 3D ed entrare in modalità modifica.', style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: 320,
      height: 220,
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
          const Text('Modalità Codice', style: TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            maxLines: null,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Scrivi qui il markdown...',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
