import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/core/markdown/widgets/advanced_markdown_viewer.dart';
import 'package:solducci/core/markdown/widgets/interactive_line_item.dart';
import 'package:solducci/widgets/liquid_markdown_editor.dart';

void main() {
  testWidgets('LiquidMarkdownEditor mounts AdvancedMarkdownViewer and preserves interactions', (tester) async {
    String currentText = '''# Shopping
- [ ] Fresh milk
- [x] Artisan bread''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiquidMarkdownEditor(
              initialText: currentText,
              initialTitle: 'Shopping Note',
              limit: 1, // Activates reading preview mode
              onTextChanged: (newText) {
                currentText = newText;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title is rendered (in front and/or back flip layers)
    expect(find.text('Shopping Note'), findsAtLeastNWidgets(1));

    // Verify AdvancedMarkdownViewer is mounted
    expect(find.byType(AdvancedMarkdownViewer), findsAtLeastNWidgets(1));

    // Verify line elements are present
    expect(find.text('Fresh milk'), findsAtLeastNWidgets(1));
    expect(find.text('Artisan bread'), findsAtLeastNWidgets(1));

    // Tap checkbox for 'Fresh milk' on the active visible reader face
    final freshMilkItemFinder = find.ancestor(
      of: find.text('Fresh milk'),
      matching: find.byType(InteractiveLineItem),
    ).last;

    final checkboxFinder = find.descendant(
      of: freshMilkItemFinder,
      matching: find.byType(GestureDetector),
    );

    await tester.tap(checkboxFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify callback was triggered and updated markdown
    expect(currentText.contains('- [x] Fresh milk'), isTrue);
  });
}
