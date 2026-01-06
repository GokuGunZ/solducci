import 'package:solducci/domain/repositories/task_completion_repository.dart';
import 'package:solducci/models/task_completion.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of TaskCompletionRepository
class SupabaseTaskCompletionRepository implements TaskCompletionRepository {
  final SupabaseClient _supabase;

  SupabaseTaskCompletionRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<void> insertCompletion({
    required String taskId,
    required DateTime completedAt,
    String? notes,
  }) async {
    try {
      await _supabase.from('task_completions').insert({
        'task_id': taskId,
        'completed_at': completedAt.toIso8601String(),
        'notes': notes,
      });
      AppLogger.debug('Inserted completion for task: $taskId');
    } catch (e) {
      AppLogger.error('Error inserting completion: $e');
      rethrow;
    }
  }

  @override
  Future<void> markTaskCompleted({
    required String taskId,
    required DateTime completedAt,
  }) async {
    try {
      await _supabase.from('tasks').update({
        'status': TaskStatus.completed.value,
        'completed_at': completedAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
      AppLogger.debug('Marked task completed: $taskId');
    } catch (e) {
      AppLogger.error('Error marking task completed: $e');
      rethrow;
    }
  }

  @override
  Future<void> markTaskPending({
    required String taskId,
  }) async {
    try {
      await _supabase.from('tasks').update({
        'status': TaskStatus.pending.value,
        'completed_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
      AppLogger.debug('Marked task pending: $taskId');
    } catch (e) {
      AppLogger.error('Error marking task pending: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetRecurringTask({
    required String taskId,
    DateTime? nextDueDate,
  }) async {
    try {
      final updateData = {
        'status': TaskStatus.pending.value,
        'completed_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nextDueDate != null) {
        updateData['due_date'] = nextDueDate.toIso8601String();
      }

      await _supabase.from('tasks').update(updateData).eq('id', taskId);
      AppLogger.debug('Reset recurring task: $taskId');
    } catch (e) {
      AppLogger.error('Error resetting recurring task: $e');
      rethrow;
    }
  }

  @override
  Future<List<TaskCompletion>> getCompletionHistory(String taskId) async {
    try {
      final response = await _supabase
          .from('task_completions')
          .select()
          .eq('task_id', taskId)
          .order('completed_at', ascending: false);

      return response.map((map) => TaskCompletion.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Error fetching completion history: $e');
      return [];
    }
  }
}
