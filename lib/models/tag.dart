import 'package:flutter/material.dart';

/// Tag model with hierarchical support
/// Tags can be organized in a tree structure (parent-child relationships)
/// and are used to categorize tasks. Each tag can have:
/// - UI customization (color, icon)
/// - Behavior configuration (advanced states, show completed)
/// - Recurrence rules that are inherited by associated tasks
class Tag {
  final String id;
  final String userId;
  String name;
  String? description;
  String? color; // Hex color without '#' (e.g., 'FF5733')
  String? icon; // Icon identifier (e.g., 'work', 'home', 'shopping')
  final String? parentTagId;

  // Tag-specific configurations
  bool useAdvancedStates; // Enable assigned/in_progress states for tasks
  bool showCompleted; // Show completed tasks by default in this tag view

  final DateTime createdAt;
  DateTime updatedAt;

  // Relationships (lazy loaded, not stored in DB directly)
  List<Tag>? childTags;

  Tag({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.parentTagId,
    required this.useAdvancedStates,
    required this.showCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.childTags,
  });

  /// Check if tag has child tags
  bool get hasChildren => childTags != null && childTags!.isNotEmpty;

  /// Check if this is a root tag (no parent)
  bool get isRoot => parentTagId == null;

  /// Get Color object from hex string
  Color? get colorObject {
    if (color == null) return null;
    try {
      // Remove '#' if present and add 'FF' for full opacity
      final hexColor = color!.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Set color from Color object
  set colorObject(Color? newColor) {
    if (newColor == null) {
      color = null;
    } else {
      // Convert to hex without '#' and alpha channel using toARGB32
      final argb = newColor.toARGB32();
      color = argb.toRadixString(16).substring(2).toUpperCase();
    }
  }

  /// Get IconData from icon identifier
  IconData? get iconData {
    if (icon == null) return null;

    // Map of icon identifiers to IconData
    // This can be expanded with more icons as needed
    final iconMap = <String, IconData>{
      'work': Icons.work,
      'home': Icons.home,
      'shopping': Icons.shopping_cart,
      'fitness': Icons.fitness_center,
      'health': Icons.local_hospital,
      'food': Icons.restaurant,
      'transport': Icons.directions_car,
      'education': Icons.school,
      'entertainment': Icons.movie,
      'family': Icons.family_restroom,
      'finance': Icons.attach_money,
      'travel': Icons.flight,
      'personal': Icons.person,
      'urgent': Icons.priority_high,
      'star': Icons.star,
      'flag': Icons.flag,
      'label': Icons.label,
      'folder': Icons.folder,
      'bookmark': Icons.bookmark,
      'heart': Icons.favorite,
      'check': Icons.check_circle,
      'calendar': Icons.calendar_today,
      'clock': Icons.access_time,
      'list': Icons.list,
      'lightbulb': Icons.lightbulb,
      'computer': Icons.computer,
      'phone': Icons.phone,
      'email': Icons.email,
      'cafe': Icons.local_cafe,
      'hotel': Icons.hotel,
    };

    return iconMap[icon];
  }

  /// Create Tag from Supabase map
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      parentTagId: map['parent_tag_id'] as String?,
      useAdvancedStates: map['use_advanced_states'] as bool? ?? false,
      showCompleted: map['show_completed'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Tag to map for Supabase
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'parent_tag_id': parentTagId,
      'use_advanced_states': useAdvancedStates,
      'show_completed': showCompleted,
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
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'use_advanced_states': useAdvancedStates,
      'show_completed': showCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Tag copyWith({
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? useAdvancedStates,
    bool? showCompleted,
    List<Tag>? childTags,
  }) {
    return Tag(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentTagId: parentTagId,
      useAdvancedStates: useAdvancedStates ?? this.useAdvancedStates,
      showCompleted: showCompleted ?? this.showCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      childTags: childTags ?? this.childTags,
    );
  }

  /// Create a new empty Tag
  factory Tag.create({
    required String userId,
    required String name,
    String? description,
    String? color,
    String? icon,
    String? parentTagId,
    bool useAdvancedStates = false,
    bool showCompleted = false,
  }) {
    return Tag(
      id: '', // Will be generated by Supabase
      userId: userId,
      name: name,
      description: description,
      color: color,
      icon: icon,
      parentTagId: parentTagId,
      useAdvancedStates: useAdvancedStates,
      showCompleted: showCompleted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get display chip for UI
  Widget getChip({VoidCallback? onTap, VoidCallback? onDelete}) {
    return Chip(
      avatar: iconData != null
          ? Icon(iconData, size: 18, color: Colors.white)
          : null,
      label: Text(
        name,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: colorObject ?? Colors.grey,
      deleteIcon: onDelete != null
          ? const Icon(Icons.close, size: 18, color: Colors.white)
          : null,
      onDeleted: onDelete,
    );
  }

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, parent: $parentTagId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
