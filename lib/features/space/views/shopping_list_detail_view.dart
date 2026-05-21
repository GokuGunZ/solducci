import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShoppingListDetailView extends StatefulWidget {
  final String documentId;

  const ShoppingListDetailView({super.key, required this.documentId});

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
    _loadDocument();
    _loadPantryProducts();
    _setupItemsSubscription();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _searchController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _setupItemsSubscription() {
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
    
    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      await _spaceService.updateShoppingListItem(ShoppingListItem(
        id: existing.id,
        documentId: existing.documentId,
        pantryItemId: existing.pantryItemId,
        name: existing.name,
        quantity: existing.quantity + 1.0,
        unit: existing.unit,
        isBought: existing.isBought,
        position: existing.position,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      ));
    } else {
      await _spaceService.createShoppingListItem(ShoppingListItem(
        id: '',
        documentId: widget.documentId,
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
        isBought: existing.isBought,
        position: existing.position,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      ));
    } else {
      await _spaceService.createShoppingListItem(ShoppingListItem(
        id: '',
        documentId: widget.documentId,
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
    if (_items.isEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lista vuota'),
          content: const Text('Se esci senza aggiungere elementi, la lista verrà cancellata.'),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_document == null) {
      return const Scaffold(body: Center(child: Text('Lista non trovata')));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: _isEditingTitle 
            ? TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Titolo lista',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                onSubmitted: (_) => _saveTitle(),
              )
            : GestureDetector(
                onTap: () => setState(() => _isEditingTitle = true),
                child: Text(_document!.title),
              ),
          actions: [
            if (_isEditingTitle)
              IconButton(icon: const Icon(Icons.check), onPressed: _saveTitle)
            else ...[
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Dispensa',
                onPressed: _showResetPantryDialog,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditingTitle = true),
              ),
            ]
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cerca prodotto...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue),
                            onPressed: _createNewProductAndAdd,
                          )
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                
                // Dropdown results
                if (_showSearchDropdown)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return ListTile(
                          title: Text(product.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _addPantryItem(product),
                          ),
                          onTap: () => _addPantryItem(product),
                        );
                      },
                    ),
                  ),

                // Main List
                Expanded(
                  child: _items.isEmpty 
                    ? const Center(child: Text('La lista è vuota'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100, left: 8, right: 8, top: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isSelected = _selectedItemIds.contains(item.id);

                          return Card(
                            color: isSelected ? Colors.blue[50] : null,
                            child: ListTile(
                              onLongPress: () => _toggleSelection(item.id),
                              onTap: () => _toggleSelection(item.id),
                              leading: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: _selectedItemIds.isNotEmpty 
                                  ? Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: Colors.blue)
                                  : Icon(item.isBought ? Icons.check_circle : Icons.shopping_cart_outlined, color: item.isBought ? Colors.green : Colors.grey),
                                onPressed: _selectedItemIds.isNotEmpty 
                                  ? () => _toggleSelection(item.id)
                                  : () => _spaceService.updateShoppingListItem(ShoppingListItem(
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
                                    )),
                              ),
                              title: Text(item.name, style: TextStyle(
                                decoration: item.isBought ? TextDecoration.lineThrough : null,
                                color: item.isBought ? Colors.grey : null,
                              )),
                              subtitle: Text('${item.quantity} ${item.unit ?? ''}'),
                              trailing: _selectedItemIds.isNotEmpty 
                                ? null 
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
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
                                      Text('${item.quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
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
                        },
                      ),
                ),
              ],
            ),

            // Bottom Selection Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              bottom: _selectedItemIds.isEmpty ? -150 : 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                          ),
                          const Text('Selezionati', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _deleteSelectedItems,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('COMPRA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showBulkPurchaseDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _selectionAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_selectionAnimation.value * 80),
              child: FloatingActionButton(
                onPressed: _showAddItemModal,
                child: const Icon(Icons.playlist_add),
              ),
            );
          },
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
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
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
          isBought: existing.isBought,
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
