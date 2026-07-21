/// Represents the detailed info for a Time Scenario
class TimeScenario {
  final String id;
  final String documentId;
  final String scenarioType; // 'event', 'trip', 'outing', 'availability', 'focus_mode'
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final Map<String, dynamic> visibilityScope;
  final bool hasCountdown;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeScenario({
    required this.id,
    required this.documentId,
    required this.scenarioType,
    required this.startDate,
    this.endDate,
    this.location,
    this.visibilityScope = const {},
    this.hasCountdown = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimeScenario.fromMap(Map<String, dynamic> map) {
    return TimeScenario(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      scenarioType: map['scenario_type'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      location: map['location'] as String?,
      visibilityScope: map['visibility_scope'] != null ? Map<String, dynamic>.from(map['visibility_scope'] as Map) : {},
      hasCountdown: map['has_countdown'] as bool? ?? false,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'scenario_type': scenarioType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'visibility_scope': visibilityScope,
      'has_countdown': hasCountdown,
      'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class TimeScenarioParticipant {
  final String timeScenarioId;
  final String userId;
  final String rsvpStatus; // 'pending', 'attending', 'declined', 'maybe'
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeScenarioParticipant({
    required this.timeScenarioId,
    required this.userId,
    this.rsvpStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimeScenarioParticipant.fromMap(Map<String, dynamic> map) {
    return TimeScenarioParticipant(
      timeScenarioId: map['time_scenario_id'] as String,
      userId: map['user_id'] as String,
      rsvpStatus: map['rsvp_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time_scenario_id': timeScenarioId,
      'user_id': userId,
      'rsvp_status': rsvpStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class TimePoll {
  final String id;
  final String documentId;
  final String title;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimePoll({
    required this.id,
    required this.documentId,
    required this.title,
    this.isClosed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimePoll.fromMap(Map<String, dynamic> map) {
    return TimePoll(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      title: map['title'] as String,
      isClosed: map['is_closed'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'title': title,
      'is_closed': isClosed,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class TimePollOption {
  final String id;
  final String pollId;
  final DateTime proposedStartTime;
  final DateTime? proposedEndTime;
  final DateTime createdAt;

  TimePollOption({
    required this.id,
    required this.pollId,
    required this.proposedStartTime,
    this.proposedEndTime,
    required this.createdAt,
  });

  factory TimePollOption.fromMap(Map<String, dynamic> map) {
    return TimePollOption(
      id: map['id'] as String,
      pollId: map['poll_id'] as String,
      proposedStartTime: DateTime.parse(map['proposed_start_time'] as String),
      proposedEndTime: map['proposed_end_time'] != null ? DateTime.parse(map['proposed_end_time'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'poll_id': pollId,
      'proposed_start_time': proposedStartTime.toIso8601String(),
      'proposed_end_time': proposedEndTime?.toIso8601String(),
    };
  }
}

class TimePollVote {
  final String optionId;
  final String userId;
  final DateTime createdAt;

  TimePollVote({
    required this.optionId,
    required this.userId,
    required this.createdAt,
  });

  factory TimePollVote.fromMap(Map<String, dynamic> map) {
    return TimePollVote(
      optionId: map['option_id'] as String,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'option_id': optionId,
      'user_id': userId,
    };
  }
}
