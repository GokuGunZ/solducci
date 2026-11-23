import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/features/life_os/data/mappers/mappers.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';

void main() {
  group('LifeEntityMapper Tests', () {
    test('Absent metadata falls back to clean domain defaults', () {
      final entity = LifeEntityMapper.fromMap(
        id: 'ent-1',
        title: 'Voglio fare un maglione oversize',
        createdAt: DateTime.parse('2026-10-01T10:00:00.000Z'),
        updatedAt: DateTime.parse('2026-10-01T10:00:00.000Z'),
        metadata: null,
      );

      expect(entity.semanticRole, equals(SemanticRole.seed));
      expect(entity.lifecycleState, equals(LifecycleState.active));
      expect(entity.currentMode, isNull);
      expect(entity.lastMeaningfulActivityAt, isNull);
      expect(entity.customMetadata, isEmpty);
    });

    test('Namespaced metadata parsed correctly and isolated from customMetadata', () {
      final rawMap = {
        'color': '#6366F1',
        'life_os': {
          'version': 1,
          'semantic_role': 'project',
          'lifecycle_state': 'paused',
          'current_mode': 'exploration',
          'last_meaningful_activity_at': '2026-10-15T12:00:00.000Z',
        },
        'custom_tag': 'experimental',
      };

      final entity = LifeEntityMapper.fromMap(
        id: 'agrivoltaico-1',
        title: 'Agrivoltaico',
        description: 'Studio fattibilità terreni',
        createdAt: DateTime.parse('2026-08-01T10:00:00.000Z'),
        updatedAt: DateTime.parse('2026-10-15T12:00:00.000Z'),
        metadata: rawMap,
      );

      expect(entity.semanticRole, equals(SemanticRole.project));
      expect(entity.lifecycleState, equals(LifecycleState.paused));
      expect(entity.currentMode, equals(OperationMode.exploration));
      expect(entity.lastMeaningfulActivityAt,
          equals(DateTime.parse('2026-10-15T12:00:00.000Z')));
      expect(entity.customMetadata['color'], equals('#6366F1'));
      expect(entity.customMetadata['custom_tag'], equals('experimental'));
      expect(entity.customMetadata.containsKey('life_os'), isFalse);
    });

    test('Round-trip preserves all fields faithfully', () {
      final original = LifeEntity(
        id: 'cubing-1',
        userId: 'user-123',
        title: 'Speedcubing Practice',
        description: 'CFOP sub-12 training',
        semanticRole: SemanticRole.practice,
        lifecycleState: LifecycleState.active,
        currentMode: OperationMode.practice,
        createdAt: DateTime.parse('2026-09-01T08:00:00.000Z'),
        updatedAt: DateTime.parse('2026-10-20T14:30:00.000Z'),
        lastMeaningfulActivityAt: DateTime.parse('2026-10-20T14:30:00.000Z'),
        customMetadata: const {'target_avg': 11.5},
      );

      final doc = LifeEntityMapper.toDocument(original);
      final restored = LifeEntityMapper.fromDocument(doc);

      expect(restored, equals(original));
    });
  });

  group('EntityRelation & Session Mappers', () {
    test('EntityRelation round-trip with contextStatus blocker', () {
      final relation = EntityRelation(
        id: 'rel-1',
        userId: 'user-1',
        sourceId: 'solducci-proj',
        sourceType: TargetType.entity,
        targetType: TargetType.entity,
        targetId: 'gdpr-concept',
        relationType: RelationType.requires,
        contextStatus: ContextStatus.blocker,
        createdAt: DateTime.parse('2026-10-20T10:00:00.000Z'),
      );

      final map = EntityRelationMapper.toMap(relation);
      final restored = EntityRelationMapper.fromMap(map);

      expect(restored, equals(relation));
      expect(restored.isBlocker, isTrue);
    });

    test('LifeSession round-trip with related entities and metrics', () {
      final session = LifeSession(
        id: 'sess-1',
        userId: 'user-1',
        primaryEntityId: 'cubing-1',
        relatedEntityIds: const ['f2l-concept', 'oll-concept'],
        startedAt: DateTime.parse('2026-10-24T10:00:00.000Z'),
        durationMinutes: 25,
        activitySummary: 'F2L slot lookahead solves',
        metrics: const {'avg': 12.4, 'best': 9.8, 'solves': 30},
        observations: 'Noticeable delay on back-left slot insertions',
        createdAt: DateTime.parse('2026-10-24T10:25:00.000Z'),
      );

      final map = LifeSessionMapper.toMap(session);
      final restored = LifeSessionMapper.fromMap(map);

      expect(restored, equals(session));
      expect(restored.touchesEntity('f2l-concept'), isTrue);
      expect(restored.touchesEntity('cubing-1'), isTrue);
      expect(restored.touchesEntity('unrelated'), isFalse);
    });
  });
}
