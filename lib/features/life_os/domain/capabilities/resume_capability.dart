import 'package:solducci/features/life_os/domain/models/models.dart';

/// Qualitative tension level indicating how much context recovery
/// the entity requires after inactivity.
enum ResumeTension {
  none,
  gentle,
  medium,
  high;
}

extension ResumeCapability on LifeEntity {
  /// Whether an entity has been inactive long enough to deserve a Resume Surface
  /// rather than a standard operational view.
  bool isResumeWorthy({
    Duration threshold = const Duration(days: 21),
    DateTime? referenceDate,
  }) {
    if (isArchived || isSeed) return false;

    final refDate = lastMeaningfulActivityAt ?? createdAt;
    final now = referenceDate ?? DateTime.now();
    return now.difference(refDate) >= threshold;
  }

  /// Calculates tension based on days of meaningful inactivity.
  ResumeTension resumeTension({DateTime? referenceDate}) {
    if (isArchived || isSeed) return ResumeTension.none;

    final refDate = lastMeaningfulActivityAt ?? createdAt;
    final now = referenceDate ?? DateTime.now();
    final days = now.difference(refDate).inDays;

    if (days < 14) return ResumeTension.none;
    if (days < 28) return ResumeTension.gentle;
    if (days < 60) return ResumeTension.medium;
    return ResumeTension.high;
  }

  /// Inactivity duration relative to last meaningful activity (or creation if no activity)
  Duration get inactiveDuration => getInactiveDuration();

  Duration getInactiveDuration({DateTime? referenceDate}) {
    final refDate = lastMeaningfulActivityAt ?? createdAt;
    final now = referenceDate ?? DateTime.now();
    return now.difference(refDate);
  }

  int get inactiveDays => inactiveDuration.inDays;

  int getInactiveDays({DateTime? referenceDate}) =>
      getInactiveDuration(referenceDate: referenceDate).inDays;
}
