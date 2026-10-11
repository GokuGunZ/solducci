import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/widgets/dashboard/base_list_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecentNotesWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const RecentNotesWidget({super.key, required this.def});

  @override
  State<RecentNotesWidget> createState() => _RecentNotesWidgetState();
}

class _RecentNotesWidgetState extends State<RecentNotesWidget> {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  final _contextManager = ContextManager();

  StreamSubscription? _docSubscription;
  List<Document> _notes = [];
  Map<String, String> _previews = {};
  bool _isLoading = true;

  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _contextManager.addListener(_onContextChanged);
    _setupNotesSubscription();
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    _docSubscription?.cancel();
    _titleController.dispose();
    _titleFocusNode.dispose();
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
        });
      }
    });
  }

  Future<void> _showQuickCreateModal({String? initialTitle}) async {
    final titleCtrl = TextEditingController(text: initialTitle ?? _titleController.text);
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
                        child: const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 20),
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
                                  final currentContext = _contextManager.currentContext;
                                  final effectiveUserId = currentContext.isPersonal
                                      ? Supabase.instance.client.auth.currentUser?.id
                                      : null;

                                  final newDoc = NoteDocument.create(
                                    userId: effectiveUserId,
                                    groupId: currentContext.groupId,
                                    title: title,
                                  );

                                  final createdDoc = await _documentService.createDocument(newDoc);

                                  final content = contentCtrl.text.trim();
                                  if (content.isNotEmpty) {
                                    await _spaceService.saveNoteContent(createdDoc.id, content);
                                  }

                                  _titleController.clear();
                                  _titleFocusNode.unfocus();

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  if (mounted) {
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
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Ieri';
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final currentContextName = _contextManager.contextDisplayName;
    final headerTitle = currentContextName.isNotEmpty ? 'Note $currentContextName' : 'Note';

    return BaseListWidget<Document>(
      heroTag: widget.def.id,
      isLoading: _isLoading,
      currentSource: headerTitle,
      color: const Color(0xFFF59E0B),
      icon: Icons.notes_rounded,
      onExpand: () => context.push('/space/notes'),
      onPreviousSource: () {},
      onNextSource: () {},
      items: _notes,
      emptyMessage: 'Nessuna nota presente.\nScrivi un titolo sopra per iniziare!',
      quickActionRow: Container(
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Nuova nota rapida...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (val) => _showQuickCreateModal(initialTitle: val),
                onChanged: (_) => setState(() {}),
              ),
            ),
            GestureDetector(
              onTap: () => _showQuickCreateModal(initialTitle: _titleController.text),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 12),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context, doc, index) {
        final preview = _previews[doc.id] ?? '';

        return GestureDetector(
          onTap: () => context.push('/space/notes/${doc.id}'),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFFF59E0B),
                    size: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _formatDate(doc.updatedAt),
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                          if (preview.isNotEmpty) ...[
                            const Text(
                              ' · ',
                              style: TextStyle(color: Colors.white24, fontSize: 10),
                            ),
                            Expanded(
                              child: Text(
                                preview.replaceAll('\n', ' '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white24,
                  size: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
