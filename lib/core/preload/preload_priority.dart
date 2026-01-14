/// Priority levels for preload tasks
///
/// Higher priority tasks are executed first.
/// This ensures critical data loads before nice-to-have data.
enum PreloadPriority {
  /// Critical data needed immediately
  /// Example: Current context data, user profile
  high(3),

  /// Important data likely needed soon
  /// Example: Group members, recent expenses
  medium(2),

  /// Nice-to-have data for future navigation
  /// Example: Balance calculations, statistics
  low(1);

  final int value;
  const PreloadPriority(this.value);

  /// Compare priorities for sorting
  bool isHigherThan(PreloadPriority other) => value > other.value;
}
