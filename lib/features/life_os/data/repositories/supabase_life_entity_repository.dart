import 'dart:async';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/features/life_os/data/mappers/life_entity_mapper.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/life_entity_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLifeEntityRepository implements LifeEntityRepository {
  final SupabaseClient _supabase;

  SupabaseLifeEntityRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<LifeEntity>> getEntities({
    String? groupId,
    bool isPersonal = false,
    SemanticRole? role,
    LifecycleState? lifecycle,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('documents')
          .select()
          .eq('document_type', 'life_entity');

      if (isPersonal) {
        query = query.isFilter('group_id', null);
      } else if (groupId != null) {
        query = query.eq('group_id', groupId);
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      List<LifeEntity> entities = data.map((row) {
        return LifeEntityMapper.fromMap(
          id: row['id'] as String,
          userId: row['user_id'] as String?,
          groupId: row['group_id'] as String?,
          title: row['title'] as String,
          description: row['description'] as String?,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          metadata: row['metadata'] != null
              ? Map<String, dynamic>.from(row['metadata'] as Map)
              : {},
        );
      }).toList();

      if (role != null) {
        entities = entities.where((e) => e.semanticRole == role).toList();
      }
      if (lifecycle != null) {
        entities = entities.where((e) => e.lifecycleState == lifecycle).toList();
      }

      return entities;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching LifeEntities', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<LifeEntity?> getEntityById(String id) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('id', id)
          .eq('document_type', 'life_entity')
          .maybeSingle();

      if (response == null) return null;

      return LifeEntityMapper.fromMap(
        id: response['id'] as String,
        userId: response['user_id'] as String?,
        groupId: response['group_id'] as String?,
        title: response['title'] as String,
        description: response['description'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
        metadata: response['metadata'] != null
            ? Map<String, dynamic>.from(response['metadata'] as Map)
            : {},
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching LifeEntity by id $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<LifeEntity> createEntity(LifeEntity entity) async {
    try {
      final map = LifeEntityMapper.toSupabaseMap(entity);
      map.remove('id'); // Let DB generate UUID if empty

      final response = await _supabase
          .from('documents')
          .insert(map)
          .select()
          .single();

      return LifeEntityMapper.fromMap(
        id: response['id'] as String,
        userId: response['user_id'] as String?,
        groupId: response['group_id'] as String?,
        title: response['title'] as String,
        description: response['description'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
        metadata: response['metadata'] != null
            ? Map<String, dynamic>.from(response['metadata'] as Map)
            : {},
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error creating LifeEntity', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<LifeEntity> updateEntity(LifeEntity entity) async {
    try {
      final map = LifeEntityMapper.toSupabaseMap(entity);
      final response = await _supabase
          .from('documents')
          .update(map)
          .eq('id', entity.id)
          .select()
          .single();

      return LifeEntityMapper.fromMap(
        id: response['id'] as String,
        userId: response['user_id'] as String?,
        groupId: response['group_id'] as String?,
        title: response['title'] as String,
        description: response['description'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
        metadata: response['metadata'] != null
            ? Map<String, dynamic>.from(response['metadata'] as Map)
            : {},
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error updating LifeEntity ${entity.id}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteEntity(String id) async {
    try {
      await _supabase.from('documents').delete().eq('id', id);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting LifeEntity $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<LifeEntity>> watchEntities({
    String? groupId,
    bool isPersonal = false,
  }) {
    return _supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('document_type', 'life_entity')
        .map((rows) {
          return rows
              .where((row) {
                if (isPersonal) return row['group_id'] == null;
                if (groupId != null) return row['group_id'] == groupId;
                return true;
              })
              .map((row) => LifeEntityMapper.fromMap(
                    id: row['id'] as String,
                    userId: row['user_id'] as String?,
                    groupId: row['group_id'] as String?,
                    title: row['title'] as String,
                    description: row['description'] as String?,
                    createdAt: DateTime.parse(row['created_at'] as String),
                    updatedAt: DateTime.parse(row['updated_at'] as String),
                    metadata: row['metadata'] != null
                        ? Map<String, dynamic>.from(row['metadata'] as Map)
                        : {},
                  ))
              .toList();
        });
  }

  @override
  Future<void> updateMeaningfulActivity(String entityId, DateTime activityTime) async {
    try {
      final current = await getEntityById(entityId);
      if (current == null) return;

      final updated = current.copyWith(
        lastMeaningfulActivityAt: () => activityTime,
      );
      await updateEntity(updated);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating meaningful activity for $entityId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<DateTime?> recalculateMeaningfulActivity(String entityId) async {
    try {
      DateTime? latestActivity;

      // 1. Query latest session touching this entity
      final sessionRes = await _supabase
          .from('life_sessions')
          .select('started_at')
          .or('primary_entity_id.eq.$entityId,related_entity_ids.cs.{"$entityId"}')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (sessionRes != null && sessionRes['started_at'] != null) {
        latestActivity = DateTime.parse(sessionRes['started_at'] as String);
      }

      // 2. Query latest completed task associated with this entity's document
      final taskRes = await _supabase
          .from('tasks')
          .select('completed_at')
          .eq('document_id', entityId)
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (taskRes != null && taskRes['completed_at'] != null) {
        final taskCompleted = DateTime.parse(taskRes['completed_at'] as String);
        if (latestActivity == null || taskCompleted.isAfter(latestActivity)) {
          latestActivity = taskCompleted;
        }
      }

      // Update derived cache on entity
      if (latestActivity != null) {
        await updateMeaningfulActivity(entityId, latestActivity);
      }

      return latestActivity;
    } catch (e, stackTrace) {
      AppLogger.error('Error recalculating meaningful activity for $entityId', e, stackTrace);
      return null;
    }
  }
}
