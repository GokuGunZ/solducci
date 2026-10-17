import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _ScratchpadTarget { asterisk, note }

class QuickScratchpadWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const QuickScratchpadWidget({super.key, required this.def});

  @override
  State<QuickScratchpadWidget> createState() => _QuickScratchpadWidgetState();
}

class _QuickScratchpadWidgetState extends State<QuickScratchpadWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  final _contextManager = ContextManager();

  _ScratchpadTarget _target = _ScratchpadTarget.asterisk;
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveScratchpad() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSaving) return;

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      final currentContext = _contextManager.currentContext;

      if (_target == _ScratchpadTarget.asterisk) {
        final docs = await _documentService.getDocumentsForContext(currentContext, 'asterisk');
        String docId;
        if (docs.isNotEmpty) {
          docId = docs.first.id;
        } else {
          final newDoc = await _documentService.createDocument(AsteriskDocument(
            id: '',
            userId: currentContext.isGroup ? null : Supabase.instance.client.auth.currentUser?.id,
            groupId: currentContext.isGroup ? currentContext.groupId : null,
            title: 'Note & Asterischi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
          docId = newDoc.id;
        }

        await _spaceService.createAsteriskItem(AsteriskItem(
          id: '',
          documentId: docId,
          content: text,
          isResolved: false,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      } else {
        // Save as Note
        final lines = text.split('\n');
        final title = lines.first.trim().isNotEmpty
            ? (lines.first.length > 30 ? '${lines.first.substring(0, 30)}...' : lines.first)
            : 'Appunto rapido';

        final effectiveUserId = currentContext.isPersonal
            ? Supabase.instance.client.auth.currentUser?.id
            : null;

        final newDoc = NoteDocument.create(
          userId: effectiveUserId,
          groupId: currentContext.groupId,
          title: title,
        );

        final createdDoc = await _documentService.createDocument(newDoc);
        await _spaceService.saveNoteContent(createdDoc.id, text);
      }

      _textController.clear();
      _focusNode.unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _target == _ScratchpadTarget.asterisk ? Icons.star_rounded : Icons.sticky_note_2_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _target == _ScratchpadTarget.asterisk ? 'Asterisco salvato!' : 'Nota salvata!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore salvataggio: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final isHeight1 = size.mainAxisCellCount <= 1;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: size,
      onTap: () {
        if (_target == _ScratchpadTarget.asterisk) {
          context.push('/space/asterisks');
        } else {
          context.push('/space/notes');
        }
      },
      child: Padding(
        padding: isHeight1
            ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0)
            : const EdgeInsets.all(12.0),
        child: isHeight1 ? _buildMiniBanner() : _buildCompactView(),
      ),
    );
  }

  // Taglia 2x1 / 4x1 (Altezza 1, Mini-Banner Interattivo)
  Widget _buildMiniBanner() {
    return Row(
      children: [
        // Target toggle chip
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _target = _target == _ScratchpadTarget.asterisk
                  ? _ScratchpadTarget.note
                  : _ScratchpadTarget.asterisk;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _target == _ScratchpadTarget.asterisk ? Icons.star_rounded : Icons.sticky_note_2_rounded,
                  size: 13,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 3),
                Text(
                  _target == _ScratchpadTarget.asterisk ? 'Asterisco' : 'Nota',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Text input
        Expanded(
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 11.5),
            decoration: InputDecoration(
              hintText: _target == _ScratchpadTarget.asterisk ? 'Cattura un asterisco...' : 'Appunto rapido...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 10.5),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => _saveScratchpad(),
          ),
        ),

        // Submit action
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isSaving ? null : _saveScratchpad,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black),
                  )
                : const Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.black),
          ),
        ),
      ],
    );
  }

  // Taglia 2x2 (Altezza 2, Blocco Appunti Immediato)
  Widget _buildCompactView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with target switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Appunto al Volo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Target selector chips
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTargetChip('⭐', _ScratchpadTarget.asterisk),
                  _buildTargetChip('📝', _ScratchpadTarget.note),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Multi-line Text Field
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF27272A).withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3),
              decoration: InputDecoration(
                hintText: _target == _ScratchpadTarget.asterisk
                    ? 'Scrivi un pensiero o promemoria...'
                    : 'Scrivi qui i tuoi appunti...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Bottom Action Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _target == _ScratchpadTarget.asterisk ? 'Salva in Asterischi' : 'Salva in Note',
              style: const TextStyle(color: Colors.white38, fontSize: 9.5),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isSaving ? null : _saveScratchpad,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: Colors.black),
                          SizedBox(width: 3),
                          Text(
                            'Salva',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetChip(String iconText, _ScratchpadTarget target) {
    final isSelected = _target == target;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _target = target);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          iconText,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}
