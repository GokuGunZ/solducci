import 'package:flutter/material.dart';

class CollectionFolder {
  final String id;
  final String name;
  CollectionFolder(this.id, this.name);
}

class QuickAddItemModal extends StatefulWidget {
  final String title;
  final Color themeColor;
  final List<CollectionFolder> folders;
  final Function(String folderId, String itemName) onAdd;

  const QuickAddItemModal({
    super.key,
    required this.title,
    required this.themeColor,
    required this.folders,
    required this.onAdd,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Color themeColor,
    required List<CollectionFolder> folders,
    required Function(String folderId, String itemName) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: QuickAddItemModal(
          title: title,
          themeColor: themeColor,
          folders: folders,
          onAdd: onAdd,
        ),
      ),
    );
  }

  @override
  State<QuickAddItemModal> createState() => _QuickAddItemModalState();
}

class _QuickAddItemModalState extends State<QuickAddItemModal> {
  String? _selectedFolderId;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.folders.isNotEmpty) {
      _selectedFolderId = widget.folders.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildFolderSelector(BuildContext context) {
    // Euristica per le chips: se ci sono <= 6 cartelle (circa 1-2 righe di Wrap su un telefono), usa i ChoiceChip.
    // Altrimenti passa a un Dropdown per risparmiare spazio.
    if (widget.folders.length <= 6) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: widget.folders.map((folder) {
          final isSelected = _selectedFolderId == folder.id;
          return ChoiceChip(
            label: Text(folder.name),
            selected: isSelected,
            selectedColor: widget.themeColor.withOpacity(0.2),
            backgroundColor: const Color(0xFF2A2A2D),
            labelStyle: TextStyle(
              color: isSelected ? widget.themeColor : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? widget.themeColor : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFolderId = folder.id;
                });
              }
            },
          );
        }).toList(),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedFolderId,
            isExpanded: true,
            dropdownColor: const Color(0xFF2A2A2D),
            icon: Icon(Icons.arrow_drop_down, color: widget.themeColor),
            items: widget.folders.map((folder) {
              return DropdownMenuItem<String>(
                value: folder.id,
                child: Text(folder.name, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedFolderId = val;
                });
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Seleziona Destinazione',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildFolderSelector(context),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nome elemento',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF2A2A2D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: widget.themeColor),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              if (_selectedFolderId != null && _nameController.text.isNotEmpty) {
                widget.onAdd(_selectedFolderId!, _nameController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text('Aggiungi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
