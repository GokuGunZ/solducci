import 'dart:math';
import 'package:flutter/material.dart';

class ConstellationMenuOverlay extends StatefulWidget {
  final Offset fabOffset;
  final Size fabSize;
  final VoidCallback onClose;
  final VoidCallback onSpesa;
  final VoidCallback onTask;
  final VoidCallback onEvento;
  final VoidCallback onNota;

  const ConstellationMenuOverlay({
    super.key,
    required this.fabOffset,
    required this.fabSize,
    required this.onClose,
    required this.onSpesa,
    required this.onTask,
    required this.onEvento,
    required this.onNota,
  });

  @override
  State<ConstellationMenuOverlay> createState() => _ConstellationMenuOverlayState();
}

class _ConstellationMenuOverlayState extends State<ConstellationMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300), // Slightly faster and snappier
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([VoidCallback? onClosed]) {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onClose();
        if (onClosed != null) {
          onClosed();
        }
      }
    });
  }

  Widget _buildSubButton(String label, IconData icon, Color color, double angle, VoidCallback onTap) {
    const double distance = 120.0; // Adjusted for overlay positioning
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curvedValue = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack).value;
        final x = cos(angle) * distance * curvedValue;
        final y = sin(angle) * distance * curvedValue;
        
        // Calculate center of the original FAB
        final fabCenter = Offset(
          widget.fabOffset.dx + widget.fabSize.width / 2,
          widget.fabOffset.dy + widget.fabSize.height / 2,
        );

        // Sub-button is roughly 56x56 + text underneath. 
        // We center the sub-button over the exact destination point.
        final buttonCenter = fabCenter + Offset(x, y);

        // We use a small SizedBox to perfectly center the sub-button at 'buttonCenter'
        return Positioned(
          left: buttonCenter.dx - 40, // 80 total width for alignment
          top: buttonCenter.dy - 40,  // 80 total height
          width: 80,
          height: 100, // Extra height for text
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
            heroTag: null, // Avoid hero conflicts in Overlay
            backgroundColor: color,
            elevation: 8,
            onPressed: () {
              _close(onTap);
            },
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label, 
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 11,
              )
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate 4 angles spread from pi to 2*pi (upper semi-circle)
    // Actually, we want a nice spread.
    final List<double> angles = [
      -pi,          // Left
      -3 * pi / 4,  // Top Left
      -pi / 4,      // Top Right
      0,            // Right
    ];

    return Stack(
      children: [
        // Dark background that catches taps to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _close(),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.8 * _controller.value),
                );
              },
            ),
          ),
        ),

        // Sub-buttons
        _buildSubButton('Spesa', Icons.attach_money, const Color(0xFF10B981), angles[0], widget.onSpesa),
        _buildSubButton('Task', Icons.check_circle_outline, const Color(0xFF3B82F6), angles[1], widget.onTask),
        _buildSubButton('Evento', Icons.event, const Color(0xFF6366F1), angles[2], widget.onEvento),
        _buildSubButton('Nota', Icons.notes, const Color(0xFFF59E0B), angles[3], widget.onNota),

        // The central FAB, perfectly overlaid on the original
        Positioned(
          left: widget.fabOffset.dx,
          top: widget.fabOffset.dy,
          width: widget.fabSize.width,
          height: widget.fabSize.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * pi / 4, // Rotates 45 degrees into an 'X'
                child: FloatingActionButton(
                  heroTag: null,
                  backgroundColor: const Color(0xFF6366F1), // Must match the fixed ShellWithNav FAB color
                  elevation: 0, 
                  onPressed: () => _close(),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              );
            }
          ),
        ),
      ],
    );
  }
}
