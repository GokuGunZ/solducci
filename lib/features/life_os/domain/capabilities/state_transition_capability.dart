import 'package:solducci/features/life_os/domain/models/models.dart';

extension StateTransitionCapability on LifeEntity {
  /// Validates whether a state transition is logically permitted.
  bool canTransitionTo(LifecycleState target) {
    if (lifecycleState == target) return false;

    switch (lifecycleState) {
      case LifecycleState.active:
        return true; // Can pause, complete, or archive
      case LifecycleState.paused:
        return target == LifecycleState.active || target == LifecycleState.archived;
      case LifecycleState.completed:
        return target == LifecycleState.active || target == LifecycleState.archived;
      case LifecycleState.archived:
        return target == LifecycleState.active; // Can reactivate
    }
  }
}
