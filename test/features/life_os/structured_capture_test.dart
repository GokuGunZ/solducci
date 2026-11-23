import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/widgets/structured_capture_sheet.dart';
import 'package:solducci/features/life_os/presentation/widgets/universal_capture_bar.dart';

class MockLifeEntityRepository extends Mock implements LifeEntityRepository {}
class MockEntityRelationRepository extends Mock implements EntityRelationRepository {}

class FakeLifeEntity extends Fake implements LifeEntity {}
class FakeEntityRelation extends Fake implements EntityRelation {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLifeEntity());
    registerFallbackValue(FakeEntityRelation());
  });

  group('StructuredCaptureSheet Unit & Widget Tests', () {
    late MockLifeEntityRepository entityRepo;
    late MockEntityRelationRepository relationRepo;

    setUp(() {
      entityRepo = MockLifeEntityRepository();
      relationRepo = MockEntityRelationRepository();
    });

    testWidgets('Renders properly with initialTitle pre-populated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructuredCaptureSheet(
              initialTitle: 'Nuovo Podcasting',
              entityRepository: entityRepo,
              relationRepository: relationRepo,
            ),
          ),
        ),
      );

      expect(find.text('Nuovo Progetto Strutturato'), findsOneWidget);
      expect(find.text('Nuovo Podcasting'), findsOneWidget);
      expect(find.text('Crea Progetto'), findsOneWidget);
    });

    testWidgets('Adds sub-ideas as chips and updates CTA label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructuredCaptureSheet(
              initialTitle: 'Progetto Alpha',
              entityRepository: entityRepo,
              relationRepository: relationRepo,
            ),
          ),
        ),
      );

      final subIdeaInput = find.widgetWithText(TextField, 'Aggiungi una prima sotto-idea o nota...');
      expect(subIdeaInput, findsOneWidget);

      await tester.enterText(subIdeaInput, 'Prima nota');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Prima nota'), findsOneWidget);
      expect(find.text('Crea Progetto con 1 elemento'), findsOneWidget);

      await tester.enterText(subIdeaInput, 'Seconda nota');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Seconda nota'), findsOneWidget);
      expect(find.text('Crea Progetto con 2 elementi'), findsOneWidget);
    });

    testWidgets('Submitting creates root entity and part_of relations for all sub-ideas', (tester) async {
      when(() => entityRepo.createEntity(any())).thenAnswer((inv) async => inv.positionalArguments[0] as LifeEntity);
      when(() => relationRepo.createRelation(any())).thenAnswer((inv) async => inv.positionalArguments[0] as EntityRelation);

      LifeEntity? createdResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  createdResult = await StructuredCaptureSheet.show(
                    ctx,
                    initialTitle: 'Progetto Audio',
                    entityRepository: entityRepo,
                    relationRepository: relationRepo,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Add 2 sub-ideas
      final subIdeaInput = find.widgetWithText(TextField, 'Aggiungi una prima sotto-idea o nota...');
      await tester.enterText(subIdeaInput, 'Microfono');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.enterText(subIdeaInput, 'Cuffie');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Tap submit
      await tester.tap(find.text('Crea Progetto con 2 elementi'));
      await tester.pumpAndSettle();

      // Verify root creation (role: project)
      final capturedEntities = verify(() => entityRepo.createEntity(captureAny())).captured;
      expect(capturedEntities.length, 3); // 1 root + 2 sub-ideas
      final root = capturedEntities[0] as LifeEntity;
      expect(root.title, 'Progetto Audio');
      expect(root.semanticRole, SemanticRole.project);

      // Verify 2 part_of relations created with targetId == root.id
      final capturedRelations = verify(() => relationRepo.createRelation(captureAny())).captured;
      expect(capturedRelations.length, 2);
      for (final rel in capturedRelations) {
        final r = rel as EntityRelation;
        expect(r.targetId, root.id);
        expect(r.relationType, RelationType.partOf);
        expect(r.targetType, TargetType.entity);
      }

      expect(createdResult?.title, 'Progetto Audio');
    });
  });

  group('UniversalCaptureBar Tests', () {
    testWidgets('Normal tap triggers onCapture callback', (tester) async {
      String? capturedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversalCaptureBar(
              onCapture: (text) => capturedText = text,
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      await tester.enterText(input, 'Seme rapido');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(capturedText, 'Seme rapido');
    });

    testWidgets('Long press triggers onStructuredCapture callback if provided', (tester) async {
      String? structuredText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversalCaptureBar(
              onCapture: (_) {},
              onStructuredCapture: (text) => structuredText = text,
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      await tester.enterText(input, 'Grande Progetto');
      await tester.longPress(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(structuredText, 'Grande Progetto');
    });
  });
}
