import 'dart:math';
import 'package:flutter/material.dart';

class ConstellationMenu extends StatefulWidget {
  final VoidCallback onSpesa;
  final VoidCallback onTask;
  final VoidCallback onEvento;
  final VoidCallback onNota;

  const ConstellationMenu({
    super.key,
    required this.onSpesa,
    required this.onTask,
    required this.onEvento,
    required this.onNota,
  });

  @override
  State<ConstellationMenu> createState() => _ConstellationMenuState();
}

class _ConstellationMenuState extends State<ConstellationMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) {
      Navigator.pop(context);
    });
  }

  Widget _buildItem(String label, IconData icon, Color color, double angle, VoidCallback onTap) {
    // angle in radians. 0 is right, -pi/2 is straight up.
    // Distance from the center button
    const double distance = 140.0;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Curve the animation for a nice bounce effect
        final curvedValue = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack).value;
        final x = cos(angle) * distance * curvedValue;
        final y = sin(angle) * distance * curvedValue;
        
        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: _controller.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: null, // Evita conflitti di Hero
            backgroundColor: color,
            elevation: 8,
            onPressed: () {
              _close();
              onTap();
            },
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label, 
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 12,
              )
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 4 items spread between -pi (left) and 0 (right).
    // Angoli per formare una costellazione radiale a semicerchio superiore.
    // Usiamo -7pi/8, -5pi/8, -3pi/8, -pi/8
    final angles = [
      -pi + (pi / 8),
      -pi + (3 * pi / 8),
      -pi + (5 * pi / 8),
      -pi + (7 * pi / 8),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background tap to close
          GestureDetector(
            onTap: _close,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.7 * _controller.value),
                );
              }
            ),
          ),
          
          // Positioned exactly where the center docked FAB is
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24), // Posizione simile al FAB docked
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _buildItem('Spesa', Icons.attach_money, const Color(0xFF10B981), angles[0], widget.onSpesa),
                  _buildItem('Task', Icons.check_circle_outline, const Color(0xFF3B82F6), angles[1], widget.onTask),
                  _buildItem('Evento', Icons.event, const Color(0xFF6366F1), angles[2], widget.onEvento),
                  _buildItem('Nota', Icons.notes, const Color(0xFFF59E0B), angles[3], widget.onNota),
                  
                  // Central close button (replaces the FAB visually)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * pi / 4, // Ruota di 45 gradi per formare una 'X'
                        child: FloatingActionButton(
                          heroTag: 'omni_fab_active',
                          backgroundColor: Colors.white,
                          onPressed: _close,
                          child: const Icon(Icons.add, color: Colors.black, size: 32),
                        ),
                      );
                    }
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
