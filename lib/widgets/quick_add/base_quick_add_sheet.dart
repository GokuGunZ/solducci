import 'package:flutter/material.dart';

class CollectionFolder {
  final String id;
  final String name;
  CollectionFolder(this.id, this.name);
}

class BaseQuickAddSheet extends StatefulWidget {
  final String title;
  final Color themeColor;
  final Future<List<CollectionFolder>> foldersFuture;
  final String folderSelectorLabel;
  final Widget Function(BuildContext context, String? selectedFolderId) childBuilder;

  const BaseQuickAddSheet({
    super.key,
    required this.title,
    required this.themeColor,
    required this.foldersFuture,
    this.folderSelectorLabel = 'Scegli destinazione',
    required this.childBuilder,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Color themeColor,
    required Future<List<CollectionFolder>> foldersFuture,
    String folderSelectorLabel = 'Scegli destinazione',
    required Widget Function(BuildContext context, String? selectedFolderId) childBuilder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BaseQuickAddSheet(
          title: title,
          themeColor: themeColor,
          foldersFuture: foldersFuture,
          folderSelectorLabel: folderSelectorLabel,
          childBuilder: childBuilder,
        ),
      ),
    );
  }

  @override
  State<BaseQuickAddSheet> createState() => _BaseQuickAddSheetState();
}

class _BaseQuickAddSheetState extends State<BaseQuickAddSheet> {
  String? _selectedFolderId;

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
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedFolderId,
            isExpanded: true,
            dropdownColor: const Color(0xFF2A2A2D),
            icon: Icon(Icons.arrow_drop_down, color: widget.themeColor),
            items: folders.map((f) => DropdownMenuItem(
              value: f.id,
              child: Text(f.name, style: const TextStyle(color: Colors.white)),
            )).toList(),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.folderSelectorLabel,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
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
              
              // Seleziona il primo di default
              if (_selectedFolderId == null && folders.isNotEmpty) {
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
          // Qui viene iniettato il form specifico per l'entità
          widget.childBuilder(context, _selectedFolderId),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
