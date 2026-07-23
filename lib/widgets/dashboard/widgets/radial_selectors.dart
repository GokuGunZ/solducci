import 'dart:math';
import 'package:flutter/material.dart';

class RadialUserSelector extends StatefulWidget {
  final String label;

  const RadialUserSelector({super.key, required this.label});

  @override
  State<RadialUserSelector> createState() => _RadialUserSelectorState();
}

class _RadialUserSelectorState extends State<RadialUserSelector> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: offset.dx + size.width / 2 - 100, // Center the radial menu
              top: offset.dy + size.height / 2 - 100,
              child: _RadialMenuOverlay(
                onClose: _closeMenu,
                items: ['Io', 'Anna', 'Marco'], // Mock users
                onSelected: (user) {
                  // TODO: Handle selection and split logic
                  _closeMenu();
                },
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _toggleMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class RadialCategorySelector extends StatefulWidget {
  const RadialCategorySelector({super.key});

  @override
  State<RadialCategorySelector> createState() => _RadialCategorySelectorState();
}

class _RadialCategorySelectorState extends State<RadialCategorySelector> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: offset.dx + size.width / 2 - 100, // Center the radial menu
              top: offset.dy + size.height / 2 - 100,
              child: _RadialMenuOverlay(
                onClose: _closeMenu,
                items: ['Spesa', 'Trasporti', 'Casa', 'Svago'], // Mock categories
                onSelected: (cat) {
                  // TODO: Handle selection
                  _closeMenu();
                },
                radius: 70,
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _toggleMenu,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        ),
        child: const Center(
          child: Icon(Icons.shopping_bag, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _RadialMenuOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final List<String> items;
  final Function(String) onSelected;
  final double radius;

  const _RadialMenuOverlay({
    required this.onClose,
    required this.items,
    required this.onSelected,
    this.radius = 60.0,
  });

  @override
  State<_RadialMenuOverlay> createState() => _RadialMenuOverlayState();
}

class _RadialMenuOverlayState extends State<_RadialMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < widget.items.length; i++)
                _buildRadialItem(i, widget.items.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadialItem(int index, int total) {
    final angle = (2 * pi / total) * index - pi / 2; // Start from top
    final currentRadius = widget.radius * CurvedAnimation(parent: _controller, curve: Curves.easeOutBack).value;
    final dx = currentRadius * cos(angle);
    final dy = currentRadius * sin(angle);
    
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut).value,
        child: GestureDetector(
          onTap: () => widget.onSelected(widget.items[index]),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E1E2C),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Center(
              child: Text(
                widget.items[index].substring(0, min(3, widget.items[index].length)),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
