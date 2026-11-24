import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/presentation/widgets/dynamic_capture_bar.dart';
import 'package:solducci/features/life_os/presentation/widgets/entity_mention_picker.dart';
import 'package:solducci/features/life_os/presentation/widgets/seed_relation_switcher_sheet.dart';

void main() {
  final testEntities = [
    LifeEntity(
      id: 'entity-proj-1',
      title: 'Solducci Redesign',
      semanticRole: SemanticRole.project,
      lifecycleState: LifecycleState.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    LifeEntity(
      id: 'entity-conc-1',
      title: 'Architettura Grafi',
      semanticRole: SemanticRole.concept,
      lifecycleState: LifecycleState.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  group('DynamicCaptureBar Unit & Widget Tests', () {
    testWidgets('Renders single-line compact layout initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCaptureBar(
              availableEntities: testEntities,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
      expect(find.text('Cattura un pensiero, seme o @entità...'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      // "Raccogli seme " label should NOT be visible initially
      expect(find.text('Raccogli seme '), findsNothing);
    });

    testWidgets('Typing multiline text shifts to expanded layout and reveals "Raccogli seme "', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCaptureBar(
              availableEntities: testEntities,
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      // Type multiline text
      await tester.enterText(input, 'Prima riga di pensiero\nSeconda riga espansa');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // finish animation

      expect(find.text('Raccogli seme '), findsOneWidget);
    });

    testWidgets('Typing @ triggers EntityMentionPicker', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCaptureBar(
              availableEntities: testEntities,
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      await tester.enterText(input, '@Sol');
      await tester.pump();

      expect(find.byType(EntityMentionPicker), findsOneWidget);
      expect(find.text('Solducci Redesign'), findsOneWidget);
    });

    testWidgets('Leading mention automatically defaults to "Figlio di" (partOf)', (tester) async {
      String? capturedText;
      List<SeedMention>? capturedMentions;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCaptureBar(
              availableEntities: testEntities,
              onCaptureWithMentions: (text, mentions) {
                capturedText = text;
                capturedMentions = mentions;
              },
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      await tester.enterText(input, '@Sol');
      await tester.pump();

      // Tap suggestion
      await tester.tap(find.text('Solducci Redesign'));
      await tester.pump();

      // Mention chip should appear with subdirectory arrow
      expect(find.text('@Solducci Redesign'), findsOneWidget);
      expect(find.byIcon(Icons.subdirectory_arrow_right_rounded), findsOneWidget);

      // Add seed text after leading mention
      await tester.enterText(input, 'Nuove feature del grafo');
      await tester.pump();

      // Tap send
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(capturedText, 'Nuove feature del grafo');
      expect(capturedMentions?.length, 1);
      expect(capturedMentions?[0].relationType, RelationType.partOf);
      expect(capturedMentions?[0].isLeadingTag, true);
    });

    testWidgets('Mid-text mention automatically defaults to "Semplice" (relatesTo)', (tester) async {
      List<SeedMention>? capturedMentions;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCaptureBar(
              availableEntities: testEntities,
              onCaptureWithMentions: (_, mentions) => capturedMentions = mentions,
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      // Type leading text, then @
      await tester.enterText(input, 'Discutere di @Arch');
      await tester.pump();

      expect(find.byType(EntityMentionPicker), findsOneWidget);
      await tester.tap(find.text('Architettura Grafi'));
      await tester.pump();

      expect(find.text('@Architettura Grafi'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);

      // Submit
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(capturedMentions?.length, 1);
      expect(capturedMentions?[0].relationType, RelationType.relatesTo);
      expect(capturedMentions?[0].isLeadingTag, false);
    });

    testWidgets('Tapping mention chip opens relation switcher sheet and updates type', (tester) async {
      List<SeedMention>? capturedMentions;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCaptureBar(
              availableEntities: testEntities,
              onCaptureWithMentions: (_, mentions) => capturedMentions = mentions,
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      await tester.enterText(input, '@Sol');
      await tester.pump();
      await tester.tap(find.text('Solducci Redesign'));
      await tester.pump();

      // Tap the tag chip
      await tester.tap(find.text('@Solducci Redesign'));
      await tester.pumpAndSettle();

      // Should show the switcher sheet
      expect(find.byType(SeedRelationSwitcherSheet), findsOneWidget);
      expect(find.text('Figlio di (parte di)'), findsOneWidget);
      expect(find.text('Connessione Semplice'), findsOneWidget);

      // Toggle to Connessione Semplice
      await tester.tap(find.text('Connessione Semplice'));
      await tester.pump();

      // Confirm
      await tester.tap(find.text('Conferma'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      // Should now be relatesTo
      expect(capturedMentions?[0].relationType, RelationType.relatesTo);
    });

    testWidgets('Dismissing relation switcher sheet without confirming does NOT remove tag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCaptureBar(
              availableEntities: testEntities,
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      await tester.enterText(input, '@Sol');
      await tester.pump();
      await tester.tap(find.text('Solducci Redesign'));
      await tester.pump();

      expect(find.text('@Solducci Redesign'), findsOneWidget);

      // Open sheet
      await tester.tap(find.text('@Solducci Redesign'));
      await tester.pumpAndSettle();
      expect(find.byType(SeedRelationSwitcherSheet), findsOneWidget);

      // Dismiss by tapping the modal barrier (tapping outside / dragging down)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Tag MUST STILL BE PRESENT!
      expect(find.text('@Solducci Redesign'), findsOneWidget);
    });

    testWidgets('Tapping Rimuovi tag removes tag from bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCaptureBar(
              availableEntities: testEntities,
            ),
          ),
        ),
      );

      final input = find.byType(TextField);
      await tester.enterText(input, '@Sol');
      await tester.pump();
      await tester.tap(find.text('Solducci Redesign'));
      await tester.pump();

      expect(find.text('@Solducci Redesign'), findsOneWidget);

      // Open sheet
      await tester.tap(find.text('@Solducci Redesign'));
      await tester.pumpAndSettle();

      // Tap Rimuovi tag
      await tester.tap(find.text('Rimuovi tag'));
      await tester.pumpAndSettle();

      // Tag should now be removed
      expect(find.text('@Solducci Redesign'), findsNothing);
    });
  });
}
