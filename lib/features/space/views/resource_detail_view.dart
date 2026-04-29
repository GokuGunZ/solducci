import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailView extends StatefulWidget {
  final String documentId;

  const ResourceDetailView({super.key, required this.documentId});

  @override
  State<ResourceDetailView> createState() => _ResourceDetailViewState();
}

class _ResourceDetailViewState extends State<ResourceDetailView> {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  final _tagService = TagService();
  
  ResourceListDocument? _document;
  bool _isLoading = true;
  List<String> _readItemIds = [];
  Map<String, List<String>> _itemTagIds = {};
  List<Tag> _allTags = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await _documentService.getDocumentById(widget.documentId);
    final readIds = await _spaceService.getReadResourceIds(widget.documentId);
    final tagIds = await _spaceService.getResourceTags(widget.documentId);
    final allTags = await _tagService.getRootTags();

    if (mounted) {
      setState(() {
        if (doc is ResourceListDocument) _document = doc;
        _readItemIds = readIds;
        _itemTagIds = tagIds;
        _allTags = allTags;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_document == null) {
      return const Scaffold(body: Center(child: Text('Documento non trovato')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: StreamBuilder<List<ResourceItem>>(
        stream: _spaceService.watchResources(widget.documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Nessuna risorsa salvata'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showAddResourceDialog,
                    child: const Text('Aggiungi la prima'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isRead = _readItemIds.contains(item.id);
              final tagIds = _itemTagIds[item.id] ?? [];
              final itemTags = _allTags.where((t) => tagIds.contains(t.id)).toList();

              return Card(
                child: ListTile(
                  leading: Icon(
                    _getIconForMediaType(item.mediaType),
                    color: isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.url != null)
                        Text(
                          item.url!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      if (itemTags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            children: itemTags.map((t) => _buildMiniTag(t)).toList(),
                          ),
                        ),
                    ],
                  ),
                  trailing: isRead 
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                    : const Icon(Icons.circle_outlined, color: Colors.blue, size: 16),
                  onTap: () => _openResource(item),
                  onLongPress: () => _showEditResourceDialog(item, tagIds),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddResourceDialog,
        child: const Icon(Icons.add_link),
      ),
    );
  }

  Widget _buildMiniTag(Tag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tag.colorObject?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.name,
        style: TextStyle(
          fontSize: 10,
          color: tag.colorObject ?? Colors.grey[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getIconForMediaType(String? type) {
    switch (type) {
      case 'video': return Icons.play_circle_outline;
      case 'image': return Icons.image_outlined;
      case 'document': return Icons.description_outlined;
      default: return Icons.link;
    }
  }

  Future<void> _openResource(ResourceItem item) async {
    if (item.url != null) {
      final uri = Uri.parse(item.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        await _spaceService.markResourceAsRead(item.id);
        if (mounted) {
          setState(() {
            if (!_readItemIds.contains(item.id)) {
              _readItemIds.add(item.id);
            }
          });
        }
      }
    }
  }

  void _showAddResourceDialog() {
    _showResourceFormDialog();
  }

  void _showEditResourceDialog(ResourceItem item, List<String> tagIds) {
    _showResourceFormDialog(item: item, initialTagIds: tagIds);
  }

  Future<void> _showResourceFormDialog({ResourceItem? item, List<String> initialTagIds = const []}) async {
    final titleController = TextEditingController(text: item?.title ?? '');
    final urlController = TextEditingController(text: item?.url ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    List<String> selectedTagIds = List.from(initialTagIds);
    String? selectedMediaType = item?.mediaType ?? 'link';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Nuova risorsa' : 'Modifica risorsa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titolo *'),
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL (opzionale)'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrizione'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMediaType,
                  items: const [
                    DropdownMenuItem(value: 'link', child: Text('Link generico')),
                    DropdownMenuItem(value: 'video', child: Text('Video / YouTube')),
                    DropdownMenuItem(value: 'image', child: Text('Immagine')),
                    DropdownMenuItem(value: 'document', child: Text('Documento / PDF')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedMediaType = v),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                const SizedBox(height: 16),
                const Text('Tag:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: _allTags.map((tag) {
                    final isSelected = selectedTagIds.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedTagIds.add(tag.id);
                          } else {
                            selectedTagIds.remove(tag.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            if (item != null)
              TextButton(
                onPressed: () async {
                  await _spaceService.deleteResourceItem(item.id);
                  Navigator.pop(context);
                  _loadData();
                },
                child: const Text('Elimina', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final newItem = ResourceItem(
                  id: item?.id ?? '',
                  documentId: widget.documentId,
                  title: title,
                  url: urlController.text.trim(),
                  description: descController.text.trim(),
                  mediaType: selectedMediaType,
                  position: item?.position ?? 0,
                  createdAt: item?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (item == null) {
                  await _spaceService.createResourceItem(newItem, selectedTagIds);
                } else {
                  await _spaceService.updateResourceItem(newItem, selectedTagIds);
                }

                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
