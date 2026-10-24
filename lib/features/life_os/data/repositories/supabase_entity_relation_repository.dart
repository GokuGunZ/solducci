import 'dart:async';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/features/life_os/data/mappers/entity_relation_mapper.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/entity_relation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEntityRelationRepository implements EntityRelationRepository {
  final SupabaseClient _supabase;

  SupabaseEntityRelationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<EntityRelation>> getRelationsForSource(String sourceId) async {
    try {
      final response = await _supabase
          .from('entity_relations')
          .select()
          .eq('source_id', sourceId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((row) => EntityRelationMapper.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching relations for source $sourceId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<EntityRelation>> getRelationsForTarget(String targetId, TargetType targetType) async {
    try {
      final response = await _supabase
          .from('entity_relations')
          .select()
          .eq('target_id', targetId)
          .eq('target_type', targetType.value)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((row) => EntityRelationMapper.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching relations for target $targetId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<EntityRelation> createRelation(EntityRelation relation) async {
    try {
      final map = EntityRelationMapper.toMap(relation);
      map.remove('id');

      final response = await _supabase
          .from('entity_relations')
          .insert(map)
          .select()
          .single();

      return EntityRelationMapper.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error creating EntityRelation', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<EntityRelation> updateRelation(EntityRelation relation) async {
    try {
      final map = EntityRelationMapper.toMap(relation);
      final response = await _supabase
          .from('entity_relations')
          .update(map)
          .eq('id', relation.id)
          .select()
          .single();

      return EntityRelationMapper.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating EntityRelation ${relation.id}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteRelation(String id) async {
    try {
      await _supabase.from('entity_relations').delete().eq('id', id);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting EntityRelation $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteRelationsBySource(String sourceId) async {
    try {
      await _supabase.from('entity_relations').delete().eq('source_id', sourceId);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting EntityRelations for source $sourceId', e, stackTrace);
      rethrow;
    }
  }
}
