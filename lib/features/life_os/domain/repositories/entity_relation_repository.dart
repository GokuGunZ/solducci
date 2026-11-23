import 'package:solducci/features/life_os/domain/models/models.dart';

abstract class EntityRelationRepository {
  /// Fetch all outgoing relations for a given source entity
  Future<List<EntityRelation>> getRelationsForSource(String sourceId);

  /// Fetch all incoming relations targeting a specific target (polymorphic)
  Future<List<EntityRelation>> getRelationsForTarget(String targetId, TargetType targetType);

  /// Create a new semantic relation edge
  Future<EntityRelation> createRelation(EntityRelation relation);

  /// Update an existing relation edge (e.g. changing contextStatus from blocker to resolved)
  Future<EntityRelation> updateRelation(EntityRelation relation);

  /// Delete a relation edge by ID
  Future<void> deleteRelation(String id);

  /// Delete all relations originating from a source entity
  Future<void> deleteRelationsBySource(String sourceId);
}
