import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

/// Un hub unificato per qualsiasi risorsa dello Spazio con struttura multi-lista.
///
/// Elimina il doppio livello "cartella > elenco liste > dettaglio lista",
/// posizionando un carosello di chip orizzontale in cima e un PageView
/// sincronizzato a tutto schermo sotto.
class UnifiedResourceHubView<TDoc extends Document> extends StatefulWidget {
  /// Titolo visualizzato nella AppBar (es. "Liste Spesa", "Task", "Note")
  final String title;

  /// Tipo documento nel DB (es. 'shopping_list', 'todo', 'note', 'asterisk', 'dispensa')
  final String documentType;

  /// Colore d'accento caratteristico della risorsa (Dark OLED neon)
  final Color accentColor;

  /// Icona caratteristica della risorsa
  final IconData icon;

  /// Se true, mostra come prima pagina la vista aggregata "Tutte"
  final bool showAllOption;

  /// Etichetta per l'opzione aggregata (default "Tutte")
  final String allLabel;

  /// Builder per il contenuto di una lista specifica
  final Widget Function(BuildContext context, TDoc document) buildDocumentPage;

  /// Builder opzionale per la vista aggregata "Tutte"
  final Widget Function(BuildContext context, List<TDoc> allDocuments)? buildAllPage;

  /// Azioni extra per l'AppBar
  final List<Widget>? appBarActions;

  /// Callback personalizzato per creare un nuovo documento (se null, usa un dialog di default)
  final Future<TDoc?> Function(BuildContext context)? onCustomCreateDocument;

  /// Floating Action Button opzionale
  final Widget? floatingActionButton;

  const UnifiedResourceHubView({
    super.key,
    required this.title,
    required this.documentType,
    required this.accentColor,
    required this.icon,
    required this.buildDocumentPage,
    this.showAllOption = false,
    this.allLabel = 'Tutte',
    this.buildAllPage,
    this.appBarActions,
    this.onCustomCreateDocument,
    this.floatingActionButton,
  });

  @override
  State<UnifiedResourceHubView<TDoc>> createState() => _UnifiedResourceHubViewState<TDoc>();
}

class _UnifiedResourceHubViewState<TDoc extends Document> extends State<UnifiedResourceHubView<TDoc>> {
  final DocumentService _documentService = DocumentService();
  final ContextManager _contextManager = ContextManager();

  late final PageController _pageController;
  final ScrollController _chipScrollController = ScrollController();

  List<TDoc> _documents = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isPageAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _contextManager.addListener(_onContextChanged);
    _loadDocuments();
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    _pageController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) {
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final currentContext = _contextManager.currentContext;
      final rawDocs = await _documentService.getDocumentsForContext(
        currentContext,
        widget.documentType,
      );

      final typedDocs = rawDocs.whereType<TDoc>().toList();

      if (mounted) {
        setState(() {
          _documents = typedDocs;
          _isLoading = false;
          // Clamp index if documents list shrunk
          final maxIdx = _totalTabsCount > 0 ? _totalTabsCount - 1 : 0;
          if (_currentIndex > maxIdx) {
            _currentIndex = maxIdx;
          }
        });
      }
    } catch (e) {
      debugPrint('[UnifiedResourceHubView] Error loading documents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _offsetForDocs => widget.showAllOption ? 1 : 0;
  int get _totalTabsCount => _documents.length + _offsetForDocs;

  void _onChipTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
      _isPageAnimating = true;
    });

    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          if (mounted) {
            setState(() => _isPageAnimating = false);
          }
        });

    _scrollChipIntoView(index);
  }

  void _onPageChanged(int index) {
    if (_isPageAnimating) return;
    setState(() {
      _currentIndex = index;
    });
    _scrollChipIntoView(index);
  }

  void _scrollChipIntoView(int index) {
    // Stima offset approssimativo per tenere la chip centrata
    final estimatedOffset = (index * 110.0) - 80.0;
    if (_chipScrollController.hasClients) {
      _chipScrollController.animateTo(
        estimatedOffset.clamp(0.0, _chipScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleCreateDocument() async {
    HapticFeedback.lightImpact();
    if (widget.onCustomCreateDocument != null) {
      final created = await widget.onCustomCreateDocument!(context);
      if (created != null && mounted) {
        await _loadDocuments();
        // Sposta sulla nuova lista
        final newIndex = _documents.indexWhere((d) => d.id == created.id);
        if (newIndex != -1) {
          _onChipTapped(newIndex + _offsetForDocs);
        }
      }
      return;
    }

    // Dialog di default per creazione
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Row(
          children: [
            Icon(widget.icon, color: widget.accentColor, size: 22),
            const SizedBox(width: 10),
            Text('Nuova ${widget.title}', style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Es. Settimanale, Lavoro, Personale...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF121215),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accentColor.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, titleController.text.trim());
              }
            },
            child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty) {
      final currentContext = _contextManager.currentContext;
      final newDoc = Document.fromMap({
        'id': '',
        'user_id': null,
        'group_id': currentContext.isGroup ? currentContext.groupId : null,
        'document_type': widget.documentType,
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final created = await _documentService.createDocument(newDoc);
      if (mounted) {
        await _loadDocuments();
        final newIndex = _documents.indexWhere((d) => d.id == created.id);
        if (newIndex != -1) {
          _onChipTapped(newIndex + _offsetForDocs);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (widget.appBarActions != null) ...widget.appBarActions!,
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildChipsBar(),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _totalTabsCount,
                        itemBuilder: (context, index) {
                          if (widget.showAllOption && index == 0) {
                            return widget.buildAllPage != null
                                ? widget.buildAllPage!(context, _documents)
                                : const SizedBox.shrink();
                          }
                          final docIndex = index - _offsetForDocs;
                          if (docIndex >= 0 && docIndex < _documents.length) {
                            return widget.buildDocumentPage(context, _documents[docIndex]);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildChipsBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        controller: _chipScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _totalTabsCount + 1, // +1 per il pulsante '+'
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // Ultimo elemento: pulsante Aggiungi Lista
          if (index == _totalTabsCount) {
            return _buildAddChip();
          }

          final isSelected = index == _currentIndex;
          final isAllTab = widget.showAllOption && index == 0;
          final label = isAllTab ? widget.allLabel : _documents[index - _offsetForDocs].title;

          return _buildFilterChip(
            label: label,
            isSelected: isSelected,
            icon: isAllTab ? Icons.apps : null,
            onTap: () => _onChipTapped(index),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.accentColor.withOpacity(0.18)
                : const Color(0xFF141417),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? widget.accentColor.withOpacity(0.6)
                  : Colors.white10,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? widget.accentColor : Colors.white54,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddChip() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleCreateDocument,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF141417),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: widget.accentColor),
              const SizedBox(width: 4),
              Text(
                'Nuova',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: widget.accentColor.withOpacity(0.2)),
              ),
              child: Icon(widget.icon, size: 54, color: widget.accentColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessuna ${widget.title.toLowerCase()}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la tua prima lista per iniziare subito a organizzare.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _handleCreateDocument,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Crea ${widget.title}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
