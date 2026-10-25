import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/data/mappers/life_entity_mapper.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/views/entity_vitrine_view.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_capture_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_recent_seeds_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_active_entities_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_pinned_entity_widget.dart';

/// In-memory mock repositories for testing Step 3 Everyday Integration
class MockLifeEntityRepository implements LifeEntityRepository {
  final Map<String, LifeEntity> _store = {};

  @override
  Future<LifeEntity> createEntity(LifeEntity entity) async {
    _store[entity.id] = entity;
    return entity;
  }

  @override
  Future<LifeEntity?> getEntityById(String id) async => _store[id];

  @override
  Future<List<LifeEntity>> getEntities({
    String? groupId,
    bool isPersonal = false,
    SemanticRole? role,
    LifecycleState? lifecycle,
  }) async {
    return _store.values.where((e) {
      if (role != null && e.semanticRole != role) return false;
      if (lifecycle != null && e.lifecycleState != lifecycle) return false;
      return true;
    }).toList();
  }

  @override
  Future<LifeEntity> updateEntity(LifeEntity entity) async {
    _store[entity.id] = entity;
    return entity;
  }

  @override
  Future<void> deleteEntity(String id) async => _store.remove(id);

  @override
  Stream<List<LifeEntity>> watchEntities({String? groupId, bool isPersonal = false}) {
    return Stream.value(_store.values.toList());
  }

  @override
  Future<void> updateMeaningfulActivity(String entityId, DateTime activityTime) async {
    final current = _store[entityId];
    if (current != null) {
      _store[entityId] = current.copyWith(
        lastMeaningfulActivityAt: () => activityTime,
      );
    }
  }

  @override
  Future<DateTime?> recalculateMeaningfulActivity(String entityId) async {
    return _store[entityId]?.lastMeaningfulActivityAt;
  }
}

class MockEntityRelationRepository implements EntityRelationRepository {
  final Map<String, EntityRelation> _relations = {};

  @override
  Future<EntityRelation> createRelation(EntityRelation relation) async {
    _relations[relation.id] = relation;
    return relation;
  }

  @override
  Future<List<EntityRelation>> getRelationsForSource(String sourceId) async {
    return _relations.values.where((r) => r.sourceId == sourceId).toList();
  }

  @override
  Future<List<EntityRelation>> getRelationsForTarget(String targetId, TargetType targetType) async {
    return _relations.values
        .where((r) => r.targetId == targetId && r.targetType == targetType)
        .toList();
  }

  @override
  Future<EntityRelation> updateRelation(EntityRelation relation) async {
    _relations[relation.id] = relation;
    return relation;
  }

  @override
  Future<void> deleteRelation(String relationId) async {
    _relations.remove(relationId);
  }

  @override
  Future<void> deleteRelationsBySource(String sourceId) async {
    _relations.removeWhere((id, r) => r.sourceId == sourceId);
  }
}

class MockUserEntityOverlayRepository implements UserEntityOverlayRepository {
  final Map<String, UserEntityOverlay> _overlays = {};

  @override
  Future<UserEntityOverlay?> getOverlay(String entityId) async => _overlays[entityId];

  @override
  Future<UserEntityOverlay> saveOverlay(UserEntityOverlay overlay) async {
    _overlays[overlay.entityId] = overlay;
    return overlay;
  }

  @override
  Future<List<UserEntityOverlay>> getWeeklyRailOverlays() async =>
      _overlays.values.where((o) => o.isInWeeklyRail).toList();

  @override
  Future<void> deleteOverlay(String entityId) async {
    _overlays.remove(entityId);
  }

  @override
  Future<void> setWeeklyRail(String entityId, bool inRail) async {
    final current = _overlays[entityId] ??
        UserEntityOverlay(
          entityId: entityId,
          userId: 'test-user',
          updatedAt: DateTime.now(),
        );
    _overlays[entityId] = current.copyWith(
      isInWeeklyRail: inRail,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> snoozeSignal(String entityId, String signalId, Duration duration) async {}
}

void main() {
  late MockLifeEntityRepository mockEntityRepo;
  late MockEntityRelationRepository mockRelationRepo;
  late MockUserEntityOverlayRepository mockOverlayRepo;

  setUp(() {
    mockEntityRepo = MockLifeEntityRepository();
    mockRelationRepo = MockEntityRelationRepository();
    mockOverlayRepo = MockUserEntityOverlayRepository();

    if (getIt.isRegistered<LifeEntityRepository>()) {
      getIt.unregister<LifeEntityRepository>();
    }
    if (getIt.isRegistered<EntityRelationRepository>()) {
      getIt.unregister<EntityRelationRepository>();
    }
    if (getIt.isRegistered<UserEntityOverlayRepository>()) {
      getIt.unregister<UserEntityOverlayRepository>();
    }

    getIt.registerSingleton<LifeEntityRepository>(mockEntityRepo);
    getIt.registerSingleton<EntityRelationRepository>(mockRelationRepo);
    getIt.registerSingleton<UserEntityOverlayRepository>(mockOverlayRepo);
  });

  group('Step 3: Progressive Properties Domain Invariants (INT-D016)', () {
    test('1. Role Change preserves existing properties non-destructively', () {
      final initialProject = LifeEntity(
        id: 'proj-gdpr',
        title: 'Capire auth GDPR per Solducci',
        semanticRole: SemanticRole.project,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        properties: const [
          EntityProperty(
            key: 'goal',
            label: 'Obiettivo',
            value: 'Autenticazione senza frizioni conforme GDPR',
          ),
          EntityProperty(
            key: 'deadline',
            label: 'Scadenza',
            value: '2026-11-15',
            type: PropertyType.date,
          ),
          EntityProperty(
            key: 'next_step',
            label: 'Prossimo Passo',
            value: 'Mappare retention policy',
          ),
        ],
      );

      // Change role to concept
      final concept = initialProject.copyWith(semanticRole: SemanticRole.concept);

      expect(concept.semanticRole, equals(SemanticRole.concept));
      expect(concept.properties.length, equals(3));
      expect(concept.properties.firstWhere((p) => p.key == 'goal').value,
          equals('Autenticazione senza frizioni conforme GDPR'));
      expect(concept.properties.firstWhere((p) => p.key == 'deadline').value,
          equals('2026-11-15'));
      expect(concept.properties.firstWhere((p) => p.key == 'next_step').value,
          equals('Mappare retention policy'));
    });

    test('2. Property Identity and Reuse: reuses existing key without duplicate goal_2', () {
      final initial = LifeEntity(
        id: 'e-1',
        title: 'Esplorazione Agrivoltaico',
        semanticRole: SemanticRole.idea,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        properties: const [
          EntityProperty(key: 'spark', label: 'Intuizione', value: 'Pannelli bifacciali'),
        ],
      );

      // Add property with key 'spark' (updated value)
      final existingIndex = initial.properties.indexWhere((p) => p.key == 'spark');
      final newProperties = List<EntityProperty>.from(initial.properties);
      const updatedProp = EntityProperty(key: 'spark', label: 'Intuizione', value: 'Pannelli verticali bifacciali');

      if (existingIndex >= 0) {
        newProperties[existingIndex] = updatedProp;
      } else {
        newProperties.add(updatedProp);
      }

      final updatedEntity = initial.copyWith(properties: newProperties);

      expect(updatedEntity.properties.length, equals(1), reason: 'Must not duplicate existing key');
      expect(updatedEntity.properties.first.value, equals('Pannelli verticali bifacciali'));
    });

    test('2b. upsertProperty on LifeEntity enforces at most one active property per key', () {
      final initial = LifeEntity(
        id: 'e-upsert',
        title: 'Upsert Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final withGoal = initial.upsertProperty(
        const EntityProperty(key: 'goal', label: 'Goal', value: 'First Goal'),
      );
      expect(withGoal.properties.length, equals(1));
      expect(withGoal.properties.first.value, equals('First Goal'));

      final updatedGoal = withGoal.upsertProperty(
        const EntityProperty(key: 'goal', label: 'Goal', value: 'Updated Goal'),
      );
      expect(updatedGoal.properties.length, equals(1), reason: 'Upsert must update existing key');
      expect(updatedGoal.properties.first.value, equals('Updated Goal'));
    });

    test('2c. Canonical PropertyType Codec serializes numbers as JSON numbers and dates as ISO-8601', () {
      const numProp = EntityProperty(
        key: 'duration',
        label: 'Durata',
        value: '42.5',
        type: PropertyType.number,
      );
      final numJson = numProp.toJson();
      expect(numJson['value'], isA<num>());
      expect(numJson['value'], equals(42.5));

      const dateProp = EntityProperty(
        key: 'target_date',
        label: 'Target',
        value: '2026-12-31T18:00:00.000Z',
        type: PropertyType.date,
      );
      final dateJson = dateProp.toJson();
      expect(dateJson['value'], isA<String>());
      expect(dateJson['value'], equals('2026-12-31T18:00:00.000Z'));
    });

    test('2d. LifeEntityMapper handles accidental duplicate keys with Last-Write-Wins deduplication', () {
      final rawMetadata = {
        'life_os': {
          'version': 1,
          'semantic_role': 'project',
          'lifecycle_state': 'active',
          'properties': [
            {'key': 'goal', 'label': 'Obiettivo', 'value': 'Vecchio Obiettivo', 'type': 'text'},
            {'key': 'goal', 'label': 'Obiettivo', 'value': 'Nuovo Obiettivo Vincente', 'type': 'text'},
          ],
        }
      };

      final entity = LifeEntityMapper.fromMap(
        id: 'dup-1',
        title: 'Duplicate Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: rawMetadata,
      );

      expect(entity.properties.length, equals(1), reason: 'Mapper must deduplicate keys');
      expect(entity.properties.first.value, equals('Nuovo Obiettivo Vincente'),
          reason: 'Last-write-wins policy must prevail');
    });

    test('2e. EntityProperty JSON round-trip for text, date, number, url, and malformed input', () {
      // 1. Text round-trip
      const textProp = EntityProperty(
        key: 'summary',
        label: 'Sommario',
        value: 'Testo esplicativo puro',
        type: PropertyType.text,
      );
      final textRoundTrip = EntityProperty.fromJson(textProp.toJson());
      expect(textRoundTrip.key, equals('summary'));
      expect(textRoundTrip.value, equals('Testo esplicativo puro'));
      expect(textRoundTrip.type, equals(PropertyType.text));
      expect(textRoundTrip.displayValue, equals('Testo esplicativo puro'));

      // 2. URL round-trip
      const urlProp = EntityProperty(
        key: 'doc_url',
        label: 'Link',
        value: 'https://lifeos.solducci.app/docs',
        type: PropertyType.url,
      );
      final urlRoundTrip = EntityProperty.fromJson(urlProp.toJson());
      expect(urlRoundTrip.key, equals('doc_url'));
      expect(urlRoundTrip.value, equals('https://lifeos.solducci.app/docs'));
      expect(urlRoundTrip.type, equals(PropertyType.url));

      // 3. Date round-trip
      const dateProp = EntityProperty(
        key: 'deadline',
        label: 'Scadenza',
        value: '2026-11-15T00:00:00.000',
        type: PropertyType.date,
      );
      final dateRoundTrip = EntityProperty.fromJson(dateProp.toJson());
      expect(dateRoundTrip.key, equals('deadline'));
      expect(dateRoundTrip.asDate, isNotNull);
      expect(dateRoundTrip.asDate!.year, equals(2026));
      expect(dateRoundTrip.asDate!.month, equals(11));
      expect(dateRoundTrip.type, equals(PropertyType.date));

      // 4. Number round-trip
      const numProp = EntityProperty(
        key: 'budget',
        label: 'Budget',
        value: 1250.75,
        type: PropertyType.number,
      );
      final numJson = numProp.toJson();
      expect(numJson['value'], isA<num>());
      expect(numJson['value'], equals(1250.75));
      final numRoundTrip = EntityProperty.fromJson(numJson);
      expect(numRoundTrip.key, equals('budget'));
      expect(numRoundTrip.value, isA<num>());
      expect(numRoundTrip.value, equals(1250.75));
      expect(numRoundTrip.asNumber, equals(1250.75));
      expect(numRoundTrip.type, equals(PropertyType.number));

      // 5. Malformed inputs handling
      final malformedNum = EntityProperty.fromJson({
        'key': 'bad_num',
        'label': 'Bad Number',
        'type': 'number',
        'value': 'not-a-valid-num',
      });
      expect(malformedNum.value, equals(0));
      expect(malformedNum.asNumber, equals(0));

      final nullNum = EntityProperty.fromJson({
        'key': 'null_num',
        'label': 'Null Num',
        'type': 'number',
        'value': null,
      });
      expect(nullNum.value, equals(0));

      final malformedDate = EntityProperty.fromJson({
        'key': 'bad_date',
        'label': 'Bad Date',
        'type': 'date',
        'value': 'invalid-date-format',
      });
      expect(malformedDate.value, equals('invalid-date-format'));
      expect(malformedDate.asDate, isNull);

      final unknownType = EntityProperty.fromJson({
        'key': 'unknown',
        'label': 'Unknown',
        'type': 'non_existent_type',
        'value': 'some-value',
      });
      expect(unknownType.type, equals(PropertyType.text));
      expect(unknownType.value, equals('some-value'));
    });

    test('3. Role Property Packs provides non-prescriptive template suggestions', () {
      final projectSuggestions = RolePropertyPacks.getSuggestionsForRole(SemanticRole.project);
      expect(projectSuggestions.map((t) => t.key), containsAll(['goal', 'next_step', 'deadline']));

      final practiceSuggestions = RolePropertyPacks.getSuggestionsForRole(SemanticRole.practice);
      expect(practiceSuggestions.map((t) => t.key), containsAll(['cadence', 'method', 'metric']));

      final conceptSuggestions = RolePropertyPacks.getSuggestionsForRole(SemanticRole.concept);
      expect(conceptSuggestions.map((t) => t.key), containsAll(['understanding', 'open_questions', 'resources']));

      final seedSuggestions = RolePropertyPacks.getSuggestionsForRole(SemanticRole.seed);
      expect(seedSuggestions, isEmpty, reason: 'Seed has no mandatory structure');
    });

    test('4. Sequential Living Content Blocks appended to Entity (INT-D015)', () {
      final entity = LifeEntity(
        id: 'e-living',
        title: 'Architettura LifeOS',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        blocks: [
          EntityBlock(
            id: 'b-1',
            content: 'Verificare retention policy.',
            position: 0,
            createdAt: DateTime.now(),
          ),
          EntityBlock(
            id: 'b-2',
            content: 'Capire diritto alla cancellazione in uno shared group.',
            position: 1,
            createdAt: DateTime.now(),
          ),
        ],
      );

      expect(entity.blocks.length, equals(2));
      expect(entity.blocks[0].content, equals('Verificare retention policy.'));
      expect(entity.blocks[1].content, equals('Capire diritto alla cancellazione in uno shared group.'));
    });

    test('5. LifeEntityMapper round-trip preserves properties and blocks faithfully', () {
      final original = LifeEntity(
        id: 'e-mapper',
        title: 'Test Entity Full',
        description: 'Descrizione principale',
        semanticRole: SemanticRole.project,
        lifecycleState: LifecycleState.active,
        currentMode: OperationMode.exploration,
        createdAt: DateTime(2026, 10, 24, 10, 0),
        updatedAt: DateTime(2026, 10, 24, 11, 0),
        properties: const [
          EntityProperty(key: 'goal', label: 'Obiettivo', value: 'Rilasciare v1'),
          EntityProperty(key: 'deadline', label: 'Data', value: '2026-12-01', type: PropertyType.date),
        ],
        blocks: [
          EntityBlock(
            id: 'b-100',
            content: 'Primo appunto',
            position: 0,
            createdAt: DateTime(2026, 10, 24, 10, 30),
          ),
        ],
      );

      final doc = LifeEntityMapper.toDocument(original);
      final restored = LifeEntityMapper.fromDocument(doc);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.semanticRole, equals(SemanticRole.project));
      expect(restored.currentMode, equals(OperationMode.exploration));
      expect(restored.properties.length, equals(2));
      expect(restored.properties[0].key, equals('goal'));
      expect(restored.properties[0].value, equals('Rilasciare v1'));
      expect(restored.properties[1].key, equals('deadline'));
      expect(restored.properties[1].type, equals(PropertyType.date));
      expect(restored.blocks.length, equals(1));
      expect(restored.blocks[0].id, equals('b-100'));
      expect(restored.blocks[0].content, equals('Primo appunto'));
    });
  });

  group('Step 3: Bento Widgets Integration (INT-D014)', () {
    testWidgets('Universal Capture Widget renders and captures raw seed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.personal(),
              child: LifeOsCaptureWidget(
                def: BentoWidgetDef(
                  id: 'w_cap',
                  type: 'life_os_capture',
                  size: const BentoWidgetSize(2, 1),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cattura Rapida'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Pensiero al volo');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      final created = await mockEntityRepo.getEntities();
      expect(created.length, equals(1));
      expect(created.first.title, equals('Pensiero al volo'));
      expect(created.first.semanticRole, equals(SemanticRole.seed));
      expect(created.first.currentMode, isNull, reason: 'Must default to null currentMode');
    });

    testWidgets('Recent Seeds Widget displays resting seeds with title', (tester) async {
      await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'seed-1',
          title: 'Comprare filo di rame',
          semanticRole: SemanticRole.seed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LifeOsRecentSeedsWidget(
              def: BentoWidgetDef(
                id: 'w_rec',
                type: 'life_os_recent_seeds',
                size: const BentoWidgetSize(2, 2),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Semi Recenti'), findsOneWidget);
      expect(find.text('Comprare filo di rame'), findsOneWidget);
    });

    testWidgets('Active Entities Widget displays projects and practices with role icons', (tester) async {
      await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'proj-1',
          title: 'GDPR Solducci',
          semanticRole: SemanticRole.project,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LifeOsActiveEntitiesWidget(
              def: BentoWidgetDef(
                id: 'w_act',
                type: 'life_os_active_entities',
                size: const BentoWidgetSize(2, 2),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Entità Attive'), findsOneWidget);
      expect(find.text('GDPR Solducci'), findsOneWidget);
      expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    });

    testWidgets('Pinned Entity Widget shows entity details and snippet', (tester) async {
      await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'pin-1',
          title: 'Progetto Speciale',
          description: 'Descrizione del progetto speciale',
          semanticRole: SemanticRole.project,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LifeOsPinnedEntityWidget(
              def: BentoWidgetDef(
                id: 'w_pin',
                type: 'life_os_pinned_entity',
                size: const BentoWidgetSize(2, 2),
                customProps: const {'entity_id': 'pin-1'},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Progetto Speciale'), findsOneWidget);
      expect(find.text('Progetto'), findsOneWidget);
      expect(find.text('Descrizione del progetto speciale'), findsOneWidget);
    });
  });

  group('Step 3: Redesigned Entity Vitrine (View = Edit & Floating Composer)', () {
    testWidgets('Vitrine renders inline editable title, compact chips, and floating composer', (tester) async {
      final entity = LifeEntity(
        id: 'vitrine-test',
        title: 'Esplorazione Modulare',
        description: 'Contesto iniziale',
        semanticRole: SemanticRole.idea,
        currentMode: OperationMode.exploration,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await mockEntityRepo.createEntity(entity);

      await tester.pumpWidget(
        MaterialApp(
          home: EntityVitrineView(
            entityId: 'vitrine-test',
            initialEntity: entity,
            showContextSwitcher: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Title is rendered without premature ellipsis in an inline TextField
      expect(find.text('Esplorazione Modulare'), findsOneWidget);

      // 2. Compact semantic chips are visible under title
      expect(find.text('Idea'), findsOneWidget);
      expect(find.text('Esplorazione'), findsOneWidget);
      expect(find.text('Focus ☆'), findsOneWidget);

      // 3. Floating composer is present at the bottom
      expect(find.byIcon(Icons.add_comment_rounded), findsOneWidget);
      expect(find.text('Aggiungi qualcosa a questa entità...'), findsOneWidget);

      // 4. Add a thought via bottom floating composer
      await tester.enterText(
        find.widgetWithText(TextField, 'Aggiungi qualcosa a questa entità...'),
        'Nuovo pensiero annotato dal vivo',
      );
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      // 5. The new block appears immediately in the living flow
      expect(find.text('Nuovo pensiero annotato dal vivo'), findsOneWidget);

      // 6. Verified in repository
      final saved = await mockEntityRepo.getEntityById('vitrine-test');
      expect(saved?.blocks.length, equals(1));
      expect(saved?.blocks.first.content, equals('Nuovo pensiero annotato dal vivo'));
    });

    testWidgets('Existing content block can be edited inline in place without modal forms (View = Edit)', (tester) async {
      final entity = LifeEntity(
        id: 'vitrine-edit-block',
        title: 'Entità con Blocco',
        semanticRole: SemanticRole.project,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        blocks: [
          EntityBlock(
            id: 'b-edit',
            content: 'Testo iniziale del blocco',
            position: 0,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await mockEntityRepo.createEntity(entity);

      await tester.pumpWidget(
        MaterialApp(
          home: EntityVitrineView(
            entityId: 'vitrine-edit-block',
            initialEntity: entity,
            showContextSwitcher: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Testo iniziale del blocco'), findsOneWidget);

      // Open menu on block and select edit
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifica blocco'));
      await tester.pumpAndSettle();

      // Enter updated content in the inline editor
      await tester.enterText(
        find.widgetWithText(TextField, 'Testo iniziale del blocco'),
        'Testo corretto dal vivo',
      );

      // Save inline
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      // Verify updated content visible
      expect(find.text('Testo corretto dal vivo'), findsOneWidget);

      // Verify in repository
      final updated = await mockEntityRepo.getEntityById('vitrine-edit-block');
      expect(updated?.blocks.first.content, equals('Testo corretto dal vivo'));
    });
  });
}
