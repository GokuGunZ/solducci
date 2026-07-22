import 'package:solducci/widgets/solducci_app_bar.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DemoLiquidCardView extends StatefulWidget {
  const DemoLiquidCardView({super.key});

  @override
  State<DemoLiquidCardView> createState() => _DemoLiquidCardViewState();
}

class _DemoLiquidCardViewState extends State<DemoLiquidCardView> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _waveController;
  late TextEditingController _textController;
  
  double _dragExtent = 0.0;
  bool _isEditing = false;
  final double _flipThreshold = 150.0;
  double _dragY = 100.0; 
  
  DateTime? _lastTime;
  double _pullVelocity = 0.0;
  double _baseWavePhase = 0.0;
  double _rippleWavePhase = 0.0;
  double _currentRippleSpeed = 0.05;
  
  double _currentHeight = 250.0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: '# Appunto Liquido\nTira la card per svelare l\'editor.\n- Acqua in movimento\n- Fisica elastica');
    
    _controller = AnimationController(vsync: this, lowerBound: -double.infinity, upperBound: double.infinity);
    _controller.addListener(() {
      setState(() {
        _dragExtent = _controller.value;
        // When snapping, calculate velocity to keep wave bouncy
        if (_controller.velocity.abs() > 0) {
          _pullVelocity = _controller.velocity.abs();
        }
      });
    });
    
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _waveController.addListener(() {
      setState(() {
        double baseSpeed = 0.06; // Leggermente più rapida
        _baseWavePhase += baseSpeed;
        
        double minRippleSpeed = 0.03;
        double maxRippleSpeed = 0.12; // Velocità massima ridotta per l'effetto melma
        
        // Mappiamo la pullVelocity sull'intervallo [min, max]
        double targetRippleSpeed = minRippleSpeed + (_pullVelocity / 1500.0) * (maxRippleSpeed - minRippleSpeed);
        targetRippleSpeed = targetRippleSpeed.clamp(minRippleSpeed, maxRippleSpeed);
        
        // Interpolazione morbida per evitare variazioni frenetiche della velocità
        _currentRippleSpeed += (targetRippleSpeed - _currentRippleSpeed) * 0.05;
        
        _rippleWavePhase += _currentRippleSpeed;
        
        if (_pullVelocity > 0) {
          _pullVelocity *= 0.92; // smooth decay
          if (_pullVelocity < 0.1) _pullVelocity = 0;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  void _updateHeightState(bool editing) {
    if (_isEditing == editing) return;
    _isEditing = editing;
    
    if (!_isEditing) {
      FocusScope.of(context).unfocus();
    }
    
    // Delayed height adjustment
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isEditing == editing) {
        setState(() {
          _currentHeight = editing ? 400.0 : 250.0;
        });
      }
    });
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
      if (_dragExtent < -340) _dragExtent = -340;
      _dragY = details.localPosition.dy;
      
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
        target = -340.0; 
        _updateHeightState(true);
      }
    } else {
      if (_dragExtent > -(_flipThreshold) || velocity > 500) {
        target = 0.0;
        _updateHeightState(false);
      } else {
        target = -340.0;
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
      appBar: SolducciAppBar(
        title: const Text('Soluzione 3: Elastic Liquid', style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
          width: 340,
          height: _currentHeight,
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
                    const Text('Modalità Codice', style: TextStyle(color: Color(0xFFE068F1), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        autofocus: false,
                        maxLines: null,
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Editor rivelato dall\'onda...',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Foreground (Reader) wrapped in Liquid Clipper
              IgnorePointer(
                ignoring: _isEditing,
                child: ClipPath(
                  clipper: LiquidClipper(
                    pullExtent: _dragExtent, 
                    pullY: _dragY,
                    baseWavePhase: _baseWavePhase,
                    rippleWavePhase: _rippleWavePhase,
                  ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.waves, color: Color(0xFFE068F1), size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Markdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            Icon(Icons.arrow_back_ios, color: Colors.white.withValues(alpha: 0.1), size: 16),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: MarkdownBody(
                              data: _textController.text.isEmpty ? '*Vuoto*' : _textController.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(color: Colors.white70, fontSize: 15),
                                h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                listBullet: const TextStyle(color: Color(0xFFE068F1)),
                                checkbox: const TextStyle(color: Color(0xFFE068F1)),
                              ),
                            ),
                          ),
                        ),
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
    
    // Cono stretto: lag concentrato
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
      
      // La base wave usa la sua fase indipendente e fissa. Frequenza ridotta (5*pi) per essere più sinuosa e lunga.
      double baseWave = sin(t * 10 * pi + baseWavePhase);
      
      // Il ripple ha frequenza ridotta (12*pi) per essere meno spigoloso (non "frizzante")
      double rippleWave = sin(t * 12 * pi - rippleWavePhase);
      
      // AM Synthesis
      double waveX = baseWave * (baseAmplitude + (rippleWave * rippleAmp));
      
      // Elasticità (Cono) molto stretta attorno al dito
      double stretch = 0;
      double influenceRadius = 90.0; // Cono meno ampio (più appuntito ma liscio)
      if (dist < influenceRadius) {
         double influence = cos((dist / influenceRadius) * (pi / 2));
         stretch = influence * lag;
      }
      
      // Sottraiamo lo stretch in modo che al centro (dist=0) x = rightEdgeBase - lag = size.width - pull
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
