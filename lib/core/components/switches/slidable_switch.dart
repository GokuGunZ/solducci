import 'package:flutter/material.dart';

/// Configuration for a single switch option
///
/// Defines the visual and data properties of one option in a [SlidableSwitch].
class SlidableSwitchOption<T extends Enum> {
  /// The enum value this option represents
  final T value;

  /// Display label for the option
  final String label;

  /// Icon displayed in the chip when this option is selected
  final IconData icon;

  /// Color of the chip when this option is selected
  final Color color;

  const SlidableSwitchOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Generic slidable switch with drag support and color gradient animation
///
/// A highly interactive switch component that supports both click and drag interactions.
/// The switch displays two options (left and right) with smooth animations and color
/// gradients during transitions.
///
/// ## Type Parameters
/// - `T`: Enum type for switch options (must have exactly 2 values)
///
/// ## Features
/// - Click either side to switch instantly
/// - Drag the colored chip to switch with real-time gradient
/// - Smooth bidirectional animations (300ms)
/// - Color interpolation during drag
/// - Enable/disable state
/// - Fully customizable appearance
///
/// ## Example
///
/// ```dart
/// enum Theme { light, dark }
///
/// SlidableSwitch<Theme>(
///   options: [
///     SlidableSwitchOption(
///       value: Theme.light,
///       label: 'Light',
///       icon: Icons.light_mode,
///       color: Colors.amber,
///     ),
///     SlidableSwitchOption(
///       value: Theme.dark,
///       label: 'Dark',
///       icon: Icons.dark_mode,
///       color: Colors.indigo,
///     ),
///   ],
///   initialValue: Theme.light,
///   onChanged: (theme) => print('Selected: $theme'),
/// )
/// ```
///
/// ## Design Patterns
/// - **Strategy Pattern**: Options define behavior through configuration
/// - **Generic Programming**: Type-safe enum-based API
class SlidableSwitch<T extends Enum> extends StatefulWidget {
  /// The two switch options (left and right)
  ///
  /// Must contain exactly 2 options. First option is displayed on the left,
  /// second option on the right.
  final List<SlidableSwitchOption<T>> options;

  /// Initial selected option
  final T initialValue;

  /// Callback when option changes
  ///
  /// Called after animation completes for click interactions, or on drag end.
  final ValueChanged<T> onChanged;

  /// Whether the switch is enabled
  ///
  /// When disabled, the switch is greyed out and does not respond to interactions.
  final bool enabled;

  /// Height of the switch track
  final double height;

  /// Background color of the track
  ///
  /// Defaults to light grey if not specified.
  final Color? trackColor;

  /// Border radius of the switch
  ///
  /// Applied to both the track and the sliding chip.
  final double borderRadius;

  /// Animation duration for programmatic switches
  ///
  /// This duration is used when the user clicks (not drags) the switch.
  final Duration animationDuration;

  const SlidableSwitch({
    super.key,
    required this.options,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
    this.height = 64,
    this.trackColor,
    this.borderRadius = 32,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : assert(options.length == 2, 'SlidableSwitch requires exactly 2 options');

  @override
  State<SlidableSwitch<T>> createState() => _SlidableSwitchState<T>();
}

class _SlidableSwitchState<T extends Enum> extends State<SlidableSwitch<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late T _currentValue;

  // Drag tracking
  double? _dragStartX;
  double _dragPosition = 0.0; // 0.0 = left option, 1.0 = right option

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Initialize position based on current value
    _dragPosition = _isRightOption(_currentValue) ? 1.0 : 0.0;
    _animationController.value = _dragPosition;
  }

  @override
  void didUpdateWidget(SlidableSwitch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle external value changes
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _currentValue) {
      _switchTo(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if the given value is the right option
  bool _isRightOption(T value) {
    return value == widget.options[1].value;
  }

  /// Get option configuration for a value
  SlidableSwitchOption<T> _getOption(T value) {
    return widget.options.firstWhere((opt) => opt.value == value);
  }

  /// Switch to a new value programmatically
  void _switchTo(T newValue) {
    if (newValue == _currentValue || !widget.enabled) return;

    setState(() {
      _currentValue = newValue;
      _dragPosition = _isRightOption(newValue) ? 1.0 : 0.0;
    });

    _animationController.animateTo(
      _dragPosition,
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
    );

    widget.onChanged(newValue);
  }

  /// Handle drag start
  void _onDragStart(DragStartDetails details, double trackWidth) {
    if (!widget.enabled) return;
    _dragStartX = details.localPosition.dx;
  }

  /// Handle drag update with real-time position tracking
  void _onDragUpdate(
    DragUpdateDetails details,
    double trackWidth,
    double chipWidth,
  ) {
    if (!widget.enabled || _dragStartX == null) return;

    final dragDelta = details.localPosition.dx - _dragStartX!;
    final startPosition = _isRightOption(_currentValue) ? 1.0 : 0.0;
    final maxTravel = trackWidth - chipWidth;

    // Calculate new position (0.0 to 1.0)
    double newPosition = (startPosition * maxTravel + dragDelta) / maxTravel;
    newPosition = newPosition.clamp(0.0, 1.0);

    setState(() {
      _dragPosition = newPosition;
      _animationController.value = newPosition;
    });
  }

  /// Handle drag end with snap to nearest option
  void _onDragEnd(DragEndDetails details, double trackWidth) {
    if (!widget.enabled) return;

    // Snap to nearest option
    final newValue = _dragPosition > 0.5
        ? widget.options[1].value
        : widget.options[0].value;

    if (newValue != _currentValue) {
      widget.onChanged(newValue);
    }

    setState(() {
      _currentValue = newValue;
      _dragPosition = _isRightOption(newValue) ? 1.0 : 0.0;
    });

    _animationController.animateTo(
      _dragPosition,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// Interpolate color based on current animation position
  Color _getInterpolatedColor() {
    return Color.lerp(
      widget.options[0].color,
      widget.options[1].color,
      _animationController.value,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final trackColor = widget.trackColor ?? const Color(0xFFF3F4F6);
    final disabledTrackColor = Colors.grey.shade300;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final chipWidth = trackWidth * 0.5;

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final leftPosition = _animationController.value * (trackWidth - chipWidth);
              final currentColor = _getInterpolatedColor();

              return Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.enabled ? trackColor : disabledTrackColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: Stack(
                  children: [
                    // Background labels (always visible)
                    Row(
                      children: [
                        // Left option label
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.enabled
                                ? () => _switchTo(widget.options[0].value)
                                : null,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                widget.options[0].label,
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

                        // Right option label
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.enabled
                                ? () => _switchTo(widget.options[1].value)
                                : null,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                widget.options[1].label,
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

                    // Sliding chip with icon and label
                    Positioned(
                      left: leftPosition,
                      top: 4,
                      bottom: 4,
                      child: GestureDetector(
                        onHorizontalDragStart: widget.enabled
                            ? (details) => _onDragStart(details, trackWidth)
                            : null,
                        onHorizontalDragUpdate: widget.enabled
                            ? (details) =>
                                _onDragUpdate(details, trackWidth, chipWidth)
                            : null,
                        onHorizontalDragEnd: widget.enabled
                            ? (details) => _onDragEnd(details, trackWidth)
                            : null,
                        child: Container(
                          width: chipWidth - 8,
                          decoration: BoxDecoration(
                            color: currentColor,
                            borderRadius:
                                BorderRadius.circular(widget.borderRadius - 4),
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
                                _getOption(_currentValue).icon,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getOption(_currentValue).label,
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
      ),
    );
  }
}
