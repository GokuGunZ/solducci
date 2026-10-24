import 'package:solducci/features/life_os/domain/models/models.dart';

extension ActionableCapability on LifeEntity {
  /// Whether an entity is in an active execution or practice mode suitable
  /// for taking actions or scheduling into weekly rails.
  bool get isExecutionCandidate {
    if (isArchived || isPaused) return false;
    return isProject || isPractice;
  }
}
