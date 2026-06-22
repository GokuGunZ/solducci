import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';

class NoteDetailView extends StatefulWidget {
  final String documentId;

  const NoteDetailView({super.key, required this.documentId});

  @override
  State<NoteDetailView> createState() => _NoteDetailViewState();
}

class _NoteDetailViewState extends State<NoteDetailView> {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  
  NoteDocument? _document;
  List<NoteItem> _items = [];
  bool _isLoading = true;
  StreamSubscription? _itemsSubscription;

  final _contentController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _subscribeToItems();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    _debounceTimer?.cancel();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final doc = await _documentService.getDocumentById(widget.documentId);
    if (doc is NoteDocument && mounted) {
      setState(() {
        _document = doc;
        _isLoading = false;
        // In a simple note, we might just have one NoteItem or use the document description.
        // The requirements suggest note_items table for multiple blocks.
      });
    }
  }

  void _subscribeToItems() {
    _itemsSubscription = _spaceService.watchNotes(widget.documentId).listen((items) {
      if (mounted) {
        setState(() {
          _items = items;
          if (items.isNotEmpty && _contentController.text.isEmpty) {
            _contentController.text = items.first.content;
          }
        });
      }
    });
  }

  void _onContentChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _saveContent(value);
    });
  }

  Future<void> _saveContent(String value) async {
    if (_items.isEmpty) {
      final newItem = NoteItem(
        id: '',
        documentId: widget.documentId,
        content: value,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _spaceService.createNoteItem(newItem);
    } else {
      final updatedItem = NoteItem(
        id: _items.first.id,
        documentId: widget.documentId,
        content: value,
        position: _items.first.position,
        createdAt: _items.first.createdAt,
        updatedAt: DateTime.now(),
      );
      await _spaceService.updateNoteItem(updatedItem);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Se c'è un salvataggio in sospeso, lo eseguiamo prima di uscire
        if (_debounceTimer?.isActive ?? false) {
          _debounceTimer!.cancel();
          await _saveContent(_contentController.text);
        }

        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_document!.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: _showEditTitleDialog,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Scrivi qui i tuoi appunti...',
              border: InputBorder.none,
            ),
            onChanged: _onContentChanged,
          ),
        ),
      ),
    );
  }

  Future<void> _showEditTitleDialog() async {
    final controller = TextEditingController(text: _document!.title);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica titolo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Titolo'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.pop(context);
                final updatedDoc = NoteDocument(
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
                setState(() {
                  _document = updatedDoc;
                });
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
