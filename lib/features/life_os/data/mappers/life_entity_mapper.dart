import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/models/document.dart';

/// Centralized mapper between the persistence model [LifeEntityDocument]
/// and the pure domain model [LifeEntity].
///
/// Implements namespaced metadata discipline:
/// metadata['life_os'] = {
///   'version': 1,
///   'semantic_role': 'seed',
///   'lifecycle_state': 'active',
///   'current_mode': null,
///   'last_meaningful_activity_at': null,
/// }
class LifeEntityMapper {
  static const String namespace = 'life_os';
  static const int currentVersion = 1;

  /// Map from persistence DTO to pure domain model
  static LifeEntity fromDocument(LifeEntityDocument doc) {
    return fromMap(
      id: doc.id,
      userId: doc.userId,
      groupId: doc.groupId,
      title: doc.title,
      description: doc.description,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      metadata: doc.metadata,
    );
  }

  /// Map from raw document fields / Supabase row
  static LifeEntity fromMap({
    required String id,
    String? userId,
    String? groupId,
    required String title,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    final meta = metadata ?? {};
    
    // Check for namespaced metadata first, fallback to root for tolerance
    final Map<String, dynamic> lifeOsMeta = meta[namespace] is Map
        ? Map<String, dynamic>.from(meta[namespace] as Map)
        : meta;

    final semanticRoleStr = lifeOsMeta['semantic_role'] as String?;
    final lifecycleStateStr = lifeOsMeta['lifecycle_state'] as String?;
    final currentModeStr = lifeOsMeta['current_mode'] as String?;
    final lastActivityStr = lifeOsMeta['last_meaningful_activity_at'] as String?;

    final propertiesRaw = lifeOsMeta['properties'] as List?;
    final properties = propertiesRaw != null
        ? propertiesRaw
            .whereType<Map>()
            .map((p) => EntityProperty.fromJson(Map<String, dynamic>.from(p)))
            .toList()
        : const <EntityProperty>[];

    final blocksRaw = lifeOsMeta['blocks'] as List?;
    final blocks = blocksRaw != null
        ? blocksRaw
            .whereType<Map>()
            .map((b) => EntityBlock.fromJson(Map<String, dynamic>.from(b)))
            .toList()
        : const <EntityBlock>[];

    // Parse custom metadata excluding the namespaced block
    final customMeta = Map<String, dynamic>.from(meta)..remove(namespace);

    return LifeEntity(
      id: id,
      userId: userId,
      groupId: groupId,
      title: title,
      description: description,
      semanticRole: SemanticRole.fromString(semanticRoleStr),
      lifecycleState: LifecycleState.fromString(lifecycleStateStr),
      currentMode: OperationMode.fromString(currentModeStr),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMeaningfulActivityAt: lastActivityStr != null 
          ? DateTime.tryParse(lastActivityStr) 
          : null,
      properties: properties,
      blocks: blocks,
      customMetadata: customMeta,
    );
  }

  /// Map from pure domain model to persistence DTO
  static LifeEntityDocument toDocument(LifeEntity entity) {
    final meta = Map<String, dynamic>.from(entity.customMetadata);

    // Build namespaced block
    meta[namespace] = {
      'version': currentVersion,
      'semantic_role': entity.semanticRole.value,
      'lifecycle_state': entity.lifecycleState.value,
      'current_mode': entity.currentMode?.value,
      'last_meaningful_activity_at': entity.lastMeaningfulActivityAt?.toIso8601String(),
      'properties': entity.properties.map((p) => p.toJson()).toList(),
      'blocks': entity.blocks.map((b) => b.toJson()).toList(),
    };

    return LifeEntityDocument(
      id: entity.id,
      userId: entity.userId,
      groupId: entity.groupId,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      metadata: meta,
    );
  }

  /// Map from pure domain model to Supabase insert map
  static Map<String, dynamic> toSupabaseMap(LifeEntity entity) {
    final doc = toDocument(entity);
    return doc.toMap();
  }
}
