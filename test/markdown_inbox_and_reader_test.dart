import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/service/markdown_settings_service.dart';
import 'package:solducci/widgets/liquid_markdown_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarkdownSettingsService Tests', () {
    test('Default values are correct', () {
      final service = MarkdownSettingsService();
      expect(service.defaultExpanded, isTrue);
      expect(service.fontSize, equals(14.5));
      expect(service.readOnlyLock, isFalse);
    });
  });

  group('LiquidMarkdownEditor Widget Tests', () {
    testWidgets('renders markdown body by default when limit is 0 and not editing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidMarkdownEditor(
              initialTitle: 'Test Document',
              initialText: 'This is the **markdown body** content.',
              limit: 0,
              defaultExpanded: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title appears in both reader and hidden editor stack
      expect(find.text('Test Document'), findsAtLeastNWidgets(1));

      // Body text should be visible by default (not collapsed)
      expect(find.textContaining('This is the'), findsAtLeastNWidgets(1));
    });

    testWidgets('collapses body when isExpanded is explicitly false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidMarkdownEditor(
              initialTitle: 'Collapsed Document',
              initialText: 'Hidden markdown body.',
              limit: 0,
              isExpanded: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Collapsed Document'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Hidden markdown body'), findsNothing);
    });
  });
}
