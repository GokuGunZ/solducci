import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_document == null) {
      return const Scaffold(body: Center(child: Text('Dispensa non trovata')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.title),
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
          _PantryList(documentId: widget.documentId, showOnlyLow: false),
          _PantryList(documentId: widget.documentId, showOnlyLow: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
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

  const _PantryList({required this.documentId, required this.showOnlyLow});

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
        
        // This is a simplification. To properly check isMissing, 
        // we need to load quantities for each item or use a join.
        // For now, we'll display items and provide a button to manage quantities.

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
            return Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text('Unità: ${item.unit}${item.thresholdLow != null ? ' | Soglia: ${item.thresholdLow}' : ''}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showManageQuantitiesDialog(context, item),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showManageQuantitiesDialog(BuildContext context, PantryItem item) async {
    final spaceService = SpaceService();
    final quantities = await spaceService.getPantryQuantities(item.id);

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Gestione ${item.name}'),
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
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: quantities.length,
                      itemBuilder: (context, index) {
                        final q = quantities[index];
                        return ListTile(
                          title: Text('${q.quantity} ${item.unit}'),
                          subtitle: q.expirationDate != null 
                              ? Text('Scadenza: ${q.expirationDate!.day}/${q.expirationDate!.month}/${q.expirationDate!.year}')
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await spaceService.deletePantryQuantity(q.id);
                              final updated = await spaceService.getPantryQuantities(item.id);
                              setState(() => quantities.clear());
                              setState(() => quantities.addAll(updated));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final newQ = await _showAddQuantityDialog(context, item);
                    if (newQ != null) {
                      await spaceService.addPantryQuantity(newQ);
                      final updated = await spaceService.getPantryQuantities(item.id);
                      setState(() => quantities.clear());
                      setState(() => quantities.addAll(updated));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi scorta'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<PantryQuantity?> _showAddQuantityDialog(BuildContext context, PantryItem item) async {
    final quantityController = TextEditingController(text: '1');
    DateTime? selectedDate;

    return showDialog<PantryQuantity>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aggiungi quantità'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantità (${item.unit})'),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Data di scadenza'),
                subtitle: Text(selectedDate == null ? 'Non impostata' : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final qValue = double.tryParse(quantityController.text);
                if (qValue != null && qValue > 0) {
                  Navigator.pop(context, PantryQuantity(
                    id: '',
                    pantryItemId: item.id,
                    quantity: qValue,
                    expirationDate: selectedDate,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                }
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }
}
