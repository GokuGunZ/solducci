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
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    if (_document == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: Text('Documento non trovato', style: TextStyle(color: Colors.white70))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        titleSpacing: 0,
        title: Text(
          _document!.title,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
        ],
      ),
      body: StreamBuilder<List<ResourceItem>>(
        stream: _spaceService.watchResources(widget.documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                    ),
                    child: const Icon(Icons.bookmark_border_rounded, size: 48, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Nessuna risorsa salvata', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Tocca il pulsante + per salvare un link o documento', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isRead = _readItemIds.contains(item.id);
              final tagIds = _itemTagIds[item.id] ?? [];
              final itemTags = _allTags.where((t) => tagIds.contains(t.id)).toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: Key('resource_${item.id}'),
                  background: Container(
                    decoration: BoxDecoration(
                      color: isRead ? const Color(0xFF3B82F6).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead ? const Color(0xFF3B82F6).withOpacity(0.4) : const Color(0xFF10B981).withOpacity(0.4),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: Row(
                      children: [
                        Icon(
                          isRead ? Icons.mark_email_unread_rounded : Icons.check_circle_rounded,
                          color: isRead ? const Color(0xFF60A5FA) : const Color(0xFF34D399),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRead ? 'Segna come non letto' : 'Segna come letto',
                          style: TextStyle(
                            color: isRead ? const Color(0xFF60A5FA) : const Color(0xFF34D399),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Elimina',
                          style: TextStyle(
                            color: Color(0xFFF87171),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline_rounded, color: Color(0xFFF87171)),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await _spaceService.markResourceAsRead(item.id);
                      _loadData();
                      return false;
                    } else {
                      return await _confirmDelete(item);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: IconButton(
                        icon: Icon(
                          isRead ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          color: isRead ? const Color(0xFF10B981) : Colors.white38,
                          size: 22,
                        ),
                        onPressed: () async {
                          await _spaceService.markResourceAsRead(item.id);
                          _loadData();
                        },
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                          fontSize: 14,
                          color: isRead ? Colors.white38 : Colors.white,
                          decoration: isRead ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white38,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (itemTags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Wrap(spacing: 4, runSpacing: 4, children: itemTags.map((t) => _buildMiniTag(t)).toList()),
                            ),
                          if (item.url != null && item.url!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.url!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: isRead
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                              ),
                              child: const Text(
                                'LETTO',
                                style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                          : const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white38),
                      onTap: () => _openResource(item),
                      onLongPress: () => _showEditResourceDialog(item, tagIds),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _showAddResourceDialog,
        child: const Icon(Icons.add_link),
      ),
    );
  }

  Future<bool> _confirmDelete(ResourceItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text('Elimina risorsa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Sei sicuro di voler eliminare questa risorsa?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Elimina', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
    final baseColor = tag.colorObject ?? const Color(0xFF6366F1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: baseColor.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        tag.name,
        style: TextStyle(
          fontSize: 10,
          color: baseColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _openResource(ResourceItem item) async {
    if (item.url != null) {
      final uri = Uri.parse(item.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
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
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            item == null ? 'Nuova risorsa' : 'Modifica risorsa',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Titolo *',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
                  ),
                ),
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'URL (opzionale)',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
                  ),
                ),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMediaType,
                  dropdownColor: const Color(0xFF27272A),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'link', child: Text('Link generico')),
                    DropdownMenuItem(value: 'video', child: Text('Video / YouTube')),
                    DropdownMenuItem(value: 'image', child: Text('Immagine')),
                    DropdownMenuItem(value: 'document', child: Text('Documento / PDF')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedMediaType = v),
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allTags.map((tag) {
                    final isSelected = selectedTagIds.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.name, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF3B82F6).withOpacity(0.4),
                      backgroundColor: const Color(0xFF27272A),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isSelected ? const Color(0xFF3B82F6) : Colors.white12),
                      ),
                      onSelected: (selected) => setDialogState(() => selected ? selectedTagIds.add(tag.id) : selectedTagIds.remove(tag.id)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
              child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
