import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/widgets/common/view_group_picker_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Etichetta per il pulsante di gestione liste (es. "Liste", "Tag", "Taccuini")
  final String managementLabel;

  /// Se true, mostra il toggle per la modalità compatta / estesa
  final bool showDensityToggle;

  /// Builder per il contenuto di una lista specifica
  final Widget Function(BuildContext context, TDoc document, ValueNotifier<bool> showAllPropertiesNotifier) buildDocumentPage;

  /// Builder opzionale per la vista aggregata "Tutte"
  final Widget Function(BuildContext context, List<TDoc> allDocuments, ValueNotifier<bool> showAllPropertiesNotifier)? buildAllPage;

  /// Azioni extra per l'AppBar
  final List<Widget>? appBarActions;

  /// Callback personalizzato per creare un nuovo documento (se null, usa un dialog di default)
  final Future<TDoc?> Function(BuildContext context)? onCustomCreateDocument;

  /// Documento opzionale da selezionare all'apertura
  final String? initialDocumentId;

  /// Floating Action Button opzionale
  final Widget? floatingActionButton;

  const UnifiedResourceHubView({
    super.key,
    required this.title,
    required this.documentType,
    required this.accentColor,
    required this.icon,
    required this.buildDocumentPage,
    this.initialDocumentId,
    this.showAllOption = false,
    this.allLabel = 'Tutte',
    this.managementLabel = 'Liste',
    this.showDensityToggle = true,
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

  final ValueNotifier<bool> _showAllPropertiesNotifier = ValueNotifier<bool>(false);

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
    _showAllPropertiesNotifier.dispose();
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

      var typedDocs = rawDocs.whereType<TDoc>().toList();

      if (typedDocs.isEmpty && (widget.documentType == 'shopping_list' || widget.documentType == 'dispensa')) {
        typedDocs = await _seedDefaultPresets(currentContext);
      }

      if (mounted) {
        int targetIndex = _currentIndex;
        if (widget.initialDocumentId != null) {
          final foundIdx = typedDocs.indexWhere((d) => d.id == widget.initialDocumentId);
          if (foundIdx != -1) {
            targetIndex = foundIdx + (widget.showAllOption ? 1 : 0);
          }
        }
        final totalCount = typedDocs.length + (widget.showAllOption ? 1 : 0);
        final maxIdx = totalCount > 0 ? totalCount - 1 : 0;
        if (targetIndex > maxIdx) {
          targetIndex = maxIdx;
        }

        setState(() {
          _documents = typedDocs;
          _isLoading = false;
          _currentIndex = targetIndex;
        });

        if (targetIndex > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(targetIndex);
              _scrollChipIntoView(targetIndex);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[UnifiedResourceHubView] Error loading documents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<TDoc>> _seedDefaultPresets(dynamic currentContext) async {
    final presets = [
      {'title': 'Alimentari', 'color': '10B981'},
      {'title': 'Casa', 'color': '3B82F6'},
      {'title': 'Pulizie', 'color': '06B6D4'},
      {'title': 'Oggettistica', 'color': 'A855F7'},
    ];

    final createdList = <TDoc>[];
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    for (final p in presets) {
      final docMap = {
        'id': '',
        'user_id': currentContext.isPersonal ? currentUserId : null,
        'group_id': currentContext.isGroup ? currentContext.groupId : null,
        'document_type': widget.documentType,
        'title': p['title'],
        'metadata': {'color': p['color']},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      try {
        final newDoc = Document.fromMap(docMap);
        final created = await _documentService.createDocument(newDoc);
        if (created is TDoc) {
          createdList.add(created as TDoc);
        }
      } catch (e) {
        debugPrint('Error creating preset doc: $e');
      }
    }
    return createdList;
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

    // Preset palette neon OLED per personalizzazione liste
    const presetColors = [
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEAB308), // Yellow
      Color(0xFF0EA5E9), // Sky
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFFF43F5E), // Rose
      Color(0xFF84CC16), // Lime
      Color(0xFF6366F1), // Indigo
      Color(0xFF14B8A6), // Teal
    ];

    Color selectedColor = widget.accentColor;

    // Dialog di default per creazione
    final titleController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white10),
          ),
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedColor.withOpacity(0.2),
                  border: Border.all(color: selectedColor.withOpacity(0.6)),
                ),
                child: Icon(widget.icon, color: selectedColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Nuova ${widget.title}', style: const TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
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
                    borderSide: BorderSide(color: selectedColor.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: selectedColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'COLORE IDENTIFICATIVO',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: presetColors.map((color) {
                    final isPicked = color.value == selectedColor.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setDialogState(() => selectedColor = color);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: isPicked ? Colors.white : Colors.white24,
                              width: isPicked ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(isPicked ? 0.6 : 0.25),
                                blurRadius: isPicked ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isPicked
                              ? const Icon(Icons.check, color: Colors.black, size: 18)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, {
                    'title': titleController.text.trim(),
                    'color': selectedColor,
                  });
                }
              },
              child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final title = result['title'] as String;
      final color = result['color'] as Color?;
      final hexColor = color?.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

      final currentContext = _contextManager.currentContext;
      String? targetGroupId = currentContext.groupId;
      String? targetUserId = currentContext.isPersonal ? Supabase.instance.client.auth.currentUser?.id : null;

      if (currentContext.isView) {
        final choice = await ViewGroupPickerSheet.show(
          context,
          title: 'Crea Risorsa',
          subtitle: 'Scegli in quale contesto creare questo elemento',
        );
        if (choice == null) return;
        if (choice.isPersonal) {
          targetUserId = Supabase.instance.client.auth.currentUser?.id;
          targetGroupId = null;
        } else {
          targetGroupId = choice.groupId;
          targetUserId = null;
        }
      }

      final newDoc = Document.fromMap({
        'id': '',
        'user_id': targetUserId,
        'group_id': targetGroupId,
        'document_type': widget.documentType,
        'title': title,
        'metadata': hexColor != null ? {'color': hexColor} : <String, dynamic>{},
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
      floatingActionButton: widget.floatingActionButton,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildIntegratedHeader(),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _totalTabsCount,
                        itemBuilder: (context, index) {
                          if (widget.showAllOption && index == 0) {
                            return widget.buildAllPage != null
                                ? widget.buildAllPage!(context, _documents, _showAllPropertiesNotifier)
                                : const SizedBox.shrink();
                          }
                          final docIndex = index - _offsetForDocs;
                          if (docIndex >= 0 && docIndex < _documents.length) {
                            return widget.buildDocumentPage(context, _documents[docIndex], _showAllPropertiesNotifier);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildIntegratedHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(color: Colors.white10, width: 1.0),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Back button, Title & Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${_documents.length} ${_documents.length == 1 ? 'lista' : 'liste'} attive',
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.accentColor.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Density toggle button (Compact vs Full)
                      if (widget.showDensityToggle)
                        ValueListenableBuilder<bool>(
                          valueListenable: _showAllPropertiesNotifier,
                          builder: (context, showAll, _) {
                            return IconButton(
                              icon: Icon(
                                showAll ? Icons.edit_off : Icons.edit,
                                color: showAll ? widget.accentColor : Colors.white70,
                                size: 20,
                              ),
                              tooltip: showAll
                                  ? 'Nascondi dettagli e proprietà'
                                  : 'Mostra tutti i dettagli',
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showAllPropertiesNotifier.value = !showAll;
                              },
                            );
                          },
                        ),

                      // Management sheet button (List management)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: widget.accentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: Icon(Icons.tune, size: 16, color: widget.accentColor),
                        label: Text(
                          widget.managementLabel,
                          style: TextStyle(
                            color: widget.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: _showManagementBottomSheet,
                      ),

                      if (widget.appBarActions != null) ...widget.appBarActions!,
                    ],
                  ),
                ),

                // Bottom Row: Animated Dot / Expanding Pill Carousel
                _buildChipsBar(),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipsBar() {
    return SizedBox(
      height: 56,
      child: Center(
        child: SingleChildScrollView(
          controller: _chipScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int index = 0; index < _totalTabsCount; index++) ...[
                Builder(
                  builder: (context) {
                    final isSelected = index == _currentIndex;
                    final isAllTab = widget.showAllOption && index == 0;
                    final doc = isAllTab ? null : _documents[index - _offsetForDocs];
                    final label = isAllTab ? widget.allLabel : doc!.title;
                    final dotColor = doc?.colorObject ?? widget.accentColor;

                    return _buildDotToPillChip(
                      index: index,
                      label: label,
                      isSelected: isSelected,
                      icon: isAllTab ? Icons.apps : widget.icon,
                      color: dotColor,
                      onTap: () => _onChipTapped(index),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              _buildAddChip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotToPillChip({
    required int index,
    required String label,
    required bool isSelected,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 0,
          vertical: isSelected ? 6 : 0,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.7),
                    color.withOpacity(0.5),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon inside glass circle
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: isSelected ? 24 : 32,
                  height: isSelected ? 24 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [
                              Colors.white.withOpacity(0.4),
                              Colors.white.withOpacity(0.2),
                            ]
                          : [
                              color.withOpacity(0.8),
                              color.withOpacity(0.6),
                            ],
                    ),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.7)
                          : Color.lerp(
                              color,
                              Colors.white,
                              0.3,
                            )!.withOpacity(0.7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(isSelected ? 0.3 : 0.5),
                        blurRadius: isSelected ? 6 : 8,
                        offset: Offset(0, isSelected ? 2 : 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isSelected ? 14 : 18,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Label (only when active)
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddChip() {
    return GestureDetector(
      onTap: _handleCreateDocument,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.accentColor.withOpacity(0.8),
                  widget.accentColor.withOpacity(0.5),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 14,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
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

  Future<void> _showManagementBottomSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141417),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Colors.white12),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.tune, color: widget.accentColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Gestione ${widget.managementLabel}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _documents.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, idx) {
                          final doc = _documents[idx];
                          final docColor = doc.colorObject ?? widget.accentColor;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: GestureDetector(
                              onTap: () => _showColorPickerForDoc(doc, setModalState),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: docColor.withOpacity(0.2),
                                  border: Border.all(color: docColor.withOpacity(0.6), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: docColor.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(widget.icon, color: docColor, size: 18),
                              ),
                            ),
                            title: Text(
                              doc.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Change color button
                                IconButton(
                                  tooltip: 'Cambia colore',
                                  icon: const Icon(Icons.palette_outlined, size: 20, color: Colors.white70),
                                  onPressed: () => _showColorPickerForDoc(doc, setModalState),
                                ),
                                // Edit title button
                                IconButton(
                                  tooltip: 'Rinomina',
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white70),
                                  onPressed: () async {
                                    final editController = TextEditingController(text: doc.title);
                                    final newTitle = await showDialog<String>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        backgroundColor: const Color(0xFF18181B),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: const BorderSide(color: Colors.white10),
                                        ),
                                        title: const Text('Rinomina', style: TextStyle(color: Colors.white)),
                                        content: TextField(
                                          controller: editController,
                                          autofocus: true,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: const Color(0xFF121215),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dCtx),
                                            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: widget.accentColor,
                                              foregroundColor: Colors.black,
                                            ),
                                            onPressed: () => Navigator.pop(dCtx, editController.text.trim()),
                                            child: const Text('Salva'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (newTitle != null && newTitle.isNotEmpty && newTitle != doc.title) {
                                      doc.title = newTitle;
                                      doc.updatedAt = DateTime.now();
                                      await _documentService.updateDocument(doc);
                                      await _loadDocuments();
                                      setModalState(() {});
                                    }
                                  },
                                ),
                                // Delete list button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        backgroundColor: const Color(0xFF18181B),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: const BorderSide(color: Colors.white10),
                                        ),
                                        title: const Text('Elimina lista', style: TextStyle(color: Colors.white)),
                                        content: Text(
                                          'Vuoi davvero eliminare "${doc.title}"?\nTutti gli elementi al suo interno verranno persi.',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dCtx, false),
                                            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFEF4444),
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () => Navigator.pop(dCtx, true),
                                            child: const Text('Elimina'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await _documentService.deleteDocument(doc.id);
                                      await _loadDocuments();
                                      setModalState(() {});
                                      if (_documents.isEmpty) {
                                        if (ctx.mounted) Navigator.pop(ctx);
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accentColor.withOpacity(0.18),
                          foregroundColor: widget.accentColor,
                          side: BorderSide(color: widget.accentColor.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleCreateDocument();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('Nuova ${widget.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showColorPickerForDoc(
    TDoc doc,
    void Function(void Function()) setModalState,
  ) async {
    const presetColors = [
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEAB308), // Yellow
      Color(0xFF0EA5E9), // Sky
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFFF43F5E), // Rose
      Color(0xFF84CC16), // Lime
      Color(0xFF6366F1), // Indigo
      Color(0xFF14B8A6), // Teal
    ];

    Color selectedColor = doc.colorObject ?? widget.accentColor;

    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setPickerState) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white10),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedColor,
                  boxShadow: [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Colore per "${doc.title}"',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: presetColors.map((color) {
              final isPicked = color.value == selectedColor.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setPickerState(() => selectedColor = color);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: isPicked ? Colors.white : Colors.white24,
                      width: isPicked ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(isPicked ? 0.7 : 0.3),
                        blurRadius: isPicked ? 10 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isPicked
                      ? const Icon(Icons.check, color: Colors.black, size: 22)
                      : null,
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dCtx, selectedColor),
              child: const Text('Applica', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (pickedColor != null) {
      final hex = pickedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
      doc.colorHex = hex;
      doc.updatedAt = DateTime.now();
      await _documentService.updateDocument(doc);
      await _loadDocuments();
      setModalState(() {});
      if (mounted) setState(() {});
    }
  }
}
