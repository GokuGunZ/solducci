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

    testWidgets('Renders committed seed card, separator and chained input bar', (tester) async {
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

      expect(find.text('Catena di Semi (1)'), findsOneWidget);
      expect(find.text('Idea iniziale del progetto'), findsOneWidget);
      expect(find.text('Modifica'), findsOneWidget);
      expect(find.text('Raccogli una catena di semi'), findsOneWidget);
      expect(find.text('Aggiungi il prossimo seme connesso...'), findsOneWidget);
    });

    testWidgets('Modifica allows editing the committed seed title', (tester) async {
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

    testWidgets('Submitting a chained seed creates child document and partOf relation to root seed', (tester) async {
      LifeEntity? addedChildResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainedCaptureOverlay(
              initialSeed: initialSeed,
              entityRepository: entityRepo,
              relationRepository: relationRepo,
              onDismiss: () {},
              onSeedAdded: (seed) => addedChildResult = seed,
            ),
          ),
        ),
      );

      // Find the secondary capture input bar
      final input = find.widgetWithText(TextField, 'Aggiungi il prossimo seme connesso...');
      expect(input, findsOneWidget);

      await tester.enterText(input, 'Secondo anello di pensiero');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      // Verify that createEntity was called for the new child
      verify(() => entityRepo.createEntity(any(that: isA<LifeEntity>()))).called(1);

      // Verify that createRelation was called linking new seed to initialSeed
      final capturedRelation = verify(() => relationRepo.createRelation(captureAny())).captured.first as EntityRelation;
      expect(capturedRelation.targetId, initialSeed.id);
      expect(capturedRelation.relationType, RelationType.partOf);
      expect(capturedRelation.metadata['chain_order'], 1);

      // Verify UI updated to Catena di Semi (2)
      expect(find.text('Catena di Semi (2)'), findsOneWidget);
      expect(find.text('Secondo anello di pensiero'), findsOneWidget);
      expect(addedChildResult?.title, 'Secondo anello di pensiero');
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
