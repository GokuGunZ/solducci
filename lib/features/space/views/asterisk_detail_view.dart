import 'package:solducci/widgets/solducci_app_bar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';

class AsteriskDetailView extends StatefulWidget {
  final String documentId;

  const AsteriskDetailView({super.key, required this.documentId});

  @override
  State<AsteriskDetailView> createState() => _AsteriskDetailViewState();
}

class _AsteriskDetailViewState extends State<AsteriskDetailView> with SingleTickerProviderStateMixin {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  
  AsteriskDocument? _document;
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
    if (doc is AsteriskDocument && mounted) {
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
      return const Scaffold(body: Center(child: Text('Documento non trovato')));
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFBBF24),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Attivi'),
            Tab(text: 'Risolti'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AsteriskList(documentId: widget.documentId, isResolved: false),
          _AsteriskList(documentId: widget.documentId, isResolved: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFBBF24),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _showAddAsteriskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddAsteriskDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuovo punto di discussione'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Cosa vuoi discutere?'),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addAsterisk(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addAsterisk(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAsterisk(String content) async {
    final newItem = AsteriskItem(
      id: '',
      documentId: widget.documentId,
      content: content,
      isResolved: false,
      position: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _spaceService.createAsteriskItem(newItem);
  }

  Future<void> _showEditTitleDialog() async {
    final controller = TextEditingController(text: _document!.title);
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifica titolo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Titolo'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
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

class _AsteriskList extends StatelessWidget {
  final String documentId;
  final bool isResolved;

  const _AsteriskList({required this.documentId, required this.isResolved});

  @override
  Widget build(BuildContext context) {
    final spaceService = SpaceService();

    return StreamBuilder<List<AsteriskItem>>(
      stream: spaceService.watchAsterisks(documentId, isResolved: isResolved),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                    color: const Color(0xFFFBBF24).withOpacity(0.1),
                  ),
                  child: const Icon(Icons.star_outline, size: 48, color: Color(0xFFFBBF24)),
                ),
                const SizedBox(height: 12),
                Text(
                  isResolved ? 'Nessun punto risolto' : 'Nessun punto attivo 📝',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
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
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.isResolved ? Colors.white10 : const Color(0xFFFBBF24).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Checkbox(
                  value: item.isResolved,
                  activeColor: const Color(0xFFFBBF24),
                  checkColor: Colors.black,
                  side: const BorderSide(color: Colors.white38, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (value) {
                    final updatedItem = AsteriskItem(
                      id: item.id,
                      documentId: item.documentId,
                      content: item.content,
                      isResolved: value ?? false,
                      position: item.position,
                      createdAt: item.createdAt,
                      updatedAt: DateTime.now(),
                    );
                    spaceService.updateAsteriskItem(updatedItem);
                  },
                ),
                title: Text(
                  item.content,
                  style: TextStyle(
                    decoration: item.isResolved ? TextDecoration.lineThrough : null,
                    color: item.isResolved ? Colors.white38 : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white38),
                  onPressed: () => _confirmDelete(context, item),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, AsteriskItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina asterisco'),
        content: const Text('Sei sicuro di voler eliminare questo punto di discussione?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SpaceService().deleteAsteriskItem(item.id);
    }
  }
}
