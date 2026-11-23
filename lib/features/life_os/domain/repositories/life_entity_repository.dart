import 'package:solducci/features/life_os/domain/models/models.dart';

abstract class LifeEntityRepository {
  /// Fetch all entities matching context criteria
  Future<List<LifeEntity>> getEntities({
    String? groupId,
    List<String>? groupIds,
    bool isPersonal = false,
    SemanticRole? role,
    LifecycleState? lifecycle,
  });

  /// Get single entity by ID
  Future<LifeEntity?> getEntityById(String id);

  /// Create a new LifeEntity
  Future<LifeEntity> createEntity(LifeEntity entity);

  /// Update an existing LifeEntity
  Future<LifeEntity> updateEntity(LifeEntity entity);

  /// Delete an entity by ID
  Future<void> deleteEntity(String id);

  /// Watch entities stream for real-time updates
  Stream<List<LifeEntity>> watchEntities({
    String? groupId,
    bool isPersonal = false,
  });

  /// Update derived last_meaningful_activity_at cache on the entity
  Future<void> updateMeaningfulActivity(String entityId, DateTime activityTime);

  /// Auto-healing: recalculate last meaningful activity from canonical sessions and tasks
  Future<DateTime?> recalculateMeaningfulActivity(String entityId);
}
