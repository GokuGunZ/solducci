import 'package:flutter/foundation.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';

/// Configuration object for TaskListItem display and behavior.
///
/// Groups related configuration parameters to reduce constructor clutter
/// and improve maintainability. Provides preset configurations for common use cases.
class TaskItemConfig {
  /// The document this task belongs to (optional)
  final TodoDocument? document;

  /// Indentation level for nested tasks (0 = root level)
  final int depth;

  /// Notifier to control whether all properties should be shown
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  /// Pre-loaded tags for this specific task (optimization)
  final List<Tag>? preloadedTags;

  /// Pre-loaded tags map for all tasks (optimization for batch rendering)
  final Map<String, List<Tag>>? taskTagsMap;

  /// Whether swipe-to-delete/duplicate gestures are enabled
  final bool dismissibleEnabled;

  /// Whether to show task properties (priority, date, size, recurrence)
  final bool showProperties;

  /// Whether to allow expanding/collapsing subtasks
  final bool allowSubtasks;

  /// Whether to allow inline editing (title, description)
  final bool allowInlineEdit;

  const TaskItemConfig({
    this.document,
    this.depth = 0,
    this.showAllPropertiesNotifier,
    this.preloadedTags,
    this.taskTagsMap,
    this.dismissibleEnabled = true,
    this.showProperties = true,
    this.allowSubtasks = true,
    this.allowInlineEdit = true,
  });

  /// Preset: Read-only view (no editing, no swipe actions)
  ///
  /// Use for displaying tasks in contexts where editing should not be allowed,
  /// such as completed task archives or read-only views.
  static const readOnly = TaskItemConfig(
    allowInlineEdit: false,
    dismissibleEnabled: false,
  );

  /// Preset: Compact view (no properties, no subtasks)
  ///
  /// Use for displaying tasks in a minimal form, such as in search results
  /// or quick-pick lists where space is limited.
  static const compact = TaskItemConfig(
    showProperties: false,
    allowSubtasks: false,
  );

  /// Preset: Minimal view (compact + read-only)
  ///
  /// Use for the most minimal task display, such as in notifications
  /// or previews where only the task title is relevant.
  static const minimal = TaskItemConfig(
    showProperties: false,
    allowSubtasks: false,
    allowInlineEdit: false,
    dismissibleEnabled: false,
  );

  /// Create a copy with some fields replaced
  TaskItemConfig copyWith({
    TodoDocument? document,
    int? depth,
    ValueNotifier<bool>? showAllPropertiesNotifier,
    List<Tag>? preloadedTags,
    Map<String, List<Tag>>? taskTagsMap,
    bool? dismissibleEnabled,
    bool? showProperties,
    bool? allowSubtasks,
    bool? allowInlineEdit,
  }) {
    return TaskItemConfig(
      document: document ?? this.document,
      depth: depth ?? this.depth,
      showAllPropertiesNotifier:
          showAllPropertiesNotifier ?? this.showAllPropertiesNotifier,
      preloadedTags: preloadedTags ?? this.preloadedTags,
      taskTagsMap: taskTagsMap ?? this.taskTagsMap,
      dismissibleEnabled: dismissibleEnabled ?? this.dismissibleEnabled,
      showProperties: showProperties ?? this.showProperties,
      allowSubtasks: allowSubtasks ?? this.allowSubtasks,
      allowInlineEdit: allowInlineEdit ?? this.allowInlineEdit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskItemConfig &&
        other.document == document &&
        other.depth == depth &&
        other.showAllPropertiesNotifier == showAllPropertiesNotifier &&
        other.preloadedTags == preloadedTags &&
        other.taskTagsMap == taskTagsMap &&
        other.dismissibleEnabled == dismissibleEnabled &&
        other.showProperties == showProperties &&
        other.allowSubtasks == allowSubtasks &&
        other.allowInlineEdit == allowInlineEdit;
  }

  @override
  int get hashCode {
    return Object.hash(
      document,
      depth,
      showAllPropertiesNotifier,
      preloadedTags,
      taskTagsMap,
      dismissibleEnabled,
      showProperties,
      allowSubtasks,
      allowInlineEdit,
    );
  }

  @override
  String toString() {
    return 'TaskItemConfig('
        'depth: $depth, '
        'dismissible: $dismissibleEnabled, '
        'showProperties: $showProperties, '
        'allowSubtasks: $allowSubtasks, '
        'allowInlineEdit: $allowInlineEdit'
        ')';
  }
}
