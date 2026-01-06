import 'package:flutter/material.dart';

/// Mixin for adding highlight animation to widgets
///
/// Provides a fade-in/fade-out highlight effect that can be triggered
/// when an item is repositioned or updated.
///
/// Usage:
/// ```dart
/// class MyWidget extends StatefulWidget { ... }
///
/// class _MyWidgetState extends State<MyWidget>
///     with SingleTickerProviderStateMixin, HighlightAnimationMixin {
///
///   @override
///   void initState() {
///     super.initState();
///     initHighlightAnimation();
///     startHighlightAnimation(); // Trigger on init
///   }
///
///   @override
///   void dispose() {
///     disposeHighlightAnimation();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return buildWithHighlight(
///       context,
///       child: MyContent(),
///     );
///   }
/// }
/// ```
mixin HighlightAnimationMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  /// Initialize the highlight animation
  /// Call this in initState()
  void initHighlightAnimation({
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOut,
  }) {
    _highlightController = AnimationController(
      duration: duration,
      vsync: this,
    );

    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _highlightController,
        curve: curve,
      ),
    );
  }

  /// Start the highlight animation (fade in then fade out)
  void startHighlightAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _highlightController.forward().then((_) {
          if (mounted) {
            _highlightController.reverse();
          }
        });
      }
    });
  }

  /// Dispose the animation controller
  /// Call this in dispose()
  void disposeHighlightAnimation() {
    _highlightController.dispose();
  }

  /// Get current highlight opacity (0.0 to 1.0)
  double get highlightOpacity {
    final value = _highlightAnimation.value;
    // Fade in first half, fade out second half
    return value <= 0.5 ? value * 2 : (1.0 - value) * 2;
  }

  /// Build widget with highlight effect
  Widget buildWithHighlight(
    BuildContext context, {
    required Widget child,
    double maxOpacity = 0.3,
    double maxBlur = 12.0,
    double maxSpread = 2.0,
    BorderRadius? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, _) {
        final opacity = highlightOpacity;
        final theme = Theme.of(context);

        return Container(
          decoration: opacity > 0.05
              ? BoxDecoration(
                  borderRadius: borderRadius ?? BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary
                          .withValues(alpha: opacity * maxOpacity),
                      blurRadius: maxBlur * opacity,
                      spreadRadius: maxSpread * opacity,
                    ),
                  ],
                )
              : null,
          child: child,
        );
      },
    );
  }
}

/// Standalone widget for highlight animation (Stateless alternative)
///
/// Use when you need highlight without managing animation state yourself.
///
/// Usage:
/// ```dart
/// HighlightContainer(
///   autoStart: true,
///   child: MyWidget(),
/// )
/// ```
class HighlightContainer extends StatefulWidget {
  final Widget child;
  final bool autoStart;
  final Duration duration;
  final Curve curve;
  final double maxOpacity;
  final double maxBlur;
  final double maxSpread;
  final BorderRadius? borderRadius;

  const HighlightContainer({
    super.key,
    required this.child,
    this.autoStart = true,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeInOut,
    this.maxOpacity = 0.3,
    this.maxBlur = 12.0,
    this.maxSpread = 2.0,
    this.borderRadius,
  });

  @override
  State<HighlightContainer> createState() => _HighlightContainerState();
}

class _HighlightContainerState extends State<HighlightContainer>
    with SingleTickerProviderStateMixin, HighlightAnimationMixin {
  @override
  void initState() {
    super.initState();
    initHighlightAnimation(
      duration: widget.duration,
      curve: widget.curve,
    );

    if (widget.autoStart) {
      startHighlightAnimation();
    }
  }

  @override
  void dispose() {
    disposeHighlightAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildWithHighlight(
      context,
      child: widget.child,
      maxOpacity: widget.maxOpacity,
      maxBlur: widget.maxBlur,
      maxSpread: widget.maxSpread,
      borderRadius: widget.borderRadius,
    );
  }
}
