import 'package:flutter/material.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'base_quick_add_sheet.dart';

class SimpleContentQuickAddForm extends StatefulWidget {
  final String? selectedFolderId;
  final VoidCallback onAdded;
  final String type; // 'asterisk' or 'note'

  const SimpleContentQuickAddForm({
    super.key,
    this.selectedFolderId,
    required this.onAdded,
    required this.type,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Color themeColor,
    required String type,
    required Future<List<CollectionFolder>> foldersFuture,
    required VoidCallback onAdded,
  }) {
    return BaseQuickAddSheet.show(
      context: context,
      title: title,
      themeColor: themeColor,
      foldersFuture: foldersFuture,
      childBuilder: (ctx, folderId) => SimpleContentQuickAddForm(
        selectedFolderId: folderId,
        onAdded: onAdded,
        type: type,
      ),
    );
  }

  @override
  State<SimpleContentQuickAddForm> createState() => _SimpleContentQuickAddFormState();
}

class _SimpleContentQuickAddFormState extends State<SimpleContentQuickAddForm> {
  final _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.selectedFolderId == null) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      if (widget.type == 'asterisk') {
        final newItem = AsteriskItem(
          id: '',
          documentId: widget.selectedFolderId!,
          content: content,
          isResolved: false,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await SpaceService().createAsteriskItem(newItem);
      } else if (widget.type == 'note') {
        final newItem = NoteItem(
          id: '',
          documentId: widget.selectedFolderId!,
          content: content,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await SpaceService().createNoteItem(newItem);
      }
      
      if (mounted) {
        widget.onAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Errore durante l'aggiunta")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _contentController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            labelText: 'Contenuto *',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: (_isSaving || widget.selectedFolderId == null) ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.type == 'asterisk' ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            disabledBackgroundColor: (widget.type == 'asterisk' ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6)).withValues(alpha: 0.5),
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Aggiungi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
