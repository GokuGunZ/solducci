import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/core/markdown/models/line_element.dart';
import 'package:solducci/core/markdown/widgets/line_modifier_dialog.dart';

void main() {
  group('LineModifierDialog Responsive & Usability Tests', () {
    const testElement = LineElement(
      id: 'test_1',
      lineIndex: 0,
      markerType: LineMarkerType.checkbox,
      markerRaw: '- [ ]',
      indentLevel: 0,
      textContent: 'Item for styling',
      rawSourceLine: '- [ ] Item for styling',
    );

    const testRule = LineMarkerRule(
      markerType: LineMarkerType.checkbox,
      modifier: LineModifierStyle(),
      dataSource: DataSourceBindingConfig(),
    );

    testWidgets('renders split configuration modal with morphology, styling, and data-source sections', (tester) async {
      LineMarkerRule? savedRule;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LineModifierDialog(
              element: testElement,
              currentRule: testRule,
              onSaveRule: (r) => savedRule = r,
            ),
          ),
        ),
      );

      // Verify sections are visible
      expect(find.text('Personalizza Elemento di Riga'), findsOneWidget);
      expect(find.text('1. Morfologia Icona'), findsOneWidget);
      expect(find.text('2. Modificatore di Riga'), findsOneWidget);
      expect(find.text('3. Connessione Fonte Dati Solducci'), findsOneWidget);

      // Verify styling toggles
      expect(find.text('Testo Barrato (Strikethrough)'), findsOneWidget);
      expect(find.text('Grassetto (Bold Weight)'), findsOneWidget);

      // Toggle bold and save
      await tester.tap(find.text('Grassetto (Bold Weight)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Applica alla Pagina'));
      await tester.pumpAndSettle();

      expect(savedRule, isNotNull);
      expect(savedRule?.modifier.bold, isTrue);
    });

    testWidgets('activates data source binding fields when switch is enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LineModifierDialog(
              element: testElement,
              currentRule: testRule,
              onSaveRule: (_) {},
            ),
          ),
        ),
      );

      // Initially data source dropdowns are not rendered
      expect(find.text('Entità Target'), findsNothing);

      // Toggle the data-source switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Now target dropdown should appear
      expect(find.text('Entità Target'), findsOneWidget);
      expect(find.text('Ambito Contesto'), findsOneWidget);
    });
  });
}
