import 'package:flutter/material.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'base_quick_add_sheet.dart';

class ResourceQuickAddForm extends StatefulWidget {
  final String? selectedFolderId;
  final VoidCallback onAdded;

  const ResourceQuickAddForm({
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
      title: 'Aggiungi Risorsa',
      themeColor: const Color(0xFF3B82F6),
      foldersFuture: foldersFuture,
      childBuilder: (ctx, folderId) => ResourceQuickAddForm(
        selectedFolderId: folderId,
        onAdded: onAdded,
      ),
    );
  }

  @override
  State<ResourceQuickAddForm> createState() => _ResourceQuickAddFormState();
}

class _ResourceQuickAddFormState extends State<ResourceQuickAddForm> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedMediaType = 'link';
  final List<String> _selectedTagIds = [];
  List<Tag> _allTags = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await TagService().stream.first;
      if (mounted) setState(() => _allTags = tags);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.selectedFolderId == null) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final newItem = ResourceItem(
        id: '',
        documentId: widget.selectedFolderId!,
        title: title,
        url: _urlController.text,
        description: _descController.text,
        mediaType: _selectedMediaType,
        isRead: false,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await SpaceService().createResourceItem(newItem, _selectedTagIds);
      
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
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Titolo *',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _urlController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'URL (opzionale)',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Descrizione (opzionale)',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedMediaType,
          dropdownColor: const Color(0xFF2A2A2D),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Tipo Media',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          items: const [
            DropdownMenuItem(value: 'link', child: Text('Link generico')),
            DropdownMenuItem(value: 'video', child: Text('Video / YouTube')),
            DropdownMenuItem(value: 'image', child: Text('Immagine')),
            DropdownMenuItem(value: 'document', child: Text('Documento / PDF')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _selectedMediaType = v);
          },
        ),
        if (_allTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Tags', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _allTags.map((tag) {
              final isSelected = _selectedTagIds.contains(tag.id);
              return FilterChip(
                label: Text(tag.name),
                selected: isSelected,
                selectedColor: tag.colorObject?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                backgroundColor: const Color(0xFF2A2A2D),
                side: BorderSide(
                  color: isSelected ? (tag.colorObject ?? Colors.blue) : Colors.transparent,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTagIds.add(tag.id);
                    } else {
                      _selectedTagIds.remove(tag.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: (_isSaving || widget.selectedFolderId == null) ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            disabledBackgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.5),
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Aggiungi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
