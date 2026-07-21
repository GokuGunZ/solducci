import 'package:flutter/material.dart';

class CollectionFolder {
  final String id;
  final String name;
  CollectionFolder(this.id, this.name);
}

class QuickAddItemModal extends StatefulWidget {
  final String title;
  final Color themeColor;
  final Future<List<CollectionFolder>> foldersFuture;
  final Function(String folderId, String itemName) onAdd;

  const QuickAddItemModal({
    super.key,
    required this.title,
    required this.themeColor,
    required this.foldersFuture,
    required this.onAdd,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Color themeColor,
    required Future<List<CollectionFolder>> foldersFuture,
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
          foldersFuture: foldersFuture,
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildFolderSelector(BuildContext context, List<CollectionFolder> folders) {
    if (folders.isEmpty) {
      return const Text('Nessuna destinazione trovata. Creane una prima.', style: TextStyle(color: Colors.white54));
    }

    if (folders.length <= 6) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: folders.map((folder) {
          final isSelected = _selectedFolderId == folder.id;
          return ChoiceChip(
            label: Text(folder.name),
            selected: isSelected,
            selectedColor: widget.themeColor.withValues(alpha: 0.2),
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
            items: folders.map((folder) {
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
          FutureBuilder<List<CollectionFolder>>(
            future: widget.foldersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: widget.themeColor),
                  ),
                );
              }
              
              final folders = snapshot.data ?? [];
              
              // Seleziona il primo di default se non è già stato selezionato
              if (_selectedFolderId == null && folders.isNotEmpty) {
                // Posticipiamo l'aggiornamento dello stato alla fine del frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedFolderId == null) {
                    setState(() {
                      _selectedFolderId = folders.first.id;
                    });
                  }
                });
              }
              
              return _buildFolderSelector(context, folders);
            },
          ),
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
