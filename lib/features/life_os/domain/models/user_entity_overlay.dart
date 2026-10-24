import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/enums.dart';

/// Pure Domain Model for personal, user-specific overlay state on any entity.
/// Amendment B: Single source of truth for all USER-SPECIFIC state.
class UserEntityOverlay extends Equatable {
  final String userId;
  final String entityId;
  final bool isInWeeklyRail;
  final CommitmentWeight? commitmentWeight;
  final Map<String, dynamic> snoozedSignals;
  final DateTime updatedAt;

  const UserEntityOverlay({
    required this.userId,
    required this.entityId,
    this.isInWeeklyRail = false,
    this.commitmentWeight,
    this.snoozedSignals = const {},
    required this.updatedAt,
  });

  bool isSignalSnoozed(String signalId, [DateTime? now]) {
    final expiryStr = snoozedSignals[signalId] as String?;
    if (expiryStr == null) return false;
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return false;
    final current = now ?? DateTime.now();
    return current.isBefore(expiry);
  }

  UserEntityOverlay copyWith({
    String? userId,
    String? entityId,
    bool? isInWeeklyRail,
    CommitmentWeight? Function()? commitmentWeight,
    Map<String, dynamic>? snoozedSignals,
    DateTime? updatedAt,
  }) {
    return UserEntityOverlay(
      userId: userId ?? this.userId,
      entityId: entityId ?? this.entityId,
      isInWeeklyRail: isInWeeklyRail ?? this.isInWeeklyRail,
      commitmentWeight: commitmentWeight != null ? commitmentWeight() : this.commitmentWeight,
      snoozedSignals: snoozedSignals ?? this.snoozedSignals,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        entityId,
        isInWeeklyRail,
        commitmentWeight,
        snoozedSignals,
        updatedAt,
      ];
}
