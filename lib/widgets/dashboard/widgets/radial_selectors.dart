import 'dart:math';
import 'package:flutter/material.dart';

class RadialUserSelector extends StatefulWidget {
  final String label;
  final bool isDefaultAll;

  const RadialUserSelector({super.key, required this.label, this.isDefaultAll = false});

  @override
  State<RadialUserSelector> createState() => _RadialUserSelectorState();
}

class _RadialUserSelectorState extends State<RadialUserSelector> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<String> _selectedUsers = [];
  final List<String> _allUsers = const <String>['Io', 'Anna', 'Marco'];

  @override
  void initState() {
    super.initState();
    _selectedUsers = widget.isDefaultAll ? List<String>.from(_allUsers) : <String>['Io'];
  }

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
    final screenSize = MediaQuery.of(context).size;

    final double centerX = offset.dx + size.width / 2;
    final double centerY = offset.dy + size.height / 2;
    final double menuSize = 300.0;
    
    double left = centerX - menuSize / 2;
    double top = centerY - menuSize / 2;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            Positioned(
              left: left,
              top: top,
              child: SizedBox(
                width: menuSize,
                height: menuSize,
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    return _RadialMenuOverlay(
                      onClose: _closeMenu,
                      items: _allUsers,
                      selectedItems: _selectedUsers,
                      onSelected: (user) {
                        setState(() {
                          if (_selectedUsers.contains(user)) {
                            // Prevent deselecting last user
                            if (_selectedUsers.length > 1) {
                              _selectedUsers.remove(user);
                            }
                          } else {
                            _selectedUsers.add(user);
                          }
                        });
                        setOverlayState(() {});
                      },
                      radius: 70,
                      isUser: true,
                      centerPosition: Offset(centerX, centerY),
                      screenSize: screenSize,
                    );
                  }
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildSingleAvatar(String name, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade200,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCluster(double baseRadius) {
    if (_selectedUsers.isEmpty) {
      return _buildSingleAvatar('?', baseRadius);
    } else if (_selectedUsers.length == 1) {
      return _buildSingleAvatar(_selectedUsers.first, baseRadius);
    } else {
      final int count = _selectedUsers.length > 3 ? 3 : _selectedUsers.length;
      final double smallRadius = baseRadius * 0.75;
      
      List<Widget> stackChildren = [];
      for (int i = count - 1; i >= 0; i--) {
        Widget child;
        if (i == 2 && _selectedUsers.length > 3) {
          child = Container(
            width: smallRadius * 2,
            height: smallRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
            ),
            child: Center(
              child: Text(
                '+${_selectedUsers.length - 2}',
                style: TextStyle(fontSize: smallRadius * 0.9, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          );
        } else {
          child = _buildSingleAvatar(_selectedUsers[i], smallRadius);
        }

        stackChildren.add(
          Positioned(
            left: i * (baseRadius * 0.9),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF09090B), width: 1.5),
              ),
              child: child,
            ),
          ),
        );
      }

      return SizedBox(
        width: baseRadius * 2 + (count - 1) * (baseRadius * 0.9),
        height: baseRadius * 2,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: stackChildren,
        ),
      );
    }
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
          _buildAvatarCluster(14.0), // radius = 14 -> 28x28
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
  IconData _selectedIcon = Icons.shopping_bag;

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
    final screenSize = MediaQuery.of(context).size;

    final double centerX = offset.dx + size.width / 2;
    final double centerY = offset.dy + size.height / 2;
    final double menuSize = 300.0;
    
    double left = centerX - menuSize / 2;
    double top = centerY - menuSize / 2;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            Positioned(
              left: left,
              top: top,
              child: SizedBox(
                width: menuSize,
                height: menuSize,
                child: _RadialMenuOverlay(
                  onClose: _closeMenu,
                  items: const <String>['Spesa', 'Trasporti', 'Casa', 'Svago', 'Salute', 'Altro'],
                  selectedItems: const <String>[],
                  onSelected: (cat) {
                    setState(() {
                      if (cat == 'Spesa') _selectedIcon = Icons.shopping_cart;
                      else if (cat == 'Trasporti') _selectedIcon = Icons.directions_car;
                      else if (cat == 'Casa') _selectedIcon = Icons.home;
                      else if (cat == 'Svago') _selectedIcon = Icons.movie;
                      else if (cat == 'Salute') _selectedIcon = Icons.favorite;
                      else _selectedIcon = Icons.more_horiz;
                    });
                    _closeMenu();
                  },
                  radius: 70,
                  isUser: false,
                  centerPosition: Offset(centerX, centerY),
                  screenSize: screenSize,
                ),
              ),
            ),
          ],
        ),
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
        child: Center(
          child: Icon(_selectedIcon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _RadialMenuOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final List<String> items;
  final List<String> selectedItems;
  final Function(String) onSelected;
  final double radius;
  final bool isUser;
  final Offset centerPosition;
  final Size screenSize;

  const _RadialMenuOverlay({
    required this.onClose,
    required this.items,
    required this.selectedItems,
    required this.onSelected,
    required this.centerPosition,
    required this.screenSize,
    this.radius = 60.0,
    this.isUser = true,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double startAngle = -pi / 2; 
        double sweepAngle = 2 * pi;

        bool overflowRight = widget.centerPosition.dx + widget.radius + 30 > widget.screenSize.width;
        bool overflowLeft = widget.centerPosition.dx - widget.radius - 30 < 0;
        bool overflowTop = widget.centerPosition.dy - widget.radius - 30 < 0;
        bool overflowBottom = widget.centerPosition.dy + widget.radius + 30 > widget.screenSize.height;

        if (overflowRight && overflowTop) {
          startAngle = pi / 2; sweepAngle = pi / 2; // bottom-left
        } else if (overflowRight && overflowBottom) {
          startAngle = pi; sweepAngle = pi / 2; // top-left
        } else if (overflowLeft && overflowTop) {
          startAngle = 0; sweepAngle = pi / 2; // bottom-right
        } else if (overflowLeft && overflowBottom) {
          startAngle = -pi / 2; sweepAngle = pi / 2; // top-right
        } else if (overflowRight) {
          startAngle = pi / 2; sweepAngle = pi; // left semi-circle
        } else if (overflowLeft) {
          startAngle = -pi / 2; sweepAngle = pi; // right semi-circle
        } else if (overflowTop) {
          startAngle = 0; sweepAngle = pi; // bottom semi-circle
        } else if (overflowBottom) {
          startAngle = pi; sweepAngle = pi; // top semi-circle
        }

        final int total = widget.items.length;
        final double angleStep = sweepAngle >= 2 * pi - 0.01 
            ? (sweepAngle / total) 
            : (sweepAngle / (total > 1 ? total - 1 : 1));

        double targetRadius = widget.radius;
        if (total > 1 && angleStep > 0) {
          double requiredChord = widget.isUser ? 50.0 : 54.0;
          double minRadius = requiredChord / (2 * sin(angleStep / 2));
          if (minRadius > targetRadius) {
            targetRadius = minRadius;
          }
          if (targetRadius > 140.0) targetRadius = 140.0;
        }

        final currentRadius = targetRadius * CurvedAnimation(parent: _controller, curve: Curves.easeOutBack).value;
        final borderThickness = widget.isUser ? 52.0 : 42.0;
        final containerSize = (currentRadius + borderThickness / 2) * 2;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (currentRadius > 0)
              Opacity(
                opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut).value,
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06), 
                      width: borderThickness,
                    ),
                  ),
                ),
              ),
            for (int i = 0; i < widget.items.length; i++)
              _buildRadialItem(i, startAngle, angleStep, currentRadius),
          ],
        );
      },
    );
  }

  Widget _buildRadialItem(int index, double startAngle, double angleStep, double currentRadius) {
    final angle = startAngle + angleStep * index;

    final dx = currentRadius * cos(angle);
    final dy = currentRadius * sin(angle);
    
    final item = widget.items[index];
    final isSelected = widget.selectedItems.contains(item);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut).value,
        child: GestureDetector(
          onTap: () => widget.onSelected(item),
          child: widget.isUser ? _buildUserItem(item, isSelected) : _buildCategoryItem(item),
        ),
      ),
    );
  }

  Widget _buildUserItem(String name, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.green.shade200 : Colors.blue.shade200,
            border: Border.all(
              color: isSelected ? Colors.green.shade600 : Colors.white24, 
              width: isSelected ? 2.5 : 1
            ),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green.shade900 : Colors.blue.shade900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String name) {
    IconData icon;
    Color color;
    
    if (name == 'Spesa') { icon = Icons.shopping_cart; color = Colors.orange; }
    else if (name == 'Trasporti') { icon = Icons.directions_car; color = Colors.blue; }
    else if (name == 'Casa') { icon = Icons.home; color = Colors.green; }
    else if (name == 'Svago') { icon = Icons.movie; color = Colors.purple; }
    else if (name == 'Salute') { icon = Icons.favorite; color = Colors.red; }
    else { icon = Icons.more_horiz; color = Colors.grey; }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 14),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

