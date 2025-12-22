import 'package:solducci/models/recurrence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing recurrences attached to tasks or tags
/// Handles CRUD operations and recurrence calculations
class RecurrenceService {
  // Singleton pattern
  static final RecurrenceService _instance = RecurrenceService._internal();
  factory RecurrenceService() => _instance;
  RecurrenceService._internal();

  final _supabase = Supabase.instance.client;

  /// Get recurrence for a specific task
  Future<Recurrence?> getRecurrenceForTask(String taskId) async {
    try {
      final response = await _supabase
          .from('recurrences')
          .select()
          .eq('task_id', taskId)
          .maybeSingle();

      if (response == null) return null;

      return Recurrence.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Get recurrence for a specific tag
  Future<Recurrence?> getRecurrenceForTag(String tagId) async {
    try {
      final response = await _supabase
          .from('recurrences')
          .select()
          .eq('tag_id', tagId)
          .maybeSingle();

      if (response == null) return null;

      return Recurrence.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Get all recurrences for tasks
  Future<List<Recurrence>> getAllTaskRecurrences() async {
    try {
      final response = await _supabase
          .from('recurrences')
          .select()
          .not('task_id', 'is', null);

      return _parseRecurrences(response);
    } catch (e) {
      return [];
    }
  }

  /// Get all recurrences for tags
  Future<List<Recurrence>> getAllTagRecurrences() async {
    try {
      final response = await _supabase
          .from('recurrences')
          .select()
          .not('tag_id', 'is', null);

      return _parseRecurrences(response);
    } catch (e) {
      return [];
    }
  }

  /// Get active recurrences (within start and end date range)
  Future<List<Recurrence>> getActiveRecurrences() async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('recurrences')
          .select()
          .lte('start_date', now)
          .or('end_date.is.null,end_date.gte.$now');

      return _parseRecurrences(response);
    } catch (e) {
      return [];
    }
  }

  /// Create a new recurrence
  Future<Recurrence> createRecurrence(Recurrence recurrence) async {
    try {
      // Validation is done in the model constructor via assertions
      final dataToInsert = recurrence.toInsertMap();

      final response = await _supabase
          .from('recurrences')
          .insert(dataToInsert)
          .select()
          .single();

      return Recurrence.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing recurrence
  Future<void> updateRecurrence(Recurrence recurrence) async {
    try {
      // Note: Cannot change task_id or tag_id after creation
      final dataToUpdate = {
        'hourly_frequency': recurrence.hourlyFrequency,
        'specific_times': recurrence.specificTimes?.map((t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00'
        ).toList(),
        'daily_frequency': recurrence.dailyFrequency,
        'weekly_days': recurrence.weeklyDays,
        'monthly_days': recurrence.monthlyDays,
        'yearly_dates': recurrence.yearlyDates,
        'start_date': recurrence.startDate.toIso8601String(),
        'end_date': recurrence.endDate?.toIso8601String(),
        'is_enabled': recurrence.isEnabled,
      };

      await _supabase
          .from('recurrences')
          .update(dataToUpdate)
          .eq('id', recurrence.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a recurrence
  Future<void> deleteRecurrence(String recurrenceId) async {
    try {
      await _supabase
          .from('recurrences')
          .delete()
          .eq('id', recurrenceId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete recurrence for a specific task
  Future<void> deleteRecurrenceForTask(String taskId) async {
    try {
      await _supabase
          .from('recurrences')
          .delete()
          .eq('task_id', taskId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete recurrence for a specific tag
  Future<void> deleteRecurrenceForTag(String tagId) async {
    try {
      await _supabase
          .from('recurrences')
          .delete()
          .eq('tag_id', tagId);
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate next occurrence for a recurrence
  DateTime? calculateNextOccurrence(Recurrence recurrence, [DateTime? from]) {
    return recurrence.getNextOccurrence(from);
  }

  /// Check if a recurrence should trigger on a specific date
  bool shouldTriggerOn(Recurrence recurrence, DateTime date) {
    if (!recurrence.isActive) return false;
    if (date.isBefore(recurrence.startDate)) return false;
    if (recurrence.endDate != null && date.isAfter(recurrence.endDate!)) {
      return false;
    }

    // Check inter-day frequency
    bool matchesInterDay = false;

    if (recurrence.dailyFrequency != null) {
      final daysSinceStart = date.difference(recurrence.startDate).inDays;
      matchesInterDay = daysSinceStart % recurrence.dailyFrequency! == 0;
    } else if (recurrence.weeklyDays != null) {
      final weekday = date.weekday % 7; // Convert to 0=Sunday
      matchesInterDay = recurrence.weeklyDays!.contains(weekday);
    } else if (recurrence.monthlyDays != null) {
      matchesInterDay = recurrence.monthlyDays!.contains(date.day);
    } else if (recurrence.yearlyDates != null) {
      final dateStr = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      matchesInterDay = recurrence.yearlyDates!.contains(dateStr);
    }

    if (!matchesInterDay) return false;

    // Check intra-day frequency
    if (recurrence.specificTimes != null) {
      for (final time in recurrence.specificTimes!) {
        if (date.hour == time.hour && date.minute == time.minute) {
          return true;
        }
      }
      return false;
    } else if (recurrence.hourlyFrequency != null) {
      final hoursSinceStart = date.difference(recurrence.startDate).inHours;
      return hoursSinceStart % recurrence.hourlyFrequency! == 0;
    }

    // Default: matches if inter-day matches and no specific time constraints
    return true;
  }

  /// Get all occurrences for a recurrence within a date range
  List<DateTime> getOccurrencesInRange(
    Recurrence recurrence,
    DateTime startRange,
    DateTime endRange,
  ) {
    final occurrences = <DateTime>[];
    DateTime? current = recurrence.getNextOccurrence(startRange);

    while (current != null && current.isBefore(endRange)) {
      occurrences.add(current);
      current = recurrence.getNextOccurrence(current.add(const Duration(minutes: 1)));
    }

    return occurrences;
  }

  /// Get human-readable description of a recurrence
  String getRecurrenceDescription(Recurrence recurrence) {
    return recurrence.getDescription();
  }

  /// Check if two recurrences conflict (overlap in time)
  bool doRecurrencesConflict(Recurrence r1, Recurrence r2) {
    // Check if date ranges overlap
    if (r1.endDate != null && r2.startDate.isAfter(r1.endDate!)) return false;
    if (r2.endDate != null && r1.startDate.isAfter(r2.endDate!)) return false;

    // If date ranges overlap, there's potential conflict
    // For a more detailed check, we'd need to compare actual occurrences
    return true;
  }

  /// Parse list of recurrence maps to Recurrence objects
  List<Recurrence> _parseRecurrences(List<Map<String, dynamic>> data) {
    final recurrences = <Recurrence>[];
    for (final map in data) {
      try {
        recurrences.add(Recurrence.fromMap(map));
      } catch (e) {
        // Skip recurrences that fail to parse
      }
    }
    return recurrences;
  }

  /// Validate recurrence configuration
  /// Returns null if valid, error message if invalid
  String? validateRecurrence(Recurrence recurrence) {
    try {
      // Check that start date is not in the past (with 1 minute tolerance)
      if (recurrence.startDate.isBefore(
        DateTime.now().subtract(const Duration(minutes: 1)),
      )) {
        return 'Data di inizio non può essere nel passato';
      }

      // Check that end date is after start date
      if (recurrence.endDate != null &&
          recurrence.endDate!.isBefore(recurrence.startDate)) {
        return 'Data di fine deve essere dopo la data di inizio';
      }

      // Check intra-day frequency
      if (recurrence.hourlyFrequency == null &&
          (recurrence.specificTimes == null || recurrence.specificTimes!.isEmpty)) {
        return 'Deve essere specificata una frequenza giornaliera';
      }

      // Check inter-day frequency
      if (recurrence.dailyFrequency == null &&
          (recurrence.weeklyDays == null || recurrence.weeklyDays!.isEmpty) &&
          (recurrence.monthlyDays == null || recurrence.monthlyDays!.isEmpty) &&
          (recurrence.yearlyDates == null || recurrence.yearlyDates!.isEmpty)) {
        return 'Deve essere specificata una frequenza settimanale/mensile/annuale';
      }

      // Validate weekly days (0-6)
      if (recurrence.weeklyDays != null) {
        for (final day in recurrence.weeklyDays!) {
          if (day < 0 || day > 6) {
            return 'Giorni della settimana non validi (devono essere 0-6)';
          }
        }
      }

      // Validate monthly days (1-31)
      if (recurrence.monthlyDays != null) {
        for (final day in recurrence.monthlyDays!) {
          if (day < 1 || day > 31) {
            return 'Giorni del mese non validi (devono essere 1-31)';
          }
        }
      }

      // Validate yearly dates (MM-DD format)
      if (recurrence.yearlyDates != null) {
        for (final dateStr in recurrence.yearlyDates!) {
          final parts = dateStr.split('-');
          if (parts.length != 2) {
            return 'Formato date annuali non valido (deve essere MM-DD)';
          }
          final month = int.tryParse(parts[0]);
          final day = int.tryParse(parts[1]);
          if (month == null || month < 1 || month > 12 ||
              day == null || day < 1 || day > 31) {
            return 'Date annuali non valide';
          }
        }
      }

      return null; // Valid
    } catch (e) {
      return 'Errore di validazione: $e';
    }
  }
}
