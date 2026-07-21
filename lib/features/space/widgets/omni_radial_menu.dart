import 'dart:math';
import 'package:flutter/material.dart';

class OmniRadialMenu extends StatefulWidget {
  final Function(String type) onCreateNode;

  const OmniRadialMenu({
    super.key,
    required this.onCreateNode,
  });

  @override
  State<OmniRadialMenu> createState() => _OmniRadialMenuState();
}

class _OmniRadialMenuState extends State<OmniRadialMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  Widget _buildItem(IconData icon, Color color, double angle, String type) {
    final double rad = angle * pi / 180;
    // We will translate from the center (FAB position) outward by 75 pixels.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Curve for a springy effect
        final double val = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack).value;
        final double distance = 75.0 * val;
        
        return Transform.translate(
          offset: Offset(distance * cos(rad), distance * sin(rad)),
          child: Transform.scale(
            scale: val == 0 ? 0.001 : val, // Prevent 0 scale issues
            child: child,
          ),
        );
      },
      child: LongPressDraggable<Map<String, String>>(
        data: {'omni-type': type},
        feedback: FloatingActionButton(
          mini: true,
          onPressed: null,
          backgroundColor: color.withValues(alpha: 0.8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        onDragStarted: () => _toggleMenu(),
        child: FloatingActionButton(
          heroTag: 'omni_$type',
          mini: true,
          onPressed: () {
            _toggleMenu();
            widget.onCreateNode(type);
          },
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Items
          // Angles: Note at top (270 deg), Folder at middle (225 deg), Bookmark at left (180 deg)
          _buildItem(Icons.bookmark, const Color(0xFFF59E0B), 180, 'bookmark'),
          _buildItem(Icons.folder, const Color(0xFF3B82F6), 225, 'folder'),
          _buildItem(Icons.article, const Color(0xFF10B981), 270, 'markdown'),
          
          // Main FAB
          FloatingActionButton(
            heroTag: 'omni_main',
            onPressed: _toggleMenu,
            backgroundColor: const Color(0xFF6366F1),
            child: RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 0.125).animate(_controller),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
