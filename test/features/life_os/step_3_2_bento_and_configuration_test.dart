import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/domain/services/user_property_pack_service.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/expense_view.dart';
import 'package:solducci/widgets/dashboard/config/bento_widget_config_registry.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_capture_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_recent_seeds_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_pinned_entity_widget.dart';

class MockLifeEntityRepo implements LifeEntityRepository {
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
    List<String>? groupIds,
    bool isPersonal = false,
    SemanticRole? role,
    LifecycleState? lifecycle,
  }) async {
    return _store.values.where((e) {
      if (isPersonal && e.groupId != null) return false;
      if (groupIds != null && (e.groupId == null || !groupIds.contains(e.groupId))) return false;
      if (groupId != null && e.groupId != groupId) return false;
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

class MockOverlayRepo implements UserEntityOverlayRepository {
  final Map<String, UserEntityOverlay> _overlays = {};

  @override
  Future<UserEntityOverlay?> getOverlay(String entityId) async => _overlays[entityId];

  @override
  Future<UserEntityOverlay> saveOverlay(UserEntityOverlay overlay) async {
    _overlays[overlay.entityId] = overlay;
    return overlay;
  }

  @override
  Future<List<UserEntityOverlay>> getWeeklyRailOverlays() async {
    return _overlays.values.where((o) => o.isInWeeklyRail).toList();
  }

  @override
  Future<void> deleteOverlay(String entityId) async {
    _overlays.remove(entityId);
  }

  @override
  Future<void> setWeeklyRail(String entityId, bool inRail) async {
    final current = _overlays[entityId] ??
        UserEntityOverlay(
          userId: 'test-user',
          entityId: entityId,
          updatedAt: DateTime.now(),
        );
    _overlays[entityId] = current.copyWith(isInWeeklyRail: inRail);
  }

  @override
  Future<void> snoozeSignal(String entityId, String signalId, Duration duration) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLifeEntityRepo mockEntityRepo;
  late MockOverlayRepo mockOverlayRepo;
  late UserPropertyPackService packService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    packService = UserPropertyPackService();
    if (getIt.isRegistered<UserPropertyPackService>()) {
      getIt.unregister<UserPropertyPackService>();
    }
    getIt.registerSingleton<UserPropertyPackService>(packService);

    mockEntityRepo = MockLifeEntityRepo();
    if (getIt.isRegistered<LifeEntityRepository>()) {
      getIt.unregister<LifeEntityRepository>();
    }
    getIt.registerSingleton<LifeEntityRepository>(mockEntityRepo);

    mockOverlayRepo = MockOverlayRepo();
    if (getIt.isRegistered<UserEntityOverlayRepository>()) {
      getIt.unregister<UserEntityOverlayRepository>();
    }
    getIt.registerSingleton<UserEntityOverlayRepository>(mockOverlayRepo);
  });

  group('1. UserPropertyPackService Invariants & Cross-User Isolation', () {
    test('Loads default suggestions when no user customization exists', () async {
      final projectTemplates = await packService.getTemplatesForRole(SemanticRole.project);
      final projectKeys = projectTemplates.map((t) => t.key).toList();
      expect(projectKeys, containsAll(['goal', 'next_step', 'deadline']));

      final practiceTemplates = await packService.getTemplatesForRole(SemanticRole.practice);
      final practiceKeys = practiceTemplates.map((t) => t.key).toList();
      expect(practiceKeys, containsAll(['cadence', 'method', 'metric']));

      final conceptTemplates = await packService.getTemplatesForRole(SemanticRole.concept);
      final conceptKeys = conceptTemplates.map((t) => t.key).toList();
      expect(conceptKeys, containsAll(['understanding', 'open_questions', 'resources']));
    });

    test('Customizing and saving suggestions persists and updates role suggestions', () async {
      final current = await packService.getTemplatesForRole(SemanticRole.project);
      final updated = [
        ...current,
        const PropertyTemplate(
          key: 'budget',
          label: 'Budget Dedicato',
          placeholder: 'Es. 500€',
          defaultType: PropertyType.number,
        ),
      ];
      await packService.saveTemplatesForRole(SemanticRole.project, updated);

      final fresh = await packService.getTemplatesForRole(SemanticRole.project);
      expect(fresh.any((t) => t.key == 'budget'), isTrue);
      expect(fresh.last.key, equals('budget'));
    });

    test('Reset to defaults restores pristine suggested packs', () async {
      final custom = [
        const PropertyTemplate(
          key: 'custom_only',
          label: 'Custom Only',
          placeholder: '',
          defaultType: PropertyType.text,
        ),
      ];
      await packService.saveTemplatesForRole(SemanticRole.project, custom);
      expect((await packService.getTemplatesForRole(SemanticRole.project)).length, equals(1));

      await packService.resetToDefaults(SemanticRole.project);
      final restored = await packService.getTemplatesForRole(SemanticRole.project);
      final restoredKeys = restored.map((t) => t.key).toList();
      expect(restoredKeys, contains('goal'));
      expect(restoredKeys, isNot(contains('custom_only')));
    });

    test('User A customization != User B customization (cross-device/user isolation)', () async {
      const userA = 'user_uuid_alice';
      const userB = 'user_uuid_bob';

      // Alice customizes Project pack
      final aliceCustom = [
        const PropertyTemplate(
          key: 'alice_kpi',
          label: 'Alice KPI',
          placeholder: 'Target personale',
          defaultType: PropertyType.text,
        ),
      ];
      await packService.saveTemplatesForRole(SemanticRole.project, aliceCustom, userId: userA);

      // Bob loads Project pack - must receive pristine system defaults, NOT Alice's customization
      final bobTemplates = await packService.getTemplatesForRole(SemanticRole.project, userId: userB);
      expect(bobTemplates.any((t) => t.key == 'alice_kpi'), isFalse);
      expect(bobTemplates.map((t) => t.key), contains('goal'));

      // Bob customizes his own pack
      final bobCustom = [
        const PropertyTemplate(
          key: 'bob_budget',
          label: 'Bob Budget',
          placeholder: 'Budget Bob',
          defaultType: PropertyType.number,
        ),
      ];
      await packService.saveTemplatesForRole(SemanticRole.project, bobCustom, userId: userB);

      // Verify Alice still has Alice's pack
      final aliceFresh = await packService.getTemplatesForRole(SemanticRole.project, userId: userA);
      expect(aliceFresh.any((t) => t.key == 'alice_kpi'), isTrue);
      expect(aliceFresh.any((t) => t.key == 'bob_budget'), isFalse);

      // Simulate Logout / Account Switch: clearMemoryCache clears active memory
      packService.clearMemoryCache();

      // After account switch, loading Alice's pack reloads Alice's isolated local projection
      final aliceReloaded = await packService.getTemplatesForRole(SemanticRole.project, userId: userA);
      expect(aliceReloaded.any((t) => t.key == 'alice_kpi'), isTrue);

      final bobReloaded = await packService.getTemplatesForRole(SemanticRole.project, userId: userB);
      expect(bobReloaded.any((t) => t.key == 'bob_budget'), isTrue);
    });
  });

  group('2. LifeOsCaptureWidget Dimension Semantics', () {
    testWidgets('2x1 renders exclusively composer row with [ ∞ Scrivi qualcosa... ↑ ] and zero card headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.personal(),
              child: LifeOsCaptureWidget(
                def: BentoWidgetDef(
                  id: 'cap_2x1',
                  type: 'life_os_capture',
                  size: const BentoWidgetSize(2, 1),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand signature icon ∞
      expect(find.byIcon(Icons.all_inclusive_rounded), findsOneWidget);

      // Input field present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Scrivi qualcosa...'), findsOneWidget);

      // Submit arrow present
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

      // Verify NO extraneous chrome/headers
      expect(find.text('Cattura Rapida'), findsNothing);
      expect(find.text('Life OS'), findsNothing);

      // Enter text and tap submit
      await tester.enterText(find.byType(TextField), 'Idea fulminea in 2x1');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Text field cleared and seed saved
      expect(find.text('Idea fulminea in 2x1'), findsNothing);
      final entities = await mockEntityRepo.getEntities();
      expect(entities.any((e) => e.title == 'Idea fulminea in 2x1' && e.isSeed), isTrue);
    });

    testWidgets('4x1 renders wide pure composer row with zero chrome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.personal(),
              child: LifeOsCaptureWidget(
                def: BentoWidgetDef(
                  id: 'cap_4x1',
                  type: 'life_os_capture',
                  size: const BentoWidgetSize(4, 1),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.all_inclusive_rounded), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cattura un pensiero al volo...'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

      // Verify NO duplicate title headers
      expect(find.text('Cattura Rapida'), findsNothing);
    });

    testWidgets('2x2 renders spacious dominant composer card with ambient ∞', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.personal(),
              child: LifeOsCaptureWidget(
                def: BentoWidgetDef(
                  id: 'cap_2x2',
                  type: 'life_os_capture',
                  size: const BentoWidgetSize(2, 2),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.all_inclusive_rounded), findsOneWidget);
      expect(find.text('Cattura un pensiero, intuizione o seme...'), findsOneWidget);
    });
  });

  group('3. LifeOsRecentSeedsWidget Dimension Semantics', () {
    testWidgets('2x1 renders glanceable mini-banner with latest seed & count badge', (tester) async {
      await mockEntityRepo.createEntity(
        LifeEntity(
          id: 's1',
          title: 'Comprare filo di rame',
          semanticRole: SemanticRole.seed,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          updatedAt: DateTime.now(),
        ),
      );
      await mockEntityRepo.createEntity(
        LifeEntity(
          id: 's2',
          title: 'Idea per nuovo plugin',
          semanticRole: SemanticRole.seed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.personal(),
              child: LifeOsRecentSeedsWidget(
                def: BentoWidgetDef(
                  id: 'seeds_2x1',
                  type: 'life_os_recent_seeds',
                  size: const BentoWidgetSize(2, 1),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Eco icon banner
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
      // Latest seed rendered
      expect(find.text('Idea per nuovo plugin'), findsOneWidget);
      // Total count badge
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('4x2 renders asymmetric split: 35% analytics counter and 65% operational stream', (tester) async {
      await mockEntityRepo.createEntity(
        LifeEntity(
          id: 's1',
          title: 'Seed One',
          semanticRole: SemanticRole.seed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.personal(),
              child: LifeOsRecentSeedsWidget(
                def: BentoWidgetDef(
                  id: 'seeds_4x2',
                  type: 'life_os_recent_seeds',
                  size: const BentoWidgetSize(4, 2),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Left analytics column
      expect(find.text('SEMI'), findsOneWidget);
      expect(find.text('a riposo'), findsOneWidget);
      expect(find.text('Apri LifeOS'), findsOneWidget);

      // Right stream column
      expect(find.text('ULTIME CATTURE'), findsOneWidget);
      expect(find.text('Seed One'), findsOneWidget);
    });
  });

  group('4. LifeOsPinnedEntityWidget Dimension Semantics & Context Protection', () {
    testWidgets('Unconfigured pinned entity renders clear Call to Action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LifeOsPinnedEntityWidget(
              def: BentoWidgetDef(
                id: 'pin_unconf',
                type: 'life_os_pinned_entity',
                size: const BentoWidgetSize(2, 2),
                customProps: const {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tocca per scegliere un\'entità'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    });

    testWidgets('2x1 renders compact identity pill when entity is configured', (tester) async {
      await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'pin_e1',
          title: 'Solducci LifeOS 2.0',
          semanticRole: SemanticRole.project,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.personal(),
              child: LifeOsPinnedEntityWidget(
                def: BentoWidgetDef(
                  id: 'pin_2x1',
                  type: 'life_os_pinned_entity',
                  size: const BentoWidgetSize(2, 1),
                  customProps: const {'entity_id': 'pin_e1'},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Solducci LifeOS 2.0'), findsOneWidget);
      expect(find.text('Progetto'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });

    testWidgets('4x2 renders asymmetric split: 35% dossier and 65% content snippet', (tester) async {
      await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'pin_e2',
          title: 'Architettura Distribuita',
          description: 'Documento sui nodi del cluster',
          semanticRole: SemanticRole.concept,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          blocks: [
            EntityBlock(
              id: 'b1',
              content: 'Primo pensiero su Kafka e CDC',
              position: 0,
              createdAt: DateTime.parse('2026-10-25T01:00:00Z'),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.personal(),
              child: LifeOsPinnedEntityWidget(
                def: BentoWidgetDef(
                  id: 'pin_4x2',
                  type: 'life_os_pinned_entity',
                  size: const BentoWidgetSize(4, 2),
                  customProps: const {'entity_id': 'pin_e2'},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Left Dossier column
      expect(find.text('CONCETTO'), findsOneWidget);
      expect(find.text('Architettura Distribuita'), findsOneWidget);

      // Right Content Snippet column
      expect(find.text('CONTENUTI & PROPRIETÀ'), findsOneWidget);
      expect(find.text('Primo pensiero su Kafka e CDC'), findsOneWidget);
    });

    testWidgets('Context Switch Protection: Pinned entity from Group A displays out-of-context in Group B', (tester) async {
      const groupAId = 'grp_alpha';
      const groupBId = 'grp_beta';

      final groupAEntity = await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'grp_a_entity',
          groupId: groupAId,
          title: 'Strategia Gruppo Alpha',
          semanticRole: SemanticRole.project,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final groupA = ExpenseGroup(
        id: groupAId,
        name: 'Gruppo Alpha',
        createdBy: 'user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final groupB = ExpenseGroup(
        id: groupBId,
        name: 'Gruppo Beta',
        createdBy: 'user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. Mount in Group A context - entity is visible
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.group(groupA),
              child: LifeOsPinnedEntityWidget(
                def: BentoWidgetDef(
                  id: 'pin_ctx',
                  type: 'life_os_pinned_entity',
                  size: const BentoWidgetSize(2, 2),
                  customProps: {'entity_id': groupAEntity.id},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Strategia Gruppo Alpha'), findsOneWidget);
      expect(find.text('Entità fuori dal contesto'), findsNothing);

      // 2. Switch tab to Group B context - entity is out of context
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.group(groupB),
              child: LifeOsPinnedEntityWidget(
                def: BentoWidgetDef(
                  id: 'pin_ctx',
                  type: 'life_os_pinned_entity',
                  size: const BentoWidgetSize(2, 2),
                  customProps: {'entity_id': groupAEntity.id},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Strategia Gruppo Alpha'), findsNothing);
      expect(find.text('Entità fuori dal contesto'), findsOneWidget);

      // 3. Switch back to Group A context - entity is restored
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardContextScope(
              tabContext: ExpenseContext.group(groupA),
              child: LifeOsPinnedEntityWidget(
                def: BentoWidgetDef(
                  id: 'pin_ctx',
                  type: 'life_os_pinned_entity',
                  size: const BentoWidgetSize(2, 2),
                  customProps: {'entity_id': groupAEntity.id},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Strategia Gruppo Alpha'), findsOneWidget);
      expect(find.text('Entità fuori dal contesto'), findsNothing);
    });
  });

  group('5. Bento Context Source & Configuration Audit', () {
    test('Personal, Group, and Aggregated View context filtering in Bento Config Registry', () async {
      // 1. Personal entity
      final personalEntity = await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'ent_personal',
          title: 'Diario Personale',
          semanticRole: SemanticRole.idea,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 2. Group 1 entity
      final group1Entity = await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'ent_g1',
          groupId: 'g1',
          title: 'Progetto Squadra 1',
          semanticRole: SemanticRole.project,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 3. Group 2 entity
      final group2Entity = await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'ent_g2',
          groupId: 'g2',
          title: 'Progetto Squadra 2',
          semanticRole: SemanticRole.project,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Group 1 object
      final g1 = ExpenseGroup(
        id: 'g1',
        name: 'G1',
        createdBy: 'u1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Aggregated View object spanning g1 and g2
      final aggregatedView = ExpenseView(
        id: 'view_1',
        name: 'Progetti Cumulativi',
        groupIds: ['g1', 'g2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test Personal context config: shows only personal entity
      final personalConfig = await BentoWidgetConfigRegistry.getConfigForWidget(
        type: 'life_os_pinned_entity',
      );
      final personalIds = personalConfig.options.map((o) => o.id).toList();
      expect(personalIds, contains(personalEntity.id));
      expect(personalIds, isNot(contains(group1Entity.id)));
      expect(personalIds, isNot(contains(group2Entity.id)));

      // Test Group 1 context
      final groupContext = ExpenseContext.group(g1);
      final g1Entities = await mockEntityRepo.getEntities(
        groupId: groupContext.groupId,
        isPersonal: groupContext.isPersonal,
      );
      expect(g1Entities.map((e) => e.id), contains(group1Entity.id));
      expect(g1Entities.map((e) => e.id), isNot(contains(personalEntity.id)));
      expect(g1Entities.map((e) => e.id), isNot(contains(group2Entity.id)));

      // Test Aggregated View context: shows both g1 and g2 entities
      final viewContext = ExpenseContext.view(aggregatedView);
      final viewEntities = await mockEntityRepo.getEntities(
        groupIds: viewContext.view?.groupIds,
        isPersonal: viewContext.isPersonal,
      );
      expect(viewEntities.map((e) => e.id), containsAll([group1Entity.id, group2Entity.id]));
      expect(viewEntities.map((e) => e.id), isNot(contains(personalEntity.id)));
    });

    test('Context-aware options sort Weekly Rail entities first under focus section', () async {
      final e1 = await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'focus_proj',
          title: 'Progetto Focus Primario',
          semanticRole: SemanticRole.project,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final e2 = await mockEntityRepo.createEntity(
        LifeEntity(
          id: 'regular_proj',
          title: 'Progetto Regolare Backlog',
          semanticRole: SemanticRole.project,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Set e1 as Weekly Rail in overlay
      await mockOverlayRepo.saveOverlay(
        UserEntityOverlay(
          entityId: e1.id,
          userId: 'test-user',
          isInWeeklyRail: true,
          updatedAt: DateTime.now(),
        ),
      );

      final config = await BentoWidgetConfigRegistry.getConfigForWidget(
        type: 'life_os_pinned_entity',
      );

      expect(config.options.length, equals(2));
      // First option is the weekly rail focus entity
      expect(config.options.first.id, equals(e1.id));
      expect(config.options.first.subtitle, contains('NEL TUO FOCUS'));
      expect(config.options.first.props['entity_id'], equals(e1.id));

      // Second option is regular entity
      expect(config.options[1].id, equals(e2.id));
      expect(config.options[1].props['entity_id'], equals(e2.id));
    });
  });
}
