import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/widgets/chained_capture_overlay.dart';

class MockLifeEntityRepository extends Mock implements LifeEntityRepository {}
class MockEntityRelationRepository extends Mock implements EntityRelationRepository {}

class FakeLifeEntity extends Fake implements LifeEntity {}
class FakeEntityRelation extends Fake implements EntityRelation {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLifeEntity());
    registerFallbackValue(FakeEntityRelation());
  });

  group('ChainedCaptureOverlay Widget Tests', () {
    late MockLifeEntityRepository entityRepo;
    late MockEntityRelationRepository relationRepo;

    final initialSeed = LifeEntity(
      id: 'seed-root-1',
      title: 'Idea iniziale del progetto',
      semanticRole: SemanticRole.seed,
      lifecycleState: LifecycleState.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      entityRepo = MockLifeEntityRepository();
      relationRepo = MockEntityRelationRepository();

      when(() => entityRepo.createEntity(any())).thenAnswer((inv) async => inv.positionalArguments[0] as LifeEntity);
      when(() => entityRepo.updateEntity(any())).thenAnswer((inv) async => inv.positionalArguments[0] as LifeEntity);
      when(() => relationRepo.createRelation(any())).thenAnswer((inv) async => inv.positionalArguments[0] as EntityRelation);
    });

    testWidgets('Renders main seed fixed at the top, divider, and evolutionary input bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainedCaptureOverlay(
              initialSeed: initialSeed,
              entityRepository: entityRepo,
              relationRepository: relationRepo,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Flusso del Seme'), findsOneWidget);
      expect(find.text('SEME PRINCIPALE'), findsOneWidget);
      expect(find.text('Idea iniziale del progetto'), findsOneWidget);
      expect(find.text('Modifica'), findsOneWidget);
      expect(find.text('FLUSSO EVOLUTIVO'), findsOneWidget);
      expect(find.text('Aggiungi un pensiero al flusso evolutivo...'), findsOneWidget);
    });

    testWidgets('Modifica allows editing the main seed title', (tester) async {
      LifeEntity? updatedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainedCaptureOverlay(
              initialSeed: initialSeed,
              entityRepository: entityRepo,
              relationRepository: relationRepo,
              onDismiss: () {},
              onSeedUpdated: (seed) => updatedResult = seed,
            ),
          ),
        ),
      );

      // Tap Modifica
      await tester.tap(find.text('Modifica'));
      await tester.pump();

      expect(find.text('Salva'), findsOneWidget);

      // Enter new text
      final editField = find.byType(TextField).first;
      await tester.enterText(editField, 'Idea iniziale aggiornata');
      await tester.tap(find.text('Salva'));
      await tester.pump();

      expect(find.text('Idea iniziale aggiornata'), findsOneWidget);
      expect(updatedResult?.title, 'Idea iniziale aggiornata');
    });

    testWidgets('Submitting thoughts adds them as direct children of main seed at the same level and updates blocks', (tester) async {
      LifeEntity? addedChildResult;
      LifeEntity? updatedRootResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainedCaptureOverlay(
              initialSeed: initialSeed,
              entityRepository: entityRepo,
              relationRepository: relationRepo,
              onDismiss: () {},
              onSeedAdded: (seed) => addedChildResult = seed,
              onSeedUpdated: (seed) => updatedRootResult = seed,
            ),
          ),
        ),
      );

      // Find the evolutionary input bar
      final input = find.widgetWithText(TextField, 'Aggiungi un pensiero al flusso evolutivo...');
      expect(input, findsOneWidget);

      // Add thought 1
      await tester.enterText(input, 'Primo pensiero');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      // Verify that createEntity was called for the new child
      verify(() => entityRepo.createEntity(any(that: isA<LifeEntity>()))).called(1);

      // Verify relation links directly to initialSeed
      final capturedRelation1 = verify(() => relationRepo.createRelation(captureAny())).captured.first as EntityRelation;
      expect(capturedRelation1.targetId, initialSeed.id);
      expect(capturedRelation1.relationType, RelationType.partOf);

      // Verify that root seed's blocks (flusso evolutivo) was updated
      expect(updatedRootResult?.blocks.length, 1);
      expect(updatedRootResult?.blocks.first.content, 'Primo pensiero');

      // Verify thought 1 appears in the list with "Aggiungi dentro" action
      expect(find.text('Primo pensiero'), findsOneWidget);
      expect(find.text('Aggiungi dentro'), findsOneWidget);
      expect(addedChildResult?.title, 'Primo pensiero');

      // Add thought 2 (also direct child at same level)
      await tester.enterText(input, 'Secondo pensiero allo stesso livello');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      final capturedRelations = verify(() => relationRepo.createRelation(captureAny())).captured;
      final capturedRelation2 = capturedRelations.last as EntityRelation;
      // Also targets initialSeed (same level, NOT nested in thought 1!)
      expect(capturedRelation2.targetId, initialSeed.id);
      expect(capturedRelation2.relationType, RelationType.partOf);

      expect(find.text('Secondo pensiero allo stesso livello'), findsOneWidget);
      expect(find.text('FLUSSO EVOLUTIVO (2 aggiunti)'), findsOneWidget);
    });

    testWidgets('Tapping "Aggiungi dentro" targets that secondary thought for nested nesting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainedCaptureOverlay(
              initialSeed: initialSeed,
              entityRepository: entityRepo,
              relationRepository: relationRepo,
              onDismiss: () {},
            ),
          ),
        ),
      );

      final input = find.byType(TextField);

      // 1. Add secondary thought
      await tester.enterText(input, 'Macro-blocco A');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Macro-blocco A'), findsOneWidget);
      expect(find.text('Aggiungi dentro'), findsOneWidget);

      // 2. Tap "Aggiungi dentro" on Macro-blocco A
      await tester.tap(find.text('Aggiungi dentro'));
      await tester.pumpAndSettle();

      // Should indicate target
      expect(find.text('Aggiungi dentro: "Macro-blocco A"'), findsOneWidget);
      expect(find.text('Aggiungi sotto a "Macro-blocco A"...'), findsOneWidget);

      // 3. Add nested sub-thought
      final nestedInput = find.widgetWithText(TextField, 'Aggiungi sotto a "Macro-blocco A"...');
      await tester.enterText(nestedInput, 'Dettaglio innestato');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      // Verify that this relation was linked to Macro-blocco A, not root!
      final capturedRelations = verify(() => relationRepo.createRelation(captureAny())).captured;
      final nestedRel = capturedRelations.last as EntityRelation;
      expect(nestedRel.targetId, isNot(initialSeed.id)); // targeted child A!
      expect(nestedRel.relationType, RelationType.partOf);

      // Verify nested UI indication
      expect(find.text('dentro "Macro-blocco A"'), findsOneWidget);
      expect(find.text('Dettaglio innestato'), findsOneWidget);
    });

    testWidgets('Tapping Fatto triggers onDismiss callback', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainedCaptureOverlay(
              initialSeed: initialSeed,
              entityRepository: entityRepo,
              relationRepository: relationRepo,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Fatto'));
      await tester.pump();

      expect(dismissed, true);
    });
  });
}
