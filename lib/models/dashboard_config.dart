import 'dart:convert';
import 'package:flutter/material.dart';

/// Defines the size of a widget in the Bento Grid
class BentoWidgetSize {
  final int crossAxisCellCount; // How many columns it spans (width)
  final int mainAxisCellCount;  // How many rows it spans (height)

  const BentoWidgetSize(this.crossAxisCellCount, this.mainAxisCellCount);

  factory BentoWidgetSize.fromMap(Map<String, dynamic> map) {
    return BentoWidgetSize(
      map['crossAxisCellCount'] as int? ?? 1,
      map['mainAxisCellCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'crossAxisCellCount': crossAxisCellCount,
      'mainAxisCellCount': mainAxisCellCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BentoWidgetSize &&
        other.crossAxisCellCount == crossAxisCellCount &&
        other.mainAxisCellCount == mainAxisCellCount;
  }

  @override
  int get hashCode => crossAxisCellCount.hashCode ^ mainAxisCellCount.hashCode;
}

/// Definition of a single widget in the dashboard layout
class BentoWidgetDef {
  final String id;
  final String type; // e.g., 'balance', 'focus_tasks', 'quick_expense'
  final BentoWidgetSize size;
  final Map<String, dynamic>? customProps; // Extra config for specific widgets

  BentoWidgetDef({
    required this.id,
    required this.type,
    required this.size,
    this.customProps,
  });

  factory BentoWidgetDef.fromMap(Map<String, dynamic> map) {
    return BentoWidgetDef(
      id: map['id'] as String,
      type: map['type'] as String,
      size: BentoWidgetSize.fromMap(map['size'] as Map<String, dynamic>),
      customProps: map['customProps'] != null 
          ? Map<String, dynamic>.from(map['customProps'] as Map) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'size': size.toMap(),
      'customProps': customProps,
    };
  }

  BentoWidgetDef copyWith({
    String? id,
    String? type,
    BentoWidgetSize? size,
    Map<String, dynamic>? customProps,
  }) {
    return BentoWidgetDef(
      id: id ?? this.id,
      type: type ?? this.type,
      size: size ?? this.size,
      customProps: customProps ?? this.customProps,
    );
  }
}

/// Represents a single dashboard tab / page belonging to a context
class BentoDashboardTab {
  final String id;
  final String contextKey; // 'personal', 'group_<id>', 'view_<id>'
  final String title;
  final String iconName; // e.g. 'home', 'wallet', 'bolt', 'kitchen', 'sticky_note', 'star'
  final Color accentColor;
  final int orderIndex;
  final List<BentoWidgetDef> layout;
  final bool isDefault;

  const BentoDashboardTab({
    required this.id,
    required this.contextKey,
    required this.title,
    this.iconName = 'dashboard',
    this.accentColor = const Color(0xFF6366F1),
    this.orderIndex = 0,
    required this.layout,
    this.isDefault = false,
  });

  factory BentoDashboardTab.fromMap(Map<String, dynamic> map) {
    final rawLayout = map['layout'] as List<dynamic>? ?? [];
    final parsedLayout = rawLayout
        .map((e) => BentoWidgetDef.fromMap(e as Map<String, dynamic>))
        .toList();

    return BentoDashboardTab(
      id: map['id'] as String? ?? 'tab_${DateTime.now().millisecondsSinceEpoch}',
      contextKey: map['context_key'] as String? ?? 'personal',
      title: map['title'] as String? ?? 'Home',
      iconName: map['icon_name'] as String? ?? 'dashboard',
      accentColor: map['accent_color'] != null
          ? Color(map['accent_color'] as int)
          : const Color(0xFF6366F1),
      orderIndex: map['order_index'] as int? ?? 0,
      layout: parsedLayout,
      isDefault: map['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'context_key': contextKey,
      'title': title,
      'icon_name': iconName,
      'accent_color': accentColor.value,
      'order_index': orderIndex,
      'layout': layout.map((w) => w.toMap()).toList(),
      'is_default': isDefault,
    };
  }

  BentoDashboardTab copyWith({
    String? id,
    String? contextKey,
    String? title,
    String? iconName,
    Color? accentColor,
    int? orderIndex,
    List<BentoWidgetDef>? layout,
    bool? isDefault,
  }) {
    return BentoDashboardTab(
      id: id ?? this.id,
      contextKey: contextKey ?? this.contextKey,
      title: title ?? this.title,
      iconName: iconName ?? this.iconName,
      accentColor: accentColor ?? this.accentColor,
      orderIndex: orderIndex ?? this.orderIndex,
      layout: layout ?? this.layout,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// The complete dashboard configuration for a specific device type
class DashboardConfig {
  final String id;
  final String userId;
  final String deviceType; // 'mobile', 'tablet', 'desktop'
  final List<BentoDashboardTab> tabs;
  final String? activeTabId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardConfig({
    required this.id,
    required this.userId,
    required this.deviceType,
    required this.tabs,
    this.activeTabId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Backward-compatible getter: returns the layout of the currently active tab
  List<BentoWidgetDef> get layout {
    if (tabs.isEmpty) return const [];
    if (activeTabId != null) {
      final active = tabs.where((t) => t.id == activeTabId).firstOrNull;
      if (active != null) return active.layout;
    }
    final defaultTab = tabs.where((t) => t.isDefault).firstOrNull;
    if (defaultTab != null) return defaultTab.layout;
    return tabs.first.layout;
  }

  /// Returns all tabs belonging to a specific context, sorted by orderIndex
  List<BentoDashboardTab> tabsForContext(String contextKey) {
    final filtered = tabs.where((t) => t.contextKey == contextKey).toList();
    filtered.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return filtered;
  }

  /// Returns the active tab for a specific context
  BentoDashboardTab? activeTabForContext(String contextKey) {
    final contextTabs = tabsForContext(contextKey);
    if (contextTabs.isEmpty) return null;
    if (activeTabId != null) {
      final matched = contextTabs.where((t) => t.id == activeTabId).firstOrNull;
      if (matched != null) return matched;
    }
    return contextTabs.where((t) => t.isDefault).firstOrNull ?? contextTabs.first;
  }

  factory DashboardConfig.fromMap(Map<String, dynamic> map) {
    List<BentoDashboardTab> parsedTabs = [];
    String? activeTabId;

    if (map['layout_json'] != null) {
      final dynamic raw = map['layout_json'];
      dynamic decoded = raw;
      if (raw is String) {
        try {
          decoded = jsonDecode(raw);
        } catch (_) {}
      }

      // Check if it's the new multi-tab format (Map with 'tabs')
      if (decoded is Map<String, dynamic> && decoded['tabs'] != null) {
        final tabsList = decoded['tabs'] as List<dynamic>? ?? [];
        parsedTabs = tabsList
            .map((e) => BentoDashboardTab.fromMap(e as Map<String, dynamic>))
            .toList();
        activeTabId = decoded['active_tab_id'] as String?;
      } else if (decoded is List) {
        // Legacy format: array of BentoWidgetDef.
        // Transparently migrate into an initial 'Home' tab for Personal context!
        final parsedLayout = decoded
            .map((e) => BentoWidgetDef.fromMap(e as Map<String, dynamic>))
            .toList();

        parsedTabs = [
          BentoDashboardTab(
            id: 'tab_default_personal',
            contextKey: 'personal',
            title: 'Home',
            iconName: 'home',
            accentColor: const Color(0xFF6366F1),
            orderIndex: 0,
            layout: parsedLayout,
            isDefault: true,
          ),
        ];
        activeTabId = 'tab_default_personal';
      }
    }

    return DashboardConfig(
      id: map['id'] as String? ?? 'dash_${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id'] as String? ?? '',
      deviceType: map['device_type'] as String? ?? 'mobile',
      tabs: parsedTabs,
      activeTabId: activeTabId,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : DateTime.now(),
    );
  }

  DashboardConfig copyWith({
    String? id,
    String? userId,
    String? deviceType,
    List<BentoDashboardTab>? tabs,
    String? activeTabId,
    List<BentoWidgetDef>? layout,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    List<BentoDashboardTab> updatedTabs = tabs ?? this.tabs;
    if (layout != null && tabs == null) {
      final currentActiveId = activeTabId ?? this.activeTabId;
      if (updatedTabs.isNotEmpty) {
        final targetIndex = currentActiveId != null
            ? updatedTabs.indexWhere((t) => t.id == currentActiveId)
            : 0;
        final validIndex = targetIndex >= 0 ? targetIndex : 0;
        final modifiedList = List<BentoDashboardTab>.from(updatedTabs);
        modifiedList[validIndex] = modifiedList[validIndex].copyWith(layout: layout);
        updatedTabs = modifiedList;
      } else {
        updatedTabs = [
          BentoDashboardTab(
            id: 'tab_default_personal',
            contextKey: 'personal',
            title: 'Home',
            layout: layout,
            isDefault: true,
          ),
        ];
      }
    }

    return DashboardConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceType: deviceType ?? this.deviceType,
      tabs: updatedTabs,
      activeTabId: activeTabId ?? this.activeTabId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device_type': deviceType,
      'layout_json': {
        'tabs': tabs.map((t) => t.toMap()).toList(),
        'active_tab_id': activeTabId,
      },
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
  
  Map<String, dynamic> toInsertMap() {
    final map = toMap();
    map['user_id'] = userId;
    return map;
  }
}
