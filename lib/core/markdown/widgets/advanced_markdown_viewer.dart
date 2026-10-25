import 'package:flutter/material.dart';
import '../models/line_element.dart';
import '../parser/markdown_ast_visitor.dart';
import 'interactive_line_item.dart';
import 'line_modifier_dialog.dart';

/// Interactive Markdown viewer widget supporting non-destructive line styling,
/// gesture disambiguation (tap vs long-press), and data-source configuration.
class AdvancedMarkdownViewer extends StatefulWidget {
  final String markdown;
  final ValueChanged<String>? onMarkdownChanged;
  final Map<LineMarkerType, LineMarkerRule>? initialRules;
  final ValueChanged<Map<LineMarkerType, LineMarkerRule>>? onRulesChanged;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AdvancedMarkdownViewer({
    super.key,
    required this.markdown,
    this.onMarkdownChanged,
    this.initialRules,
    this.onRulesChanged,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<AdvancedMarkdownViewer> createState() => _AdvancedMarkdownViewerState();
}

class _AdvancedMarkdownViewerState extends State<AdvancedMarkdownViewer> {
  late final MarkdownAstVisitor _visitor;
  late Map<LineMarkerType, LineMarkerRule> _rules;
  late List<LineElement> _elements;

  @override
  void initState() {
    super.initState();
    _visitor = MarkdownAstVisitor();
    _rules = widget.initialRules != null
        ? Map.from(widget.initialRules!)
        : _createDefaultRules();
    _parseMarkdown();
  }

  @override
  void didUpdateWidget(AdvancedMarkdownViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdown != widget.markdown) {
      _parseMarkdown();
    }
  }

  void _parseMarkdown() {
    _elements = _visitor.parse(widget.markdown);
  }

  Map<LineMarkerType, LineMarkerRule> _createDefaultRules() {
    return {
      LineMarkerType.checkbox: const LineMarkerRule(
        markerType: LineMarkerType.checkbox,
        modifier: LineModifierStyle.checkedDefault,
      ),
      LineMarkerType.bullet: const LineMarkerRule(
        markerType: LineMarkerType.bullet,
        modifier: LineModifierStyle(),
      ),
      LineMarkerType.numbered: const LineMarkerRule(
        markerType: LineMarkerType.numbered,
        modifier: LineModifierStyle(),
      ),
      LineMarkerType.quote: const LineMarkerRule(
        markerType: LineMarkerType.quote,
        modifier: LineModifierStyle(),
      ),
    };
  }

  void _handleToggleCheckbox(int lineIndex) {
    final updated = MarkdownAstVisitor.toggleCheckboxInMarkdown(widget.markdown, lineIndex);
    widget.onMarkdownChanged?.call(updated);
    setState(() {
      _parseMarkdown();
    });
  }

  void _handleLongPressMarker(LineElement element) async {
    final rule = _rules[element.markerType] ??
        LineMarkerRule(markerType: element.markerType);

    final updated = await LineModifierDialog.show(
      context,
      element: element,
      currentRule: rule,
    );

    if (updated != null && mounted) {
      setState(() {
        _rules[element.markerType] = updated;
      });
      widget.onRulesChanged?.call(_rules);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_elements.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      controller: widget.scrollController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _elements.length,
      itemBuilder: (context, index) {
        final element = _elements[index];
        final rule = _rules[element.markerType];
        final isDataBound = rule?.dataSource.isConnected ?? false;

        return InteractiveLineItem(
          key: ValueKey('line_${element.id}_${element.isChecked}'),
          element: element,
          modifier: rule?.modifier,
          isDataBound: isDataBound,
          onToggleCheckbox: _handleToggleCheckbox,
          onLongPressMarker: _handleLongPressMarker,
        );
      },
    );
  }
}
