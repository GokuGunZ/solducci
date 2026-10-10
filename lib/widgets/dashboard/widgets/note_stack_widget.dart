import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
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
  final _contextManager = ContextManager();

  StreamSubscription? _docSubscription;
  List<Document> _notes = [];
  Map<String, String> _previews = {};
  bool _isLoading = true;

  int _currentIndex = 0;
  double _dragDx = 0.0;
  late AnimationController _animController;
  late Animation<double> _anim;
  double _animStartDx = 0.0;
  double _animEndDx = 0.0;
  int _targetIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _anim.addListener(() {
      setState(() {
        _dragDx = _animStartDx + (_animEndDx - _animStartDx) * _anim.value;
      });
    });
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_targetIndex != _currentIndex) {
          setState(() {
            _currentIndex = _targetIndex;
            _dragDx = 0.0;
          });
        } else {
          setState(() {
            _dragDx = 0.0;
          });
        }
      }
    });

    _contextManager.addListener(_onContextChanged);
    _setupNotesSubscription();
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    _docSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onContextChanged() {
    _setupNotesSubscription();
  }

  void _setupNotesSubscription() {
    _docSubscription?.cancel();
    final currentContext = _contextManager.currentContext;

    _docSubscription = _documentService
        .watchDocumentsForContext(currentContext, 'note')
        .listen((docs) async {
      if (!mounted) return;

      final previews = await _spaceService.getNotePreviews(docs.map((d) => d.id).toList());

      if (mounted) {
        setState(() {
          _notes = docs;
          _previews = previews;
          _isLoading = false;
          if (_currentIndex >= docs.length) {
            _currentIndex = docs.isNotEmpty ? docs.length - 1 : 0;
          }
        });
      }
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_notes.length <= 1) {
      // Elastic resistance if only 1 note
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
    if (_notes.length <= 1) {
      _animateBack();
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;
    const threshold = 40.0;

    if (_dragDx < -threshold || velocity < -400) {
      // Swipe left -> Next note
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex + 1) % _notes.length;
      _animateDismiss(toLeft: true);
    } else if (_dragDx > threshold || velocity > 400) {
      // Swipe right -> Previous note
      HapticFeedback.selectionClick();
      _targetIndex = (_currentIndex - 1 + _notes.length) % _notes.length;
      _animateDismiss(toLeft: false);
    } else {
      _animateBack();
    }
  }

  void _animateDismiss({required bool toLeft}) {
    _animStartDx = _dragDx;
    _animEndDx = toLeft ? -250.0 : 250.0;
    _animController.forward(from: 0.0);
  }

  void _animateBack() {
    _targetIndex = _currentIndex;
    _animStartDx = _dragDx;
    _animEndDx = 0.0;
    _animController.forward(from: 0.0);
  }

  void _openNote(Document doc) {
    context.push('/space/notes/${doc.id}');
  }

  Future<void> _showCreateNoteDialog() async {
    final titleController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Row(
          children: [
            Icon(Icons.sticky_note_2_rounded, color: Color(0xFFF59E0B), size: 20),
            SizedBox(width: 8),
            Text('Nuova Nota', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Titolo della nota...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF59E0B))),
          ),
          onSubmitted: (val) => Navigator.pop(context, val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, titleController.text.trim()),
            child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final currentContext = _contextManager.currentContext;
      final effectiveUserId = currentContext.isPersonal
          ? Supabase.instance.client.auth.currentUser?.id
          : null;
      final newDoc = NoteDocument.create(
        userId: effectiveUserId,
        groupId: currentContext.groupId,
        title: result,
      );
      final created = await _documentService.createDocument(newDoc);
      if (mounted) {
        _openNote(created);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Oggi, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const BentoWidgetContainer(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B), strokeWidth: 2),
        ),
      );
    }

    if (_notes.isEmpty) {
      return BentoWidgetContainer(
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
                const Text(
                  'Nessuna nota',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tocca per crearne una',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeDoc = _notes[_currentIndex];
    final previewText = _previews[activeDoc.id] ?? '';

    return BentoWidgetContainer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 2 behind (if 3 or more notes)
            if (_notes.length >= 3)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Transform.translate(
                    offset: const Offset(0, 10),
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
            if (_notes.length >= 2)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Transform.translate(
                    offset: const Offset(0, 5),
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
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  onTap: () => _openNote(activeDoc),
                  child: Transform.translate(
                    offset: Offset(_dragDx, 0),
                    child: Transform.rotate(
                      angle: (_dragDx / 400).clamp(-0.15, 0.15),
                      child: Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.25),
                            width: 1,
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
                            // Card Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.sticky_note_2_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activeDoc.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Stack indicator pill (e.g. 1/3)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_currentIndex + 1}/${_notes.length}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Quick Add note button
                                InkWell(
                                  onTap: _showCreateNoteDialog,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(Icons.add, color: Color(0xFFF59E0B), size: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Date
                            Text(
                              _formatDate(activeDoc.updatedAt),
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                            const SizedBox(height: 8),
                            // Content preview
                            Expanded(
                              child: Text(
                                previewText.isNotEmpty ? previewText : 'Nota vuota... Tocca per scrivere',
                                maxLines: 6,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  color: previewText.isNotEmpty ? Colors.white70 : Colors.white30,
                                  fontStyle: previewText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            // Subtle footer cue
                            if (_notes.length > 1)
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
    );
  }
}
