import 'package:solducci/core/preload/preload_priority.dart';

/// Represents a preload task with priority and cancellation support
///
/// Each task has:
/// - Unique ID (for deduplication)
/// - Priority level (for queue ordering)
/// - Action to execute (the actual preload logic)
/// - Description (for debugging)
class PreloadTask implements Comparable<PreloadTask> {
  /// Unique identifier for this task (used for deduplication)
  final String id;

  /// Priority level for queue ordering
  final PreloadPriority priority;

  /// The actual preload action to execute
  final Future<void> Function() action;

  /// Human-readable description for debugging
  final String description;

  /// Timestamp when task was created
  final DateTime createdAt;

  PreloadTask({
    required this.id,
    required this.priority,
    required this.action,
    required this.description,
  }) : createdAt = DateTime.now();

  /// Compare tasks for priority queue sorting
  /// Higher priority tasks come first
  /// For same priority, older tasks come first (FIFO)
  @override
  int compareTo(PreloadTask other) {
    // First compare by priority (higher priority first)
    final priorityComparison = other.priority.value.compareTo(priority.value);
    if (priorityComparison != 0) return priorityComparison;

    // If same priority, older tasks first (FIFO)
    return createdAt.compareTo(other.createdAt);
  }

  @override
  String toString() => 'PreloadTask($id, ${priority.name}, $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreloadTask && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
