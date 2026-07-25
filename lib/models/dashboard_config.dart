import 'dart:convert';

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

/// The complete dashboard configuration for a specific device type
class DashboardConfig {
  final String id;
  final String userId;
  final String deviceType; // 'mobile', 'tablet', 'desktop'
  final List<BentoWidgetDef> layout;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardConfig({
    required this.id,
    required this.userId,
    required this.deviceType,
    required this.layout,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DashboardConfig.fromMap(Map<String, dynamic> map) {
    List<BentoWidgetDef> parsedLayout = [];
    
    if (map['layout_json'] != null) {
      final dynamic rawLayout = map['layout_json'];
      List<dynamic> layoutList;
      
      // Handle both String (if it comes unparsed) and List (if jsonb is automatically parsed)
      if (rawLayout is String) {
        layoutList = jsonDecode(rawLayout) as List<dynamic>;
      } else {
        layoutList = rawLayout as List<dynamic>;
      }

      parsedLayout = layoutList
          .map((e) => BentoWidgetDef.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return DashboardConfig(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      deviceType: map['device_type'] as String? ?? 'mobile',
      layout: parsedLayout,
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
    List<BentoWidgetDef>? layout,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DashboardConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceType: deviceType ?? this.deviceType,
      layout: layout ?? this.layout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device_type': deviceType,
      'layout_json': layout.map((w) => w.toMap()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
  
  Map<String, dynamic> toInsertMap() {
    final map = toMap();
    map['user_id'] = userId;
    return map;
  }
}
