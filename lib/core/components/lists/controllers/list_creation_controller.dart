import 'package:flutter/material.dart';
import 'package:solducci/core/animations/app_animations.dart';

/// Controller for managing inline item creation in lists
///
/// Coordinates between external triggers (FAB, buttons) and
/// the list's inline creation UI with synchronized animations.
///
/// Workflow:
/// 1. External widget calls `startInlineCreation()`
/// 2. List shows empty item with slide-down animation
/// 3. User fills in required fields
/// 4. User saves → `completeCreation(item)` → animate transform
/// 5. User cancels → `cancelCreation()` → animate slide-up
///
/// Usage:
/// ```dart
/// final controller = ListCreationController<Task>(
///   vsync: this,
/// );
///
/// // From FAB
/// onPressed: () => controller.startInlineCreation()
///
/// // From list
/// if (controller.isCreating) {
///   return EmptyTaskItem(
///     onSave: (task) => controller.completeCreation(task),
///     onCancel: () => controller.cancelCreation(),
///   );
/// }
/// ```
class ListCreationController<T> extends ChangeNotifier {
  /// Animation controller for slide animations
  final AnimationController animationController;

  /// Current creation state
  bool _isCreating = false;

  /// Item being created (temporary storage)
  T? _pendingItem;

  /// Callback when creation completes successfully
  final void Function(T item)? onCreationComplete;

  /// Callback when creation is cancelled
  final VoidCallback? onCreationCancelled;

  ListCreationController({
    required TickerProvider vsync,
    this.onCreationComplete,
    this.onCreationCancelled,
  }) : animationController = AnimationController(
          vsync: vsync,
          duration: AppAnimations.insertDuration,
        );

  /// Whether inline creation is active
  bool get isCreating => _isCreating;

  /// Pending item (if any)
  T? get pendingItem => _pendingItem;

  /// Animation for slide in/out
  Animation<Offset> get slideAnimation => Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: AppAnimations.insertCurve,
      ));

  /// Animation for fade in/out
  Animation<double> get fadeAnimation => CurvedAnimation(
        parent: animationController,
        curve: AppAnimations.insertCurve,
      );

  // ============================================================
  // CREATION LIFECYCLE
  // ============================================================

  /// Start inline creation process
  ///
  /// Triggers slide-down animation and shows empty item
  Future<void> startInlineCreation() async {
    if (_isCreating) return; // Already creating

    _isCreating = true;
    _pendingItem = null;
    notifyListeners();

    // Animate in
    await animationController.forward();
  }

  /// Complete creation with new item
  ///
  /// Validates item, triggers callback, and animates out
  Future<void> completeCreation(T item) async {
    if (!_isCreating) return;

    _pendingItem = item;

    // Animate out (slide up)
    await animationController.reverse();

    _isCreating = false;
    notifyListeners();

    // Notify callback
    onCreationComplete?.call(item);

    _pendingItem = null;
  }

  /// Cancel creation
  ///
  /// Discards changes and animates out
  Future<void> cancelCreation() async {
    if (!_isCreating) return;

    // Animate out (slide up)
    await animationController.reverse();

    _isCreating = false;
    _pendingItem = null;
    notifyListeners();

    // Notify callback
    onCreationCancelled?.call();
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Reset controller to initial state
  void reset() {
    _isCreating = false;
    _pendingItem = null;
    animationController.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}

/// Widget that listens to ListCreationController and rebuilds
///
/// Usage:
/// ```dart
/// ListCreationBuilder<Task>(
///   controller: creationController,
///   builder: (context, isCreating) {
///     if (isCreating) {
///       return EmptyTaskItem(...);
///     }
///     return SizedBox.shrink();
///   },
/// )
/// ```
class ListCreationBuilder<T> extends StatelessWidget {
  final ListCreationController<T> controller;
  final Widget Function(BuildContext context, bool isCreating) builder;

  const ListCreationBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return builder(context, controller.isCreating);
      },
    );
  }
}

/// Animated widget for inline creation UI
///
/// Handles slide-in/out animations automatically
class AnimatedInlineCreation extends StatelessWidget {
  final ListCreationController controller;
  final Widget child;

  const AnimatedInlineCreation({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: controller.slideAnimation,
      child: FadeTransition(
        opacity: controller.fadeAnimation,
        child: child,
      ),
    );
  }
}
