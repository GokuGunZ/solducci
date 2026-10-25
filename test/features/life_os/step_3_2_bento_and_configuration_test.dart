import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/domain/services/user_property_pack_service.dart';
import 'package:solducci/models/dashboard_config.dart';
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

  group('1. UserPropertyPackService Invariants', () {
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

  group('4. LifeOsPinnedEntityWidget Dimension Semantics & Config', () {
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
            body: LifeOsPinnedEntityWidget(
              def: BentoWidgetDef(
                id: 'pin_2x1',
                type: 'life_os_pinned_entity',
                size: const BentoWidgetSize(2, 1),
                customProps: const {'entity_id': 'pin_e1'},
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
            body: LifeOsPinnedEntityWidget(
              def: BentoWidgetDef(
                id: 'pin_4x2',
                type: 'life_os_pinned_entity',
                size: const BentoWidgetSize(4, 2),
                customProps: const {'entity_id': 'pin_e2'},
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
  });

  group('5. BentoWidgetConfigRegistry Pinned Entity Configuration', () {
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
