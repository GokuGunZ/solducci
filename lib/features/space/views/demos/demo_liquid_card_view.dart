import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class DemoLiquidCardView extends StatefulWidget {
  const DemoLiquidCardView({super.key});

  @override
  State<DemoLiquidCardView> createState() => _DemoLiquidCardViewState();
}

class _DemoLiquidCardViewState extends State<DemoLiquidCardView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  bool _isEditing = false;
  final double _flipThreshold = 150.0;
  double _dragY = 100.0; 

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
    setState(() {
      _dragY = details.localPosition.dy;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      // Constrain _dragExtent to stay between -320 and 0
      if (_dragExtent > 0) _dragExtent = 0;
      if (_dragExtent < -320) _dragExtent = -320;
      _dragY = details.localPosition.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    double velocity = details.velocity.pixelsPerSecond.dx;
    double target = 0.0;

    if (!_isEditing) {
      if (_dragExtent < -_flipThreshold || velocity < -500) {
        target = -320.0; 
        _isEditing = true;
      }
    } else {
      if (_dragExtent > -(_flipThreshold) || velocity > 500) {
        target = 0.0;
        _isEditing = false;
      } else {
        target = -320.0;
      }
    }

    final spring = SpringDescription(mass: 1.0, stiffness: 150.0, damping: 15.0);
    final simulation = SpringSimulation(spring, _dragExtent, target, velocity);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Soluzione 3: Elastic Liquid', style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SizedBox(
          width: 320,
          height: 220,
          child: Stack(
            children: [
              // Background (Editor)
              Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.only(left: 40, top: 24, right: 24, bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C3E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE068F1).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFE068F1).withOpacity(0.2), blurRadius: 30, spreadRadius: -10),
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Editor Segreto', style: TextStyle(color: Color(0xFFE068F1), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: false, // Prevents keyboard popping immediately
                      maxLines: null,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Editor rivelato dall\'onda...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Foreground (Reader) wrapped in Liquid Clipper
              IgnorePointer(
                ignoring: _isEditing, // When editing, foreground should not block taps
                child: ClipPath(
                  clipper: LiquidClipper(pullExtent: _dragExtent, pullY: _dragY),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.only(left: 24, top: 24, right: 40, bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(-10, 0)),
                      ]
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFFE068F1), size: 36),
                        SizedBox(height: 16),
                        Text('Tira il bordo', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('Trascina da destra verso sinistra per deformare la card come fosse liquida.', style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5)),
                      ],
                    ),
                  ),
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
        ),
      ),
    );
  }
}

class LiquidClipper extends CustomClipper<Path> {
  final double pullExtent;
  final double pullY;

  LiquidClipper({required this.pullExtent, required this.pullY});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    if (pullExtent >= 0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    double pull = pullExtent.abs();
    if (pull >= size.width - 1) {
      return Path(); // Fully revealed
    }

    double y = pullY.clamp(0.0, size.height);
    
    // The base edge moves exactly with the pull
    double rightEdgeBase = size.width - pull; 
    
    // The peak of the gooey curve stretches much further left
    double controlPointX = size.width - (pull * 2.5); 

    path.lineTo(rightEdgeBase, 0);
    path.lineTo(rightEdgeBase, y - 100);
    path.quadraticBezierTo(
      controlPointX, y, 
      rightEdgeBase, y + 100
    );
    path.lineTo(rightEdgeBase, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(LiquidClipper oldClipper) => true;
}
