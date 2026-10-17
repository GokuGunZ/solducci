import 'package:solducci/widgets/solducci_app_bar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/auth_service.dart';

class ShoppingListDetailView extends StatefulWidget {
  final String documentId;
  final bool isEmbeddedMode;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  final bool isAllMode;
  final List<ShoppingListDocument>? allDocuments;

  const ShoppingListDetailView({
    super.key,
    required this.documentId,
    this.isEmbeddedMode = false,
    this.showAllPropertiesNotifier,
    this.isAllMode = false,
    this.allDocuments,
  });

  @override
  State<ShoppingListDetailView> createState() => _ShoppingListDetailViewState();
}

class _ShoppingListDetailViewState extends State<ShoppingListDetailView> with SingleTickerProviderStateMixin {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  
  ShoppingListDocument? _document;
  List<ShoppingListItem> _items = [];
  List<PantryItem> _allPantryProducts = [];
  StreamSubscription? _itemsSubscription;
  final List<StreamSubscription> _multiSubscriptions = [];
  Map<String, ShoppingListDocument> _docMap = {};
  bool _isLoading = true;

  // Title editing
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();

  // Search
  final TextEditingController _searchController = TextEditingController();
  List<PantryItem> _searchResults = [];
  bool _showSearchDropdown = false;

  // Selection
  final Set<String> _selectedItemIds = {};
  late AnimationController _selectionController;
  late Animation<double> _selectionAnimation;

  // Completed items section collapse
  bool _isCompletedSectionExpanded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _selectionAnimation = CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    );

    if (widget.isAllMode && widget.allDocuments != null) {
      _docMap = {for (var d in widget.allDocuments!) d.id: d};
      _setupAllItemsSubscription();
      _isLoading = false;
    } else {
      _loadDocument();
      _setupItemsSubscription();
    }
    _loadPantryProducts();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    for (var sub in _multiSubscriptions) {
      sub.cancel();
    }
    _titleController.dispose();
    _titleFocusNode.dispose();
    _searchController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _setupAllItemsSubscription() {
    for (var sub in _multiSubscriptions) {
      sub.cancel();
    }
    _multiSubscriptions.clear();

    final Map<String, List<ShoppingListItem>> docItems = {};

    for (var doc in widget.allDocuments ?? []) {
      final sub = _spaceService.watchShoppingListItems(doc.id).listen((items) {
        if (mounted) {
          docItems[doc.id] = items;
          final allItems = docItems.values.expand((element) => element).toList();
          setState(() {
            _items = allItems;
            _isLoading = false;
          });
        }
      });
      _multiSubscriptions.add(sub);
    }
  }

  void _setupItemsSubscription() {
    if (widget.isAllMode) return;
    _itemsSubscription = _spaceService.watchShoppingListItems(widget.documentId).listen((items) {
      if (mounted) {
        setState(() {
          _items = items;
        });
      }
    });
  }

  Future<void> _loadDocument() async {
    final doc = await _documentService.getDocumentById(widget.documentId);
    if (doc is ShoppingListDocument && mounted) {
      setState(() {
        _document = doc;
        _titleController.text = doc.title;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPantryProducts() async {
    final context = _document?.groupId != null 
        ? ExpenseContext.fromGroupId(_document!.groupId!) 
        : ExpenseContext.personal();
    
    final pantryDocs = await _documentService.getDocumentsForContext(context, 'dispensa');
    if (pantryDocs.isNotEmpty) {
      final items = await _spaceService.watchPantryItems(pantryDocs.first.id).first;
      if (mounted) {
        setState(() {
          _allPantryProducts = items;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchDropdown = false;
      });
      return;
    }

    final results = _allPantryProducts
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    setState(() {
      _searchResults = results;
      _showSearchDropdown = true;
    });
  }

  Future<void> _addPantryItem(PantryItem pantryItem) async {
    final existingIndex = _items.indexWhere((i) => i.pantryItemId == pantryItem.id);
    final targetDocId = widget.isAllMode 
        ? (widget.allDocuments?.firstOrNull?.id ?? widget.documentId)
        : widget.documentId;
    
    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      await _spaceService.updateShoppingListItem(ShoppingListItem(
        id: existing.id,
        documentId: existing.documentId,
        pantryItemId: existing.pantryItemId,
        name: existing.name,
        quantity: existing.quantity + 1.0,
        unit: existing.unit,
        isBought: false, // Return to active items!
        position: existing.position,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      ));
    } else {
      await _spaceService.createShoppingListItem(ShoppingListItem(
        id: '',
        documentId: targetDocId,
        pantryItemId: pantryItem.id,
        name: pantryItem.name,
        quantity: 1.0,
        unit: pantryItem.unit,
        isBought: false,
        position: _items.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    _searchController.clear();
    setState(() {
      _showSearchDropdown = false;
    });
  }

  Future<void> _createNewProductAndAdd() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;

    final targetDocId = widget.isAllMode 
        ? (widget.allDocuments?.firstOrNull?.id ?? widget.documentId)
        : widget.documentId;

    final existingIndex = _items.indexWhere((i) => i.name.toLowerCase() == name.toLowerCase() && i.pantryItemId == null);
    
    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      await _spaceService.updateShoppingListItem(ShoppingListItem(
        id: existing.id,
        documentId: existing.documentId,
        pantryItemId: null,
        name: existing.name,
        quantity: existing.quantity + 1.0,
        unit: existing.unit,
        isBought: false, // Return to active items!
        position: existing.position,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      ));
    } else {
      await _spaceService.createShoppingListItem(ShoppingListItem(
        id: '',
        documentId: targetDocId,
        name: name,
        quantity: 1.0,
        isBought: false,
        position: _items.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    
    _searchController.clear();
    setState(() {
      _showSearchDropdown = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" aggiunto!')));
    }
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }

      if (_selectedItemIds.isNotEmpty) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    });
  }

  Future<void> _saveTitle() async {
    if (_document == null || _titleController.text.isEmpty) return;
    
    final updatedDoc = ShoppingListDocument(
      id: _document!.id,
      userId: _document!.userId,
      groupId: _document!.groupId,
      title: _titleController.text,
      createdAt: _document!.createdAt,
      updatedAt: DateTime.now(),
      metadata: _document!.metadata,
    );

    await _documentService.updateDocument(updatedDoc);
    setState(() {
      _document = updatedDoc;
      _isEditingTitle = false;
    });
  }

  Future<bool> _onWillPop() async {
    final isTemporary = _document?.metadata['is_temporary'] == true;
    if (isTemporary && _items.isEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lista temporanea vuota'),
          content: const Text('Se esci senza aggiungere elementi, la lista temporanea verrà cancellata.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'stay'),
              child: const Text('Rimani'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('Esci e Cancella', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (result == 'delete') {
        await _documentService.deleteDocument(widget.documentId);
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    if (!widget.isAllMode && _document == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Lista non trovata', style: TextStyle(color: Colors.white70))),
      );
    }

    final completedItems = _items.where((i) => i.isBought).toList();

    final scaffold = Scaffold(
        backgroundColor: const Color(0xFF09090B),
        appBar: widget.isEmbeddedMode
            ? null
            : SolducciAppBar(
                titleSpacing: 0,
                title: _isEditingTitle 
            ? TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Titolo lista',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                onSubmitted: (_) => _saveTitle(),
              )
            : GestureDetector(
                onTap: () {
                  if (!widget.isAllMode) {
                    setState(() => _isEditingTitle = true);
                  }
                },
                child: Text(
                  widget.isAllMode ? 'Totale Spesa' : (_document?.title ?? 'Lista'),
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ),
          actions: [
            if (_isEditingTitle)
              IconButton(icon: const Icon(Icons.check, color: Color(0xFF10B981)), onPressed: _saveTitle)
            else ...[
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Dispensa',
                onPressed: _showResetPantryDialog,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _isEditingTitle = true),
              ),
            ]
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Inline Quick-Add Row with Pantry Suggestions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141417),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _createNewProductAndAdd(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Aggiungi prodotto al volo...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.add_shopping_cart, color: Color(0xFF10B981), size: 20),
                        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        suffixIcon: _searchController.text.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981)),
                              onPressed: _createNewProductAndAdd,
                            )
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                
                // Dropdown Pantry Suggestions Chips
                if (_showSearchDropdown && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'DALLA DISPENSA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _searchResults.take(6).map((product) {
                            return InkWell(
                              onTap: () => _addPantryItem(product),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add, size: 14, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                // Main List with Split Active vs Completed
                Expanded(
                  child: _items.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10B981).withOpacity(0.1),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(height: 12),
                            const Text('La lista è vuota', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Scrivi sopra e premi invio per aggiungere al volo', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final pendingItems = _items.where((i) => !i.isBought).toList();
                          final completedItems = _items.where((i) => i.isBought).toList();

                          return ListView(
                            padding: const EdgeInsets.only(bottom: 110, left: 16, right: 16, top: 4),
                            children: [
                              // 1. Pending Items
                              ...pendingItems.map((item) => _buildItemTile(item)),

                              // 2. Completed Section (Collapsible Accordion)
                              if (completedItems.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isCompletedSectionExpanded = !_isCompletedSectionExpanded;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isCompletedSectionExpanded 
                                              ? Icons.keyboard_arrow_down_rounded 
                                              : Icons.keyboard_arrow_right_rounded,
                                          color: Colors.white54,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'PRESI (${completedItems.length})',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${((completedItems.length / _items.length) * 100).toInt()}%',
                                            style: const TextStyle(
                                              color: Color(0xFF10B981),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isCompletedSectionExpanded)
                                  ...completedItems.map((item) => _buildItemTile(item)),
                              ],
                            ],
                          );
                        },
                      ),
                ),
              ],
            ),
            if (completedItems.isNotEmpty && _selectedItemIds.isEmpty)
              _buildPresiMiniDock(completedItems),
            _buildSelectionBar(),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _selectionAnimation,
          builder: (context, child) {
            final offsetBottom = _selectedItemIds.isNotEmpty
                ? -_selectionAnimation.value * 80
                : (completedItems.isNotEmpty ? -70.0 : 0.0);
            return Transform.translate(
              offset: Offset(0, offsetBottom),
              child: FloatingActionButton(
                heroTag: 'shopping_list_fab_${widget.documentId}',
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: _showAddItemModal,
                child: const Icon(Icons.add),
              ),
            );
          },
        ),
      );

    if (widget.isEmbeddedMode) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: scaffold,
    );
  }

  Widget _buildListBadge(String documentId) {
    final doc = _docMap[documentId];
    if (doc == null) return const SizedBox.shrink();
    final color = doc.colorObject ?? const Color(0xFF10B981);
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        doc.title,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _toggleBought(ShoppingListItem item) {
    HapticFeedback.selectionClick();
    final updated = ShoppingListItem(
      id: item.id,
      documentId: item.documentId,
      pantryItemId: item.pantryItemId,
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      isBought: !item.isBought,
      position: item.position,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
    );
    setState(() {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _items[idx] = updated;
      }
    });
    _spaceService.updateShoppingListItem(updated);
  }

  Widget _buildPresiMiniDock(List<ShoppingListItem> completedItems) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${completedItems.length} ${completedItems.length == 1 ? "elemento preso" : "elementi presi"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    completedItems.map((e) => e.name).take(3).join(', ') +
                        (completedItems.length > 3 ? '...' : ''),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onPressed: () => _cancelCompletedItems(completedItems),
              child: const Text('Cancella', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              icon: const Icon(Icons.kitchen_outlined, size: 16),
              label: const Text('Compra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _buyCompletedItems(completedItems),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelCompletedItems(List<ShoppingListItem> items) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Cancella elementi presi', style: TextStyle(color: Colors.white)),
        content: Text(
          'Vuoi eliminare ${items.length} ${items.length == 1 ? "elemento preso" : "elementi presi"} dalla lista?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final idsToDelete = items.map((e) => e.id).toSet();
      setState(() {
        _items.removeWhere((i) => idsToDelete.contains(i.id));
      });
      for (final item in items) {
        await _spaceService.deleteShoppingListItem(item.id);
      }
    }
  }

  Future<void> _buyCompletedItems(List<ShoppingListItem> items) async {
    HapticFeedback.heavyImpact();
    final currentContext = ContextManager().currentContext;

    final rawPantries = await _documentService.getDocumentsForContext(currentContext, 'dispensa');
    final pantries = rawPantries.whereType<DispensaDocument>().toList();

    final Map<String, List<ShoppingListItem>> itemsByPantryTitle = {};

    for (final item in items) {
      String targetTitle = _document?.title ?? 'Alimentari';
      if (widget.isAllMode) {
        final itemDoc = _docMap[item.documentId];
        if (itemDoc != null) {
          targetTitle = itemDoc.title;
        }
      }
      itemsByPantryTitle.putIfAbsent(targetTitle, () => []).add(item);
    }

    final itemIds = items.map((e) => e.id).toSet();
    setState(() {
      _items.removeWhere((i) => itemIds.contains(i.id));
    });

    for (final entry in itemsByPantryTitle.entries) {
      final pantryTitle = entry.key;
      final groupItems = entry.value;

      var targetPantry = pantries.where((p) => p.title.trim().toLowerCase() == pantryTitle.trim().toLowerCase()).firstOrNull;
      if (targetPantry == null) {
        final currentUserId = AuthService().currentUserId;
        final newPantryDoc = DispensaDocument(
          id: '',
          userId: currentContext.isPersonal ? currentUserId : null,
          groupId: currentContext.isGroup ? currentContext.groupId : null,
          title: pantryTitle,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        targetPantry = (await _documentService.createDocument(newPantryDoc)) as DispensaDocument;
      }

      await _spaceService.transferBoughtItemsToPantry(
        itemsToTransfer: groupItems,
        targetPantryDocId: targetPantry.id,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.kitchen_outlined, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${items.length} ${items.length == 1 ? "prodotto trasferito" : "prodotti trasferiti"} in Dispensa!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF18181B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF10B981)),
          ),
        ),
      );
    }
  }

  Widget _buildItemTile(ShoppingListItem item) {
    final isSelected = _selectedItemIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF10B981).withOpacity(0.18) 
            : const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF10B981) : Colors.white10,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        onLongPress: () => _toggleSelection(item.id),
        onTap: () {
          if (_selectedItemIds.isNotEmpty) {
            _toggleSelection(item.id);
          } else {
            _toggleBought(item);
          }
        },
        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: _selectedItemIds.isNotEmpty 
            ? Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined, 
                color: const Color(0xFF10B981),
              )
            : Icon(
                item.isBought ? Icons.check_circle : Icons.radio_button_unchecked, 
                color: item.isBought ? const Color(0xFF10B981) : Colors.white38,
              ),
          onPressed: () {
            if (_selectedItemIds.isNotEmpty) {
              _toggleSelection(item.id);
            } else {
              _toggleBought(item);
            }
          },
        ),
        title: Row(
          children: [
            if (widget.isAllMode) _buildListBadge(item.documentId),
            Expanded(
              child: Text(
                item.name, 
                style: TextStyle(
                  decoration: item.isBought ? TextDecoration.lineThrough : null,
                  color: item.isBought ? Colors.white38 : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        subtitle: (widget.showAllPropertiesNotifier == null 
            ? (item.unit != null && item.unit!.isNotEmpty ? Text('${item.quantity} ${item.unit!}', style: const TextStyle(color: Colors.white38, fontSize: 11)) : null)
            : ValueListenableBuilder<bool>(
                valueListenable: widget.showAllPropertiesNotifier!,
                builder: (context, showAll, _) {
                  if (!showAll && (item.unit == null || item.unit!.isEmpty)) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    showAll 
                        ? '${item.quantity} ${item.unit ?? 'pz'} • Pos. ${item.position + 1}'
                        : '${item.quantity} ${item.unit ?? ''}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  );
                },
              )),
        trailing: _selectedItemIds.isNotEmpty 
          ? null 
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.white54),
                  onPressed: item.quantity > 1 
                    ? () => _spaceService.updateShoppingListItem(ShoppingListItem(
                        id: item.id,
                        documentId: item.documentId,
                        pantryItemId: item.pantryItemId,
                        name: item.name,
                        quantity: item.quantity - 1,
                        unit: item.unit,
                        isBought: item.isBought,
                        position: item.position,
                        createdAt: item.createdAt,
                        updatedAt: DateTime.now(),
                      ))
                    : null,
                ),
                Text(
                  '${item.quantity.toInt()}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF10B981)),
                  onPressed: () => _spaceService.updateShoppingListItem(ShoppingListItem(
                    id: item.id,
                    documentId: item.documentId,
                    pantryItemId: item.pantryItemId,
                    name: item.name,
                    quantity: item.quantity + 1,
                    unit: item.unit,
                    isBought: item.isBought,
                    position: item.position,
                    createdAt: item.createdAt,
                    updatedAt: DateTime.now(),
                  )),
                ),
              ],
            ),
      ),
    );
  }

  // Bottom Selection Bar - Dark Glassmorphism
  Widget _buildSelectionBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      bottom: _selectedItemIds.isEmpty ? -150 : 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          border: const Border(top: BorderSide(color: Colors.white12, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -6),
            )
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedItemIds.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF10B981)),
                  ),
                  const Text('Selezionati', style: TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: _deleteSelectedItems,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text('COMPRA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _showBulkPurchaseDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSelectedItems() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina elementi'),
        content: Text('Vuoi eliminare ${_selectedItemIds.length} elementi dalla lista?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Elimina')),
        ],
      ),
    );

    if (confirm == true) {
      for (var id in _selectedItemIds) {
        await _spaceService.deleteShoppingListItem(id);
      }
      setState(() {
        _selectedItemIds.clear();
        _selectionController.reverse();
      });
    }
  }

  Future<void> _showBulkPurchaseDialog() async {
    final selectedItems = _items.where((i) => _selectedItemIds.contains(i.id)).toList();
    if (selectedItems.isEmpty) return;

    // Build initial purchase state
    final Map<String, List<PurchaseQuantity>> purchaseState = {};
    for (var item in selectedItems) {
      purchaseState[item.id] = [PurchaseQuantity(size: item.quantity, count: 1)];
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Conferma acquisto'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                        2: IntrinsicColumnWidth(),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        const TableRow(
                          children: [
                            Padding(padding: EdgeInsets.all(4), child: Text('Prodotto', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(4), child: Text('Quantità', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(4), child: Text('Disp.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                          ],
                        ),
                        ...selectedItems.map((item) {
                          final purchaseList = purchaseState[item.id]!;
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
                                    IconButton(
                                      icon: const Icon(Icons.add_box_outlined, size: 18, color: Colors.blue),
                                      onPressed: () {
                                        setDialogState(() {
                                          purchaseList.add(PurchaseQuantity(size: item.quantity, count: 1));
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  children: purchaseList.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final q = entry.value;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                                          onPressed: () {
                                            if (q.count > 1) {
                                              setDialogState(() => purchaseList[idx] = PurchaseQuantity(size: q.size, count: q.count - 1));
                                            } else if (purchaseList.length > 1) {
                                              setDialogState(() => purchaseList.removeAt(idx));
                                            }
                                          },
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final newCount = await _showNumericInputDialog(context, 'Quantità', q.count.toDouble());
                                            if (newCount != null) {
                                              setDialogState(() => purchaseList[idx] = PurchaseQuantity(size: q.size, count: newCount.toInt()));
                                            }
                                          },
                                          child: Text('${q.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.add_circle_outline, size: 18),
                                          onPressed: () {
                                            setDialogState(() => purchaseList[idx] = PurchaseQuantity(size: q.size, count: q.count + 1));
                                          },
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final newSize = await _showNumericInputDialog(context, 'Dimensione (${item.unit ?? ''})', q.size);
                                            if (newSize != null) {
                                              setDialogState(() => purchaseList[idx] = PurchaseQuantity(size: newSize, count: q.count));
                                            }
                                          },
                                          child: Text(' x ${q.size}${item.unit ?? ''}', style: const TextStyle(fontSize: 11, decoration: TextDecoration.underline)),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Pantry Stock
                              FutureBuilder<double>(
                                future: item.pantryItemId != null 
                                  ? _spaceService.getPantryQuantities(item.pantryItemId!).then((qs) => qs.fold<double>(0.0, (s, q) => s + q.totalQuantity))
                                  : Future.value(0.0),
                                builder: (context, snapshot) {
                                  return Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text('${snapshot.data ?? 0}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  );
                                }
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: () async {
                  await _finalizeBulkPurchase(purchaseState);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Fatto'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<double?> _showNumericInputDialog(BuildContext context, String title, double initialValue) async {
    final controller = TextEditingController(text: initialValue.toString());
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeBulkPurchase(Map<String, List<PurchaseQuantity>> purchaseState) async {
    for (var entry in purchaseState.entries) {
      final itemId = entry.key;
      final quantities = entry.value;
      final item = _items.firstWhere((i) => i.id == itemId);

      if (item.pantryItemId != null) {
        for (var q in quantities) {
          if (q.count > 0) {
            await _spaceService.addPantryQuantity(PantryQuantity(
              id: '',
              pantryItemId: item.pantryItemId!,
              sizePerUnit: q.size,
              unitsCount: q.count,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }
        }
      }

      // Mark as bought and strikethrough (don't delete as requested)
      await _spaceService.updateShoppingListItem(ShoppingListItem(
        id: item.id,
        documentId: item.documentId,
        pantryItemId: item.pantryItemId,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        isBought: true,
        position: item.position,
        createdAt: item.createdAt,
        updatedAt: DateTime.now(),
      ));
    }

    setState(() {
      _selectedItemIds.clear();
      _selectionController.reverse();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acquisto completato!')));
    }
  }

  Future<void> _showResetPantryDialog() async {
    bool resetUnbought = true;
    bool resetBought = true;

    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Reset Dispensa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Seleziona quali elementi della lista vuoi azzerare in dispensa:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Elementi non comprati'),
                  value: resetUnbought,
                  onChanged: (val) => setDialogState(() => resetUnbought = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Elementi comprati'),
                  value: resetBought,
                  onChanged: (val) => setDialogState(() => resetBought = val ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: (!resetUnbought && !resetBought) ? null : () => Navigator.pop(context, {'unbought': resetUnbought, 'bought': resetBought}),
                child: const Text('Conferma Reset'),
              ),
            ],
          );
        }
      ),
    );

    if (result != null) {
      await _performPantryReset(result['unbought']!, result['bought']!);
    }
  }

  Future<void> _performPantryReset(bool unbought, bool bought) async {
    final itemsToReset = _items.where((i) {
      if (i.pantryItemId == null) return false;
      if (i.isBought) return bought;
      return unbought;
    }).toList();

    for (var item in itemsToReset) {
      final quantities = await _spaceService.getPantryQuantities(item.pantryItemId!);
      for (var q in quantities) {
        await _spaceService.deletePantryQuantity(q.id);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset completato!')));
    }
  }

  Future<void> _showAddItemModal() async {
    // Re-using the logic from the old dialog but showing it as a full modal
    // Or just keeping the FAB logic as requested
    return _showAddItemDialog();
  }

  // RE-IMPLEMENTING old dialog logic but with the requested UI changes
  Future<void> _showAddItemDialog() async {
    final context = _document!.groupId != null 
        ? ExpenseContext.fromGroupId(_document!.groupId!) 
        : ExpenseContext.personal();
    
    final pantryDocs = await _documentService.getDocumentsForContext(context, 'dispensa');
    if (pantryDocs.isEmpty) {
       if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Nessuna dispensa trovata')));
       return;
    }

    final pantryItems = await _spaceService.watchPantryItems(pantryDocs.first.id).first;

    if (!mounted) return;

    return showDialog(
      context: this.context,
      builder: (context) => _ProductSelectorDialog(
        allProducts: pantryItems,
        shoppingListId: widget.documentId,
        onAdded: () {},
      ),
    );
  }
}

class PurchaseQuantity {
  final double size;
  final int count;
  PurchaseQuantity({required this.size, required this.count});
}

// Keeping _ProductSelectorDialog but updating its UI as requested
class _ProductSelectorDialog extends StatefulWidget {
  final List<PantryItem> allProducts;
  final String shoppingListId;
  final VoidCallback onAdded;

  const _ProductSelectorDialog({
    required this.allProducts,
    required this.shoppingListId,
    required this.onAdded,
  });

  @override
  State<_ProductSelectorDialog> createState() => _ProductSelectorDialogState();
}

class _ProductSelectorDialogState extends State<_ProductSelectorDialog> {
  final _spaceService = SpaceService();
  final _customNameController = TextEditingController();
  final Map<String, double> _selectedQuantities = {};
  List<_PantryItemWithStock> _sortedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  Future<void> _prepareData() async {
    List<_PantryItemWithStock> itemsWithStock = [];
    
    for (var item in widget.allProducts) {
      final quantities = await _spaceService.getPantryQuantities(item.id);
      final total = quantities.fold(0.0, (sum, q) => sum + q.totalQuantity);
      final isLow = item.thresholdLow != null && total <= item.thresholdLow!;
      itemsWithStock.add(_PantryItemWithStock(item: item, currentStock: total, isLow: isLow));
    }

    itemsWithStock.sort((a, b) {
      if (a.isLow && !b.isLow) return -1;
      if (!a.isLow && b.isLow) return 1;
      return a.item.name.compareTo(b.item.name);
    });

    if (mounted) {
      setState(() {
        _sortedItems = itemsWithStock;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aggiungi prodotti'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customNameController,
              decoration: const InputDecoration(
                labelText: 'Nuovo prodotto',
                suffixIcon: Icon(Icons.add_circle_outline),
              ),
              onSubmitted: (val) => _addCustomItem(),
            ),
            const Divider(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sortedItems.length,
                  itemBuilder: (context, index) {
                    final wrapper = _sortedItems[index];
                    final isSelected = _selectedQuantities.containsKey(wrapper.item.id);

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        wrapper.isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                        color: wrapper.isLow ? Colors.red : Colors.green,
                      ),
                      title: Text(wrapper.item.name),
                      trailing: isSelected 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() {
                                if (_selectedQuantities[wrapper.item.id]! > 1) {
                                  _selectedQuantities[wrapper.item.id] = _selectedQuantities[wrapper.item.id]! - 1;
                                } else {
                                  _selectedQuantities.remove(wrapper.item.id);
                                }
                              })),
                              Text('${_selectedQuantities[wrapper.item.id]!.toInt()}'),
                              IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _selectedQuantities[wrapper.item.id] = _selectedQuantities[wrapper.item.id]! + 1)),
                            ],
                          )
                        : IconButton(
                            icon: const Icon(Icons.add), // Changed to (+) icon as requested
                            onPressed: () => setState(() => _selectedQuantities[wrapper.item.id] = 1.0),
                          ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        ElevatedButton(
          onPressed: _selectedQuantities.isEmpty ? null : _saveSelection,
          child: const Text('Conferma'),
        ),
      ],
    );
  }

  void _addCustomItem() async {
    final name = _customNameController.text.trim();
    if (name.isEmpty) return;

    await _spaceService.createShoppingListItem(ShoppingListItem(
      id: '',
      documentId: widget.shoppingListId,
      name: name,
      quantity: 1.0,
      isBought: false,
      position: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    
    _customNameController.clear();
    widget.onAdded();
  }

  Future<void> _saveSelection() async {
    // 1. Get current items to check for compaction
    final currentItems = await _spaceService.watchShoppingListItems(widget.shoppingListId).first;

    for (var entry in _selectedQuantities.entries) {
      final pantryItem = widget.allProducts.firstWhere((p) => p.id == entry.key);
      final existingIndex = currentItems.indexWhere((i) => i.pantryItemId == pantryItem.id);

      if (existingIndex != -1) {
        final existing = currentItems[existingIndex];
        await _spaceService.updateShoppingListItem(ShoppingListItem(
          id: existing.id,
          documentId: existing.documentId,
          pantryItemId: existing.pantryItemId,
          name: existing.name,
          quantity: existing.quantity + entry.value,
          unit: existing.unit,
          isBought: false,
          position: existing.position,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        ));
      } else {
        await _spaceService.createShoppingListItem(ShoppingListItem(
          id: '',
          documentId: widget.shoppingListId,
          pantryItemId: pantryItem.id,
          name: pantryItem.name,
          quantity: entry.value,
          unit: pantryItem.unit,
          isBought: false,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    widget.onAdded();
  }
}

class _PantryItemWithStock {
  final PantryItem item;
  final double currentStock;
  final bool isLow;

  _PantryItemWithStock({required this.item, required this.currentStock, required this.isLow});
}
