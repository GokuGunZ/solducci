import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/controllers/canvas_tree_controller.dart';
import 'package:solducci/features/space/services/canvas_sync_service.dart';

class MarkdownNodeWidget extends StatefulWidget {
  final CanvasNode node;
  final CanvasTreeController controller;
  final int depth;

  const MarkdownNodeWidget({
    super.key,
    required this.node,
    required this.controller,
    required this.depth,
  });

  @override
  State<MarkdownNodeWidget> createState() => _MarkdownNodeWidgetState();
}

class _MarkdownNodeWidgetState extends State<MarkdownNodeWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  Timer? _debounce;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.node.payload['text'] ?? '');
    _focusNode = FocusNode();
    
    // Auto-save on blur
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _saveContent();
        setState(() => _isEditing = false);
      }
    });

    if (widget.node.payload.isEmpty) {
      CanvasSyncService().loadPayload(widget.node.id);
    }
  }

  @override
  void didUpdateWidget(MarkdownNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.payload['text'] != widget.node.payload['text'] && 
        !_focusNode.hasFocus) {
      _textController.text = widget.node.payload['text'] ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _saveContent();
    });
  }

  void _saveContent() {
    final currentText = widget.node.payload['text'] ?? '';
    if (_textController.text != currentText) {
      widget.controller.updateNodeText(
        widget.node, 
        _textController.text
      );
    }
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final double leftPadding = widget.depth == 0 ? 0.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.node.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isEditing ? _buildEditor() : _buildReader(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return TextField(
      key: const ValueKey('editor'),
      controller: _textController,
      focusNode: _focusNode,
      maxLines: null,
      onChanged: _onTextChanged,
      style: const TextStyle(
        color: Color(0xFFE0E0E0), 
        fontSize: 14, 
        fontFamily: 'monospace',
      ),
      decoration: const InputDecoration(
        hintText: 'Scrivi qui...',
        hintStyle: TextStyle(color: Colors.white24),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildReader() {
    final text = _textController.text;
    
    return GestureDetector(
      key: const ValueKey('reader'),
      onTap: _startEditing,
      behavior: HitTestBehavior.opaque,
      child: text.trim().isEmpty 
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text(
              'Tocca per scrivere un appunto...',
              style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic),
            ),
          )
        : MarkdownBody(
            data: text,
            selectable: false,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 15, height: 1.5),
              h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
              h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
              h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
              h4: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
              h5: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
              h6: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.2),
              em: const TextStyle(fontStyle: FontStyle.italic),
              strong: const TextStyle(fontWeight: FontWeight.bold),
              blockquote: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
              blockquoteDecoration: BoxDecoration(
                border: const Border(left: BorderSide(color: Color(0xFF6366F1), width: 4)),
                color: const Color(0xFF6366F1).withOpacity(0.1),
              ),
              code: const TextStyle(color: Color(0xFF10B981), backgroundColor: Colors.transparent, fontFamily: 'monospace'),
              codeblockDecoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              listBullet: const TextStyle(color: Color(0xFF6366F1)),
              checkbox: const TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
    );
  }
}
