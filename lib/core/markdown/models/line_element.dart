import 'package:flutter/material.dart';

/// Supported classifications for Markdown line-level elements.
enum LineMarkerType {
  bullet,
  numbered,
  checkbox,
  quote,
  header,
  codeFence,
  rawText,
}

/// Condition determining when line modifier styling is applied.
enum ModifierCondition {
  always,
  whenChecked,
}

/// Visual modifier applied to a line without altering the Markdown source.
class LineModifierStyle {
  final bool strikethrough;
  final bool underline;
  final bool bold;
  final Color? textColor;
  final Color? backgroundColor;
  final double opacity;
  final ModifierCondition applyCondition;

  const LineModifierStyle({
    this.strikethrough = false,
    this.underline = false,
    this.bold = false,
    this.textColor,
    this.backgroundColor,
    this.opacity = 1.0,
    this.applyCondition = ModifierCondition.always,
  });

  LineModifierStyle copyWith({
    bool? strikethrough,
    bool? underline,
    bool? bold,
    Color? textColor,
    Color? backgroundColor,
    double? opacity,
    ModifierCondition? applyCondition,
  }) {
    return LineModifierStyle(
      strikethrough: strikethrough ?? this.strikethrough,
      underline: underline ?? this.underline,
      bold: bold ?? this.bold,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      opacity: opacity ?? this.opacity,
      applyCondition: applyCondition ?? this.applyCondition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'strikethrough': strikethrough,
      'underline': underline,
      'bold': bold,
      'text_color': textColor != null ? '#${textColor!.value.toRadixString(16).padLeft(8, '0').substring(2)}' : null,
      'background_color': backgroundColor != null ? '#${backgroundColor!.value.toRadixString(16).padLeft(8, '0').substring(2)}' : null,
      'opacity': opacity,
      'apply_condition': applyCondition.name,
    };
  }

  factory LineModifierStyle.fromMap(Map<String, dynamic> map) {
    Color? parseHex(String? hex) {
      if (hex == null || hex.isEmpty) return null;
      final clean = hex.replaceAll('#', '');
      return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
    }

    return LineModifierStyle(
      strikethrough: map['strikethrough'] as bool? ?? false,
      underline: map['underline'] as bool? ?? false,
      bold: map['bold'] as bool? ?? false,
      textColor: parseHex(map['text_color'] as String?),
      backgroundColor: parseHex(map['background_color'] as String?),
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      applyCondition: map['apply_condition'] == 'whenChecked'
          ? ModifierCondition.whenChecked
          : ModifierCondition.always,
    );
  }

  /// Default modifier for checked items
  static const checkedDefault = LineModifierStyle(
    strikethrough: true,
    opacity: 0.6,
    applyCondition: ModifierCondition.whenChecked,
  );
}

/// Configuration for binding a line marker to an external domain entity.
class DataSourceBindingConfig {
  final bool isConnected;
  final String targetEntityType; // 'task', 'shopping_list', 'dispensa', etc.
  final String? targetDocumentId;
  final String contextScope; // 'personal', 'group'

  const DataSourceBindingConfig({
    this.isConnected = false,
    this.targetEntityType = 'task',
    this.targetDocumentId,
    this.contextScope = 'personal',
  });

  DataSourceBindingConfig copyWith({
    bool? isConnected,
    String? targetEntityType,
    String? targetDocumentId,
    String? contextScope,
  }) {
    return DataSourceBindingConfig(
      isConnected: isConnected ?? this.isConnected,
      targetEntityType: targetEntityType ?? this.targetEntityType,
      targetDocumentId: targetDocumentId ?? this.targetDocumentId,
      contextScope: contextScope ?? this.contextScope,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_connected': isConnected,
      'target_entity_type': targetEntityType,
      'target_document_id': targetDocumentId,
      'context_scope': contextScope,
    };
  }

  factory DataSourceBindingConfig.fromMap(Map<String, dynamic> map) {
    return DataSourceBindingConfig(
      isConnected: map['is_connected'] as bool? ?? false,
      targetEntityType: map['target_entity_type'] as String? ?? 'task',
      targetDocumentId: map['target_document_id'] as String?,
      contextScope: map['context_scope'] as String? ?? 'personal',
    );
  }
}

/// Unified customization rule for a specific line marker type.
class LineMarkerRule {
  final LineMarkerType markerType;
  final String? customIconName;
  final LineModifierStyle modifier;
  final DataSourceBindingConfig dataSource;

  const LineMarkerRule({
    required this.markerType,
    this.customIconName,
    this.modifier = const LineModifierStyle(),
    this.dataSource = const DataSourceBindingConfig(),
  });

  LineMarkerRule copyWith({
    LineMarkerType? markerType,
    String? customIconName,
    LineModifierStyle? modifier,
    DataSourceBindingConfig? dataSource,
  }) {
    return LineMarkerRule(
      markerType: markerType ?? this.markerType,
      customIconName: customIconName ?? this.customIconName,
      modifier: modifier ?? this.modifier,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'marker_type': markerType.name,
      'custom_icon': customIconName,
      'modifier': modifier.toMap(),
      'data_source': dataSource.toMap(),
    };
  }

  factory LineMarkerRule.fromMap(Map<String, dynamic> map) {
    final mType = LineMarkerType.values.firstWhere(
      (e) => e.name == map['marker_type'],
      orElse: () => LineMarkerType.bullet,
    );
    return LineMarkerRule(
      markerType: mType,
      customIconName: map['custom_icon'] as String?,
      modifier: map['modifier'] != null
          ? LineModifierStyle.fromMap(Map<String, dynamic>.from(map['modifier'] as Map))
          : const LineModifierStyle(),
      dataSource: map['data_source'] != null
          ? DataSourceBindingConfig.fromMap(Map<String, dynamic>.from(map['data_source'] as Map))
          : const DataSourceBindingConfig(),
    );
  }
}

/// Represents an inspected, interactive line extracted from Markdown AST.
class LineElement {
  final String id;
  final int lineIndex;
  final LineMarkerType markerType;
  final String markerRaw;
  final int indentLevel;
  final bool isChecked;
  final String textContent;
  final String rawSourceLine;
  final int headerLevel; // 1 to 6 if header

  const LineElement({
    required this.id,
    required this.lineIndex,
    required this.markerType,
    required this.markerRaw,
    required this.indentLevel,
    this.isChecked = false,
    required this.textContent,
    required this.rawSourceLine,
    this.headerLevel = 0,
  });

  LineElement copyWith({
    String? id,
    int? lineIndex,
    LineMarkerType? markerType,
    String? markerRaw,
    int? indentLevel,
    bool? isChecked,
    String? textContent,
    String? rawSourceLine,
    int? headerLevel,
  }) {
    return LineElement(
      id: id ?? this.id,
      lineIndex: lineIndex ?? this.lineIndex,
      markerType: markerType ?? this.markerType,
      markerRaw: markerRaw ?? this.markerRaw,
      indentLevel: indentLevel ?? this.indentLevel,
      isChecked: isChecked ?? this.isChecked,
      textContent: textContent ?? this.textContent,
      rawSourceLine: rawSourceLine ?? this.rawSourceLine,
      headerLevel: headerLevel ?? this.headerLevel,
    );
  }
}
