import 'package:flutter/material.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/theme/app_theme.dart';

/// Living Content Block Card in the sequential stream with inline editing (View = Edit).
class LivingBlockCard extends StatefulWidget {
  final EntityBlock block;
  final ValueChanged<String> onUpdate;
  final VoidCallback onDelete;

  const LivingBlockCard({
    super.key,
    required this.block,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<LivingBlockCard> createState() => _LivingBlockCardState();
}

class _LivingBlockCardState extends State<LivingBlockCard> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.block.content);
  }

  @override
  void didUpdateWidget(covariant LivingBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content && !_isEditing) {
      _editController.text = widget.block.content;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _save() {
    final clean = _editController.text.trim();
    if (clean.isNotEmpty && clean != widget.block.content) {
      widget.onUpdate(clean);
    }
    setState(() => _isEditing = false);
  }

  void _cancel() {
    _editController.text = widget.block.content;
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isEditing ? AppTheme.primary.withOpacity(0.5) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            TextField(
              controller: _editController,
              autofocus: true,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancel,
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  label: const Text('Salva', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: _save,
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () => setState(() => _isEditing = true),
                    child: Text(
                      widget.block.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white38),
                  color: const Color(0xFF222228),
                  onSelected: (val) {
                    if (val == 'edit') {
                      setState(() => _isEditing = true);
                    } else if (val == 'delete') {
                      widget.onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Modifica blocco', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Elimina blocco', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.block.createdAt.hour.toString().padLeft(2, '0')}:${widget.block.createdAt.minute.toString().padLeft(2, '0')} · ${widget.block.createdAt.day}/${widget.block.createdAt.month}',
              style: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
