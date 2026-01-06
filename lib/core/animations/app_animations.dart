import 'package:flutter/material.dart';

/// Centralized animation registry for consistent animations across the app
///
/// This provides:
/// - Standard durations and curves
/// - Reusable animation builders
/// - Consistent UX across different components
///
/// Usage:
/// ```dart
/// AnimatedList(
///   insertDuration: AppAnimations.insertDuration,
///   builder: (context, animation) {
///     return AppAnimations.buildInsertAnimation(
///       context,
///       animation,
///       child: MyWidget(),
///     );
///   },
/// )
/// ```
class AppAnimations {
  AppAnimations._(); // Private constructor - static only

  // ============================================================
  // DURATIONS - Standard animation timings
  // ============================================================

  /// Duration for inserting items into lists
  static const Duration insertDuration = Duration(milliseconds: 300);

  /// Duration for removing items from lists
  static const Duration removeDuration = Duration(milliseconds: 250);

  /// Duration for swipe/page transitions
  static const Duration swipeDuration = Duration(milliseconds: 400);

  /// Duration for reordering items
  static const Duration reorderDuration = Duration(milliseconds: 350);

  /// Duration for expand/collapse animations
  static const Duration expandDuration = Duration(milliseconds: 300);

  /// Duration for fade transitions
  static const Duration fadeDuration = Duration(milliseconds: 200);

  /// Duration for quick UI updates
  static const Duration quickDuration = Duration(milliseconds: 150);

  // ============================================================
  // CURVES - Standard easing functions
  // ============================================================

  /// Curve for insert animations (enters view)
  static const Curve insertCurve = Curves.easeOut;

  /// Curve for remove animations (exits view)
  static const Curve removeCurve = Curves.easeIn;

  /// Curve for swipe/slide transitions
  static const Curve swipeCurve = Curves.easeInOut;

  /// Curve for bounce effects
  static const Curve bounceCurve = Curves.elasticOut;

  /// Curve for smooth transitions
  static const Curve smoothCurve = Curves.easeInOutCubic;

  // ============================================================
  // ANIMATION BUILDERS - Reusable animation patterns
  // ============================================================

  /// Standard insert animation: fade + slide from top
  ///
  /// Used when items are added to lists
  static Widget buildInsertAnimation(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: insertCurve,
        )),
        child: child,
      ),
    );
  }

  /// Standard remove animation: fade + slide to bottom
  ///
  /// Used when items are removed from lists
  static Widget buildRemoveAnimation(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 0.2),
        ).animate(CurvedAnimation(
          parent: animation,
          curve: removeCurve,
        )),
        child: SizeTransition(
          sizeFactor: animation,
          child: child,
        ),
      ),
    );
  }

  /// Swipe left animation
  ///
  /// Used for page transitions going forward
  static Widget buildSwipeLeftAnimation(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: swipeCurve,
      )),
      child: child,
    );
  }

  /// Swipe right animation
  ///
  /// Used for page transitions going backward
  static Widget buildSwipeRightAnimation(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: swipeCurve,
      )),
      child: child,
    );
  }

  /// Scale + fade animation
  ///
  /// Used for modals and dialogs
  static Widget buildScaleFadeAnimation(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: smoothCurve,
          ),
        ),
        child: child,
      ),
    );
  }

  /// Expand/collapse animation
  ///
  /// Used for expandable items (like nested tasks)
  static Widget buildExpandAnimation(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: smoothCurve,
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Reorder animation with scale effect
  ///
  /// Used when items are being dragged and reordered
  static Widget buildReorderAnimation(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      ),
      child: child,
    );
  }

  /// Highlight pulse animation
  ///
  /// Used to draw attention to items (e.g., after reorder)
  static Widget buildHighlightAnimation(
    BuildContext context,
    Animation<double> animation,
    Widget child, {
    Color? highlightColor,
  }) {
    final color = highlightColor ?? Theme.of(context).colorScheme.primary;

    // Calculate opacity: fade in then fade out
    final opacity = animation.value <= 0.5
        ? animation.value * 2 // 0.0 → 1.0 in first half
        : (1.0 - animation.value) * 2; // 1.0 → 0.0 in second half

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: opacity > 0.05
            ? [
                BoxShadow(
                  color: color.withValues(alpha: opacity * 0.3),
                  blurRadius: 12 * opacity,
                  spreadRadius: 2 * opacity,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Create a curved animation from parent
  static Animation<double> createCurvedAnimation(
    Animation<double> parent,
    Curve curve,
  ) {
    return CurvedAnimation(parent: parent, curve: curve);
  }

  /// Create a tween animation
  static Animation<T> createTweenAnimation<T>(
    Animation<double> parent,
    T begin,
    T end,
    Curve curve,
  ) {
    return Tween<T>(begin: begin, end: end).animate(
      CurvedAnimation(parent: parent, curve: curve),
    );
  }
}
