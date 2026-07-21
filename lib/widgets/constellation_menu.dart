import 'dart:math';
import 'package:flutter/material.dart';

class ConstellationAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  
  const ConstellationAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class ConstellationMenuOverlay extends StatefulWidget {
  final Offset fabOffset;
  final Size fabSize;
  final VoidCallback onClose;
  final VoidCallback onSpesa;
  final VoidCallback onTask;
  final VoidCallback onEvento;
  final VoidCallback onNota;
  final List<ConstellationAction>? outerActions;
  final Color tabColor;

  const ConstellationMenuOverlay({
    super.key,
    required this.fabOffset,
    required this.fabSize,
    required this.onClose,
    required this.onSpesa,
    required this.onTask,
    required this.onEvento,
    required this.onNota,
    this.outerActions,
    this.tabColor = const Color(0xFF6366F1),
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
      duration: const Duration(milliseconds: 300), // Snappy animation
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

  Widget _buildSubButton(String label, IconData icon, Color color, double angle, VoidCallback onTap, {bool isOuter = false}) {
    final double distance = isOuter ? 190.0 : 110.0; // Outer radius vs Inner radius
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curvedValue = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack).value;
        final x = cos(angle) * distance * curvedValue;
        final y = sin(angle) * distance * curvedValue;
        
        final fabCenter = Offset(
          widget.fabOffset.dx + widget.fabSize.width / 2,
          widget.fabOffset.dy + widget.fabSize.height / 2,
        );

        final buttonCenter = fabCenter + Offset(x, y);

        return Positioned(
          left: buttonCenter.dx - 40,
          top: buttonCenter.dy - 40,
          width: 80,
          height: 100,
          child: Opacity(
            opacity: _controller.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isOuter ? _buildOuterFab(icon, color, onTap) : _buildInnerFab(icon, color, onTap),
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

  Widget _buildInnerFab(IconData icon, Color color, VoidCallback onTap) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: color,
      elevation: 8,
      onPressed: () => _close(onTap),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildOuterFab(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color(0xFF1E1E1E), // OLED surface
        elevation: 0,
        shape: CircleBorder(side: BorderSide(color: color.withOpacity(0.5), width: 1.5)),
        onPressed: () => _close(onTap),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inner angles
    final List<double> innerAngles = [
      -pi,          // Left
      -3 * pi / 4,  // Top Left
      -pi / 4,      // Top Right
      0,            // Right
    ];

    // Outer angles (interleaved)
    final List<double> outerAngles = [
      -7 * pi / 8, // Between Left and Top Left
      -pi / 2,     // Straight UP (Between Top Left and Top Right)
      -pi / 8,     // Between Top Right and Right
    ];

    final hasOuter = widget.outerActions != null && widget.outerActions!.isNotEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _close(),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.85 * _controller.value),
                );
              },
            ),
          ),
        ),

        // Outer Buttons
        if (hasOuter)
          for (int i = 0; i < min(widget.outerActions!.length, outerAngles.length); i++)
            _buildSubButton(
              widget.outerActions![i].label, 
              widget.outerActions![i].icon, 
              widget.tabColor, 
              outerAngles[i], 
              widget.outerActions![i].onTap,
              isOuter: true,
            ),

        // Inner Buttons
        _buildSubButton('Spesa', Icons.attach_money, const Color(0xFF10B981), innerAngles[0], widget.onSpesa),
        _buildSubButton('Task', Icons.check_circle_outline, const Color(0xFF3B82F6), innerAngles[1], widget.onTask),
        _buildSubButton('Evento', Icons.event, const Color(0xFF6366F1), innerAngles[2], widget.onEvento),
        _buildSubButton('Nota', Icons.notes, const Color(0xFFF59E0B), innerAngles[3], widget.onNota),

        // The central FAB
        Positioned(
          left: widget.fabOffset.dx,
          top: widget.fabOffset.dy,
          width: widget.fabSize.width,
          height: widget.fabSize.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * pi / 4,
                child: FloatingActionButton(
                  heroTag: null,
                  backgroundColor: const Color(0xFF6366F1),
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
