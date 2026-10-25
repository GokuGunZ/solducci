import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/controllers/life_os_center_cubit.dart';
import 'package:solducci/features/life_os/presentation/controllers/entity_vitrine_cubit.dart';
import 'package:solducci/features/life_os/presentation/controllers/entity_vitrine_state.dart';
import 'package:solducci/features/life_os/presentation/views/life_os_center_view.dart';
import 'package:solducci/features/life_os/presentation/widgets/universal_capture_bar.dart';
import 'package:solducci/features/life_os/presentation/widgets/recent_seeds_section.dart';
import 'package:solducci/features/life_os/presentation/widgets/how_life_os_works_section.dart';

class InMemoryLifeEntityRepository implements LifeEntityRepository {
  final Map<String, LifeEntity> _storage = {};
  bool shouldFailOnCreate = false;
  bool shouldFailOnUpdate = false;

  @override
  Future<List<LifeEntity>> getEntities({
    String? groupId,
    List<String>? groupIds,
    bool isPersonal = false,
    SemanticRole? role,
    LifecycleState? lifecycle,
  }) async {
    return _storage.values.where((e) {
      if (isPersonal && e.groupId != null) return false;
      if (groupIds != null && (e.groupId == null || !groupIds.contains(e.groupId))) return false;
      if (groupId != null && e.groupId != groupId) return false;
      if (role != null && e.semanticRole != role) return false;
      if (lifecycle != null && e.lifecycleState != lifecycle) return false;
      return true;
    }).toList();
  }

  @override
  Future<LifeEntity?> getEntityById(String id) async {
    return _storage[id];
  }

  @override
  Future<LifeEntity> createEntity(LifeEntity entity) async {
    if (shouldFailOnCreate) {
      throw Exception('Network disconnected');
    }
    _storage[entity.id] = entity;
    return entity;
  }

  @override
  Future<LifeEntity> updateEntity(LifeEntity entity) async {
    if (shouldFailOnUpdate) {
      throw Exception('Network disconnected');
    }
    _storage[entity.id] = entity;
    return entity;
  }

  @override
  Future<void> deleteEntity(String id) async {
    _storage.remove(id);
  }

  @override
  Stream<List<LifeEntity>> watchEntities({String? groupId, bool isPersonal = false}) {
    return Stream.value(_storage.values.toList());
  }

  @override
  Future<void> updateMeaningfulActivity(String entityId, DateTime activityTime) async {
    final existing = _storage[entityId];
    if (existing != null) {
      _storage[entityId] = existing.copyWith(
        lastMeaningfulActivityAt: () => activityTime,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<DateTime?> recalculateMeaningfulActivity(String entityId) async {
    return _storage[entityId]?.lastMeaningfulActivityAt;
  }
}

class InMemoryEntityRelationRepository implements EntityRelationRepository {
  final Map<String, EntityRelation> _relations = {};

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
  Future<EntityRelation> createRelation(EntityRelation relation) async {
    _relations[relation.id] = relation;
    return relation;
  }

  @override
  Future<EntityRelation> updateRelation(EntityRelation relation) async {
    _relations[relation.id] = relation;
    return relation;
  }

  @override
  Future<void> deleteRelation(String id) async {
    _relations.remove(id);
  }

  @override
  Future<void> deleteRelationsBySource(String sourceId) async {
    _relations.removeWhere((id, r) => r.sourceId == sourceId);
  }
}

class InMemoryUserOverlayRepository implements UserEntityOverlayRepository {
  final Map<String, UserEntityOverlay> _overlays = {};

  @override
  Future<UserEntityOverlay?> getOverlay(String entityId) async {
    return _overlays[entityId];
  }

  @override
  Future<List<UserEntityOverlay>> getWeeklyRailOverlays() async {
    return _overlays.values.where((o) => o.isInWeeklyRail).toList();
  }

  @override
  Future<UserEntityOverlay> saveOverlay(UserEntityOverlay overlay) async {
    _overlays[overlay.entityId] = overlay;
    return overlay;
  }

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
  Future<void> snoozeSignal(String entityId, String signalId, Duration duration) async {
    final current = _overlays[entityId] ??
        UserEntityOverlay(
          entityId: entityId,
          userId: 'test-user',
          updatedAt: DateTime.now(),
        );
    final updatedSnoozed = Map<String, dynamic>.from(current.snoozedSignals);
    updatedSnoozed[signalId] = DateTime.now().add(duration).toIso8601String();
    _overlays[entityId] = current.copyWith(
      snoozedSignals: updatedSnoozed,
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  late InMemoryLifeEntityRepository entityRepo;
  late InMemoryEntityRelationRepository relationRepo;
  late InMemoryUserOverlayRepository overlayRepo;

  setUp(() {
    entityRepo = InMemoryLifeEntityRepository();
    relationRepo = InMemoryEntityRelationRepository();
    overlayRepo = InMemoryUserOverlayRepository();

    // Register or re-register in getIt
    if (getIt.isRegistered<LifeEntityRepository>()) {
      getIt.unregister<LifeEntityRepository>();
    }
    if (getIt.isRegistered<EntityRelationRepository>()) {
      getIt.unregister<EntityRelationRepository>();
    }
    if (getIt.isRegistered<UserEntityOverlayRepository>()) {
      getIt.unregister<UserEntityOverlayRepository>();
    }

    getIt.registerSingleton<LifeEntityRepository>(entityRepo);
    getIt.registerSingleton<EntityRelationRepository>(relationRepo);
    getIt.registerSingleton<UserEntityOverlayRepository>(overlayRepo);
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: child,
    );
  }

  group('Step 2: The Minimal Living Hatch UI Tests', () {
    testWidgets('1. LifeOS Center mounts cleanly and renders initial state', (tester) async {
      final cubit = LifeOsCenterCubit(entityRepository: entityRepo);
      await tester.pumpWidget(buildTestApp(LifeOsCenterView(
        cubit: cubit,
        showContextSwitcher: false,
      )));
      await tester.pumpAndSettle();

      expect(find.text('LifeOS Center'), findsOneWidget);
      expect(find.text('0 Semi in attesa · 0 Attive'), findsOneWidget);
      expect(find.byType(UniversalCaptureBar), findsOneWidget);
      expect(find.byType(RecentSeedsSection), findsOneWidget);
      expect(find.byType(HowLifeOsWorksSection), findsOneWidget);

      await cubit.close();
    });

    testWidgets('2. Real-life captures: 4 test prompts captured with zero categorization (Amendment A)', (tester) async {
      final cubit = LifeOsCenterCubit(entityRepository: entityRepo);

      // Prompt 1: "Studiare meglio F2L"
      final s1 = await cubit.captureSeed('Studiare meglio F2L');
      expect(s1, isTrue);

      // Prompt 2: "Capire auth GDPR per Solducci"
      final s2 = await cubit.captureSeed('Capire auth GDPR per Solducci');
      expect(s2, isTrue);

      // Prompt 3: "Fare un maglione oversize"
      final s3 = await cubit.captureSeed('Fare un maglione oversize');
      expect(s3, isTrue);

      // Prompt 4: "Approfondire agrivoltaico"
      final s4 = await cubit.captureSeed('Approfondire agrivoltaico');
      expect(s4, isTrue);

      expect(cubit.state.seeds.length, equals(4));

      // Verify all 4 are seeds, active, with null currentMode (Amendment A)
      for (final seed in cubit.state.seeds) {
        expect(seed.semanticRole, equals(SemanticRole.seed));
        expect(seed.lifecycleState, equals(LifecycleState.active));
        expect(seed.currentMode, isNull, reason: 'Amendment A: no synthetic mode on raw capture');
      }

      await cubit.close();
    });

    testWidgets('3. Progressive differentiation in Vitrine (Step 2.1: strict Role / Mode decoupling)', (tester) async {
      // Seed 1: "Studiare meglio F2L" -> practice, mode remains null until set
      final seed1 = await entityRepo.createEntity(LifeEntity(
        id: 'ent-f2l',
        title: 'Studiare meglio F2L',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final cubit = EntityVitrineCubit(
        entityId: 'ent-f2l',
        entityRepository: entityRepo,
        relationRepository: relationRepo,
        overlayRepository: overlayRepo,
        initialEntity: seed1,
      );

      // "Coltivalo come pratica" -> sets semanticRole = practice, currentMode remains null
      final ok1 = await cubit.setRole(SemanticRole.practice);
      expect(ok1, isTrue);
      expect(cubit.state.entity!.semanticRole, equals(SemanticRole.practice));
      expect(cubit.state.entity!.currentMode, isNull, reason: 'Changing role must not force an operational mode');

      // Now set mode independently: in practice
      final okMode1 = await cubit.setMode(OperationMode.practice);
      expect(okMode1, isTrue);
      expect(cubit.state.entity!.currentMode, equals(OperationMode.practice));

      // Seed 2: "Capire auth GDPR per Solducci" -> project, mode remains null until set
      final seed2 = await entityRepo.createEntity(LifeEntity(
        id: 'ent-gdpr',
        title: 'Capire auth GDPR per Solducci',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final cubit2 = EntityVitrineCubit(
        entityId: 'ent-gdpr',
        entityRepository: entityRepo,
        relationRepository: relationRepo,
        overlayRepository: overlayRepo,
        initialEntity: seed2,
      );

      // "Trattalo come progetto" -> sets semanticRole = project, currentMode remains null
      final ok2 = await cubit2.setRole(SemanticRole.project);
      expect(ok2, isTrue);
      expect(cubit2.state.entity!.semanticRole, equals(SemanticRole.project));
      expect(cubit2.state.entity!.currentMode, isNull, reason: 'Changing role must not force execution mode');

      // Seed 3: "Approfondire agrivoltaico" -> explore
      final seed3 = await entityRepo.createEntity(LifeEntity(
        id: 'ent-agri',
        title: 'Approfondire agrivoltaico',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final cubit3 = EntityVitrineCubit(
        entityId: 'ent-agri',
        entityRepository: entityRepo,
        relationRepository: relationRepo,
        overlayRepository: overlayRepo,
        initialEntity: seed3,
      );

      // "Esplora" -> sets currentMode = exploration, semanticRole remains seed!
      final ok3 = await cubit3.applyIntention(HumanIntention.explore);
      expect(ok3, isTrue);
      expect(cubit3.state.entity!.semanticRole, equals(SemanticRole.seed), reason: 'Esplora must not force changing seed to idea');
      expect(cubit3.state.entity!.currentMode, equals(OperationMode.exploration));

      // Clean up cubits
      await cubit.close();
      await cubit2.close();
      await cubit3.close();
    });

    testWidgets('4. Truthful offline error handling with retry (Amendment B)', (tester) async {
      entityRepo.shouldFailOnCreate = true; // Simulate network failure

      final cubit = LifeOsCenterCubit(entityRepository: entityRepo);

      final result = await cubit.captureSeed('Pensiero offline');
      expect(result, isFalse);
      expect(cubit.state.captureError, contains('connessione assente o errore di rete'));
      expect(cubit.state.lastFailedCaptureTitle, equals('Pensiero offline'));

      // Restore connection & retry
      entityRepo.shouldFailOnCreate = false;
      final retryResult = await cubit.retryLastCapture();
      expect(retryResult, isTrue);
      expect(cubit.state.seeds.length, equals(1));
      expect(cubit.state.seeds.first.title, equals('Pensiero offline'));
      expect(cubit.state.captureError, isNull);

      await cubit.close();
    });

    testWidgets('5. Weekly Rail toggle stores user-specific overlay (Amendment B)', (tester) async {
      final entity = await entityRepo.createEntity(LifeEntity(
        id: 'ent-weekly-test',
        title: 'Progetto Focus Settimanale',
        semanticRole: SemanticRole.project,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final cubit = EntityVitrineCubit(
        entityId: 'ent-weekly-test',
        entityRepository: entityRepo,
        relationRepository: relationRepo,
        overlayRepository: overlayRepo,
        initialEntity: entity,
      );

      // Initially null or false
      expect(cubit.state.overlay?.isInWeeklyRail ?? false, isFalse);

      // Toggle to true
      final ok = await cubit.toggleWeeklyRail();
      expect(ok, isTrue);
      expect(cubit.state.overlay?.isInWeeklyRail, isTrue);

      // Verify overlay repository has it
      final savedOverlay = await overlayRepo.getOverlay('ent-weekly-test');
      expect(savedOverlay?.isInWeeklyRail, isTrue);

      await cubit.close();
    });

    testWidgets('6. How LifeOS Works expandable cards show live facts', (tester) async {
      await tester.pumpWidget(buildTestApp(const Scaffold(
        body: SingleChildScrollView(
          child: HowLifeOsWorksSection(
            seedCount: 7,
            activeCount: 3,
          ),
        ),
      )));
      await tester.pumpAndSettle();

      // Tap on Strutturazione Progressiva to expand
      await tester.tap(find.text('Strutturazione Progressiva'));
      await tester.pumpAndSettle();

      expect(find.text('Hai 7 semi grezzi in attesa di maturazione.'), findsOneWidget);
    });
  });
}
