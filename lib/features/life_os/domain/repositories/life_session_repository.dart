import 'package:solducci/features/life_os/domain/models/models.dart';

abstract class LifeSessionRepository {
  /// Fetch all sessions touching a specific entity (as primary or related)
  Future<List<LifeSession>> getSessionsForEntity(String entityId);

  /// Fetch user's recent sessions, optionally within a time window
  Future<List<LifeSession>> getUserSessions({
    DateTime? from,
    DateTime? to,
    int? limit,
  });

  /// Get a single session by ID
  Future<LifeSession?> getSessionById(String id);

  /// Create and persist a new life session
  Future<LifeSession> createSession(LifeSession session);

  /// Update an existing session
  Future<LifeSession> updateSession(LifeSession session);

  /// Delete a session
  Future<void> deleteSession(String id);

  /// Get the timestamp of the most recent session for an entity
  Future<DateTime?> getLatestSessionDateForEntity(String entityId);
}
