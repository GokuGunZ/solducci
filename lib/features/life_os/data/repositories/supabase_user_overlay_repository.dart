import 'dart:async';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/features/life_os/data/mappers/user_entity_overlay_mapper.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/user_entity_overlay_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserOverlayRepository implements UserEntityOverlayRepository {
  final SupabaseClient _supabase;

  SupabaseUserOverlayRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<UserEntityOverlay?> getOverlay(String entityId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('user_entity_overlays')
          .select()
          .eq('user_id', user.id)
          .eq('entity_id', entityId)
          .maybeSingle();

      if (response == null) return null;
      return UserEntityOverlayMapper.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching overlay for entity $entityId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<UserEntityOverlay>> getWeeklyRailOverlays() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('user_entity_overlays')
          .select()
          .eq('user_id', user.id)
          .eq('is_in_weekly_rail', true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((row) => UserEntityOverlayMapper.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching weekly rail overlays', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserEntityOverlay> saveOverlay(UserEntityOverlay overlay) async {
    try {
      final map = UserEntityOverlayMapper.toMap(overlay);
      final response = await _supabase
          .from('user_entity_overlays')
          .upsert(map)
          .select()
          .single();

      return UserEntityOverlayMapper.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving overlay for entity ${overlay.entityId}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteOverlay(String entityId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_entity_overlays')
          .delete()
          .eq('user_id', user.id)
          .eq('entity_id', entityId);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting overlay for entity $entityId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setWeeklyRail(String entityId, bool inRail) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final existing = await getOverlay(entityId);
      final overlay = (existing ??
              UserEntityOverlay(
                userId: user.id,
                entityId: entityId,
                updatedAt: DateTime.now(),
              ))
          .copyWith(
        isInWeeklyRail: inRail,
        updatedAt: DateTime.now(),
      );

      await saveOverlay(overlay);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating weekly rail for entity $entityId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> snoozeSignal(String entityId, String signalId, Duration duration) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final existing = await getOverlay(entityId);
      final expiry = DateTime.now().add(duration).toIso8601String();
      final updatedSnoozes = Map<String, dynamic>.from(existing?.snoozedSignals ?? {})
        ..[signalId] = expiry;

      final overlay = (existing ??
              UserEntityOverlay(
                userId: user.id,
                entityId: entityId,
                updatedAt: DateTime.now(),
              ))
          .copyWith(
        snoozedSignals: updatedSnoozes,
        updatedAt: DateTime.now(),
      );

      await saveOverlay(overlay);
    } catch (e, stackTrace) {
      AppLogger.error('Error snoozing signal $signalId for entity $entityId', e, stackTrace);
      rethrow;
    }
  }
}
