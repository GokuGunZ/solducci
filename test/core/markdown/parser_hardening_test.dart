import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/core/markdown/parser/markdown_ast_visitor.dart';
import 'package:solducci/core/markdown/models/line_element.dart';

void main() {
  group('Phase A — Parser Hardening & Source Line Alignment Tests', () {
    late MarkdownAstVisitor parser;

    setUp(() {
      parser = MarkdownAstVisitor();
    });

    test('correctly maps physical line index across headers, blank lines, and paragraphs', () {
      final doc = [
        '# Document Header', // line 0
        '',                   // line 1
        'Introductory paragraph line 1', // line 2
        'and continuation line 2',       // line 3
        '',                   // line 4
        '- [ ] First checklist item', // line 5
        '- [x] Second checklist item', // line 6
      ].join('\n');

      final elements = parser.parse(doc);

      // Header
      expect(elements[0].lineIndex, equals(0));
      expect(elements[0].markerType, equals(LineMarkerType.header));

      // Paragraph
      expect(elements[1].lineIndex, equals(2));
      expect(elements[1].lineCount, equals(2));
      expect(elements[1].markerType, equals(LineMarkerType.rawText));

      // Checkboxes
      final check1 = elements.firstWhere((e) => e.textContent.contains('First checklist item'));
      final check2 = elements.firstWhere((e) => e.textContent.contains('Second checklist item'));

      expect(check1.lineIndex, equals(5));
      expect(check1.isChecked, isFalse);
      expect(check2.lineIndex, equals(6));
      expect(check2.isChecked, isTrue);

      // Toggle first item directly by physical line index
      final updated = MarkdownAstVisitor.toggleCheckboxInMarkdown(doc, check1.lineIndex);
      final reParsed = parser.parse(updated);
      final reCheck1 = reParsed.firstWhere((e) => e.textContent.contains('First checklist item'));
      expect(reCheck1.isChecked, isTrue);
    });

    test('accurately assigns distinct line indices to identical duplicate list items', () {
      final doc = [
        '- [ ] Buy milk', // line 0
        '- [ ] Buy apples', // line 1
        '- [ ] Buy milk', // line 2 (duplicate content)
      ].join('\n');

      final elements = parser.parse(doc);
      final milkItems = elements.where((e) => e.textContent == 'Buy milk').toList();

      expect(milkItems.length, equals(2));
      expect(milkItems[0].lineIndex, equals(0));
      expect(milkItems[1].lineIndex, equals(2));

      // Toggling only the second duplicate milk item
      final toggled = MarkdownAstVisitor.toggleCheckboxInMarkdown(doc, milkItems[1].lineIndex);
      final reParsed = parser.parse(toggled);
      final reMilks = reParsed.where((e) => e.textContent == 'Buy milk').toList();

      expect(reMilks[0].isChecked, isFalse);
      expect(reMilks[1].isChecked, isTrue);
    });

    test('handles multi-line list items and tracks lineCount correctly', () {
      final doc = [
        '- [ ] Task with long description', // line 0
        '  This is a continuation line for task 1', // line 1
        '  And another sub-line', // line 2
        '- [ ] Task 2 next item', // line 3
      ].join('\n');

      final elements = parser.parse(doc);
      expect(elements.length, equals(2));

      expect(elements[0].lineIndex, equals(0));
      expect(elements[0].lineCount, equals(3));
      expect(elements[1].lineIndex, equals(3));
      expect(elements[1].lineCount, equals(1));

      // Toggle Task 2
      final toggled = MarkdownAstVisitor.toggleCheckboxInMarkdown(doc, elements[1].lineIndex);
      final reParsed = parser.parse(toggled);
      expect(reParsed[1].isChecked, isTrue);
      expect(reParsed[0].isChecked, isFalse);
    });

    test('preserves CRLF line endings when toggling checkboxes', () {
      final crlfDoc = '# Shopping\r\n\r\n- [ ] Almond milk\r\n- [ ] Sourdough bread\r\n';
      
      final elements = parser.parse(crlfDoc);
      final almond = elements.firstWhere((e) => e.textContent.contains('Almond milk'));
      expect(almond.lineIndex, equals(2));

      final updated = MarkdownAstVisitor.toggleCheckboxInMarkdown(crlfDoc, almond.lineIndex);
      expect(updated.contains('\r\n'), isTrue);
      expect(updated, contains('- [x] Almond milk\r\n'));
      expect(updated, contains('- [ ] Sourdough bread\r\n'));
    });

    test('preserves LF line endings when toggling checkboxes', () {
      final lfDoc = '# Shopping\n\n- [ ] Oat milk\n- [ ] Sourdough bread\n';

      final elements = parser.parse(lfDoc);
      final oat = elements.firstWhere((e) => e.textContent.contains('Oat milk'));
      expect(oat.lineIndex, equals(2));

      final updated = MarkdownAstVisitor.toggleCheckboxInMarkdown(lfDoc, oat.lineIndex);
      expect(updated.contains('\r\n'), isFalse);
      expect(updated, contains('- [x] Oat milk\n'));
    });

    test('accurately locates nested list items across hierarchies', () {
      final doc = [
        '1. Top ordered item 1', // line 0
        '  - Child bullet A',    // line 1
        '  - [ ] Child checkbox B', // line 2
        '2. Top ordered item 2', // line 3
      ].join('\n');

      final elements = parser.parse(doc);
      final top1 = elements.firstWhere((e) => e.textContent.contains('Top ordered item 1'));
      final childA = elements.firstWhere((e) => e.textContent.contains('Child bullet A'));
      final childB = elements.firstWhere((e) => e.textContent.contains('Child checkbox B'));
      final top2 = elements.firstWhere((e) => e.textContent.contains('Top ordered item 2'));

      expect(top1.lineIndex, equals(0));
      expect(childA.lineIndex, equals(1));
      expect(childB.lineIndex, equals(2));
      expect(top2.lineIndex, equals(3));

      // Toggle child checkbox B
      final toggled = MarkdownAstVisitor.toggleCheckboxInMarkdown(doc, childB.lineIndex);
      final reParsed = parser.parse(toggled);
      final reChildB = reParsed.firstWhere((e) => e.textContent.contains('Child checkbox B'));
      expect(reChildB.isChecked, isTrue);
    });

    test('does not modify non-checkbox lines even if invalid line index is requested', () {
      final doc = '# Header\nSome regular paragraph\n- [ ] Task 1';
      final untouched = MarkdownAstVisitor.toggleCheckboxInMarkdown(doc, 0); // Header index
      expect(untouched, equals(doc));
    });
  });
}
