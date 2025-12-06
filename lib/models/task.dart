import 'package:flutter/material.dart';

/// Task status enum
enum TaskStatus {
  pending('pending'),
  completed('completed'),
  assigned('assigned'),
  inProgress('in_progress');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus fromValue(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Da fare';
      case TaskStatus.completed:
        return 'Completata';
      case TaskStatus.assigned:
        return 'Assegnata';
      case TaskStatus.inProgress:
        return 'In corso';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskStatus.pending:
        return Icons.circle_outlined;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.assigned:
        return Icons.person_outline;
      case TaskStatus.inProgress:
        return Icons.timelapse;
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.assigned:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
    }
  }
}

/// Task priority enum
enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  final String value;
  const TaskPriority(this.value);

  static TaskPriority fromValue(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.medium,
    );
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Bassa';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }
}

/// T-shirt size enum for estimation
enum TShirtSize {
  xs('xs'),
  s('s'),
  m('m'),
  l('l'),
  xl('xl');

  final String value;
  const TShirtSize(this.value);

  static TShirtSize fromValue(String value) {
    return TShirtSize.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TShirtSize.m,
    );
  }

  String get label => value.toUpperCase();
}

/// Task model with hierarchical support (parent-child relationships)
/// Tasks can have sub-tasks forming an arbitrary deep tree structure.
/// They inherit tags and recurrence from parent tasks and associated tags.
class Task {
  final String id;
  final String documentId;
  final String? parentTaskId;

  String title;
  String? description;
  TaskStatus status;
  DateTime? completedAt;
  TaskPriority? priority;
  TShirtSize? tShirtSize;
  DateTime? dueDate;
  int position;

  final DateTime createdAt;
  DateTime updatedAt;

  // Relationships (lazy loaded, not stored in DB directly)
  List<Task>? subtasks;

  Task({
    required this.id,
    required this.documentId,
    this.parentTaskId,
    required this.title,
    this.description,
    required this.status,
    this.completedAt,
    this.priority,
    this.tShirtSize,
    this.dueDate,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks,
  });

  /// Check if task is completed
  bool get isCompleted => status == TaskStatus.completed;

  /// Check if task has sub-tasks
  bool get hasSubtasks => subtasks != null && subtasks!.isNotEmpty;

  /// Check if this is a root task (no parent)
  bool get isRoot => parentTaskId == null;

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Get depth level in hierarchy (0 = root, 1 = first level child, etc.)
  int getDepthLevel() {
    // Note: This would need to be calculated by traversing up the parent chain
    // For now, return 0 for root, 1 for children (service layer will calculate actual depth)
    return parentTaskId == null ? 0 : 1;
  }

  /// Create Task from Supabase map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      parentTaskId: map['parent_task_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: TaskStatus.fromValue(map['status'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      priority: map['priority'] != null
          ? TaskPriority.fromValue(map['priority'] as String)
          : null,
      tShirtSize: map['t_shirt_size'] != null
          ? TShirtSize.fromValue(map['t_shirt_size'] as String)
          : null,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      position: map['position'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Task to map for Supabase
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'document_id': documentId,
      'parent_task_id': parentTaskId,
      'title': title,
      'description': description,
      'status': status.value,
      'completed_at': completedAt?.toIso8601String(),
      'priority': priority?.value,
      't_shirt_size': tShirtSize?.value,
      'due_date': dueDate?.toIso8601String(),
      'position': position,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Only include id for updates
    if (id.isNotEmpty && id != '00000000-0000-0000-0000-000000000000') {
      map['id'] = id;
    }

    return map;
  }

  /// Convert to map for insert (without id and timestamps)
  Map<String, dynamic> toInsertMap() {
    final map = toMap();
    map.remove('id');
    map.remove('updated_at');
    return map;
  }

  /// Convert to map for update (only mutable fields)
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'status': status.value,
      'completed_at': completedAt?.toIso8601String(),
      'priority': priority?.value,
      't_shirt_size': tShirtSize?.value,
      'due_date': dueDate?.toIso8601String(),
      'position': position,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? completedAt,
    TaskPriority? priority,
    TShirtSize? tShirtSize,
    DateTime? dueDate,
    int? position,
    List<Task>? subtasks,
  }) {
    return Task(
      id: id,
      documentId: documentId,
      parentTaskId: parentTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      tShirtSize: tShirtSize ?? this.tShirtSize,
      dueDate: dueDate ?? this.dueDate,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      subtasks: subtasks ?? this.subtasks,
    );
  }

  /// Create a new empty Task
  factory Task.create({
    required String documentId,
    String? parentTaskId,
    required String title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    int position = 0,
  }) {
    return Task(
      id: '', // Will be generated by Supabase
      documentId: documentId,
      parentTaskId: parentTaskId,
      title: title,
      description: description,
      status: TaskStatus.pending,
      priority: priority,
      dueDate: dueDate,
      position: position,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: ${status.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
