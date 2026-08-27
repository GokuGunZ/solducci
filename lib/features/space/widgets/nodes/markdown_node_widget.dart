import 'package:flutter/material.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/controllers/canvas_tree_controller.dart';
import 'package:solducci/features/space/services/canvas_sync_service.dart';
import 'package:solducci/widgets/liquid_markdown_editor.dart';

class MarkdownNodeWidget extends StatefulWidget {
  final CanvasNode node;
  final CanvasTreeController controller;
  final int depth;
  final int limit;
  final String? selectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelect;

  const MarkdownNodeWidget({
    super.key,
    required this.node,
    required this.controller,
    required this.depth,
    required this.limit,
    this.selectionMode,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<MarkdownNodeWidget> createState() => _MarkdownNodeWidgetState();
}

class _MarkdownNodeWidgetState extends State<MarkdownNodeWidget> {
  bool _autoOpenEditor = false;

  @override
  void initState() {
    super.initState();

    if (widget.node.payload.isEmpty) {
      CanvasSyncService().loadPayload(widget.node.id);
    }

    if (widget.node.metadata['isDraftNew'] == true) {
      _autoOpenEditor = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.updateNodeMetadata(widget.node.id, {'isDraftNew': false});
      });
    } else {
      final isNew = DateTime.now().toUtc().difference(widget.node.createdAt).inSeconds.abs() < 5;
      final text = widget.node.payload['text'] ?? '';
      if (isNew && text.isEmpty) {
        _autoOpenEditor = true;
      }
    }
  }

  void _onTextChanged(String newText) {
    widget.controller.updateNodeText(widget.node, newText);
  }

  void _onTitleChanged(String newTitle) {
    final titleToSave = newTitle.trim().isEmpty ? 'Senza Titolo' : newTitle.trim();
    widget.controller.updateNodeTitle(widget.node, titleToSave);
  }

  @override
  Widget build(BuildContext context) {
    return LiquidMarkdownEditor(
      initialText: widget.node.payload['text'] ?? '',
      initialTitle: widget.node.title,
      onTextChanged: _onTextChanged,
      onTitleChanged: _onTitleChanged,
      markdownFontSize: widget.controller.markdownFontSize,
      autoOpenEditor: _autoOpenEditor,
      isSelected: widget.isSelected,
      selectionMode: widget.selectionMode,
      onSelect: widget.onSelect,
      depth: widget.depth,
      limit: widget.limit,
    );
  }
}
