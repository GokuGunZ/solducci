import 'package:solducci/features/life_os/domain/models/models.dart';

abstract class UserEntityOverlayRepository {
  /// Fetch user-specific overlay for an entity (null if not yet created - lazy)
  Future<UserEntityOverlay?> getOverlay(String entityId);

  /// Fetch all overlays where entity is marked in weekly rail
  Future<List<UserEntityOverlay>> getWeeklyRailOverlays();

  /// Save or update an overlay
  Future<UserEntityOverlay> saveOverlay(UserEntityOverlay overlay);

  /// Delete an overlay
  Future<void> deleteOverlay(String entityId);

  /// Toggle weekly rail membership for an entity
  Future<void> setWeeklyRail(String entityId, bool inRail);

  /// Snooze a mirror signal for an entity for a given duration
  Future<void> snoozeSignal(String entityId, String signalId, Duration duration);
}
