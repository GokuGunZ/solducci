import 'package:flutter/material.dart';

/// Tipo di spesa: personale o di gruppo
enum ExpenseType {
  personal,
  group;

  String get label {
    switch (this) {
      case ExpenseType.personal:
        return 'Personale';
      case ExpenseType.group:
        return 'Di Gruppo';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseType.personal:
        return Icons.person;
      case ExpenseType.group:
        return Icons.group;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseType.personal:
        return const Color(0xFF9333EA); // Purple-600 for Personal
      case ExpenseType.group:
        return const Color(0xFF10B981); // Green-500 for Group
    }
  }
}

/// Elegant slidable switch with drag support and color gradient animation
///
/// Features:
/// - Clean, minimal design with pill-shaped chip
/// - Click on either side to switch
/// - Drag the colored chip to switch
/// - Smooth color gradient during drag
/// - Bidirectional animations
class ExpenseTypeSwitch extends StatefulWidget {
  final ExpenseType initialType;
  final ValueChanged<ExpenseType> onTypeChanged;
  final bool enabled;

  const ExpenseTypeSwitch({
    super.key,
    required this.initialType,
    required this.onTypeChanged,
    this.enabled = true,
  });

  @override
  State<ExpenseTypeSwitch> createState() => _ExpenseTypeSwitchState();
}

class _ExpenseTypeSwitchState extends State<ExpenseTypeSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ExpenseType _currentType;

  // For drag tracking
  double? _dragStartX;
  double _dragPosition = 0.0; // 0.0 = left (Agency), 1.0 = right (Freelancer)

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize position based on current type
    _dragPosition = _currentType == ExpenseType.group ? 1.0 : 0.0;
    _animationController.value = _dragPosition;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _switchTo(ExpenseType newType) {
    if (newType == _currentType || !widget.enabled) return;

    setState(() {
      _currentType = newType;
      _dragPosition = newType == ExpenseType.group ? 1.0 : 0.0;
    });

    _animationController.animateTo(
      _dragPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    widget.onTypeChanged(newType);
  }

  void _onDragStart(DragStartDetails details, double trackWidth) {
    if (!widget.enabled) return;
    _dragStartX = details.localPosition.dx;
  }

  void _onDragUpdate(DragUpdateDetails details, double trackWidth, double chipWidth) {
    if (!widget.enabled || _dragStartX == null) return;

    final dragDelta = details.localPosition.dx - _dragStartX!;
    final startPosition = _currentType == ExpenseType.personal ? 0.0 : 1.0;
    final maxTravel = trackWidth - chipWidth;

    double newPosition = (startPosition * maxTravel + dragDelta) / maxTravel;
    newPosition = newPosition.clamp(0.0, 1.0);

    setState(() {
      _dragPosition = newPosition;
      _animationController.value = newPosition;
    });
  }

  void _onDragEnd(DragEndDetails details, double trackWidth) {
    if (!widget.enabled) return;

    // Snap to nearest position
    final newType = _dragPosition > 0.5 ? ExpenseType.group : ExpenseType.personal;

    if (newType != _currentType) {
      widget.onTypeChanged(newType);
    }

    setState(() {
      _currentType = newType;
      _dragPosition = newType == ExpenseType.group ? 1.0 : 0.0;
    });

    _animationController.animateTo(
      _dragPosition,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Color _getInterpolatedColor() {
    // Interpolate between Agency gray and Freelancer turquoise
    return Color.lerp(
      ExpenseType.personal.color,
      ExpenseType.group.color,
      _animationController.value,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final chipWidth = trackWidth * 0.5;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final leftPosition = _animationController.value * (trackWidth - chipWidth);
            final currentColor = _getInterpolatedColor();

            return Container(
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // Light gray background
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                children: [
                  // Background labels (always visible)
                  Row(
                    children: [
                      // Agency label
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _switchTo(ExpenseType.personal),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              ExpenseType.personal.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Freelancer label
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _switchTo(ExpenseType.group),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              ExpenseType.group.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Sliding chip with label
                  Positioned(
                    left: leftPosition,
                    top: 4,
                    bottom: 4,
                    child: GestureDetector(
                      onHorizontalDragStart: (details) => _onDragStart(details, trackWidth),
                      onHorizontalDragUpdate: (details) => _onDragUpdate(details, trackWidth, chipWidth),
                      onHorizontalDragEnd: (details) => _onDragEnd(details, trackWidth),
                      child: Container(
                        width: chipWidth - 8,
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentType.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentType.label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
