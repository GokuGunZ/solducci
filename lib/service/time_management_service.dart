import 'package:solducci/models/time_scenario.dart';
import 'package:solducci/models/routine.dart';
import 'package:solducci/service/context_manager.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:async/async.dart';

class TimeManagementService {
  static final TimeManagementService _instance = TimeManagementService._internal();
  factory TimeManagementService() => _instance;
  TimeManagementService._internal();

  final _supabase = Supabase.instance.client;
  final _contextManager = ContextManager();
  
  // Manual refresh trigger for when Supabase Realtime is disabled
  final _refreshTrigger = StreamController<void>.broadcast();
  void _triggerRefresh() => _refreshTrigger.add(null);

  // ========================================
  // TIME SCENARIOS (Events, Trips, Outings, Radar)
  // ========================================

  /// Stream of Time Scenarios based on the current context
  Stream<List<TimeScenario>> get timeScenariosStream {
    final context = _contextManager.currentContext;
    final userId = _supabase.auth.currentUser?.id;
    final supabaseStream = _supabase
        .from('time_scenarios')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((map) => TimeScenario.fromMap(map)).toList());

    return StreamGroup.merge([
      supabaseStream,
      _refreshTrigger.stream.asyncMap((_) async {
        final data = await _supabase.from('time_scenarios').select();
        return data.map((m) => TimeScenario.fromMap(m)).toList();
      })
    ]);
  }

  /// Get specific TimeScenario details
  Future<TimeScenario?> getScenarioDetails(String documentId) async {
    try {
      final response = await _supabase
          .from('time_scenarios')
          .select()
          .eq('document_id', documentId)
          .maybeSingle();

      if (response == null) return null;
      return TimeScenario.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Create a new Time Scenario detail
  Future<void> createTimeScenario(TimeScenario scenario, {List<TimeScenarioParticipant>? participants}) async {
    try {
      final context = _contextManager.currentContext;
      final userId = _supabase.auth.currentUser?.id;
      
      // 1. Create the parent Document first
      final docData = {
        'document_type': 'time_scenario',
        'title': scenario.title,
        'group_id': context.isGroup ? context.groupId : null,
        'user_id': context.isGroup ? null : userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'metadata': {},
      };

      final docResponse = await _supabase
          .from('documents')
          .insert(docData)
          .select()
          .single();
          
      final newDocumentId = docResponse['id'] as String;

      // 2. Link the generated documentId to the scenario and insert
      final scenarioData = scenario.toMap();
      scenarioData['document_id'] = newDocumentId;

      final response = await _supabase.from('time_scenarios').insert(scenarioData).select().single();
      final generatedId = response['id'] as String;
      
      if (participants != null && participants.isNotEmpty) {
        for (var p in participants) {
          final pMap = p.toMap();
          pMap['time_scenario_id'] = generatedId;
          await _supabase.from('time_scenario_participants').insert(pMap);
        }
      }
      _triggerRefresh();
    } catch (e) {
      rethrow;
    }
  }

  /// Update Time Scenario
  Future<void> updateScenario(TimeScenario scenario) async {
    try {
      await _supabase.from('time_scenarios').update(scenario.toMap()).eq('id', scenario.id);
      _triggerRefresh();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete Time Scenario (also deletes the linked document)
  Future<void> deleteScenario(String id) async {
    try {
      await _supabase.from('time_scenario_participants').delete().eq('time_scenario_id', id);
      await _supabase.from('time_scenarios').delete().eq('id', id);
      _triggerRefresh();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // RSVP (Participants)
  // ========================================

  Future<void> updateRsvp(String timeScenarioId, String status) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('time_scenario_participants').upsert({
        'time_scenario_id': timeScenarioId,
        'user_id': userId,
        'rsvp_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _triggerRefresh();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<TimeScenarioParticipant>> getParticipantsStream(String timeScenarioId) {
    final supabaseStream = _supabase
        .from('time_scenario_participants')
        .stream(primaryKey: ['time_scenario_id', 'user_id'])
        .eq('time_scenario_id', timeScenarioId)
        .map((data) => data.map((map) => TimeScenarioParticipant.fromMap(map)).toList());

    return StreamGroup.merge([
      supabaseStream,
      _refreshTrigger.stream.asyncMap((_) async {
        final data = await _supabase.from('time_scenario_participants').select().eq('time_scenario_id', timeScenarioId);
        return data.map((m) => TimeScenarioParticipant.fromMap(m)).toList();
      })
    ]);
  }

  // ========================================
  // ROUTINES & ALARMS
  // ========================================

  Stream<List<RoutineTemplate>> get routinesStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    final supabaseStream = _supabase
        .from('routine_templates')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((map) => RoutineTemplate.fromMap(map)).toList());

    return StreamGroup.merge([
      supabaseStream,
      _refreshTrigger.stream.asyncMap((_) async {
        final data = await _supabase.from('routine_templates').select();
        return data.map((m) => RoutineTemplate.fromMap(m)).toList();
      })
    ]);
  }

  Stream<List<RoutineAlarm>> getAlarmsStream(String templateId) {
    final supabaseStream = _supabase
        .from('routine_alarms')
        .stream(primaryKey: ['id'])
        .eq('routine_template_id', templateId)
        .order('offset_minutes', ascending: true)
        .map((data) => data.map((map) => RoutineAlarm.fromMap(map)).toList());

    return StreamGroup.merge([
      supabaseStream,
      _refreshTrigger.stream.asyncMap((_) async {
        final data = await _supabase.from('routine_alarms').select().eq('routine_template_id', templateId);
        return data.map((m) => RoutineAlarm.fromMap(m)).toList();
      })
    ]);
  }

  Stream<List<RoutineSchedule>> getSchedulesStream(String templateId) {
    final supabaseStream = _supabase
        .from('routine_schedules')
        .stream(primaryKey: ['id'])
        .eq('routine_template_id', templateId)
        .map((data) => data.map((map) => RoutineSchedule.fromMap(map)).toList());

    return StreamGroup.merge([
      supabaseStream,
      _refreshTrigger.stream.asyncMap((_) async {
        final data = await _supabase.from('routine_schedules').select().eq('routine_template_id', templateId);
        return data.map((m) => RoutineSchedule.fromMap(m)).toList();
      })
    ]);
  }

  Future<void> toggleRoutinePauseForToday(RoutineSchedule schedule) async {
    try {
      final now = DateTime.now();
      final isCurrentlyPaused = schedule.isPausedForToday != null &&
          schedule.isPausedForToday!.year == now.year &&
          schedule.isPausedForToday!.month == now.month &&
          schedule.isPausedForToday!.day == now.day;

      await _supabase.from('routine_schedules').update({
        'is_paused_for_today': isCurrentlyPaused ? null : now.toIso8601String(),
      }).eq('id', schedule.id);
      _triggerRefresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createRoutineTemplate(RoutineTemplate template, List<RoutineSchedule> schedules, List<RoutineAlarm> alarms) async {
    try {
      final response = await _supabase.from('routine_templates').insert(template.toMap()).select().single();
      final generatedId = response['id'] as String;
      
      for (var schedule in schedules) {
        final scheduleMap = schedule.toMap();
        scheduleMap['routine_template_id'] = generatedId;
        await _supabase.from('routine_schedules').insert(scheduleMap);
      }
      
      for (var alarm in alarms) {
        final alarmMap = alarm.toMap();
        alarmMap['routine_template_id'] = generatedId;
        await _supabase.from('routine_alarms').insert(alarmMap);
      }
      _triggerRefresh();
    } catch (e) {
      rethrow;
    }
  }

  /// Update routine template status (active/inactive)
  Future<void> updateRoutineStatus(String id, bool isActive) async {
    try {
      await _supabase.from('routine_templates').update({'is_active': isActive}).eq('id', id);
      _triggerRefresh();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete Routine Template (cascades manually to avoid FK constraint errors)
  Future<void> deleteRoutine(String id) async {
    try {
      await _supabase.from('routine_schedules').delete().eq('routine_template_id', id);
      await _supabase.from('routine_alarms').delete().eq('routine_template_id', id);
      await _supabase.from('routine_templates').delete().eq('id', id);
      _triggerRefresh();
    } catch (e) {
      rethrow;
    }
  }
}
