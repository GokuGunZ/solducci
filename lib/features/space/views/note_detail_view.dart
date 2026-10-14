import 'package:solducci/widgets/solducci_app_bar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';

class NoteDetailView extends StatefulWidget {
  final String documentId;
  final bool isEmbeddedMode;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const NoteDetailView({
    super.key,
    required this.documentId,
    this.isEmbeddedMode = false,
    this.showAllPropertiesNotifier,
  });

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

  bool _isSaving = false;
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _loadDocument();
    _subscribeToItems();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    _debounceTimer?.cancel();
    _contentController.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final doc = await _documentService.getDocumentById(widget.documentId);
    if (doc is NoteDocument && mounted) {
      setState(() {
        _document = doc;
        _titleController.text = doc.title;
        _isLoading = false;
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
    setState(() => _isSaving = true);
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
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
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveTitle() async {
    if (_document == null || _titleController.text.trim().isEmpty) return;
    final newTitle = _titleController.text.trim();
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
    if (mounted) {
      setState(() {
        _document = updatedDoc;
        _isEditingTitle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
      );
    }

    if (_document == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: Text('Documento non trovato', style: TextStyle(color: Colors.white70))),
      );
    }

    final docColor = _document!.colorObject ?? const Color(0xFFF59E0B);

    final content = Column(
      children: [
        // Top status/properties bar (especially useful in embedded mode)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: widget.isEmbeddedMode ? 8.0 : 4.0,
          ),
          child: Row(
            children: [
              // Saving status badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isSaving
                      ? const Color(0xFFF59E0B).withOpacity(0.15)
                      : const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSaving
                        ? const Color(0xFFF59E0B).withOpacity(0.3)
                        : const Color(0xFF10B981).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSaving ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSaving ? 'Salvataggio...' : 'Salvato',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isSaving ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Density properties (word & char count, updated date)
              if (widget.showAllPropertiesNotifier != null)
                ValueListenableBuilder<bool>(
                  valueListenable: widget.showAllPropertiesNotifier!,
                  builder: (context, showAll, _) {
                    if (!showAll) return const SizedBox.shrink();
                    final text = _contentController.text;
                    final charCount = text.length;
                    final wordCount = text.trim().isEmpty
                        ? 0
                        : text.trim().split(RegExp(r'\s+')).length;

                    return AnimatedOpacity(
                      opacity: showAll ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          '$wordCount parole  •  $charCount caratteri',
                          style: const TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        // Text editor area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141417),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                cursorColor: docColor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  hintText: 'Scrivi qui i tuoi appunti...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                  border: InputBorder.none,
                ),
                onChanged: _onContentChanged,
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isEmbeddedMode) {
      return content;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_debounceTimer?.isActive ?? false) {
          _debounceTimer!.cancel();
          await _saveContent(_contentController.text);
        }

        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        appBar: SolducciAppBar(
          titleSpacing: 0,
          title: _isEditingTitle
              ? TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Titolo nota',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                  onSubmitted: (_) => _saveTitle(),
                )
              : GestureDetector(
                  onTap: () => setState(() => _isEditingTitle = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _document!.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, size: 14, color: Colors.white38),
                    ],
                  ),
                ),
          actions: [
            if (_isEditingTitle)
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF10B981)),
                onPressed: _saveTitle,
              ),
          ],
        ),
        body: SafeArea(child: content),
      ),
    );
  }
}
