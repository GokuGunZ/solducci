import 'package:markdown/markdown.dart' as md;
import '../models/line_element.dart';

/// Hardened CommonMark / GFM Markdown Parser backed by `package:markdown`.
///
/// Converts a Markdown document into a sequence of structured [LineElement]s
/// with exact physical source line tracking, multi-line span calculation,
/// nesting depth, and marker classification, while guaranteeing byte-exact
/// round-trip fidelity and zero document pollution.
class MarkdownAstVisitor {
  final md.Document _document;

  MarkdownAstVisitor({md.ExtensionSet? extensionSet})
      : _document = md.Document(
          extensionSet: extensionSet ?? md.ExtensionSet.gitHubFlavored,
          encodeHtml: false,
        );

  /// Regular expressions for physical line marker detection
  static final RegExp _headerRegex = RegExp(r'^\s*(#{1,6})\s+(.*)$');
  static final RegExp _checkboxRegex = RegExp(r'^(\s*[-*+]\s+)\[([ xX])\]\s*(.*)$');
  static final RegExp _orderedRegex = RegExp(r'^(\s*)(\d+)[.)]\s+(.*)$');
  static final RegExp _bulletRegex = RegExp(r'^(\s*[-*+]\s+)(?!\[[ xX]\])(.*)$');
  static final RegExp _quoteRegex = RegExp(r'^\s*>\s*(.*)$');
  static final RegExp _codeFenceRegex = RegExp(r'^\s*(```|~~~)(.*)$');

  /// Parses [source] and returns an ordered list of [LineElement]s with exact physical line indices.
  List<LineElement> parse(String source) {
    if (source.isEmpty) return [];

    final rawLines = source.split(RegExp(r'\r?\n'));
    final astNodes = _document.parseLines(rawLines);
    final elements = <LineElement>[];

    // Monotonically advancing pointer into rawLines to guarantee accurate physical line assignment
    int rawCursor = 0;

    void processNode(md.Node node, int depth) {
      if (node is md.Element) {
        final tag = node.tag;

        // 1. Headers: h1..h6
        if (tag.startsWith('h') && tag.length == 2 && int.tryParse(tag[1]) != null) {
          final level = int.parse(tag[1]);
          final text = _extractText(node);

          // Find matching header line at or after rawCursor
          int lineIdx = -1;
          for (int i = rawCursor; i < rawLines.length; i++) {
            final match = _headerRegex.firstMatch(rawLines[i]);
            if (match != null && match.group(1)!.length == level) {
              lineIdx = i;
              break;
            }
          }

          if (lineIdx == -1) {
            lineIdx = rawCursor < rawLines.length ? rawCursor : rawLines.length - 1;
          }

          final raw = lineIdx < rawLines.length ? rawLines[lineIdx] : '# $text';
          elements.add(LineElement(
            id: 'h_${lineIdx}_$level',
            lineIndex: lineIdx,
            lineCount: 1,
            markerType: LineMarkerType.header,
            markerRaw: '#' * level,
            indentLevel: 0,
            textContent: text,
            rawSourceLine: raw,
            headerLevel: level,
          ));
          rawCursor = lineIdx + 1;
          return;
        }

        // 2. Code fences: pre / code
        if (tag == 'pre') {
          // Find opening code fence at or after rawCursor
          int openIdx = -1;
          for (int i = rawCursor; i < rawLines.length; i++) {
            if (_codeFenceRegex.hasMatch(rawLines[i])) {
              openIdx = i;
              break;
            }
          }

          if (openIdx != -1) {
            // Find closing fence
            int closeIdx = rawLines.length;
            for (int i = openIdx + 1; i < rawLines.length; i++) {
              if (_codeFenceRegex.hasMatch(rawLines[i])) {
                closeIdx = i;
                break;
              }
            }

            final totalFenceLines = (closeIdx < rawLines.length ? closeIdx - openIdx + 1 : rawLines.length - openIdx);
            final codeText = _extractText(node);
            final raw = rawLines[openIdx];

            elements.add(LineElement(
              id: 'code_$openIdx',
              lineIndex: openIdx,
              lineCount: totalFenceLines,
              markerType: LineMarkerType.codeFence,
              markerRaw: '```',
              indentLevel: depth,
              textContent: codeText.trim(),
              rawSourceLine: raw,
            ));

            rawCursor = (closeIdx < rawLines.length ? closeIdx + 1 : rawLines.length);
            return;
          }
        }

        // 3. Blockquotes
        if (tag == 'blockquote') {
          // Advance past any blockquote container markers
          for (var child in node.children ?? []) {
            processNode(child, depth + 1);
          }
          return;
        }

        // 4. Lists: ul / ol
        if (tag == 'ul' || tag == 'ol') {
          for (var child in node.children ?? []) {
            if (child is md.Element && child.tag == 'li') {
              _processListItem(
                liNode: child,
                isOrdered: tag == 'ol',
                depth: depth,
                rawLines: rawLines,
                output: elements,
                getCursor: () => rawCursor,
                setCursor: (c) => rawCursor = c,
              );
            } else {
              processNode(child, depth);
            }
          }
          return;
        }

        // 5. Paragraphs: p
        if (tag == 'p') {
          final text = _extractText(node);
          int lineIdx = -1;

          // Find first matching non-empty line at or after rawCursor
          for (int i = rawCursor; i < rawLines.length; i++) {
            final trimmed = rawLines[i].trim();
            if (trimmed.isNotEmpty && !_headerRegex.hasMatch(rawLines[i]) && !_codeFenceRegex.hasMatch(rawLines[i])) {
              lineIdx = i;
              break;
            }
          }

          if (lineIdx == -1) {
            lineIdx = rawCursor < rawLines.length ? rawCursor : rawLines.length - 1;
          }

          final raw = lineIdx >= 0 && lineIdx < rawLines.length ? rawLines[lineIdx] : text;
          final isQuote = _quoteRegex.hasMatch(raw);

          // Calculate paragraph line span (multi-line paragraph)
          int pLineCount = 1;
          for (int j = lineIdx + 1; j < rawLines.length; j++) {
            if (rawLines[j].trim().isEmpty) break;
            if (_headerRegex.hasMatch(rawLines[j]) ||
                _checkboxRegex.hasMatch(rawLines[j]) ||
                _bulletRegex.hasMatch(rawLines[j]) ||
                _orderedRegex.hasMatch(rawLines[j]) ||
                _codeFenceRegex.hasMatch(rawLines[j])) {
              break;
            }
            pLineCount++;
          }

          elements.add(LineElement(
            id: 'p_$lineIdx',
            lineIndex: lineIdx,
            lineCount: pLineCount,
            markerType: isQuote ? LineMarkerType.quote : LineMarkerType.rawText,
            markerRaw: isQuote ? '>' : '',
            indentLevel: depth,
            textContent: text,
            rawSourceLine: raw,
          ));

          rawCursor = lineIdx + pLineCount;
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

  void _processListItem({
    required md.Element liNode,
    required bool isOrdered,
    required int depth,
    required List<String> rawLines,
    required List<LineElement> output,
    required int Function() getCursor,
    required void Function(int) setCursor,
  }) {
    // Detect if this li contains a GFM checkbox input
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

    // Collect nested list elements to process recursively after this item
    final nestedElements = <md.Element>[];
    final textBuffer = StringBuffer();

    void extractInline(md.Node n) {
      if (n is md.Element) {
        if (n.tag == 'input') return; // skip checkbox input
        if (n.tag == 'ul' || n.tag == 'ol') {
          nestedElements.add(n);
          return;
        }
        n.children?.forEach(extractInline);
      } else if (n is md.Text) {
        textBuffer.write(n.text);
      }
    }

    extractInline(liNode);
    final text = textBuffer.toString().trim();

    // Physical line alignment: search forward from cursor for matching list line
    int cursor = getCursor();
    int physicalLineIdx = -1;

    for (int i = cursor; i < rawLines.length; i++) {
      final line = rawLines[i];
      if (isTaskItem) {
        if (_checkboxRegex.hasMatch(line)) {
          physicalLineIdx = i;
          break;
        }
      } else if (isOrdered) {
        if (_orderedRegex.hasMatch(line)) {
          physicalLineIdx = i;
          break;
        }
      } else {
        if (_bulletRegex.hasMatch(line)) {
          physicalLineIdx = i;
          break;
        }
      }
    }

    if (physicalLineIdx == -1) {
      // Fallback safe index if AST and raw string diverge
      physicalLineIdx = cursor < rawLines.length ? cursor : rawLines.length - 1;
    }

    final raw = physicalLineIdx >= 0 && physicalLineIdx < rawLines.length
        ? rawLines[physicalLineIdx]
        : (isTaskItem ? '- [${isChecked ? 'x' : ' '}] $text' : '- $text');

    final markerType = isTaskItem
        ? LineMarkerType.checkbox
        : (isOrdered ? LineMarkerType.numbered : LineMarkerType.bullet);

    final markerRaw = isTaskItem
        ? (isChecked ? '- [x]' : '- [ ]')
        : (isOrdered ? '1.' : '-');

    // Calculate multi-line span (e.g. paragraph inside list item before nested list or next item)
    int spanLines = 1;
    for (int j = physicalLineIdx + 1; j < rawLines.length; j++) {
      final nextLine = rawLines[j];
      final trimmed = nextLine.trim();
      if (trimmed.isEmpty) break;
      if (_checkboxRegex.hasMatch(nextLine) ||
          _bulletRegex.hasMatch(nextLine) ||
          _orderedRegex.hasMatch(nextLine) ||
          _headerRegex.hasMatch(nextLine) ||
          _codeFenceRegex.hasMatch(nextLine)) {
        break;
      }
      // Indented continuation line belonging to this item
      if (nextLine.startsWith('  ') || nextLine.startsWith('\t')) {
        spanLines++;
      } else {
        break;
      }
    }

    output.add(LineElement(
      id: 'li_${physicalLineIdx}_$depth',
      lineIndex: physicalLineIdx,
      lineCount: spanLines,
      markerType: markerType,
      markerRaw: markerRaw,
      indentLevel: depth,
      isChecked: isChecked,
      textContent: text,
      rawSourceLine: raw,
    ));

    // Advance cursor past this item's header line
    setCursor(physicalLineIdx + 1);

    // Recursively process nested list children
    for (var nested in nestedElements) {
      for (var child in nested.children ?? []) {
        if (child is md.Element && child.tag == 'li') {
          _processListItem(
            liNode: child,
            isOrdered: nested.tag == 'ol',
            depth: depth + 1,
            rawLines: rawLines,
            output: output,
            getCursor: getCursor,
            setCursor: setCursor,
          );
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

  /// Toggles a checkbox in [originalMarkdown] at physical line [targetLineIndex]
  /// with byte-exact precision, zero pollution, and line-ending (CRLF vs LF) preservation.
  static String toggleCheckboxInMarkdown(String originalMarkdown, int targetLineIndex) {
    if (originalMarkdown.isEmpty) return originalMarkdown;

    final lineEnding = originalMarkdown.contains('\r\n') ? '\r\n' : '\n';
    final lines = originalMarkdown.split(RegExp(r'\r?\n'));

    if (targetLineIndex < 0 || targetLineIndex >= lines.length) return originalMarkdown;

    final target = lines[targetLineIndex];
    final uncheckedRegex = RegExp(r'^(\s*[-*+]\s+\[) (\].*)$');
    final checkedRegex = RegExp(r'^(\s*[-*+]\s+\[)[xX](\].*)$');

    String updated = target;

    if (uncheckedRegex.hasMatch(target)) {
      updated = target.replaceFirstMapped(uncheckedRegex, (m) => '${m.group(1)}x${m.group(2)}');
    } else if (checkedRegex.hasMatch(target)) {
      updated = target.replaceFirstMapped(checkedRegex, (m) => '${m.group(1)} ${m.group(2)}');
    } else {
      // The target line is not a checkbox line; safeguard document by returning unmodified
      return originalMarkdown;
    }

    lines[targetLineIndex] = updated;
    return lines.join(lineEnding);
  }
}
