import 'package:flutter/material.dart';

/// Recurrence model with two-level frequency configuration
///
/// Level 1 (Intra-day): How many times per day?
/// - Every N hours
/// - At specific times of day
///
/// Level 2 (Inter-day): On which days?
/// - Every N days
/// - Specific days of the week
/// - Specific days of the month
/// - Specific dates of the year
///
/// Recurrence can be attached to either a Task or a Tag.
/// When attached to a Tag, all tasks with that tag inherit the recurrence
/// (unless the task has its own recurrence, which takes priority).
class Recurrence {
  final String id;
  final String? taskId; // Attached to a specific task
  final String? tagId; // Attached to a tag (inherited by all tasks with that tag)

  // ========== Level 1: Intra-day frequency ==========
  int? hourlyFrequency; // Repeat every N hours
  List<TimeOfDay>? specificTimes; // Repeat at specific times (e.g., 08:00, 14:00, 20:00)

  // ========== Level 2: Inter-day frequency ==========
  int? dailyFrequency; // Repeat every N days
  List<int>? weeklyDays; // Days of week (0=Sunday, 1=Monday, ..., 6=Saturday)
  List<int>? monthlyDays; // Days of month (1-31)
  List<String>? yearlyDates; // Dates in 'MM-DD' format (e.g., '01-15', '12-25')

  // ========== Recurrence period ==========
  DateTime startDate;
  DateTime? endDate; // null = infinite recurrence

  final DateTime createdAt;

  Recurrence({
    required this.id,
    this.taskId,
    this.tagId,
    this.hourlyFrequency,
    this.specificTimes,
    this.dailyFrequency,
    this.weeklyDays,
    this.monthlyDays,
    this.yearlyDates,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  }) {
    // Validation: must be attached to either task or tag, not both
    // Allow both to be null during creation (will be set by service)
    assert(
      (taskId != null && tagId == null) ||
      (taskId == null && tagId != null) ||
      (taskId == null && tagId == null),
      'Recurrence must be attached to either a task or a tag, not both',
    );

    // Validation: intra-day frequency
    // Note: Both hourlyFrequency and specificTimes can be null, which means "once per day" (default behavior)
    assert(
      hourlyFrequency == null || hourlyFrequency! > 0,
      'hourlyFrequency must be greater than 0 if specified',
    );
    assert(
      specificTimes == null || specificTimes!.isNotEmpty,
      'specificTimes must not be an empty list if specified',
    );

    // Validation: must have at least one inter-day frequency
    assert(
      dailyFrequency != null ||
          (weeklyDays != null && weeklyDays!.isNotEmpty) ||
          (monthlyDays != null && monthlyDays!.isNotEmpty) ||
          (yearlyDates != null && yearlyDates!.isNotEmpty),
      'Must specify at least one inter-day frequency option',
    );
  }

  /// Check if recurrence is currently active
  bool get isActive {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Check if recurrence is attached to a task
  bool get isTaskRecurrence => taskId != null;

  /// Check if recurrence is attached to a tag
  bool get isTagRecurrence => tagId != null;

  /// Check if recurrence has an end date
  bool get isInfinite => endDate == null;

  /// Get intra-day frequency type
  IntraDayFrequencyType get intraDayType {
    if (hourlyFrequency != null) return IntraDayFrequencyType.hourly;
    if (specificTimes != null) return IntraDayFrequencyType.specific;
    return IntraDayFrequencyType.once;
  }

  /// Get inter-day frequency type
  InterDayFrequencyType get interDayType {
    if (dailyFrequency != null) return InterDayFrequencyType.daily;
    if (weeklyDays != null) return InterDayFrequencyType.weekly;
    if (monthlyDays != null) return InterDayFrequencyType.monthly;
    if (yearlyDates != null) return InterDayFrequencyType.yearly;
    return InterDayFrequencyType.daily;
  }

  /// Get human-readable description of the recurrence
  String getDescription() {
    final parts = <String>[];

    // Intra-day description
    if (hourlyFrequency != null) {
      parts.add('Ogni $hourlyFrequency ${hourlyFrequency == 1 ? 'ora' : 'ore'}');
    } else if (specificTimes != null && specificTimes!.isNotEmpty) {
      final timesStr = specificTimes!.map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}').join(', ');
      parts.add('Alle $timesStr');
    }

    // Inter-day description
    if (dailyFrequency != null) {
      parts.add('ogni ${dailyFrequency == 1 ? 'giorno' : '$dailyFrequency giorni'}');
    } else if (weeklyDays != null && weeklyDays!.isNotEmpty) {
      final dayNames = ['Dom', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'];
      final daysStr = weeklyDays!.map((d) => dayNames[d]).join(', ');
      parts.add('ogni $daysStr');
    } else if (monthlyDays != null && monthlyDays!.isNotEmpty) {
      final daysStr = monthlyDays!.join(', ');
      parts.add('il giorno $daysStr di ogni mese');
    } else if (yearlyDates != null && yearlyDates!.isNotEmpty) {
      parts.add('ogni anno il ${yearlyDates!.join(', ')}');
    }

    return parts.join(', ');
  }

  /// Calculate next occurrence from a given date
  /// Returns null if there is no next occurrence (recurrence ended)
  DateTime? getNextOccurrence([DateTime? from]) {
    final fromDate = from ?? DateTime.now();

    // Check if recurrence is still active
    if (!isActive) return null;
    if (endDate != null && fromDate.isAfter(endDate!)) return null;

    // Start from the beginning if before start date
    DateTime current = fromDate.isBefore(startDate) ? startDate : fromDate;

    // Calculate next day that matches inter-day frequency
    DateTime? nextDay;

    if (dailyFrequency != null) {
      // Every N days
      final daysSinceStart = current.difference(startDate).inDays;
      final remainder = daysSinceStart % dailyFrequency!;
      final daysToAdd = remainder == 0 ? 0 : dailyFrequency! - remainder;
      nextDay = current.add(Duration(days: daysToAdd));
    } else if (weeklyDays != null && weeklyDays!.isNotEmpty) {
      // Specific days of the week
      nextDay = _getNextWeekday(current, weeklyDays!);
    } else if (monthlyDays != null && monthlyDays!.isNotEmpty) {
      // Specific days of the month
      nextDay = _getNextMonthDay(current, monthlyDays!);
    } else if (yearlyDates != null && yearlyDates!.isNotEmpty) {
      // Specific dates of the year
      nextDay = _getNextYearlyDate(current, yearlyDates!);
    }

    if (nextDay == null) return null;

    // Apply intra-day time
    if (specificTimes != null && specificTimes!.isNotEmpty) {
      // Find first time after current time
      for (final time in specificTimes!) {
        final candidate = DateTime(
          nextDay.year,
          nextDay.month,
          nextDay.day,
          time.hour,
          time.minute,
        );
        if (candidate.isAfter(current)) {
          return candidate;
        }
      }
      // All times today have passed, use first time of next occurrence
      final nextDayOccurrence = getNextOccurrence(nextDay.add(const Duration(days: 1)));
      return nextDayOccurrence;
    } else if (hourlyFrequency != null) {
      // Every N hours - calculate next hour boundary
      final hoursSinceStart = current.difference(startDate).inHours;
      final remainder = hoursSinceStart % hourlyFrequency!;
      final hoursToAdd = remainder == 0 ? 0 : hourlyFrequency! - remainder;
      return current.add(Duration(hours: hoursToAdd));
    }

    return nextDay;
  }

  DateTime? _getNextWeekday(DateTime from, List<int> weekdays) {
    final sortedDays = weekdays.toList()..sort();
    final currentWeekday = from.weekday % 7; // Convert to 0=Sunday format

    // Check if there's a matching day later this week
    for (final day in sortedDays) {
      if (day > currentWeekday) {
        final daysToAdd = day - currentWeekday;
        return from.add(Duration(days: daysToAdd));
      }
    }

    // Wrap to next week
    final firstDay = sortedDays.first;
    final daysToAdd = 7 - currentWeekday + firstDay;
    return from.add(Duration(days: daysToAdd));
  }

  DateTime? _getNextMonthDay(DateTime from, List<int> monthDays) {
    final sortedDays = monthDays.toList()..sort();

    // Try to find a day in the current month
    for (final day in sortedDays) {
      if (day >= from.day) {
        try {
          return DateTime(from.year, from.month, day);
        } catch (e) {
          // Invalid date for this month (e.g., Feb 30)
          continue;
        }
      }
    }

    // Try next month
    final nextMonth = from.month == 12 ? 1 : from.month + 1;
    final nextYear = from.month == 12 ? from.year + 1 : from.year;
    for (final day in sortedDays) {
      try {
        return DateTime(nextYear, nextMonth, day);
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  DateTime? _getNextYearlyDate(DateTime from, List<String> yearlyDates) {
    final sortedDates = yearlyDates.toList()..sort();

    for (final dateStr in sortedDates) {
      final parts = dateStr.split('-');
      if (parts.length != 2) continue;

      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      if (month == null || day == null) continue;

      // Try this year
      try {
        final candidate = DateTime(from.year, month, day);
        if (candidate.isAfter(from)) return candidate;
      } catch (e) {
        // Invalid date
      }

      // Try next year
      try {
        return DateTime(from.year + 1, month, day);
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  /// Create Recurrence from Supabase map
  factory Recurrence.fromMap(Map<String, dynamic> map) {
    // Parse specific times from TIME[] array
    List<TimeOfDay>? specificTimes;
    if (map['specific_times'] != null) {
      final timesList = map['specific_times'] as List;
      specificTimes = timesList.map((timeStr) {
        final parts = (timeStr as String).split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    }

    // Parse arrays
    List<int>? weeklyDays;
    if (map['weekly_days'] != null) {
      weeklyDays = (map['weekly_days'] as List).cast<int>();
    }

    List<int>? monthlyDays;
    if (map['monthly_days'] != null) {
      monthlyDays = (map['monthly_days'] as List).cast<int>();
    }

    List<String>? yearlyDates;
    if (map['yearly_dates'] != null) {
      yearlyDates = (map['yearly_dates'] as List).cast<String>();
    }

    return Recurrence(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      tagId: map['tag_id'] as String?,
      hourlyFrequency: map['hourly_frequency'] as int?,
      specificTimes: specificTimes,
      dailyFrequency: map['daily_frequency'] as int?,
      weeklyDays: weeklyDays,
      monthlyDays: monthlyDays,
      yearlyDates: yearlyDates,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert Recurrence to map for Supabase
  Map<String, dynamic> toMap() {
    // Convert TimeOfDay list to TIME[] strings
    List<String>? specificTimesStr;
    if (specificTimes != null) {
      specificTimesStr = specificTimes!
          .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00')
          .toList();
    }

    final map = <String, dynamic>{
      'task_id': taskId,
      'tag_id': tagId,
      'hourly_frequency': hourlyFrequency,
      'specific_times': specificTimesStr,
      'daily_frequency': dailyFrequency,
      'weekly_days': weeklyDays,
      'monthly_days': monthlyDays,
      'yearly_dates': yearlyDates,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };

    // Only include id for updates
    if (id.isNotEmpty && id != '00000000-0000-0000-0000-000000000000') {
      map['id'] = id;
    }

    return map;
  }

  /// Convert to map for insert (without id)
  Map<String, dynamic> toInsertMap() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  /// Create a copy with modified fields
  Recurrence copyWith({
    int? hourlyFrequency,
    List<TimeOfDay>? specificTimes,
    int? dailyFrequency,
    List<int>? weeklyDays,
    List<int>? monthlyDays,
    List<String>? yearlyDates,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Recurrence(
      id: id,
      taskId: taskId,
      tagId: tagId,
      hourlyFrequency: hourlyFrequency ?? this.hourlyFrequency,
      specificTimes: specificTimes ?? this.specificTimes,
      dailyFrequency: dailyFrequency ?? this.dailyFrequency,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      monthlyDays: monthlyDays ?? this.monthlyDays,
      yearlyDates: yearlyDates ?? this.yearlyDates,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'Recurrence(id: $id, ${getDescription()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recurrence && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Intra-day frequency types
enum IntraDayFrequencyType {
  once, // Once per day (default)
  hourly, // Every N hours
  specific, // At specific times
}

/// Inter-day frequency types
enum InterDayFrequencyType {
  daily, // Every N days
  weekly, // Specific days of the week
  monthly, // Specific days of the month
  yearly, // Specific dates of the year
}
