import 'package:solducci/widgets/solducci_app_bar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantryDetailView extends StatefulWidget {
  final String documentId;

  const PantryDetailView({super.key, required this.documentId});

  @override
  State<PantryDetailView> createState() => _PantryDetailViewState();
}

class _PantryDetailViewState extends State<PantryDetailView> with SingleTickerProviderStateMixin {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  
  DispensaDocument? _document;
  bool _isLoading = true;
  late TabController _tabController;
  
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

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
    if (doc is DispensaDocument && mounted) {
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
        if (_selectedItemIds.isEmpty) _isSelectionMode = false;
      } else {
        _isSelectionMode = true;
        _selectedItemIds.add(itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_document == null) {
      return const Scaffold(body: Center(child: Text('Dispensa non trovata')));
    }

    return Scaffold(
      appBar: SolducciAppBar(
        title: _isSelectionMode 
          ? Text('${_selectedItemIds.length} selezionati')
          : Text(_document!.title),
        leading: _isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() {
              _isSelectionMode = false;
              _selectedItemIds.clear();
            }))
          : null,
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => context.push('/space/shopping'),
              tooltip: 'Liste della spesa',
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: _createNewShoppingListFromSelection,
              tooltip: 'Crea lista spesa',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tutti i prodotti'),
            Tab(text: 'In esaurimento'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PantryList(
            documentId: widget.documentId, 
            showOnlyLow: false,
            isSelectionMode: _isSelectionMode,
            selectedItemIds: _selectedItemIds,
            onToggleSelection: _toggleSelection,
          ),
          _PantryList(
            documentId: widget.documentId, 
            showOnlyLow: true,
            isSelectionMode: _isSelectionMode,
            selectedItemIds: _selectedItemIds,
            onToggleSelection: _toggleSelection,
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Future<void> _createNewShoppingListFromSelection() async {
    final titleController = TextEditingController(text: 'Lista spesa ${_document!.title}');
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova lista spesa'),
        content: TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Titolo lista'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(onPressed: () => Navigator.pop(context, titleController.text), child: const Text('Crea')),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final newDoc = await _documentService.createDocument(ShoppingListDocument(
      id: '',
      userId: _document!.userId,
      groupId: _document!.groupId,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lista "$title" creata!')));
      // Redirect to the new list
      context.push('/space/shopping/${newDoc.id}');
    }
  }

  Future<void> _showAddItemDialog() async {
    final nameController = TextEditingController();
    final thresholdController = TextEditingController();
    String selectedUnit = 'pcs';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuovo prodotto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome prodotto *'),
              autofocus: true,
            ),
            TextField(
              controller: thresholdController,
              decoration: const InputDecoration(labelText: 'Soglia minima (opzionale)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedUnit,
              items: const [
                DropdownMenuItem(value: 'pcs', child: Text('Pezzi (pcs)')),
                DropdownMenuItem(value: 'kg', child: Text('Kilogrammi (kg)')),
                DropdownMenuItem(value: 'l', child: Text('Litri (l)')),
                DropdownMenuItem(value: 'pack', child: Text('Confezioni')),
              ],
              onChanged: (v) => selectedUnit = v!,
              decoration: const InputDecoration(labelText: 'Unità di misura'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final threshold = double.tryParse(thresholdController.text);
                final newItem = PantryItem(
                  id: '',
                  documentId: widget.documentId,
                  name: name,
                  thresholdLow: threshold,
                  unit: selectedUnit,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await _spaceService.createPantryItem(newItem);
                Navigator.pop(context);
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }
}

class _PantryList extends StatelessWidget {
  final String documentId;
  final bool showOnlyLow;
  final bool isSelectionMode;
  final Set<String> selectedItemIds;
  final Function(String) onToggleSelection;

  const _PantryList({
    required this.documentId, 
    required this.showOnlyLow,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final spaceService = SpaceService();

    return StreamBuilder<List<PantryItem>>(
      stream: spaceService.watchPantryItems(documentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = snapshot.data ?? [];
        
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Nessun prodotto in dispensa',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = selectedItemIds.contains(item.id);

            return Card(
              color: isSelected ? Colors.blue[50] : null,
              child: ListTile(
                leading: isSelectionMode 
                  ? Checkbox(value: isSelected, onChanged: (_) => onToggleSelection(item.id))
                  : null,
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: FutureBuilder<List<PantryQuantity>>(
                  future: spaceService.getPantryQuantities(item.id),
                  builder: (context, qSnapshot) {
                    final qtyList = qSnapshot.data ?? [];
                    final total = qtyList.fold(0.0, (sum, q) => sum + q.totalQuantity);
                    final isLow = item.thresholdLow != null && total <= item.thresholdLow!;
                    
                    if (showOnlyLow && !isLow) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Totale: $total ${item.unit} ${isLow ? '(Sotto soglia!)' : ''}', 
                          style: TextStyle(color: isLow ? Colors.red : Colors.green[700], fontWeight: isLow ? FontWeight.bold : null)),
                      ],
                    );
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: isSelectionMode 
                  ? () => onToggleSelection(item.id)
                  : () => _showStockManagementDialog(context, item),
                onLongPress: () => onToggleSelection(item.id),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showStockManagementDialog(BuildContext context, PantryItem item) async {
    final spaceService = SpaceService();
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<List<PantryQuantity>>(
            future: spaceService.getPantryQuantities(item.id),
            builder: (context, snapshot) {
              final quantities = snapshot.data ?? [];
              final total = quantities.fold(0.0, (sum, q) => sum + q.totalQuantity);

              return AlertDialog(
                title: Text('Scorte: ${item.name}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                                                await spaceService.updatePantryQuantity(PantryQuantity(
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
                                                await spaceService.deletePantryQuantity(q.id);
                                                setDialogState(() {});
                                              },
                                        ),
                                        Text('${q.unitsCount}'),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 20),
                                          onPressed: () async {
                                            await spaceService.updatePantryQuantity(PantryQuantity(
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
                                    Padding(padding: const EdgeInsets.all(4), child: Text('${q.sizePerUnit}${item.unit}')),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () async {
                                        await spaceService.deletePantryQuantity(q.id);
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
                            const Text('TOTALE:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('$total ${item.unit}', style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.thresholdLow != null && total <= item.thresholdLow! ? Colors.red : Colors.green[700]
                            )),
                          ],
                        ),
                      ),
                      if (item.thresholdLow != null)
                        Text('Minimo richiesto: ${item.thresholdLow} ${item.unit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newQ = await _showAddQuantityDialog(context, item);
                          if (newQ != null) {
                            await spaceService.addPantryQuantity(newQ);
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Nuova confezione'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<PantryQuantity?> _showAddQuantityDialog(BuildContext context, PantryItem item) async {
    final sizeController = TextEditingController(text: '1');
    final countController = TextEditingController(text: '1');

    return showDialog<PantryQuantity>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi scorta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countController,
              decoration: const InputDecoration(labelText: 'Numero confezioni'),
              keyboardType: TextInputType.number,
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
              final size = double.tryParse(sizeController.text) ?? 1.0;
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
}
