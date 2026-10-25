import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/core/markdown/models/line_element.dart';
import 'package:solducci/core/markdown/parser/markdown_ast_visitor.dart';

void main() {
  group('MarkdownAstVisitor Parser Tests', () {
    late MarkdownAstVisitor visitor;

    setUp(() {
      visitor = MarkdownAstVisitor();
    });

    test('parses headings with correct hierarchy and levels', () {
      const mdText = '''# Heading 1
## Heading 2
### Heading 3''';

      final elements = visitor.parse(mdText);

      expect(elements.length, equals(3));
      expect(elements[0].markerType, equals(LineMarkerType.header));
      expect(elements[0].headerLevel, equals(1));
      expect(elements[0].textContent, equals('Heading 1'));

      expect(elements[1].markerType, equals(LineMarkerType.header));
      expect(elements[1].headerLevel, equals(2));

      expect(elements[2].markerType, equals(LineMarkerType.header));
      expect(elements[2].headerLevel, equals(3));
    });

    test('parses GFM task lists and distinguishes checked vs unchecked', () {
      const mdText = '''- [ ] Pending task
- [x] Completed task
* [X] Uppercase completed task''';

      final elements = visitor.parse(mdText);

      expect(elements.length, equals(3));
      expect(elements[0].markerType, equals(LineMarkerType.checkbox));
      expect(elements[0].isChecked, isFalse);
      expect(elements[0].textContent, equals('Pending task'));

      expect(elements[1].markerType, equals(LineMarkerType.checkbox));
      expect(elements[1].isChecked, isTrue);
      expect(elements[1].textContent, equals('Completed task'));

      expect(elements[2].markerType, equals(LineMarkerType.checkbox));
      expect(elements[2].isChecked, isTrue);
    });

    test('parses nested lists with correct indent levels', () {
      const mdText = '''- Parent item
  - [ ] Child task 1
  - [x] Child task 2
    - Deep grandchild''';

      final elements = visitor.parse(mdText);

      expect(elements.length, equals(4));
      expect(elements[0].textContent, equals('Parent item'));
      expect(elements[0].indentLevel, equals(0));

      expect(elements[1].markerType, equals(LineMarkerType.checkbox));
      expect(elements[1].textContent, equals('Child task 1'));
      expect(elements[1].indentLevel, equals(1));

      expect(elements[2].isChecked, isTrue);
      expect(elements[2].indentLevel, equals(1));

      expect(elements[3].indentLevel, equals(2));
    });

    test('isolates code fences without mistaking internal text for markers', () {
      const mdText = '''```dart
void main() {
  // - [ ] This is not a real checklist!
}
```''';

      final elements = visitor.parse(mdText);

      expect(elements.every((e) => e.markerType == LineMarkerType.codeFence), isTrue);
      expect(elements.any((e) => e.markerType == LineMarkerType.checkbox), isFalse);
    });

    test('toggles checkbox in markdown source with zero pollution and exact byte fidelity', () {
      const original = '''# My Notes
- [ ] Buy oat milk
- [x] Buy sourdough bread
- Regular bullet''';

      // Toggle unchecked item to checked (line 1)
      final toggled1 = MarkdownAstVisitor.toggleCheckboxInMarkdown(original, 1);
      expect(toggled1.contains('- [x] Buy oat milk'), isTrue);
      expect(toggled1.contains('- [x] Buy sourdough bread'), isTrue);

      // Toggle back checked item to unchecked (line 2)
      final toggled2 = MarkdownAstVisitor.toggleCheckboxInMarkdown(toggled1, 2);
      expect(toggled2.contains('- [ ] Buy sourdough bread'), isTrue);

      // Verify no extra comments or UUIDs were introduced
      expect(toggled2.contains('<!--'), isFalse);
      expect(toggled2.contains('id:'), isFalse);
    });
  });
}
