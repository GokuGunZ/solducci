import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/models/project_scope_context.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/domain/services/project_hierarchy_service.dart';
import 'package:solducci/features/life_os/presentation/views/entity_vitrine_view.dart';
import 'package:solducci/features/life_os/presentation/widgets/project_dashboard_view.dart';
import 'package:solducci/features/life_os/presentation/widgets/project_discovery_sheet.dart';
import 'package:solducci/features/life_os/presentation/widgets/project_folder_view.dart';
import 'package:solducci/features/life_os/presentation/widgets/graph/project_graph_view.dart';

class MockLifeEntityRepository extends Mock implements LifeEntityRepository {}
class MockEntityRelationRepository extends Mock implements EntityRelationRepository {}
class MockUserEntityOverlayRepository extends Mock implements UserEntityOverlayRepository {}
class MockProjectHierarchyService extends Mock implements ProjectHierarchyService {}

void main() {
  group('ProjectScopeContext Evaluation Unit Tests', () {
    test('Nascent project (0 children, 0 blocks) renders only hero and thought stream', () {
      final modules = ProjectScopeContext.evaluateModules(
        directChildrenCount: 0,
        totalDescendantCount: 0,
        blockCount: 0,
      );

      expect(modules, {
        ProjectModuleType.heroHeader,
        ProjectModuleType.thoughtStream,
      });
      expect(modules.contains(ProjectModuleType.folderTreePreview), isFalse);
      expect(modules.contains(ProjectModuleType.egoGraphRadar), isFalse);
    });

    test('Project with 1 child activates folder preview', () {
      final modules = ProjectScopeContext.evaluateModules(
        directChildrenCount: 1,
        totalDescendantCount: 1,
        blockCount: 1,
      );

      expect(modules.contains(ProjectModuleType.folderTreePreview), isTrue);
      expect(modules.contains(ProjectModuleType.egoGraphRadar), isFalse);
    });

    test('Project with 2 descendants activates graph radar', () {
      final modules = ProjectScopeContext.evaluateModules(
        directChildrenCount: 2,
        totalDescendantCount: 2,
        blockCount: 1,
      );

      expect(modules.contains(ProjectModuleType.folderTreePreview), isTrue);
      expect(modules.contains(ProjectModuleType.egoGraphRadar), isTrue);
      expect(modules.contains(ProjectModuleType.continuityPulse), isTrue);
    });
  });

  group('ProjectDiscoverySheet Widget Tests', () {
    testWidgets('Renders all pedagogical cards and dismisses on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ProjectDiscoverySheet.show(ctx),
                child: const Text('Guida'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Guida'));
      await tester.pumpAndSettle();

      expect(find.text('Come Funzionano i Progetti in LifeOS'), findsOneWidget);
      expect(find.text('1. Il Progetto è una Radice Vivente'), findsOneWidget);
      expect(find.text('2. Cartelle vs. Grafo: Due Proiezioni'), findsOneWidget);
      expect(find.text('3. I Gesti nel Grafo Radiale'), findsOneWidget);
      expect(find.text('4. Dashboard Progressiva'), findsOneWidget);

      await tester.tap(find.text('Ho Capito'));
      await tester.pumpAndSettle();

      expect(find.text('Come Funzionano i Progetti in LifeOS'), findsNothing);
    });
  });

  group('EntityVitrineView Project Tabs Integration Tests', () {
    late MockLifeEntityRepository entityRepo;
    late MockEntityRelationRepository relationRepo;
    late MockUserEntityOverlayRepository overlayRepo;
    late MockProjectHierarchyService hierarchyService;

    setUp(() {
      entityRepo = MockLifeEntityRepository();
      relationRepo = MockEntityRelationRepository();
      overlayRepo = MockUserEntityOverlayRepository();
      hierarchyService = MockProjectHierarchyService();

      // Register mocks in getIt if not present
      if (getIt.isRegistered<LifeEntityRepository>()) getIt.unregister<LifeEntityRepository>();
      if (getIt.isRegistered<EntityRelationRepository>()) getIt.unregister<EntityRelationRepository>();
      if (getIt.isRegistered<UserEntityOverlayRepository>()) getIt.unregister<UserEntityOverlayRepository>();
      if (getIt.isRegistered<ProjectHierarchyService>()) getIt.unregister<ProjectHierarchyService>();

      getIt.registerSingleton<LifeEntityRepository>(entityRepo);
      getIt.registerSingleton<EntityRelationRepository>(relationRepo);
      getIt.registerSingleton<UserEntityOverlayRepository>(overlayRepo);
      getIt.registerSingleton<ProjectHierarchyService>(hierarchyService);
    });

    tearDown(() {
      getIt.reset();
    });

    testWidgets('Project entity shows segmented tabs and switches between Panoramica, Cartelle, and Grafo', (tester) async {
      final now = DateTime.now();
      final projectEntity = LifeEntity(
        id: 'project_podcasting',
        title: 'Podcasting Launch',
        semanticRole: SemanticRole.project,
        createdAt: now,
        updatedAt: now,
      );

      when(() => entityRepo.getEntityById('project_podcasting')).thenAnswer((_) async => projectEntity);
      when(() => relationRepo.getRelationsForSource('project_podcasting')).thenAnswer((_) async => []);
      when(() => relationRepo.getRelationsForTarget('project_podcasting', TargetType.entity)).thenAnswer((_) async => []);
      when(() => overlayRepo.getOverlay('project_podcasting')).thenAnswer((_) async => null);
      when(() => hierarchyService.buildHierarchyTree('project_podcasting')).thenAnswer((_) async => []);
      when(() => hierarchyService.getRecursiveDescendants('project_podcasting')).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: EntityVitrineView(
            entityId: 'project_podcasting',
            initialEntity: projectEntity,
            showContextSwitcher: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify tabs exist
      expect(find.text('Panoramica'), findsOneWidget);
      expect(find.text('Cartelle'), findsOneWidget);
      expect(find.text('Grafo'), findsOneWidget);

      // Initially in Panoramica
      expect(find.byType(ProjectDashboardView), findsOneWidget);
      expect(find.byType(ProjectFolderView), findsNothing);
      expect(find.byType(ProjectGraphView), findsNothing);

      // Switch to Cartelle
      await tester.tap(find.text('Cartelle'));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectFolderView), findsOneWidget);
      expect(find.byType(ProjectDashboardView), findsNothing);

      // Switch to Grafo
      await tester.tap(find.text('Grafo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectGraphView), findsOneWidget);
      expect(find.byType(ProjectFolderView), findsNothing);

      // Check app bar guide icon
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Come Funzionano i Progetti in LifeOS'), findsOneWidget);
    });
  });
}
