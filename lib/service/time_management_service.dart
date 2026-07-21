import 'package:solducci/models/time_scenario.dart';
import 'package:solducci/models/routine.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:async/async.dart';

class TimeManagementService {
  static final TimeManagementService _instance = TimeManagementService._internal();
  factory TimeManagementService() => _instance;
  TimeManagementService._internal();

  final _supabase = Supabase.instance.client;
  final _contextManager = ContextManager();

  // ========================================
  // TIME SCENARIOS (Events, Trips, Outings, Radar)
  // ========================================

  /// Stream of Time Scenarios based on the current context
  Stream<List<TimeScenario>> get timeScenariosStream {
    final context = _contextManager.currentContext;
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return Stream.value([]);

    // We join with the documents table to check group_id/user_id 
    // since time_scenarios inherits access via documents.
    // For now, simpler: we just fetch all scenarios the user has access to
    // (RLS handles the row filtering automatically) and then filter by context.
    
    return _supabase
        .from('time_scenarios')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((map) => TimeScenario.fromMap(map)).toList());
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
  Future<void> createTimeScenario(TimeScenario scenario) async {
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

      await _supabase.from('time_scenarios').insert(scenarioData);
    } catch (e) {
      rethrow;
    }
  }

  /// Update Time Scenario
  Future<void> updateTimeScenario(TimeScenario scenario) async {
    try {
      await _supabase
          .from('time_scenarios')
          .update(scenario.toMap())
          .eq('id', scenario.id);
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
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<TimeScenarioParticipant>> getParticipantsStream(String timeScenarioId) {
    return _supabase
        .from('time_scenario_participants')
        .stream(primaryKey: ['time_scenario_id', 'user_id'])
        .eq('time_scenario_id', timeScenarioId)
        .map((data) => data.map((map) => TimeScenarioParticipant.fromMap(map)).toList());
  }

  // ========================================
  // ROUTINES & ALARMS
  // ========================================

  Stream<List<RoutineTemplate>> get routinesStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('routine_templates')
        .stream(primaryKey: ['id'])
        // RLS handles visibility (own + group shared)
        .map((data) => data.map((map) => RoutineTemplate.fromMap(map)).toList());
  }

  Stream<List<RoutineAlarm>> getAlarmsStream(String templateId) {
    return _supabase
        .from('routine_alarms')
        .stream(primaryKey: ['id'])
        .eq('routine_template_id', templateId)
        .order('offset_minutes', ascending: true)
        .map((data) => data.map((map) => RoutineAlarm.fromMap(map)).toList());
  }

  Stream<List<RoutineSchedule>> getSchedulesStream(String templateId) {
    return _supabase
        .from('routine_schedules')
        .stream(primaryKey: ['id'])
        .eq('routine_template_id', templateId)
        .map((data) => data.map((map) => RoutineSchedule.fromMap(map)).toList());
  }

  Future<void> toggleRoutinePauseForToday(RoutineSchedule schedule) async {
    try {
      final now = DateTime.now();
      // If already paused for today, unpause. Else, pause.
      final isCurrentlyPaused = schedule.isPausedForToday != null &&
          schedule.isPausedForToday!.year == now.year &&
          schedule.isPausedForToday!.month == now.month &&
          schedule.isPausedForToday!.day == now.day;

      await _supabase.from('routine_schedules').update({
        'is_paused_for_today': isCurrentlyPaused ? null : now.toIso8601String(),
      }).eq('id', schedule.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createRoutineTemplate(RoutineTemplate template, List<RoutineSchedule> schedules) async {
    try {
      final response = await _supabase.from('routine_templates').insert(template.toMap()).select().single();
      final generatedId = response['id'] as String;
      
      for (var schedule in schedules) {
        final scheduleMap = schedule.toMap();
        scheduleMap['routine_template_id'] = generatedId;
        await _supabase.from('routine_schedules').insert(scheduleMap);
      }
    } catch (e) {
      rethrow;
    }
  }
}
