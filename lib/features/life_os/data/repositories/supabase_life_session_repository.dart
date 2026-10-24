import 'dart:async';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/features/life_os/data/mappers/life_session_mapper.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/life_session_repository.dart';
import 'package:solducci/features/life_os/domain/repositories/life_entity_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLifeSessionRepository implements LifeSessionRepository {
  final SupabaseClient _supabase;
  final LifeEntityRepository? _entityRepository;

  SupabaseLifeSessionRepository({
    SupabaseClient? supabase,
    LifeEntityRepository? entityRepository,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _entityRepository = entityRepository;

  @override
  Future<List<LifeSession>> getSessionsForEntity(String entityId) async {
    try {
      final response = await _supabase
          .from('life_sessions')
          .select()
          .or('primary_entity_id.eq.$entityId,related_entity_ids.cs.{"$entityId"}')
          .order('started_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((row) => LifeSessionMapper.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching sessions for entity $entityId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<LifeSession>> getUserSessions({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase.from('life_sessions').select();

      if (from != null) {
        query = query.gte('started_at', from.toIso8601String());
      }
      if (to != null) {
        query = query.lte('started_at', to.toIso8601String());
      }

      PostgrestTransformBuilder transformQuery = query.order('started_at', ascending: false);
      if (limit != null && limit > 0) {
        transformQuery = transformQuery.limit(limit);
      }

      final response = await transformQuery;
      final List<dynamic> data = response as List<dynamic>;
      return data.map((row) => LifeSessionMapper.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching user sessions', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<LifeSession?> getSessionById(String id) async {
    try {
      final response = await _supabase
          .from('life_sessions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return LifeSessionMapper.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching session by id $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<LifeSession> createSession(LifeSession session) async {
    try {
      final map = LifeSessionMapper.toMap(session);
      map.remove('id');

      final response = await _supabase
          .from('life_sessions')
          .insert(map)
          .select()
          .single();

      final created = LifeSessionMapper.fromMap(response);

      // Auto-update meaningful activity cache on primary entity
      if (_entityRepository != null) {
        unawaited(
          _entityRepository.updateMeaningfulActivity(
            created.primaryEntityId,
            created.startedAt,
          ).catchError((_) {}),
        );
      }

      return created;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating LifeSession', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<LifeSession> updateSession(LifeSession session) async {
    try {
      final map = LifeSessionMapper.toMap(session);
      final response = await _supabase
          .from('life_sessions')
          .update(map)
          .eq('id', session.id)
          .select()
          .single();

      return LifeSessionMapper.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating LifeSession ${session.id}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      await _supabase.from('life_sessions').delete().eq('id', id);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting LifeSession $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLatestSessionDateForEntity(String entityId) async {
    try {
      final response = await _supabase
          .from('life_sessions')
          .select('started_at')
          .or('primary_entity_id.eq.$entityId,related_entity_ids.cs.{"$entityId"}')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response['started_at'] == null) return null;
      return DateTime.parse(response['started_at'] as String);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting latest session date for $entityId', e, stackTrace);
      return null;
    }
  }
}
