import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/capabilities/capabilities.dart';

void main() {
  group('LifeEntity Domain Invariants', () {
    test('Raw seed capture has null currentMode by default (Amendment A)', () {
      final entity = LifeEntity(
        id: 'seed-1',
        title: 'Comprare filo di rame',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(entity.semanticRole, equals(SemanticRole.seed));
      expect(entity.lifecycleState, equals(LifecycleState.active));
      expect(entity.currentMode, isNull,
          reason: 'Absence of mode is valid domain structure');
    });

    test('Semantic role and lifecycle are independent dimensions', () {
      final project = LifeEntity(
        id: 'proj-1',
        title: 'Solducci',
        semanticRole: SemanticRole.project,
        lifecycleState: LifecycleState.archived,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(project.semanticRole, equals(SemanticRole.project));
      expect(project.lifecycleState, equals(LifecycleState.archived));
      expect(project.isProject, isTrue);
      expect(project.isArchived, isTrue);
      expect(project.semanticRole, isNot(equals(SemanticRole.idea)),
          reason: 'Archiving a project does not transform it into an idea');
    });

    test('State transition validation obeys lifecycle rules', () {
      final active = LifeEntity(
        id: '1',
        title: 'Active',
        lifecycleState: LifecycleState.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(active.canTransitionTo(LifecycleState.paused), isTrue);
      expect(active.canTransitionTo(LifecycleState.completed), isTrue);
      expect(active.canTransitionTo(LifecycleState.archived), isTrue);
      expect(active.canTransitionTo(LifecycleState.active), isFalse);

      final archived = active.copyWith(lifecycleState: LifecycleState.archived);
      expect(archived.canTransitionTo(LifecycleState.active), isTrue);
      expect(archived.canTransitionTo(LifecycleState.paused), isFalse);
    });

    test('UserEntityOverlay maintains single source of truth for user state (Amendment B)', () {
      final now = DateTime.now();
      final overlay = UserEntityOverlay(
        userId: 'user-a',
        entityId: 'shared-proj-1',
        isInWeeklyRail: true,
        commitmentWeight: CommitmentWeight.high,
        snoozedSignals: {
          'inactivity': now.add(const Duration(days: 7)).toIso8601String(),
        },
        updatedAt: now,
      );

      expect(overlay.isInWeeklyRail, isTrue);
      expect(overlay.commitmentWeight, equals(CommitmentWeight.high));
      expect(overlay.isSignalSnoozed('inactivity', now), isTrue);
      expect(
          overlay.isSignalSnoozed(
              'inactivity', now.add(const Duration(days: 8))),
          isFalse);
    });
  });
}
