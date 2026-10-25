import 'package:solducci/core/logging/app_logger.dart';
import 'line_element.dart';

/// Out-of-band persistent link binding a Markdown line anchor to an external domain entity.
class LineBindingLink {
  final String anchorKey;
  final String targetEntityType; // 'task', 'shopping_list'
  final String targetEntityId;
  final String lastKnownText;
  final int lastKnownLineIndex;
  final LineSyncState syncState;
  final DateTime updatedAt;

  const LineBindingLink({
    required this.anchorKey,
    required this.targetEntityType,
    required this.targetEntityId,
    required this.lastKnownText,
    required this.lastKnownLineIndex,
    this.syncState = LineSyncState.synced,
    required this.updatedAt,
  });

  LineBindingLink copyWith({
    String? anchorKey,
    String? targetEntityType,
    String? targetEntityId,
    String? lastKnownText,
    int? lastKnownLineIndex,
    LineSyncState? syncState,
    DateTime? updatedAt,
  }) {
    return LineBindingLink(
      anchorKey: anchorKey ?? this.anchorKey,
      targetEntityType: targetEntityType ?? this.targetEntityType,
      targetEntityId: targetEntityId ?? this.targetEntityId,
      lastKnownText: lastKnownText ?? this.lastKnownText,
      lastKnownLineIndex: lastKnownLineIndex ?? this.lastKnownLineIndex,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'anchor_key': anchorKey,
      'target_entity_type': targetEntityType,
      'target_entity_id': targetEntityId,
      'last_known_text': lastKnownText,
      'last_known_line_index': lastKnownLineIndex,
      'sync_state': syncState.name,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LineBindingLink.fromMap(Map<String, dynamic> map) {
    LineSyncState state = LineSyncState.synced;
    if (map['sync_state'] != null) {
      state = LineSyncState.values.firstWhere(
        (e) => e.name == map['sync_state'],
        orElse: () => LineSyncState.synced,
      );
    }

    return LineBindingLink(
      anchorKey: map['anchor_key'] as String? ?? '',
      targetEntityType: map['target_entity_type'] as String? ?? 'task',
      targetEntityId: map['target_entity_id'] as String? ?? '',
      lastKnownText: map['last_known_text'] as String? ?? '',
      lastKnownLineIndex: map['last_known_line_index'] as int? ?? 0,
      syncState: state,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Versioned, persistent configuration for the Advanced Markdown Engine
/// stored within `Document.metadata` JSONB.
class DocumentMarkdownConfig {
  static const String metadataKey = 'markdown_config_v1';
  static const int currentVersion = 1;

  final int schemaVersion;
  final Map<LineMarkerType, LineMarkerRule> rules;
  final Map<String, LineBindingLink> bindings;

  const DocumentMarkdownConfig({
    this.schemaVersion = currentVersion,
    this.rules = const {},
    this.bindings = const {},
  });

  DocumentMarkdownConfig copyWith({
    int? schemaVersion,
    Map<LineMarkerType, LineMarkerRule>? rules,
    Map<String, LineBindingLink>? bindings,
  }) {
    return DocumentMarkdownConfig(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rules: rules ?? this.rules,
      bindings: bindings ?? this.bindings,
    );
  }

  /// Serializes config to a JSON-compatible map suitable for JSONB metadata.
  Map<String, dynamic> toMap() {
    return {
      'version': schemaVersion,
      'rules': rules.map((key, value) => MapEntry(key.name, value.toMap())),
      'bindings': bindings.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  /// Deserializes config from `Document.metadata`, providing resilient fallback
  /// and non-destructive recovery if metadata is missing or partially corrupted.
  factory DocumentMarkdownConfig.fromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || !metadata.containsKey(metadataKey)) {
      return const DocumentMarkdownConfig();
    }

    try {
      final raw = metadata[metadataKey];
      if (raw is! Map) {
        return const DocumentMarkdownConfig();
      }

      final map = Map<String, dynamic>.from(raw);
      final version = map['version'] as int? ?? currentVersion;

      final parsedRules = <LineMarkerType, LineMarkerRule>{};
      if (map['rules'] is Map) {
        final rulesMap = Map<String, dynamic>.from(map['rules'] as Map);
        for (var entry in rulesMap.entries) {
          try {
            final markerType = LineMarkerType.values.firstWhere(
              (e) => e.name == entry.key,
              orElse: () => LineMarkerType.bullet,
            );
            if (entry.value is Map) {
              parsedRules[markerType] = LineMarkerRule.fromMap(
                Map<String, dynamic>.from(entry.value as Map),
              );
            }
          } catch (e) {
            AppLogger.warning('Skipping invalid marker rule for ${entry.key}: $e');
          }
        }
      }

      final parsedBindings = <String, LineBindingLink>{};
      if (map['bindings'] is Map) {
        final bindingsMap = Map<String, dynamic>.from(map['bindings'] as Map);
        for (var entry in bindingsMap.entries) {
          try {
            if (entry.value is Map) {
              parsedBindings[entry.key] = LineBindingLink.fromMap(
                Map<String, dynamic>.from(entry.value as Map),
              );
            }
          } catch (e) {
            AppLogger.warning('Skipping invalid line binding for ${entry.key}: $e');
          }
        }
      }

      return DocumentMarkdownConfig(
        schemaVersion: version,
        rules: parsedRules,
        bindings: parsedBindings,
      );
    } catch (e) {
      AppLogger.error('Failed to parse DocumentMarkdownConfig from metadata: $e');
      return const DocumentMarkdownConfig();
    }
  }

  /// Injects this configuration into an existing Document metadata map without
  /// mutating or removing other metadata fields (e.g. 'color', 'icon', 'priority').
  Map<String, dynamic> applyToMetadata(Map<String, dynamic> existingMetadata) {
    final updated = Map<String, dynamic>.from(existingMetadata);
    updated[metadataKey] = toMap();
    return updated;
  }
}
