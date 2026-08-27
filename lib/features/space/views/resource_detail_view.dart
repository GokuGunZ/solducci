import 'package:solducci/widgets/solducci_app_bar.dart';
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
      appBar: SolducciAppBar(
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
            return const Center(child: Text('Nessuna risorsa salvata'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isRead = _readItemIds.contains(item.id);
              final tagIds = _itemTagIds[item.id] ?? [];
              final itemTags = _allTags.where((t) => tagIds.contains(t.id)).toList();

              return Dismissible(
                key: Key('resource_${item.id}'),
                background: Container(
                  color: isRead ? Colors.orange : Colors.green,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: Icon(isRead ? Icons.mark_email_unread : Icons.check, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _spaceService.markResourceAsRead(item.id);
                    _loadData();
                    return false; // Don't actually dismiss
                  } else {
                    return await _confirmDelete(item);
                  }
                },
                child: Card(
                  color: isRead ? Colors.grey[50] : null,
                  child: ListTile(
                    leading: IconButton(
                      icon: Icon(
                        isRead ? Icons.check_circle : Icons.circle_outlined,
                        color: isRead ? Colors.green : Colors.blue,
                      ),
                      onPressed: () async {
                        await _spaceService.markResourceAsRead(item.id);
                        _loadData();
                      },
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: isRead ? Colors.grey[600] : Colors.black87,
                        decoration: isRead ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (itemTags.isNotEmpty) 
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Wrap(spacing: 4, children: itemTags.map((t) => _buildMiniTag(t)).toList()),
                          ),
                        if (item.url != null) 
                          Text(
                            item.url!, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isRead ? Colors.grey : Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: isRead 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('LETTO', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    onTap: () => _openResource(item),
                    onLongPress: () => _showEditResourceDialog(item, tagIds),
                  ),
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

  Future<bool> _confirmDelete(ResourceItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina risorsa'),
        content: const Text('Sei sicuro di voler eliminare questa risorsa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Elimina')),
        ],
      ),
    );
    if (confirm == true) {
      await _spaceService.deleteResourceItem(item.id);
      return true;
    }
    return false;
  }

  Widget _buildMiniTag(Tag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tag.colorObject?.withValues(alpha: 0.2) ?? Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(tag.name, style: TextStyle(fontSize: 10, color: tag.colorObject ?? Colors.grey[700], fontWeight: FontWeight.bold)),
    );
  }



  Future<void> _openResource(ResourceItem item) async {
    if (item.url != null) {
      final uri = Uri.parse(item.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        // User asked for click to open, and swipe to mark as read.
        // We could also mark as read automatically here if preferred.
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
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titolo *')),
                TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL (opzionale)')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrizione')),
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
                Wrap(
                  spacing: 4,
                  children: _allTags.map((tag) {
                    final isSelected = selectedTagIds.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (selected) => setDialogState(() => selected ? selectedTagIds.add(tag.id) : selectedTagIds.remove(tag.id)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final newItem = ResourceItem(
                    id: item?.id ?? '',
                    documentId: widget.documentId,
                    title: titleController.text,
                    url: urlController.text,
                    description: descController.text,
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
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
