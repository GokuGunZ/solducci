import 'package:flutter/material.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'base_quick_add_sheet.dart';

class PantryQuickAddForm extends StatefulWidget {
  final String? selectedFolderId;
  final VoidCallback onAdded;

  const PantryQuickAddForm({
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
      title: 'Aggiungi in Dispensa',
      themeColor: const Color(0xFF10B981),
      foldersFuture: foldersFuture,
      childBuilder: (ctx, folderId) => PantryQuickAddForm(
        selectedFolderId: folderId,
        onAdded: onAdded,
      ),
    );
  }

  @override
  State<PantryQuickAddForm> createState() => _PantryQuickAddFormState();
}

class _PantryQuickAddFormState extends State<PantryQuickAddForm> {
  final _nameController = TextEditingController();
  final _thresholdController = TextEditingController();
  String _selectedUnit = 'pcs';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.selectedFolderId == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final threshold = double.tryParse(_thresholdController.text);
      final newItem = PantryItem(
        id: '',
        documentId: widget.selectedFolderId!,
        name: name,
        thresholdLow: threshold,
        unit: _selectedUnit,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await SpaceService().createPantryItem(newItem);
      
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
          decoration: InputDecoration(
            labelText: 'Nome prodotto *',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Soglia minima (opzionale)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                dropdownColor: const Color(0xFF2A2A2D),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Unità di misura',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'pcs', child: Text('Pezzi (pcs)')),
                  DropdownMenuItem(value: 'kg', child: Text('Kilogrammi (kg)')),
                  DropdownMenuItem(value: 'l', child: Text('Litri (l)')),
                  DropdownMenuItem(value: 'pack', child: Text('Confezioni')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedUnit = v);
                },
              ),
            ),
          ],
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
              : const Text('Aggiungi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
