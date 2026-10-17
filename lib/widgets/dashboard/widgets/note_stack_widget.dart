import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/blocs/dashboard/dashboard_bloc.dart';
import 'package:solducci/blocs/dashboard/dashboard_event.dart';
import 'package:solducci/blocs/dashboard/dashboard_state.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/widgets/common/view_group_picker_sheet.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoteStackWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const NoteStackWidget({super.key, required this.def});

  @override
  State<NoteStackWidget> createState() => _NoteStackWidgetState();
}

class _NoteStackWidgetState extends State<NoteStackWidget> with SingleTickerProviderStateMixin {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();

  StreamSubscription? _docSubscription;
  List<Document> _allDocs = [];
  List<Document> _notes = [];
  Set<String>? _selectedNoteIds;
  Map<String, String> _previews = {};
  bool _isLoading = true;
  ExpenseContext? _lastContext;

  int _currentIndex = 0;
  double _dragDx = 0.0;
  double _dragDy = 0.0;
  late AnimationController _animController;
  late Animation<double> _anim;
  double _animStartDx = 0.0;
  double _animEndDx = 0.0;
  double _animStartDy = 0.0;
  double _animEndDy = 0.0;
  int _targetIndex = 0;

  // Scroll & overscroll state for active note
  final ScrollController _scrollController = ScrollController();
  double _overscrollDy = 0.0;
  bool _canScrollCurrentNote = false;

  // Inline editing state
  bool _isEditingContent = false;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();
  Timer? _debounceSaveTimer;
  bool _isSavingContent = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedIdsFromProps();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _anim.addListener(() {
      setState(() {
        _dragDx = _animStartDx + (_animEndDx - _animStartDx) * _anim.value;
        _dragDy = _animStartDy + (_animEndDy - _animStartDy) * _anim.value;
      });
    });
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_targetIndex != _currentIndex) {
          _exitEditMode();
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0.0);
          }
          setState(() {
            _currentIndex = _targetIndex;
            _dragDx = 0.0;
            _dragDy = 0.0;
            _overscrollDy = 0.0;
            _canScrollCurrentNote = false;
          });
        } else {
          setState(() {
            _dragDx = 0.0;
            _dragDy = 0.0;
            _overscrollDy = 0.0;
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _exitEditMode();
      _setupNotesSubscription(currentContext);
    }
  }

  @override
  void didUpdateWidget(NoteStackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.def.customProps != widget.def.customProps) {
      _loadSelectedIdsFromProps();
      _filterNotes();
    }
  }

  void _loadSelectedIdsFromProps() {
    final list = widget.def.customProps?['selectedNoteIds'] as List?;
    if (list != null && list.isNotEmpty) {
      _selectedNoteIds = list.map((e) => e.toString()).toSet();
    } else {
      _selectedNoteIds = null;
    }
  }

  @override
  void dispose() {
    _docSubscription?.cancel();
    _animController.dispose();
    _scrollController.dispose();
    _debounceSaveTimer?.cancel();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _setupNotesSubscription([ExpenseContext? contextOverride]) {
    _docSubscription?.cancel();
    final currentContext = contextOverride ?? _lastContext ?? DashboardContextScope.of(context);

    _docSubscription = _documentService
        .watchDocumentsForContext(currentContext, 'note')
        .listen((docs) async {
      if (!mounted) return;

      final previews = await _spaceService.getNotePreviews(docs.map((d) => d.id).toList());

      if (mounted) {
        _allDocs = docs;
        _previews = previews;
        _isLoading = false;
        _filterNotes();
      }
    });
  }

  void _filterNotes() {
    if (_selectedNoteIds != null && _selectedNoteIds!.isNotEmpty) {
      _notes = _allDocs.where((d) => _selectedNoteIds!.contains(d.id)).toList();
    } else {
      _notes = List.from(_allDocs);
    }

    if (_currentIndex >= _notes.length) {
      _currentIndex = _notes.isNotEmpty ? _notes.length - 1 : 0;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isEditingContent) return; // Do not drag during inline editing

    if (_notes.length <= 1) {
      setState(() {
        _dragDx += (details.primaryDelta ?? 0) * 0.25;
      });
      return;
    }

    setState(() {
      _dragDx += details.primaryDelta ?? 0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isEditingContent) return;

    if (_notes.length <= 1) {
      _animateBack();
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;
    const threshold = 40.0;

    if (_dragDx < -threshold || velocity < -400) {
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex + 1) % _notes.length;
      _animateDismiss(toLeft: true);
    } else if (_dragDx > threshold || velocity > 400) {
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex - 1 + _notes.length) % _notes.length;
      _animateDismiss(toLeft: false);
    } else {
      _animateBack();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isEditingContent) return; // Do not drag during inline editing

    if (_notes.length <= 1) {
      setState(() {
        _dragDy += (details.primaryDelta ?? 0) * 0.25;
      });
      return;
    }

    setState(() {
      _dragDy += details.primaryDelta ?? 0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isEditingContent) return;

    if (_notes.length <= 1) {
      _animateBack();
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;
    const threshold = 40.0;

    // Swiping upwards (dy < -threshold): dismiss upwards and reveal next note
    if (_dragDy < -threshold || velocity < -400) {
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex + 1) % _notes.length;
      _animateDismiss(toUp: true);
    } else if (_dragDy > threshold || velocity > 400) {
      // Swiping downwards (dy > threshold): dismiss downwards and reveal previous note
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex - 1 + _notes.length) % _notes.length;
      _animateDismiss(toDown: true);
    } else {
      _animateBack();
    }
  }

  void _animateDismiss({bool? toLeft, bool? toDown, bool? toUp}) {
    _animStartDx = _dragDx;
    _animStartDy = _dragDy;
    if (toDown == true) {
      _animEndDx = _dragDx;
      _animEndDy = 300.0;
    } else if (toUp == true) {
      _animEndDx = _dragDx;
      _animEndDy = -300.0;
    } else {
      _animEndDx = (toLeft ?? true) ? -250.0 : 250.0;
      _animEndDy = _dragDy;
    }
    _animController.forward(from: 0.0);
  }

  void _animateBack() {
    _targetIndex = _currentIndex;
    _animStartDx = _dragDx;
    _animStartDy = _dragDy;
    _animEndDx = 0.0;
    _animEndDy = 0.0;
    _animController.forward(from: 0.0);
  }

  // --- Inline Editing Methods ---

  void _startEditing(Document activeDoc) {
    final currentText = _previews[activeDoc.id] ?? '';
    _editController.text = currentText;
    setState(() {
      _isEditingContent = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editFocusNode.requestFocus();
      }
    });
  }

  void _onInlineContentChanged(String newText, Document activeDoc) {
    _debounceSaveTimer?.cancel();
    setState(() => _isSavingContent = true);
    _debounceSaveTimer = Timer(const Duration(milliseconds: 700), () {
      _saveActiveContent(newText, activeDoc.id);
    });
  }

  Future<void> _saveActiveContent(String text, String docId) async {
    try {
      await _spaceService.saveNoteContent(docId, text);
      if (mounted) {
        setState(() {
          _previews[docId] = text;
          _isSavingContent = false;
        });
      }
    } catch (e) {
      debugPrint('Error saving note content: $e');
      if (mounted) {
        setState(() => _isSavingContent = false);
      }
    }
  }

  Future<void> _exitEditMode() async {
    if (!_isEditingContent) return;

    if (_debounceSaveTimer?.isActive ?? false) {
      _debounceSaveTimer!.cancel();
      if (_notes.isNotEmpty && _currentIndex < _notes.length) {
        await _saveActiveContent(_editController.text, _notes[_currentIndex].id);
      }
    }

    _editFocusNode.unfocus();
    if (mounted) {
      setState(() {
        _isEditingContent = false;
        _isSavingContent = false;
      });
    }
  }

  void _openNoteFullScreen(Document doc) {
    _exitEditMode();
    context.push('/space/notes/${doc.id}');
  }

  // --- Manage Stack Selection Modal ---

  void _showManageStackModal() {
    _exitEditMode();

    final tempSelected = Set<String>.from(
      _selectedNoteIds ?? _allDocs.map((d) => d.id),
    );
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _allDocs.where((doc) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              final titleMatch = doc.title.toLowerCase().contains(q);
              final previewMatch = (_previews[doc.id] ?? '').toLowerCase().contains(q);
              return titleMatch || previewMatch;
            }).toList();

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.layers_rounded, color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Note nello Stack',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tempSelected.length} selezionate',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Cerca per titolo o contenuto...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setModalState(() => searchQuery = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Select All / Deselect All shortcuts
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.select_all, size: 14, color: Color(0xFFF59E0B)),
                        label: const Text('Seleziona tutte', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11)),
                        onPressed: () {
                          setModalState(() {
                            tempSelected.addAll(_allDocs.map((d) => d.id));
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.deselect, size: 14, color: Colors.white54),
                        label: const Text('Deseleziona tutte', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        onPressed: () {
                          setModalState(() {
                            tempSelected.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Notes List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Nessuna nota trovata',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, idx) {
                              final doc = filtered[idx];
                              final isSelected = tempSelected.contains(doc.id);
                              final preview = _previews[doc.id] ?? '';

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFFF59E0B),
                                  checkColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        tempSelected.add(doc.id);
                                      } else {
                                        tempSelected.remove(doc.id);
                                      }
                                    });
                                  },
                                ),
                                title: Text(
                                  doc.title,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: preview.isNotEmpty
                                    ? Text(
                                        preview.replaceAll('\n', ' '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      )
                                    : null,
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelected.remove(doc.id);
                                    } else {
                                      tempSelected.add(doc.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _applySelectedNotes(tempSelected);
                      },
                      child: const Text('Applica Selezione', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applySelectedNotes(Set<String> selectedIds) {
    setState(() {
      _selectedNoteIds = selectedIds.isNotEmpty ? selectedIds : null;
      _filterNotes();
    });

    try {
      final bloc = context.read<DashboardBloc>();
      final state = bloc.state;
      if (state is DashboardLoaded) {
        final newLayout = state.config.layout.map((w) {
          if (w.id == widget.def.id) {
            return w.copyWith(customProps: {
              ...?w.customProps,
              'selectedNoteIds': selectedIds.toList(),
            });
          }
          return w;
        }).toList();
        bloc.add(UpdateLayout(newLayout));
      }
    } catch (e) {
      debugPrint('Could not update layout in DashboardBloc: $e');
    }
  }

  Future<void> _showCreateNoteDialog({String? initialTitle}) async {
    _exitEditMode();
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final contentCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFF59E0B), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Nuova Nota',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Titolo *',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: const Color(0xFF27272A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Content Field
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Scrivi qui i tuoi appunti...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF27272A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving ? null : () => Navigator.pop(sheetContext),
                        child: const Text('Annulla', style: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) return;

                                setModalState(() => isSaving = true);

                                try {
                                  final currentContext = _lastContext ?? DashboardContextScope.of(context);
                                  String? targetGroupId = currentContext.groupId;
                                  String? targetUserId = currentContext.isPersonal
                                      ? Supabase.instance.client.auth.currentUser?.id
                                      : null;

                                  if (currentContext.isView) {
                                    final choice = await ViewGroupPickerSheet.show(
                                      sheetContext,
                                      title: 'Nuova Nota',
                                      subtitle: 'Scegli in quale contesto salvare questa nota',
                                    );
                                    if (choice == null) {
                                      setModalState(() => isSaving = false);
                                      return;
                                    }
                                    if (choice.isPersonal) {
                                      targetUserId = Supabase.instance.client.auth.currentUser?.id;
                                      targetGroupId = null;
                                    } else {
                                      targetGroupId = choice.groupId;
                                      targetUserId = null;
                                    }
                                  }

                                  final newDoc = NoteDocument.create(
                                    userId: targetUserId,
                                    groupId: targetGroupId,
                                    title: title,
                                  );

                                  final createdDoc = await _documentService.createDocument(newDoc);

                                  final content = contentCtrl.text.trim();
                                  if (content.isNotEmpty) {
                                    await _spaceService.saveNoteContent(createdDoc.id, content);
                                  }

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }

                                  if (mounted) {
                                    // Add to selected stack notes if curated selection is active
                                    if (_selectedNoteIds != null) {
                                      final updated = Set<String>.from(_selectedNoteIds!)..add(createdDoc.id);
                                      _applySelectedNotes(updated);
                                    }

                                    setState(() {
                                      _previews[createdDoc.id] = content;
                                      final newIdx = _notes.indexWhere((n) => n.id == createdDoc.id);
                                      if (newIdx != -1) {
                                        _currentIndex = newIdx;
                                      }
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Nota "$title" salvata!'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error creating note: $e');
                                  setModalState(() => isSaving = false);
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Text('Salva Nota', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Oggi, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  double _calculateAdaptiveTitleFontSize(String title) {
    final len = title.length;
    if (len <= 10) return 15.0;
    if (len <= 18) return 13.5;
    if (len <= 26) return 12.0;
    return 11.0;
  }

  Widget _buildPanoramicView(Document activeDoc, String previewText) {
    return BentoWidgetContainer(
      size: widget.def.size,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Navigator Pane
            SizedBox(
              width: 105,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top: Stack icon only
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFF59E0B), size: 14),
                  ),

                  // Middle: Stepper (< X/N >) and Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _notes.length <= 1
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      _exitEditMode();
                                      setState(() {
                                        _currentIndex = (_currentIndex - 1 + _notes.length) % _notes.length;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFFF59E0B)),
                              ),
                            ),
                            GestureDetector(
                              onTap: _showManageStackModal,
                              child: Text(
                                '${_currentIndex + 1}/${_notes.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _notes.length <= 1
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      _exitEditMode();
                                      setState(() {
                                        _currentIndex = (_currentIndex + 1) % _notes.length;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFF59E0B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(activeDoc.updatedAt),
                        style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Bottom: Add button
                  InkWell(
                    onTap: _showCreateNoteDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 12, color: Color(0xFFF59E0B)),
                          SizedBox(width: 4),
                          Text(
                            'Nuova',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right Note Body Pane
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isEditingContent ? null : () => _startEditing(activeDoc),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isEditingContent
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFF59E0B).withOpacity(0.25),
                      width: _isEditingContent ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title and Action
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activeDoc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: _calculateAdaptiveTitleFontSize(activeDoc.title),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_isEditingContent) ...[
                            if (_isSavingContent)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            InkWell(
                              onTap: _exitEditMode,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, color: Color(0xFF10B981), size: 11),
                                    SizedBox(width: 2),
                                    Text('Fatto', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            InkWell(
                              onTap: () => _openNoteFullScreen(activeDoc),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white38),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Scrollable Preview or Editable TextField
                      Expanded(
                        child: _isEditingContent
                            ? TextField(
                                controller: _editController,
                                focusNode: _editFocusNode,
                                maxLines: null,
                                expands: true,
                                cursorColor: const Color(0xFFF59E0B),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Scrivi qui i tuoi appunti...',
                                  hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onChanged: (val) => _onInlineContentChanged(val, activeDoc),
                              )
                            : RawScrollbar(
                                thumbColor: const Color(0xFFF59E0B).withOpacity(0.35),
                                radius: const Radius.circular(3),
                                thickness: 2.5,
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: Text(
                                    previewText.isNotEmpty ? previewText : 'Nota vuota... Tocca per scrivere',
                                    style: TextStyle(
                                      color: previewText.isNotEmpty ? Colors.white70 : Colors.white30,
                                      fontStyle: previewText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                      fontSize: 11.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BentoWidgetContainer(
        size: widget.def.size,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B), strokeWidth: 2),
        ),
      );
    }

    if (_notes.isEmpty) {
      return BentoWidgetContainer(
        size: widget.def.size,
        child: InkWell(
          onTap: _showCreateNoteDialog,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                  ),
                  child: const Icon(Icons.sticky_note_2_outlined, color: Color(0xFFF59E0B), size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  _allDocs.isNotEmpty ? 'Nessuna nota selezionata' : 'Nessuna nota',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _allDocs.isNotEmpty ? 'Tocca per scegliere o crearne una' : 'Tocca per crearne una',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeDoc = _notes[_currentIndex];
    final previewText = _previews[activeDoc.id] ?? '';

    if (widget.def.size.crossAxisCellCount >= 3) {
      return _buildPanoramicView(activeDoc, previewText);
    }

    return BentoWidgetContainer(
      size: widget.def.size,
      child: Column(
        children: [
          // Top widget toolbar - dedicated space on top edge
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.layers_rounded, color: Color(0xFFF59E0B), size: 14),
                Row(
                  children: [
                    // Stack indicator pill - tap to choose notes!
                    GestureDetector(
                      onTap: _showManageStackModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_currentIndex + 1}/${_notes.length}',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFFF59E0B), size: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Quick Add note button
                    InkWell(
                      onTap: _showCreateNoteDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 0.8),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFFF59E0B), size: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Card Stack
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 2 behind (if 3 or more notes)
                  if (_notes.length >= 3 && !_isEditingContent)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 4.0),
                        child: Transform.translate(
                          offset: const Offset(0, 8),
                          child: Transform.scale(
                            scale: 0.90,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF141416),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.04)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Layer 1 behind (if 2 or more notes)
                  if (_notes.length >= 2 && !_isEditingContent)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 4.0),
                        child: Transform.translate(
                          offset: const Offset(0, 4),
                          child: Transform.scale(
                            scale: 0.95,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF161618),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Active front card with swipe gesture
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 4.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: _isEditingContent ? null : _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _isEditingContent ? null : _onHorizontalDragEnd,
                        onVerticalDragUpdate: (_isEditingContent || _canScrollCurrentNote) ? null : _onVerticalDragUpdate,
                        onVerticalDragEnd: (_isEditingContent || _canScrollCurrentNote) ? null : _onVerticalDragEnd,
                        onTap: _isEditingContent ? null : () => _startEditing(activeDoc),
                        child: Transform.translate(
                          offset: Offset(_dragDx, _dragDy),
                          child: Transform.rotate(
                            angle: ((_dragDx / 400) + (_dragDy / 1000)).clamp(-0.15, 0.15),
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _isEditingContent
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFF59E0B).withOpacity(0.25),
                                  width: _isEditingContent ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Header: Title now has full space
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          activeDoc.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: _calculateAdaptiveTitleFontSize(activeDoc.title),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // If editing: show save status & exit checkmark
                                      if (_isEditingContent) ...[
                                        if (_isSavingContent)
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.only(right: 6),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF59E0B),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        InkWell(
                                          onTap: _exitEditMode,
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withOpacity(0.18),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, color: Color(0xFF10B981), size: 12),
                                                SizedBox(width: 3),
                                                Text('Fatto', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                            const SizedBox(height: 6),

                            // Date & full-screen button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(activeDoc.updatedAt),
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                                if (!_isEditingContent)
                                  InkWell(
                                    onTap: () => _openNoteFullScreen(activeDoc),
                                    borderRadius: BorderRadius.circular(6),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Row(
                                        children: [
                                          Icon(Icons.open_in_new_rounded, size: 10, color: Colors.white24),
                                          SizedBox(width: 2),
                                          Text('espandi', style: TextStyle(color: Colors.white24, fontSize: 9)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Content: Inline editable TextField OR Preview Text
                            Expanded(
                              child: _isEditingContent
                                  ? TextField(
                                      controller: _editController,
                                      focusNode: _editFocusNode,
                                      maxLines: null,
                                      expands: true,
                                      cursorColor: const Color(0xFFF59E0B),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Scrivi qui i tuoi appunti...',
                                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                      ),
                                      onChanged: (val) => _onInlineContentChanged(val, activeDoc),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final text = previewText.isNotEmpty ? previewText : 'Nota vuota... Tocca per scrivere';
                                        final textStyle = TextStyle(
                                          color: previewText.isNotEmpty ? Colors.white70 : Colors.white30,
                                          fontStyle: previewText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                          fontSize: 12,
                                          height: 1.4,
                                        );

                                        // Measure if content overflows available card height
                                        final span = TextSpan(text: text, style: textStyle);
                                        final tp = TextPainter(
                                          text: span,
                                          textDirection: TextDirection.ltr,
                                          maxLines: null,
                                        )..layout(maxWidth: constraints.maxWidth);

                                        final canScroll = tp.size.height > (constraints.maxHeight + 2);
                                        if (canScroll != _canScrollCurrentNote) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (mounted && canScroll != _canScrollCurrentNote) {
                                              setState(() {
                                                _canScrollCurrentNote = canScroll;
                                              });
                                            }
                                          });
                                        }

                                        if (!canScroll) {
                                          return Text(
                                            text,
                                            style: textStyle,
                                          );
                                        }

                                        return NotificationListener<ScrollNotification>(
                                          onNotification: (notification) {
                                            if (_isEditingContent) return false;

                                            if (notification is ScrollStartNotification) {
                                              _overscrollDy = 0.0;
                                            } else if (notification is OverscrollNotification) {
                                              if (_notes.length <= 1) return false;
                                              // Dragging beyond boundary
                                              if (notification.overscroll > 0) {
                                                // Pulling up past the bottom -> advance to next note
                                                _overscrollDy += notification.overscroll;
                                                setState(() {
                                                  _dragDy = -(_overscrollDy * 0.6).clamp(0.0, 100.0);
                                                });
                                              } else if (notification.overscroll < 0) {
                                                // Pulling down past the top -> go back to previous note
                                                _overscrollDy += notification.overscroll;
                                                setState(() {
                                                  _dragDy = -(_overscrollDy * 0.6).clamp(-100.0, 0.0);
                                                });
                                              }
                                            } else if (notification is ScrollUpdateNotification) {
                                              if (_overscrollDy != 0.0 && notification.scrollDelta != null) {
                                                _overscrollDy += notification.scrollDelta!;
                                                setState(() {
                                                  _dragDy = -(_overscrollDy * 0.6).clamp(-100.0, 100.0);
                                                });
                                              }
                                            } else if (notification is ScrollEndNotification) {
                                              if (_notes.length > 1) {
                                                const threshold = 35.0;
                                                if (_dragDy < -threshold) {
                                                  HapticFeedback.selectionClick();
                                                  _targetIndex = (_currentIndex + 1) % _notes.length;
                                                  _animateDismiss(toUp: true);
                                                } else if (_dragDy > threshold) {
                                                  HapticFeedback.selectionClick();
                                                  _targetIndex = (_currentIndex - 1 + _notes.length) % _notes.length;
                                                  _animateDismiss(toDown: true);
                                                } else if (_dragDy != 0.0) {
                                                  _animateBack();
                                                }
                                              } else if (_dragDy != 0.0) {
                                                _animateBack();
                                              }
                                              _overscrollDy = 0.0;
                                            }
                                            return false;
                                          },
                                          child: RawScrollbar(
                                            controller: _scrollController,
                                            thumbColor: const Color(0xFFF59E0B).withOpacity(0.35),
                                            radius: const Radius.circular(3),
                                            thickness: 2.5,
                                            child: SingleChildScrollView(
                                              controller: _scrollController,
                                              physics: const ClampingScrollPhysics(),
                                              child: Text(
                                                text,
                                                style: textStyle,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // Subtle footer cue (only in preview mode)
                            if (_notes.length > 1 && !_isEditingContent)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.swipe_outlined,
                                    size: 11,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'sfoglia',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
);
}
}
