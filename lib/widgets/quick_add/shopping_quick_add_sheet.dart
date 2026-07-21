import 'package:flutter/material.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'base_quick_add_sheet.dart';

class ShoppingQuickAddForm extends StatefulWidget {
  final String? selectedFolderId;
  final VoidCallback onAdded;

  const ShoppingQuickAddForm({
    super.key,
    this.selectedFolderId,
    required this.onAdded,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<List<CollectionFolder>> foldersFuture,
    required VoidCallback onAdded,
  }) {
    return BaseQuickAddSheet.show(
      context: context,
      title: 'Aggiungi alla Spesa',
      themeColor: const Color(0xFF10B981),
      foldersFuture: foldersFuture,
      childBuilder: (ctx, folderId) => ShoppingQuickAddForm(
        selectedFolderId: folderId,
        onAdded: onAdded,
      ),
    );
  }

  @override
  State<ShoppingQuickAddForm> createState() => _ShoppingQuickAddFormState();
}

class _ShoppingQuickAddFormState extends State<ShoppingQuickAddForm> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.selectedFolderId == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final newItem = ShoppingListItem(
        id: '',
        documentId: widget.selectedFolderId!,
        name: name,
        quantity: 1.0,
        isBought: false,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await SpaceService().createShoppingListItem(newItem);
      
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
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Cerca o aggiungi prodotto...',
            labelStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: (_isSaving || widget.selectedFolderId == null) ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.5),
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Aggiungi Rapido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
