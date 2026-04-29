import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';

class ShoppingListDetailView extends StatefulWidget {
  final String documentId;
  final String? pantryId; // Optional: used to know which pantry to update

  const ShoppingListDetailView({super.key, required this.documentId, this.pantryId});

  @override
  State<ShoppingListDetailView> createState() => _ShoppingListDetailViewState();
}

class _ShoppingListDetailViewState extends State<ShoppingListDetailView> {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  
  ShoppingListDocument? _document;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: _confirmPurchase,
            tooltip: 'Concludi spesa',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditTitleDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<ShoppingListItem>>(
        stream: _spaceService.watchShoppingListItems(widget.documentId),
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
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('La lista è vuota'),
                ],
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
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.isBought ? TextDecoration.lineThrough : null,
                      color: item.isBought ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text('${item.quantity} ${item.unit ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _spaceService.deleteShoppingListItem(item.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Future<void> _confirmPurchase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Concludi spesa'),
        content: const Text('Vuoi caricare i prodotti acquistati in dispensa e rimuoverli dalla lista?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Concludi')),
        ],
      ),
    );

    if (confirm == true) {
      await _spaceService.confirmShoppingPurchase(widget.documentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispensa aggiornata con successo!')),
        );
      }
    }
  }

  Future<void> _showAddItemDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi alla lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome prodotto *'), autofocus: true),
            TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantità'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final qty = double.tryParse(quantityController.text) ?? 1.0;
                await _spaceService.createShoppingListItem(ShoppingListItem(
                  id: '',
                  documentId: widget.documentId,
                  name: name,
                  quantity: qty,
                  isBought: false,
                  position: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
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
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                final updatedDoc = ShoppingListDocument(
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
                setState(() => _document = updatedDoc);
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
