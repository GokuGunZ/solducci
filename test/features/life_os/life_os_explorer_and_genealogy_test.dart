import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/controllers/life_os_center_cubit.dart';
import 'package:solducci/features/life_os/presentation/views/life_os_explorer_view.dart';
import 'package:solducci/features/life_os/presentation/widgets/dynamic_capture_bar.dart';

class MockLifeEntityRepository extends Mock implements LifeEntityRepository {}
class MockEntityRelationRepository extends Mock implements EntityRelationRepository {}

class FakeLifeEntity extends Fake implements LifeEntity {}
class FakeEntityRelation extends Fake implements EntityRelation {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLifeEntity());
    registerFallbackValue(FakeEntityRelation());
  });

  group('LifeOsCenterCubit Parent-Child Evolution Sync', () {
    late MockLifeEntityRepository entityRepo;
    late MockEntityRelationRepository relationRepo;

    final parentEntity = LifeEntity(
      id: 'parent-ciao-id',
      title: 'ciao',
      semanticRole: SemanticRole.project,
      lifecycleState: LifecycleState.active,
      blocks: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      entityRepo = MockLifeEntityRepository();
      relationRepo = MockEntityRelationRepository();

      when(() => entityRepo.getEntities(
            groupId: any(named: 'groupId'),
            groupIds: any(named: 'groupIds'),
            isPersonal: any(named: 'isPersonal'),
            role: any(named: 'role'),
            lifecycle: any(named: 'lifecycle'),
          )).thenAnswer((_) async => [parentEntity]);

      when(() => entityRepo.createEntity(any())).thenAnswer((inv) async => inv.positionalArguments[0] as LifeEntity);
      when(() => entityRepo.updateEntity(any())).thenAnswer((inv) async => inv.positionalArguments[0] as LifeEntity);
      when(() => entityRepo.getEntityById('parent-ciao-id')).thenAnswer((_) async => parentEntity);
      when(() => relationRepo.createRelation(any())).thenAnswer((inv) async => inv.positionalArguments[0] as EntityRelation);
    });

    test('captureSeedWithMentions with partOf mention appends EntityBlock to parent', () async {
      final cubit = LifeOsCenterCubit(
        entityRepository: entityRepo,
        relationRepository: relationRepo,
      );

      final mentions = [
        const SeedMention(
          entityId: 'parent-ciao-id',
          entityTitle: 'ciao',
          role: SemanticRole.project,
          relationType: RelationType.partOf,
          isLeadingTag: true,
        ),
      ];

      final created = await cubit.captureSeedWithMentions('figlio di ciao', mentions);

      expect(created, isNotNull);
      expect(created!.title, 'figlio di ciao');

      // Verify that parent entity was fetched and updated with a new block
      verify(() => entityRepo.getEntityById('parent-ciao-id')).called(1);
      final capturedUpdate = verify(() => entityRepo.updateEntity(captureAny())).captured.first as LifeEntity;

      expect(capturedUpdate.id, 'parent-ciao-id');
      expect(capturedUpdate.blocks.length, 1);
      expect(capturedUpdate.blocks.first.content, 'figlio di ciao');
    });
  });

  group('LifeOsExplorerView Widget Tests', () {
    late MockLifeEntityRepository entityRepo;

    final testEntities = [
      LifeEntity(
        id: 'seed-1',
        title: 'Idea seme grezzo',
        description: 'Breve appunto',
        semanticRole: SemanticRole.seed,
        lifecycleState: LifecycleState.active,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      ),
      LifeEntity(
        id: 'proj-1',
        title: 'Progetto Solducci Core',
        description: 'Sviluppo architettura',
        semanticRole: SemanticRole.project,
        lifecycleState: LifecycleState.active,
        currentMode: OperationMode.execution,
        blocks: [
          EntityBlock(
            id: 'b-1',
            content: 'Primo pensiero sul progetto',
            position: 0,
            createdAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
      LifeEntity(
        id: 'concept-1',
        title: 'Concetto Ontologia',
        semanticRole: SemanticRole.concept,
        lifecycleState: LifecycleState.active,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
    ];

    setUp(() {
      entityRepo = MockLifeEntityRepository();
      when(() => entityRepo.getEntities()).thenAnswer((_) async => testEntities);
    });

    testWidgets('Renders all entities, search field and role filter chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LifeOsExplorerView(entityRepository: entityRepo),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Esploratore LifeOS'), findsOneWidget);
      expect(find.text('3 risultati'), findsOneWidget);
      expect(find.text('Idea seme grezzo'), findsOneWidget);
      expect(find.text('Progetto Solducci Core'), findsOneWidget);
      expect(find.text('Concetto Ontologia'), findsOneWidget);
      expect(find.text('1 pensiero nel flusso'), findsOneWidget);
    });

    testWidgets('Filtering by role displays only matching entities', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LifeOsExplorerView(entityRepository: entityRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on "Semi" filter chip
      await tester.tap(find.widgetWithText(InkWell, 'Semi'));
      await tester.pumpAndSettle();

      expect(find.text('1 risultato'), findsOneWidget);
      expect(find.text('Idea seme grezzo'), findsOneWidget);
      expect(find.text('Progetto Solducci Core'), findsNothing);
      expect(find.text('Concetto Ontologia'), findsNothing);

      // Tap on "Progetti" filter chip
      await tester.tap(find.widgetWithText(InkWell, 'Progetti'));
      await tester.pumpAndSettle();

      expect(find.text('1 risultato'), findsOneWidget);
      expect(find.text('Progetto Solducci Core'), findsOneWidget);
      expect(find.text('Idea seme grezzo'), findsNothing);
    });

    testWidgets('Searching dynamically filters results', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LifeOsExplorerView(entityRepository: entityRepo),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Ontologia');
      await tester.pumpAndSettle();

      expect(find.text('1 risultato'), findsOneWidget);
      expect(find.text('Concetto Ontologia'), findsOneWidget);
      expect(find.text('Idea seme grezzo'), findsNothing);
    });
  });
}
