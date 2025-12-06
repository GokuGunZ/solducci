import 'package:flutter/material.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/tag_service.dart';

/// Modal bottom sheet for selecting multiple tags
/// Shows all available tags with checkboxes and returns selected ones
class TagSelector extends StatefulWidget {
  final List<Tag> selectedTags;

  const TagSelector({
    super.key,
    required this.selectedTags,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final _tagService = TagService();
  final _selectedTagIds = <String>{};
  List<Tag> _allTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize with currently selected tags
    _selectedTagIds.addAll(widget.selectedTags.map((t) => t.id));
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      // Get flat list of all tags
      final tags = await _tagService.flatStream.first;
      if (mounted) {
        setState(() {
          _allTags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento tag: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Seleziona Tag',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTagIds.clear();
                        });
                      },
                      child: const Text('Deseleziona tutti'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tags list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _allTags.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _allTags.length,
                            itemBuilder: (context, index) {
                              final tag = _allTags[index];
                              return _buildTagItem(tag);
                            },
                          ),
              ),

              // Bottom actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedTagIds.length} ${_selectedTagIds.length == 1 ? 'tag selezionato' : 'tag selezionati'}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Conferma'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagItem(Tag tag) {
    final isSelected = _selectedTagIds.contains(tag.id);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (selected) {
        setState(() {
          if (selected == true) {
            _selectedTagIds.add(tag.id);
          } else {
            _selectedTagIds.remove(tag.id);
          }
        });
      },
      title: Row(
        children: [
          if (tag.iconData != null) ...[
            Icon(
              tag.iconData,
              color: tag.colorObject ?? Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(tag.name),
          ),
        ],
      ),
      subtitle: tag.description != null ? Text(tag.description!) : null,
      secondary: tag.colorObject != null
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: tag.colorObject,
                shape: BoxShape.circle,
              ),
            )
          : null,
      activeColor: Colors.purple[700],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.label_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nessun tag disponibile',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea i tuoi primi tag per organizzare le task',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to tag management page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gestione tag coming soon...'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Crea Tag'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    // Get selected tags from IDs
    final selectedTags = _allTags
        .where((tag) => _selectedTagIds.contains(tag.id))
        .toList();

    Navigator.pop(context, selectedTags);
  }
}
