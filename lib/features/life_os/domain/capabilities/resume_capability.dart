import 'package:solducci/features/life_os/domain/models/models.dart';

extension ResumeCapability on LifeEntity {
  /// Whether an entity has been inactive long enough to deserve a Resume Surface
  /// rather than a standard operational view.
  bool isResumeWorthy([Duration threshold = const Duration(days: 21)]) {
    if (isArchived || isSeed) return false;

    final refDate = lastMeaningfulActivityAt ?? createdAt;
    final inactiveDuration = DateTime.now().difference(refDate);
    return inactiveDuration >= threshold;
  }

  /// Inactivity duration relative to last meaningful activity (or creation if no activity)
  Duration get inactiveDuration {
    final refDate = lastMeaningfulActivityAt ?? createdAt;
    return DateTime.now().difference(refDate);
  }

  int get inactiveDays => inactiveDuration.inDays;
}
