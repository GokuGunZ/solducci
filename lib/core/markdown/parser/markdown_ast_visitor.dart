import 'package:markdown/markdown.dart' as md;
import '../models/line_element.dart';

/// Standard CommonMark / GFM Markdown Parser backed by `package:markdown`.
///
/// Converts a Markdown document into a sequence of structured [LineElement]s
/// with full AST fidelity, nesting depth, and marker classification, while
/// preserving source text integrity.
class MarkdownAstVisitor {
  final md.Document _document;

  MarkdownAstVisitor({md.ExtensionSet? extensionSet})
      : _document = md.Document(
          extensionSet: extensionSet ?? md.ExtensionSet.gitHubFlavored,
          encodeHtml: false,
        );

  /// Parses [source] and returns an ordered list of [LineElement]s.
  List<LineElement> parse(String source) {
    if (source.isEmpty) return [];

    final rawLines = source.split(RegExp(r'\r?\n'));
    final astNodes = _document.parseLines(rawLines);
    final elements = <LineElement>[];

    // Source line tracking pointer
    int currentLineIndex = 0;

    void processNode(md.Node node, int depth) {
      if (node is md.Element) {
        final tag = node.tag;

        if (tag.startsWith('h') && tag.length == 2 && int.tryParse(tag[1]) != null) {
          final level = int.parse(tag[1]);
          final text = _extractText(node);
          final raw = currentLineIndex < rawLines.length ? rawLines[currentLineIndex] : '# $text';
          elements.add(LineElement(
            id: 'h_${currentLineIndex}_$level',
            lineIndex: currentLineIndex,
            markerType: LineMarkerType.header,
            markerRaw: '#' * level,
            indentLevel: 0,
            textContent: text,
            rawSourceLine: raw,
            headerLevel: level,
          ));
          currentLineIndex++;
          return;
        }

        if (tag == 'pre') {
          final codeText = _extractText(node);
          final codeLines = codeText.split('\n');
          // Skip opening code fence line if present in raw
          if (currentLineIndex < rawLines.length && rawLines[currentLineIndex].trim().startsWith('```')) {
            currentLineIndex++;
          }
          for (var cLine in codeLines) {
            if (cLine.isEmpty && currentLineIndex >= rawLines.length) continue;
            final raw = currentLineIndex < rawLines.length ? rawLines[currentLineIndex] : cLine;
            elements.add(LineElement(
              id: 'code_$currentLineIndex',
              lineIndex: currentLineIndex,
              markerType: LineMarkerType.codeFence,
              markerRaw: '```',
              indentLevel: depth,
              textContent: cLine,
              rawSourceLine: raw,
            ));
            currentLineIndex++;
          }
          if (currentLineIndex < rawLines.length && rawLines[currentLineIndex].trim().startsWith('```')) {
            currentLineIndex++;
          }
          return;
        }

        if (tag == 'blockquote') {
          for (var child in node.children ?? []) {
            processNode(child, depth + 1);
          }
          return;
        }

        if (tag == 'ul' || tag == 'ol') {
          for (var child in node.children ?? []) {
            if (child is md.Element && child.tag == 'li') {
              _processListItem(child, tag == 'ol', depth, rawLines, elements, () => currentLineIndex++);
            } else {
              processNode(child, depth);
            }
          }
          return;
        }

        if (tag == 'p') {
          // Plain paragraph or blockquote line
          final text = _extractText(node);
          final raw = currentLineIndex < rawLines.length ? rawLines[currentLineIndex] : text;
          final isQuote = raw.trimLeft().startsWith('>');
          elements.add(LineElement(
            id: 'p_$currentLineIndex',
            lineIndex: currentLineIndex,
            markerType: isQuote ? LineMarkerType.quote : LineMarkerType.rawText,
            markerRaw: isQuote ? '>' : '',
            indentLevel: depth,
            textContent: text,
            rawSourceLine: raw,
          ));
          currentLineIndex++;
          return;
        }

        // Generic container fallback
        node.children?.forEach((c) => processNode(c, depth));
      }
    }

    for (var node in astNodes) {
      processNode(node, 0);
    }

    return elements;
  }

  void _processListItem(
    md.Element liNode,
    bool isOrdered,
    int depth,
    List<String> rawLines,
    List<LineElement> output,
    void Function() incrementLine,
  ) {
    // Check if GFM Task List item (contains checkbox input)
    bool isTaskItem = false;
    bool isChecked = false;

    void findCheckbox(md.Node n) {
      if (n is md.Element && n.tag == 'input' && n.attributes['type'] == 'checkbox') {
        isTaskItem = true;
        isChecked = n.attributes.containsKey('checked');
      }
      if (n is md.Element) {
        n.children?.forEach(findCheckbox);
      }
    }

    findCheckbox(liNode);

    // Extract text content excluding the checkbox itself
    final buffer = StringBuffer();
    final nestedElements = <md.Element>[];

    void extractInline(md.Node n) {
      if (n is md.Element) {
        if (n.tag == 'input') return; // skip input
        if (n.tag == 'ul' || n.tag == 'ol') {
          nestedElements.add(n);
          return;
        }
        n.children?.forEach(extractInline);
      } else if (n is md.Text) {
        buffer.write(n.text);
      }
    }

    extractInline(liNode);
    final text = buffer.toString().trim();

    // Align with raw line
    final lineIdx = output.length;
    final raw = lineIdx < rawLines.length ? rawLines[lineIdx] : (isTaskItem ? '- [${isChecked ? 'x' : ' '}] $text' : '- $text');

    final markerType = isTaskItem
        ? LineMarkerType.checkbox
        : (isOrdered ? LineMarkerType.numbered : LineMarkerType.bullet);

    final markerRaw = isTaskItem
        ? (isChecked ? '- [x]' : '- [ ]')
        : (isOrdered ? '1.' : '-');

    output.add(LineElement(
      id: 'li_${output.length}_$depth',
      lineIndex: output.length,
      markerType: markerType,
      markerRaw: markerRaw,
      indentLevel: depth,
      isChecked: isChecked,
      textContent: text,
      rawSourceLine: raw,
    ));
    incrementLine();

    // Process nested lists if any
    for (var nested in nestedElements) {
      for (var child in nested.children ?? []) {
        if (child is md.Element && child.tag == 'li') {
          _processListItem(child, nested.tag == 'ol', depth + 1, rawLines, output, incrementLine);
        }
      }
    }
  }

  String _extractText(md.Node node) {
    final sb = StringBuffer();
    void append(md.Node n) {
      if (n is md.Text) {
        sb.write(n.text);
      } else if (n is md.Element) {
        n.children?.forEach(append);
      }
    }
    append(node);
    return sb.toString();
  }

  /// Toggles a checkbox in [originalMarkdown] at line [targetLineIndex]
  /// with byte-exact precision and zero pollution.
  static String toggleCheckboxInMarkdown(String originalMarkdown, int targetLineIndex) {
    final lines = originalMarkdown.split(RegExp(r'\r?\n'));
    if (targetLineIndex < 0 || targetLineIndex >= lines.length) return originalMarkdown;

    final target = lines[targetLineIndex];
    String updated = target;

    final uncheckedRegex = RegExp(r'^(\s*[-*+]\s+\[) (\].*)$');
    final checkedRegex = RegExp(r'^(\s*[-*+]\s+\[)[xX](\].*)$');

    if (uncheckedRegex.hasMatch(target)) {
      updated = target.replaceFirstMapped(uncheckedRegex, (m) => '${m.group(1)}x${m.group(2)}');
    } else if (checkedRegex.hasMatch(target)) {
      updated = target.replaceFirstMapped(checkedRegex, (m) => '${m.group(1)} ${m.group(2)}');
    }

    lines[targetLineIndex] = updated;
    return lines.join('\n');
  }
}
