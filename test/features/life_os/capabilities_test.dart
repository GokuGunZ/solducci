import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/capabilities/capabilities.dart';

void main() {
  group('ResumeCapability Tests', () {
    test('Recently active project is not resume worthy', () {
      final now = DateTime.now();
      final entity = LifeEntity(
        id: '1',
        title: 'Active Project',
        semanticRole: SemanticRole.project,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
        lastMeaningfulActivityAt: now.subtract(const Duration(days: 2)),
      );

      expect(entity.isResumeWorthy(), isFalse);
    });

    test('Project inactive for > 21 days is resume worthy', () {
      final now = DateTime.now();
      final entity = LifeEntity(
        id: '1',
        title: 'Paused Project',
        semanticRole: SemanticRole.project,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 25)),
        lastMeaningfulActivityAt: now.subtract(const Duration(days: 25)),
      );

      expect(entity.isResumeWorthy(), isTrue);
      expect(entity.inactiveDays, greaterThanOrEqualTo(25));
    });

    test('Seed or archived entity is never resume worthy', () {
      final now = DateTime.now();
      final seed = LifeEntity(
        id: '1',
        title: 'Raw Thought',
        semanticRole: SemanticRole.seed,
        createdAt: now.subtract(const Duration(days: 50)),
        updatedAt: now.subtract(const Duration(days: 50)),
      );

      final archived = LifeEntity(
        id: '2',
        title: 'Old Project',
        semanticRole: SemanticRole.project,
        lifecycleState: LifecycleState.archived,
        createdAt: now.subtract(const Duration(days: 50)),
        updatedAt: now.subtract(const Duration(days: 50)),
      );

      expect(seed.isResumeWorthy(), isFalse);
      expect(archived.isResumeWorthy(), isFalse);
    });
  });

  group('TrendCapability Tests', () {
    test('Extracts numeric trend in chronological order', () {
      final sessions = [
        LifeSession(
          id: '2',
          userId: 'u1',
          primaryEntityId: 'cubing',
          startedAt: DateTime.parse('2026-10-20T10:00:00.000Z'),
          durationMinutes: 20,
          activitySummary: 'Solve block 2',
          metrics: const {'avg': 13.2},
          createdAt: DateTime.now(),
        ),
        LifeSession(
          id: '1',
          userId: 'u1',
          primaryEntityId: 'cubing',
          startedAt: DateTime.parse('2026-10-10T10:00:00.000Z'),
          durationMinutes: 20,
          activitySummary: 'Solve block 1',
          metrics: const {'avg': 14.5},
          createdAt: DateTime.now(),
        ),
        LifeSession(
          id: '3',
          userId: 'u1',
          primaryEntityId: 'cubing',
          startedAt: DateTime.parse('2026-10-24T10:00:00.000Z'),
          durationMinutes: 20,
          activitySummary: 'Solve block 3',
          metrics: const {'avg': 12.1},
          createdAt: DateTime.now(),
        ),
      ];

      expect(sessions.hasTrendFor('avg'), isTrue);
      expect(sessions.hasTrendFor('non_existent'), isFalse);

      final trend = sessions.extractTrendValues('avg');
      expect(trend, equals([14.5, 13.2, 12.1]));
    });
  });
}
