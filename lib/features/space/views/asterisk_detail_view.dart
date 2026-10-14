import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class AsteriskDetailView extends StatefulWidget {
  final String documentId;
  final bool isEmbeddedMode;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const AsteriskDetailView({
    super.key,
    required this.documentId,
    this.isEmbeddedMode = false,
    this.showAllPropertiesNotifier,
  });

  @override
  State<AsteriskDetailView> createState() => _AsteriskDetailViewState();
}

class _AsteriskDetailViewState extends State<AsteriskDetailView> with SingleTickerProviderStateMixin {
  final _documentService = DocumentService();

  AsteriskDocument? _document;
  bool _isLoading = true;
  late TabController _tabController;

  // Key to control active list inline creation
  final GlobalKey<_AsteriskListState> _activeListKey = GlobalKey<_AsteriskListState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDocument();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final doc = await _documentService.getDocumentById(widget.documentId);
    if (doc is AsteriskDocument && mounted) {
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    }
  }

  void _triggerAddAsterisk() {
    HapticFeedback.selectionClick();
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
    _activeListKey.currentState?.startInlineCreation();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_document == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Documento non trovato', style: TextStyle(color: Colors.white70))),
      );
    }

    final docColor = _document!.colorObject ?? const Color(0xFFEAB308);

    final tabBar = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: docColor.withOpacity(0.2),
          border: Border.all(color: docColor.withOpacity(0.6), width: 1),
        ),
        labelColor: docColor,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Attivi'),
          Tab(text: 'Risolti'),
        ],
      ),
    );

    final body = Column(
      children: [
        tabBar,
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AsteriskList(
                key: _activeListKey,
                documentId: widget.documentId,
                isResolved: false,
                accentColor: docColor,
              ),
              _AsteriskList(
                documentId: widget.documentId,
                isResolved: true,
                accentColor: docColor,
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbeddedMode) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
        floatingActionButton: FloatingActionButton(
          heroTag: 'asterisk_fab_${widget.documentId}',
          backgroundColor: docColor,
          foregroundColor: Colors.black,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: _triggerAddAsterisk,
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        title: Text(
          _document!.title,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditTitleDialog,
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        heroTag: 'asterisk_detail_fab',
        backgroundColor: docColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _triggerAddAsterisk,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showEditTitleDialog() async {
    final controller = TextEditingController(text: _document!.title);
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Modifica titolo', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Titolo'),
          autofocus: true,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _document!.colorObject ?? const Color(0xFFEAB308),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                final updatedDoc = AsteriskDocument(
                  id: _document!.id,
                  userId: _document!.userId,
                  groupId: _document!.groupId,
                  title: newTitle,
                  description: _document!.description,
                  createdAt: _document!.createdAt,
                  updatedAt: DateTime.now(),
                  metadata: _document!.metadata,
                );
                await _documentService.updateDocument(updatedDoc);
                if (mounted) {
                  setState(() {
                    _document = updatedDoc;
                  });
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}

class _AsteriskList extends StatefulWidget {
  final String documentId;
  final bool isResolved;
  final Color accentColor;

  const _AsteriskList({
    super.key,
    required this.documentId,
    required this.isResolved,
    required this.accentColor,
  });

  @override
  State<_AsteriskList> createState() => _AsteriskListState();
}

class _AsteriskListState extends State<_AsteriskList> {
  final _spaceService = SpaceService();
  StreamSubscription<List<AsteriskItem>>? _subscription;

  List<AsteriskItem> _items = [];
  bool _isLoading = true;

  // Aggiunta immersiva state
  bool _isCreatingInline = false;
  final TextEditingController _inlineController = TextEditingController();
  final FocusNode _inlineFocusNode = FocusNode();

  // Animating transition items
  final Set<String> _animatingItemIds = {};

  @override
  void initState() {
    super.initState();
    _startWatching();
  }

  void _startWatching() {
    _subscription = _spaceService
        .watchAsterisks(widget.documentId, isResolved: widget.isResolved)
        .listen((items) {
      if (mounted) {
        setState(() {
          // Preserve local optimistic animations by merging
          _items = items.where((it) => !_animatingItemIds.contains(it.id)).toList();
          _isLoading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _inlineController.dispose();
    _inlineFocusNode.dispose();
    super.dispose();
  }

  void startInlineCreation() {
    setState(() {
      _isCreatingInline = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inlineFocusNode.requestFocus();
    });
  }

  void _cancelInlineCreation() {
    setState(() {
      _isCreatingInline = false;
      _inlineController.clear();
    });
  }

  Future<void> _submitInlineCreation() async {
    final text = _inlineController.text.trim();
    if (text.isEmpty) {
      _cancelInlineCreation();
      return;
    }

    _inlineController.clear();
    final tempItem = AsteriskItem(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      documentId: widget.documentId,
      content: text,
      isResolved: false,
      position: _items.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _items.add(tempItem);
      _isCreatingInline = false;
    });

    try {
      final realItem = AsteriskItem(
        id: '',
        documentId: widget.documentId,
        content: text,
        isResolved: false,
        position: _items.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _spaceService.createAsteriskItem(realItem);
    } catch (e) {
      debugPrint('Error creating asterisk: $e');
    }
  }

  Future<void> _toggleResolve(AsteriskItem item) async {
    HapticFeedback.mediumImpact();
    final newResolved = !item.isResolved;

    setState(() {
      _animatingItemIds.add(item.id);
    });

    // Wait for the slide and strikethrough animation to complete smoothly
    await Future.delayed(const Duration(milliseconds: 320));

    if (mounted) {
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
        _animatingItemIds.remove(item.id);
      });
    }

    try {
      final updated = AsteriskItem(
        id: item.id,
        documentId: item.documentId,
        content: item.content,
        isResolved: newResolved,
        position: item.position,
        createdAt: item.createdAt,
        updatedAt: DateTime.now(),
      );
      await _spaceService.updateAsteriskItem(updated);
    } catch (e) {
      debugPrint('Error updating asterisk: $e');
    }
  }

  Future<void> _deleteItem(AsteriskItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Elimina asterisco', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Sei sicuro di voler eliminare questo punto di discussione?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      // Optimistic removal: remove immediately so the UI refreshes instantly
      setState(() {
        _items.removeWhere((it) => it.id == item.id);
      });
      try {
        await _spaceService.deleteAsteriskItem(item.id);
      } catch (e) {
        debugPrint('Error deleting asterisk: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Aggiunta immersiva tile (appears inline at the top of the list)
        if (_isCreatingInline)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.accentColor.withOpacity(0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.2),
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
                    color: widget.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.accentColor.withOpacity(0.4)),
                  ),
                  child: Icon(Icons.emergency, color: widget.accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _inlineController,
                    focusNode: _inlineFocusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cosa vuoi discutere?...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _submitInlineCreation(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                  onPressed: _cancelInlineCreation,
                ),
                IconButton(
                  icon: Icon(Icons.check_circle, color: widget.accentColor, size: 24),
                  onPressed: _submitInlineCreation,
                ),
              ],
            ),
          ),

        // List or empty state
        Expanded(
          child: _items.isEmpty && !_isCreatingInline
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor.withOpacity(0.1),
                        ),
                        child: Icon(Icons.emergency, size: 48, color: widget.accentColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.isResolved ? 'Nessun punto risolto' : 'Nessun punto attivo 📝',
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (!widget.isResolved) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: widget.accentColor.withOpacity(0.5)),
                            foregroundColor: widget.accentColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: startInlineCreation,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Aggiungi punto'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isAnimating = _animatingItemIds.contains(item.id);

                    // Animation slide offset: slide right if completing, slide left/fade if uncompleting
                    final targetOffset = widget.isResolved
                        ? const Offset(-1.2, 0.0)
                        : const Offset(1.2, 0.0);

                    return AnimatedSlide(
                      offset: isAnimating ? targetOffset : Offset.zero,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: AnimatedOpacity(
                        opacity: isAnimating ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 280),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isResolved
                                  ? Colors.white10
                                  : widget.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            // Asterisk icon button instead of checkbox
                            leading: GestureDetector(
                              onTap: () => _toggleResolve(item),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: item.isResolved
                                      ? Colors.white.withOpacity(0.06)
                                      : widget.accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: item.isResolved
                                        ? Colors.white24
                                        : widget.accentColor.withOpacity(0.5),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.emergency,
                                    size: 20,
                                    color: item.isResolved
                                        ? Colors.white38
                                        : widget.accentColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              item.content,
                              style: TextStyle(
                                decoration: (item.isResolved || isAnimating)
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: widget.accentColor,
                                decorationThickness: 2,
                                color: (item.isResolved || isAnimating)
                                    ? Colors.white38
                                    : Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16, // Increased text size
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Creato il ${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}/${item.createdAt.year}',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white38),
                              onPressed: () => _deleteItem(item),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
