import 'package:solducci/features/life_os/domain/models/models.dart';

extension TrendCapability on List<LifeSession> {
  /// Whether the session history contains enough quantitative data
  /// to render a trendline for the specified [metricKey].
  bool hasTrendFor(String metricKey) {
    int numericCount = 0;
    for (final s in this) {
      final val = s.metrics[metricKey];
      if (val is num) {
        numericCount++;
        if (numericCount >= 2) return true;
      }
    }
    return false;
  }

  /// Extracts chronological series of numeric values for [metricKey].
  List<double> extractTrendValues(String metricKey) {
    final sorted = List<LifeSession>.from(this)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final List<double> values = [];
    for (final s in sorted) {
      final val = s.metrics[metricKey];
      if (val is num) {
        values.add(val.toDouble());
      }
    }
    return values;
  }
}
