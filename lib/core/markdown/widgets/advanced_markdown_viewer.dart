import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import '../models/line_element.dart';
import '../models/document_markdown_config.dart';
import '../parser/markdown_ast_visitor.dart';
import '../adapters/data_binding_engine.dart';
import 'interactive_line_item.dart';
import 'line_modifier_dialog.dart';

/// Interactive Markdown viewer widget supporting non-destructive line styling,
/// gesture disambiguation (tap vs long-press), and data-source configuration.
class AdvancedMarkdownViewer extends StatefulWidget {
  final String markdown;
  final ValueChanged<String>? onMarkdownChanged;
  final Map<LineMarkerType, LineMarkerRule>? initialRules;
  final ValueChanged<Map<LineMarkerType, LineMarkerRule>>? onRulesChanged;
  final Document? document;
  final DocumentMarkdownConfig? documentConfig;
  final ValueChanged<DocumentMarkdownConfig>? onDocumentConfigChanged;
  final MarkdownDataBindingEngine? bindingEngine;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AdvancedMarkdownViewer({
    super.key,
    required this.markdown,
    this.onMarkdownChanged,
    this.initialRules,
    this.onRulesChanged,
    this.document,
    this.documentConfig,
    this.onDocumentConfigChanged,
    this.bindingEngine,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<AdvancedMarkdownViewer> createState() => _AdvancedMarkdownViewerState();
}

class _AdvancedMarkdownViewerState extends State<AdvancedMarkdownViewer> {
  late final MarkdownAstVisitor _visitor;
  late DocumentMarkdownConfig _config;
  late Map<LineMarkerType, LineMarkerRule> _rules;
  late List<LineElement> _elements;

  @override
  void initState() {
    super.initState();
    _visitor = MarkdownAstVisitor();

    if (widget.documentConfig != null) {
      _config = widget.documentConfig!;
      _rules = Map.from(_config.rules);
    } else if (widget.document != null) {
      _config = widget.document!.markdownConfig;
      _rules = Map.from(_config.rules);
    } else if (widget.initialRules != null) {
      _rules = Map.from(widget.initialRules!);
      _config = DocumentMarkdownConfig(rules: _rules);
    } else {
      _rules = _createDefaultRules();
      _config = DocumentMarkdownConfig(rules: _rules);
    }

    _parseMarkdown();
  }

  @override
  void didUpdateWidget(AdvancedMarkdownViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdown != widget.markdown) {
      _parseMarkdown();
    }
    if (widget.documentConfig != null && widget.documentConfig != oldWidget.documentConfig) {
      _config = widget.documentConfig!;
      _rules = Map.from(_config.rules);
    }
  }

  void _parseMarkdown() {
    final rawElements = _visitor.parse(widget.markdown);
    
    // Enrich parsed elements with syncState from active bindings
    _elements = rawElements.map((el) {
      final anchorKey = 'anchor_${el.id}';
      final binding = _config.bindings[anchorKey];
      if (binding != null) {
        return el.copyWith(
          syncState: binding.syncState,
          boundEntityId: binding.targetEntityId,
        );
      }
      return el;
    }).toList();
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

  void _handleToggleCheckbox(int lineIndex) async {
    final updated = MarkdownAstVisitor.toggleCheckboxInMarkdown(widget.markdown, lineIndex);
    widget.onMarkdownChanged?.call(updated);

    setState(() {
      _parseMarkdown();
    });

    // If binding engine is attached to a real document, synchronize changes
    if (widget.bindingEngine != null && widget.document != null) {
      final updatedConfig = await widget.bindingEngine!.syncDocument(
        document: widget.document!,
        elements: _elements,
      );

      if (mounted) {
        setState(() {
          _config = updatedConfig;
          _parseMarkdown();
        });
        widget.onDocumentConfigChanged?.call(_config);
      }
    }
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
      final newRules = Map<LineMarkerType, LineMarkerRule>.from(_rules);
      newRules[element.markerType] = updated;

      final newConfig = _config.copyWith(rules: newRules);

      setState(() {
        _rules = newRules;
        _config = newConfig;
        _parseMarkdown();
      });

      widget.onRulesChanged?.call(_rules);
      widget.onDocumentConfigChanged?.call(_config);

      // Trigger sync if binding changed to connected
      if (updated.dataSource.isConnected && widget.bindingEngine != null && widget.document != null) {
        final syncedConfig = await widget.bindingEngine!.syncDocument(
          document: widget.document!,
          elements: _elements,
        );

        if (mounted) {
          setState(() {
            _config = syncedConfig;
            _parseMarkdown();
          });
          widget.onDocumentConfigChanged?.call(_config);
        }
      }
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
          key: ValueKey('line_${element.id}_${element.isChecked}_${element.syncState.name}'),
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
