import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/core/markdown/models/line_element.dart';
import 'package:solducci/core/markdown/widgets/interactive_line_item.dart';

void main() {
  group('InteractiveLineItem Widget Tests', () {
    testWidgets('renders bullet line and responds to long press on 44pt hit-area', (tester) async {
      LineElement? longPressedElement;

      const element = LineElement(
        id: 'line_1',
        lineIndex: 0,
        markerType: LineMarkerType.bullet,
        markerRaw: '-',
        indentLevel: 0,
        textContent: 'Test bullet text',
        rawSourceLine: '- Test bullet text',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveLineItem(
              element: element,
              onLongPressMarker: (el) => longPressedElement = el,
            ),
          ),
        ),
      );

      expect(find.text('Test bullet text'), findsOneWidget);

      // Verify hit area size (>= 44x44pt)
      final hitAreaFinder = find.byType(GestureDetector);
      expect(hitAreaFinder, findsOneWidget);
      final size = tester.getSize(hitAreaFinder);
      expect(size.width, greaterThanOrEqualTo(44.0));
      expect(size.height, greaterThanOrEqualTo(44.0));

      // Trigger long-press
      await tester.longPress(hitAreaFinder);
      await tester.pumpAndSettle();

      expect(longPressedElement, isNotNull);
      expect(longPressedElement?.textContent, equals('Test bullet text'));
    });

    testWidgets('toggles checkbox on short tap', (tester) async {
      int? toggledIndex;

      const element = LineElement(
        id: 'chk_1',
        lineIndex: 2,
        markerType: LineMarkerType.checkbox,
        markerRaw: '- [ ]',
        indentLevel: 0,
        isChecked: false,
        textContent: 'Buy coffee',
        rawSourceLine: '- [ ] Buy coffee',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveLineItem(
              element: element,
              onToggleCheckbox: (idx) => toggledIndex = idx,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(toggledIndex, equals(2));
    });

    testWidgets('applies strikethrough, bold, and custom color modifier non-destructively', (tester) async {
      const element = LineElement(
        id: 'chk_done',
        lineIndex: 0,
        markerType: LineMarkerType.checkbox,
        markerRaw: '- [x]',
        indentLevel: 0,
        isChecked: true,
        textContent: 'Completed task',
        rawSourceLine: '- [x] Completed task',
      );

      const modifier = LineModifierStyle(
        strikethrough: true,
        underline: false,
        bold: true,
        textColor: Color(0xFFEF4444),
        opacity: 0.7,
        applyCondition: ModifierCondition.whenChecked,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveLineItem(
              element: element,
              modifier: modifier,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Completed task'));
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(textWidget.style?.color, equals(const Color(0xFFEF4444)));

      final opacityWidget = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacityWidget.opacity, equals(0.7));
    });
  });
}
