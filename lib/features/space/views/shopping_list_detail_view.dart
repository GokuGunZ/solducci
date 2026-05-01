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

class _ShoppingListDetailViewState extends State<ShoppingListDetailView> {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  
  ShoppingListDocument? _document;
  List<ShoppingListItem> _items = [];
  StreamSubscription? _itemsSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _setupItemsSubscription();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
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
      return const Scaffold(body: Center(child: Text('Lista non trovata')));
    }

    final checkedItems = _items.where((i) => i.isBought).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditTitleDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (checkedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Text('${checkedItems.length} selezionati', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('COMPRA'),
                    onPressed: () => _startPurchaseFlow(checkedItems),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('ELIMINA', style: TextStyle(color: Colors.red)),
                    onPressed: () => _deleteCheckedItems(checkedItems),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _items.isEmpty 
              ? const Center(child: Text('La lista è vuota'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: item.isBought,
                          onChanged: (value) {
                            final updated = ShoppingListItem(
                              id: item.id,
                              documentId: item.documentId,
                              pantryItemId: item.pantryItemId,
                              name: item.name,
                              quantity: item.quantity,
                              unit: item.unit,
                              isBought: value ?? false,
                              position: item.position,
                              createdAt: item.createdAt,
                              updatedAt: DateTime.now(),
                            );
                            _spaceService.updateShoppingListItem(updated);
                          },
                        ),
                        title: Text(item.name, style: TextStyle(decoration: item.isBought ? TextDecoration.lineThrough : null)),
                        subtitle: Text('${item.quantity} ${item.unit ?? ''}'),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Future<void> _startPurchaseFlow(List<ShoppingListItem> items) async {
    for (var item in items) {
      final shouldRemove = await _showPurchaseStockDialog(item);
      if (shouldRemove == null) break; // User cancelled flow entirely

      if (shouldRemove) {
        await _spaceService.deleteShoppingListItem(item.id);
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acquisto completato!')));
    }
  }

  Future<bool?> _showPurchaseStockDialog(ShoppingListItem item) async {
    if (item.pantryItemId == null) {
      // For custom items, use the existing simple dialog or a simplified one
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Acquisto: ${item.name}'),
          content: Text('Hai acquistato ${item.quantity} ${item.unit ?? ''}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Interrompi')),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Salta')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Conferma')),
          ],
        ),
      );
    }

    // For pantry items, show the tabular view
    final pantryItem = await _spaceService.getPantryItem(item.pantryItemId!);
    if (pantryItem == null) return true; // Should not happen, but if so, just remove from list

    if (!mounted) return null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<List<PantryQuantity>>(
            future: _spaceService.getPantryQuantities(pantryItem.id),
            builder: (context, snapshot) {
              final quantities = snapshot.data ?? [];
              final total = quantities.fold(0.0, (sum, q) => sum + q.totalQuantity);

              return AlertDialog(
                title: Text('Acquisto: ${pantryItem.name}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('Stai comprando: ${item.quantity} ${item.unit ?? ''}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                      const Divider(),
                      const Text('Scorte attuali in dispensa:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      if (quantities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Nessuna scorta presente'),
                        )
                      else
                        Flexible(
                          child: SingleChildScrollView(
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: IntrinsicColumnWidth(),
                                2: FlexColumnWidth(1),
                              },
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                const TableRow(
                                  children: [
                                    Padding(padding: EdgeInsets.all(4), child: Text('Conf.', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Padding(padding: EdgeInsets.all(4), child: Text('Dim.', style: TextStyle(fontWeight: FontWeight.bold))),
                                    SizedBox.shrink(),
                                  ],
                                ),
                                ...quantities.map((q) => TableRow(
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                                          onPressed: q.unitsCount > 1 
                                            ? () async {
                                                await _spaceService.updatePantryQuantity(PantryQuantity(
                                                  id: q.id,
                                                  pantryItemId: q.pantryItemId,
                                                  sizePerUnit: q.sizePerUnit,
                                                  unitsCount: q.unitsCount - 1,
                                                  createdAt: q.createdAt,
                                                  updatedAt: DateTime.now(),
                                                ));
                                                setDialogState(() {});
                                              }
                                            : () async {
                                                await _spaceService.deletePantryQuantity(q.id);
                                                setDialogState(() {});
                                              },
                                        ),
                                        Text('${q.unitsCount}'),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 20),
                                          onPressed: () async {
                                            await _spaceService.updatePantryQuantity(PantryQuantity(
                                              id: q.id,
                                              pantryItemId: q.pantryItemId,
                                              sizePerUnit: q.sizePerUnit,
                                              unitsCount: q.unitsCount + 1,
                                              createdAt: q.createdAt,
                                              updatedAt: DateTime.now(),
                                            ));
                                            setDialogState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                    Padding(padding: const EdgeInsets.all(4), child: Text('${q.sizePerUnit}${pantryItem.unit}')),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () async {
                                        await _spaceService.deletePantryQuantity(q.id);
                                        setDialogState(() {});
                                      },
                                    ),
                                  ],
                                )),
                              ],
                            ),
                          ),
                        ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTALE DISPENSA:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('$total ${pantryItem.unit}', style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: pantryItem.thresholdLow != null && total <= pantryItem.thresholdLow! ? Colors.red : Colors.green[700]
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newQ = await _showPurchaseAddQuantityDialog(context, pantryItem, item.quantity);
                          if (newQ != null) {
                            await _spaceService.addPantryQuantity(newQ);
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Aggiungi all\'acquisto'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Interrompi')),
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Salta')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Fatto')),
                ],
              );
            }
          );
        }
      ),
    );
  }

  Future<PantryQuantity?> _showPurchaseAddQuantityDialog(BuildContext context, PantryItem item, double suggestedSize) async {
    final sizeController = TextEditingController(text: suggestedSize.toString());
    final countController = TextEditingController(text: '1');

    return showDialog<PantryQuantity>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi confezione'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countController,
              decoration: const InputDecoration(labelText: 'Numero confezioni'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            TextField(
              controller: sizeController,
              decoration: InputDecoration(labelText: 'Dimensione singola (${item.unit})'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              final size = double.tryParse(sizeController.text) ?? suggestedSize;
              final count = int.tryParse(countController.text) ?? 1;
              Navigator.pop(context, PantryQuantity(
                id: '',
                pantryItemId: item.id,
                sizePerUnit: size,
                unitsCount: count,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCheckedItems(List<ShoppingListItem> items) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina elementi'),
        content: Text('Vuoi eliminare ${items.length} elementi dalla lista?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm == true) {
      for (var item in items) {
        await _spaceService.deleteShoppingListItem(item.id);
      }
    }
  }

  Future<void> _showAddItemDialog() async {
    // 1. Fetch Pantry items for this context
    final pantryItems = await _documentService.getDocumentsForContext(
      _document!.groupId != null 
        ? ExpenseContext.fromGroupId(_document!.groupId!) 
        : ExpenseContext.personal(), 
      'dispensa'
    );

    if (!mounted) return;

    List<PantryItem> allProducts = [];
    if (pantryItems.isNotEmpty) {
      // Get items from the first pantry found in this context
      final items = await _spaceService.watchPantryItems(pantryItems.first.id).first;
      allProducts = items;
    }

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (context) => _ProductSelectorDialog(
        allProducts: allProducts,
        shoppingListId: widget.documentId,
        onAdded: () {
          // Stream updates automatically
        },
      ),
    );
  }

  Future<void> _showEditTitleDialog() async {
    final controller = TextEditingController(text: _document!.title);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica titolo'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Titolo'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _documentService.updateDocument(ShoppingListDocument(
                  id: _document!.id,
                  userId: _document!.userId,
                  groupId: _document!.groupId,
                  title: controller.text,
                  createdAt: _document!.createdAt,
                  updatedAt: DateTime.now(),
                  metadata: _document!.metadata,
                ));
                _loadDocument();
                Navigator.pop(context);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}

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

    // Sort: isLow first, then alphabetically
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
            // Custom item input
            TextField(
              controller: _customNameController,
              decoration: const InputDecoration(
                labelText: 'Nuovo prodotto (non in dispensa)',
                suffixIcon: Icon(Icons.add_circle_outline),
              ),
              onSubmitted: (val) => _addCustomItem(),
            ),
            const Divider(),
            const Text('Dalla tua dispensa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_sortedItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Nessun prodotto configurato in dispensa'),
              )
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
                      title: Text(wrapper.item.name, style: TextStyle(fontWeight: wrapper.isLow ? FontWeight.bold : null)),
                      subtitle: Text('Scorta: ${wrapper.currentStock} ${wrapper.item.unit}'),
                      trailing: isSelected 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove), 
                                onPressed: () => setState(() {
                                  if (_selectedQuantities[wrapper.item.id]! > 1) {
                                    _selectedQuantities[wrapper.item.id] = _selectedQuantities[wrapper.item.id]! - 1;
                                  } else {
                                    _selectedQuantities.remove(wrapper.item.id);
                                  }
                                })
                              ),
                              Text('${_selectedQuantities[wrapper.item.id]!.toInt()}'),
                              IconButton(
                                icon: const Icon(Icons.add), 
                                onPressed: () => setState(() => _selectedQuantities[wrapper.item.id] = _selectedQuantities[wrapper.item.id]! + 1)
                              ),
                            ],
                          )
                        : TextButton(
                            onPressed: () => setState(() => _selectedQuantities[wrapper.item.id] = 1.0),
                            child: const Text('AGGIUNGI'),
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" aggiunto!')));
    }
  }

  Future<void> _saveSelection() async {
    for (var entry in _selectedQuantities.entries) {
      final item = widget.allProducts.firstWhere((p) => p.id == entry.key);
      await _spaceService.createShoppingListItem(ShoppingListItem(
        id: '',
        documentId: widget.shoppingListId,
        pantryItemId: item.id,
        name: item.name,
        quantity: entry.value,
        unit: item.unit,
        isBought: false,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
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
