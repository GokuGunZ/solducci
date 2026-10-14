import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailView extends StatefulWidget {
  final String documentId;
  final bool isEmbeddedMode;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const ResourceDetailView({
    super.key,
    required this.documentId,
    this.isEmbeddedMode = false,
    this.showAllPropertiesNotifier,
  });

  @override
  State<ResourceDetailView> createState() => _ResourceDetailViewState();
}

class _ResourceDetailViewState extends State<ResourceDetailView> {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  final _tagService = TagService();

  ResourceListDocument? _document;
  bool _isLoading = true;
  final Set<String> _readItemIds = {};
  Map<String, List<String>> _itemTagIds = {};
  List<Tag> _allTags = [];

  // Aggiunta immersiva inline state
  bool _isInlineAdding = false;
  final TextEditingController _inlineUrlOrTitleController = TextEditingController();
  final FocusNode _inlineFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _inlineUrlOrTitleController.dispose();
    _inlineFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final doc = await _documentService.getDocumentById(widget.documentId);
    final readIds = await _spaceService.getReadResourceIds(widget.documentId);
    final tagIds = await _spaceService.getResourceTags(widget.documentId);
    final allTags = await _tagService.getRootTags();

    if (mounted) {
      setState(() {
        if (doc is ResourceListDocument) _document = doc;
        _readItemIds
          ..clear()
          ..addAll(readIds);
        _itemTagIds = tagIds;
        _allTags = allTags;
        _isLoading = false;
      });
    }
  }

  void _startInlineAdding() {
    HapticFeedback.selectionClick();
    setState(() {
      _isInlineAdding = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inlineFocusNode.requestFocus();
    });
  }

  void _cancelInlineAdding() {
    setState(() {
      _isInlineAdding = false;
      _inlineUrlOrTitleController.clear();
    });
  }

  Future<void> _submitInlineResource() async {
    final input = _inlineUrlOrTitleController.text.trim();
    if (input.isEmpty) {
      _cancelInlineAdding();
      return;
    }

    _inlineUrlOrTitleController.clear();
    setState(() {
      _isInlineAdding = false;
    });

    // Detect if input is a URL or title
    final isUrl = input.startsWith('http://') ||
        input.startsWith('https://') ||
        input.startsWith('www.') ||
        input.contains('.com') ||
        input.contains('.org') ||
        input.contains('.it') ||
        input.contains('.io');

    final url = isUrl
        ? (input.startsWith('http') ? input : 'https://$input')
        : '';
    final title = isUrl
        ? Uri.tryParse(url)?.host ?? input
        : input;

    final mediaType = _detectMediaType(url);

    final newItem = ResourceItem(
      id: '',
      documentId: widget.documentId,
      title: title,
      url: url.isNotEmpty ? url : null,
      description: null,
      mediaType: mediaType,
      position: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _spaceService.createResourceItem(newItem, []);
    } catch (e) {
      debugPrint('Error creating inline resource: $e');
    }
  }

  String _detectMediaType(String? url) {
    if (url == null || url.isEmpty) return 'link';
    final lower = url.toLowerCase();
    if (lower.contains('youtube') ||
        lower.contains('youtu.be') ||
        lower.contains('vimeo') ||
        lower.endsWith('.mp4')) {
      return 'video';
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return 'image';
    }
    if (lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.txt')) {
      return 'document';
    }
    return 'link';
  }

  IconData _getMediaIcon(String? type, String? url) {
    final t = type?.toLowerCase() ?? _detectMediaType(url);
    switch (t) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'image':
        return Icons.image_outlined;
      case 'document':
        return Icons.description_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  Future<void> _toggleReadState(ResourceItem item) async {
    HapticFeedback.lightImpact();
    final isCurrentlyRead = _readItemIds.contains(item.id);

    // Optimistic local update without full page refresh!
    setState(() {
      if (isCurrentlyRead) {
        _readItemIds.remove(item.id);
      } else {
        _readItemIds.add(item.id);
      }
    });

    try {
      if (isCurrentlyRead) {
        await _spaceService.markResourceAsUnread(item.id);
      } else {
        await _spaceService.markResourceAsRead(item.id);
      }
    } catch (e) {
      debugPrint('Error toggling read state: $e');
      // Revert if error
      if (mounted) {
        setState(() {
          if (isCurrentlyRead) {
            _readItemIds.add(item.id);
          } else {
            _readItemIds.remove(item.id);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    if (_document == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Documento non trovato', style: TextStyle(color: Colors.white70))),
      );
    }

    final docColor = _document!.colorObject ?? const Color(0xFF3B82F6);

    final body = Column(
      children: [
        // Aggiunta immersiva inline card
        if (_isInlineAdding)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: docColor.withOpacity(0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: docColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: docColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: docColor.withOpacity(0.4)),
                  ),
                  child: Icon(Icons.link_rounded, color: docColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _inlineUrlOrTitleController,
                    focusNode: _inlineFocusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Incolla link o scrivi titolo risorsa...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _submitInlineResource(),
                  ),
                ),
                IconButton(
                  tooltip: 'Più opzioni',
                  icon: const Icon(Icons.tune, color: Colors.white38, size: 20),
                  onPressed: () {
                    final text = _inlineUrlOrTitleController.text.trim();
                    _cancelInlineAdding();
                    _showAddResourceDialog(prefilledTitle: text);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                  onPressed: _cancelInlineAdding,
                ),
                IconButton(
                  icon: Icon(Icons.check_circle, color: docColor, size: 24),
                  onPressed: _submitInlineResource,
                ),
              ],
            ),
          ),

        // Stream of resources
        Expanded(
          child: StreamBuilder<List<ResourceItem>>(
            stream: _spaceService.watchResources(widget.documentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _readItemIds.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty && !_isInlineAdding) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: docColor.withOpacity(0.1),
                        ),
                        child: Icon(Icons.bookmark_border_rounded, size: 48, color: docColor),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nessuna risorsa salvata',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tocca il pulsante + per salvare un link o documento',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: docColor.withOpacity(0.5)),
                          foregroundColor: docColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _startInlineAdding,
                        icon: const Icon(Icons.add_link, size: 18),
                        label: const Text('Aggiungi risorsa'),
                      ),
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
                  final mediaIcon = _getMediaIcon(item.mediaType, item.url);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Dismissible(
                      key: Key('resource_${item.id}'),
                      // Start to end swipe toggles Read / Unread
                      background: Container(
                        decoration: BoxDecoration(
                          color: isRead
                              ? const Color(0xFF3B82F6).withOpacity(0.2)
                              : const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead
                                ? const Color(0xFF3B82F6).withOpacity(0.4)
                                : const Color(0xFF10B981).withOpacity(0.4),
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
                              isRead ? 'Segna come non consumata' : 'Segna come consumata',
                              style: TextStyle(
                                color: isRead ? const Color(0xFF60A5FA) : const Color(0xFF34D399),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // End to start swipe deletes
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
                          await _toggleReadState(item);
                          return false; // Don't dismiss the tile
                        } else {
                          return await _confirmDelete(item);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead ? Colors.white10 : docColor.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          // Media type icon instead of checkbox
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Colors.white.withOpacity(0.06)
                                  : docColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isRead
                                    ? Colors.white24
                                    : docColor.withOpacity(0.4),
                              ),
                            ),
                            child: Icon(
                              mediaIcon,
                              color: isRead ? Colors.white38 : docColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                              fontSize: 15,
                              color: isRead ? Colors.white54 : Colors.white,
                              // No strikethrough per user request!
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (itemTags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: itemTags.map((t) => _buildMiniTag(t)).toList(),
                                  ),
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
                          // "Consumata" badge instead of "LETTO"
                          trailing: isRead
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                                  ),
                                  child: const Text(
                                    'Consumata',
                                    style: TextStyle(
                                      color: Color(0xFF60A5FA),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
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
        ),
      ],
    );

    if (widget.isEmbeddedMode) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
        floatingActionButton: FloatingActionButton(
          heroTag: 'resource_fab_${widget.documentId}',
          backgroundColor: docColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: _startInlineAdding,
          child: const Icon(Icons.add_link),
        ),
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
      body: body,
      floatingActionButton: FloatingActionButton(
        heroTag: 'resource_detail_fab',
        backgroundColor: docColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _startInlineAdding,
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
    if (item.url != null && item.url!.isNotEmpty) {
      final uri = Uri.parse(item.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      // If no URL, open edit dialog
      _showEditResourceDialog(item, _itemTagIds[item.id] ?? []);
    }
  }

  void _showAddResourceDialog({String? prefilledTitle}) {
    _showResourceFormDialog(prefilledTitle: prefilledTitle);
  }

  void _showEditResourceDialog(ResourceItem item, List<String> tagIds) {
    _showResourceFormDialog(item: item, initialTagIds: tagIds);
  }

  Future<void> _showResourceFormDialog({
    ResourceItem? item,
    List<String> initialTagIds = const [],
    String? prefilledTitle,
  }) async {
    final titleController = TextEditingController(text: item?.title ?? prefilledTitle ?? '');
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const Text(
                  'TAG',
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ..._allTags.map((tag) {
                      final isSelected = selectedTagIds.contains(tag.id);
                      return FilterChip(
                        label: Text(
                          tag.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF3B82F6).withOpacity(0.4),
                        backgroundColor: const Color(0xFF27272A),
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSelected ? const Color(0xFF3B82F6) : Colors.white12),
                        ),
                        onSelected: (selected) => setDialogState(() {
                          if (selected) {
                            selectedTagIds.add(tag.id);
                          } else {
                            selectedTagIds.remove(tag.id);
                          }
                        }),
                      );
                    }),
                    // Dynamic tag creation chip
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: Color(0xFF60A5FA)),
                      label: const Text('Nuovo tag', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12)),
                      backgroundColor: const Color(0xFF3B82F6).withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                      ),
                      onPressed: () async {
                        final newTagName = await _promptNewTagName(context);
                        if (newTagName != null && newTagName.trim().isNotEmpty) {
                          try {
                            final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                            final newTag = await _tagService.createTag(
                              Tag.create(
                                userId: userId,
                                name: newTagName.trim(),
                                color: '#3B82F6',
                              ),
                            );
                            setDialogState(() {
                              _allTags.add(newTag);
                              selectedTagIds.add(newTag.id);
                            });
                          } catch (e) {
                            debugPrint('Error creating tag: $e');
                          }
                        }
                      },
                    ),
                  ],
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
                    url: urlController.text.isNotEmpty ? urlController.text : null,
                    description: descController.text.isNotEmpty ? descController.text : null,
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

  Future<String?> _promptNewTagName(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text('Crea nuovo tag', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Es. Design, Tech, Studio...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF121215),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }
}
