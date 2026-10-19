import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/features/space/services/note_folder_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/widgets/common/view_group_picker_sheet.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
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
  final _folderService = NoteFolderService();

  StreamSubscription? _docSubscription;
  List<NoteDocument> _notes = [];
  List<String> _customFolderNames = [];
  NoteFolder _selectedFolder = NoteFolder.all;
  Map<String, String> _previews = {};
  bool _isLoading = true;
  bool _isFoldersSidebarOpen = true;
  ExpenseContext? _lastContext;

  final TextEditingController _quickTitleController = TextEditingController();
  final FocusNode _quickTitleFocusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _initFoldersAndSubscription(currentContext);
    }
  }

  @override
  void dispose() {
    _docSubscription?.cancel();
    _quickTitleController.dispose();
    _quickTitleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initFoldersAndSubscription([ExpenseContext? ctx]) async {
    await _loadCustomFolders();
    _setupNotesSubscription(ctx);
  }

  Future<void> _loadCustomFolders() async {
    final names = await _folderService.getCustomFolderNames();
    if (mounted) {
      setState(() {
        _customFolderNames = names;
      });
    }
  }

  void _setupNotesSubscription([ExpenseContext? contextOverride]) {
    _docSubscription?.cancel();
    final currentContext = contextOverride ?? _lastContext ?? DashboardContextScope.of(context);

    _docSubscription = _documentService
        .watchDocumentsForContext(currentContext, 'note')
        .listen((docs) async {
      if (!mounted) return;

      final noteDocs = docs.whereType<NoteDocument>().toList();
      final previews = await _spaceService.getNotePreviews(noteDocs.map((d) => d.id).toList());

      if (mounted) {
        setState(() {
          _notes = noteDocs;
          _previews = previews;
          _isLoading = false;
        });
      }
    });
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

  Future<void> _createQuickNote({String? initialTitle}) async {
    final title = (initialTitle ?? _quickTitleController.text).trim();
    if (title.isEmpty) return;

    try {
      final currentContext = _lastContext ?? DashboardContextScope.of(context);
      String? targetGroupId = currentContext.groupId;
      String? targetUserId = currentContext.isPersonal
          ? Supabase.instance.client.auth.currentUser?.id
          : null;

      if (currentContext.isView) {
        final choice = await ViewGroupPickerSheet.show(
          context,
          title: 'Nuova Nota',
          subtitle: 'Scegli in quale contesto salvare questa nota',
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

      String? targetFolder;
      if (!_selectedFolder.isSpecialAll && !_selectedFolder.isDefault) {
        targetFolder = _selectedFolder.effectivePath;
      }

      final newDoc = Document.fromMap({
        'id': '',
        'user_id': targetUserId,
        'group_id': targetGroupId,
        'document_type': 'note',
        'title': title,
        'metadata': targetFolder != null ? {'folder': targetFolder} : {},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _documentService.createDocument(newDoc);
      _quickTitleController.clear();
      _quickTitleFocusNode.unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nota "$title" creata!'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating quick note: $e');
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_outlined, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text('Nuova Cartella', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Es. Progetti, Idee...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) Navigator.pop(ctx, val);
            },
            child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final fullPath = await _folderService.addCustomFolder(result);
      await _loadCustomFolders();
      if (mounted) {
        setState(() {
          _selectedFolder = NoteFolder(id: fullPath, fullPath: fullPath, name: result);
        });
      }
    }
  }

  void _showNoteOptionsModal(NoteDocument note) {
    final folders = _folderService.buildFolderList(_notes, _customFolderNames);
    final assignableFolders = folders.where((f) => !f.isSpecialAll).toList();
    final currentFolderName = _folderService.getFolderForNote(note);
    final titleController = TextEditingController(text: note.title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // Merged Title Form for renaming
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: 'Titolo nota...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: (newTitle) async {
                            final trimmed = newTitle.trim();
                            if (trimmed.isNotEmpty && trimmed != note.title) {
                              await _updateNoteTitle(note, trimmed);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                        tooltip: 'Salva Titolo',
                        onPressed: () async {
                          final trimmed = titleController.text.trim();
                          if (trimmed.isNotEmpty && trimmed != note.title) {
                            await _updateNoteTitle(note, trimmed);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 6),
                  child: Text(
                    'Cartella attuale: $currentFolderName',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),

                const Text(
                  'SPOSTA IN CARTELLA',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: assignableFolders.map((f) {
                    final isCurrent = f.effectivePath == currentFolderName;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(f.icon, size: 14, color: isCurrent ? Colors.black : const Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text(f.name),
                        ],
                      ),
                      selected: isCurrent,
                      selectedColor: const Color(0xFFF59E0B),
                      backgroundColor: const Color(0xFF27272A),
                      labelStyle: TextStyle(
                        color: isCurrent ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: isCurrent
                          ? null
                          : (selected) async {
                              Navigator.pop(ctx);
                              await _folderService.moveNoteToFolder(note, f.effectivePath);
                            },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),
                const Divider(color: Colors.white10),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Elimina Nota', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF18181B),
                        title: const Text('Elimina Nota', style: TextStyle(color: Colors.white)),
                        content: Text('Vuoi davvero eliminare "${note.title}"?', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Elimina'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await _documentService.deleteDocument(note.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateNoteTitle(NoteDocument note, String newTitle) async {
    final updated = NoteDocument(
      id: note.id,
      userId: note.userId,
      groupId: note.groupId,
      title: newTitle,
      description: note.description,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      metadata: note.metadata,
    );
    await _documentService.updateDocument(updated);
  }

  void _showFolderOptionsModal(NoteFolder folder) {
    if (folder.isSpecialAll || folder.isDefault) return;
    final folderController = TextEditingController(text: folder.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Merged Form to Rename Folder
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: folderController,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: 'Nome cartella...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: (newName) async {
                            final trimmed = newName.trim();
                            if (trimmed.isNotEmpty && trimmed != folder.name) {
                              await _renameFolder(folder, trimmed);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                        tooltip: 'Rinomina Cartella',
                        onPressed: () async {
                          final trimmed = folderController.text.trim();
                          if (trimmed.isNotEmpty && trimmed != folder.name) {
                            await _renameFolder(folder, trimmed);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Elimina Cartella', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Elimina questa cartella ed eventualmente tutte le sue note.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final notesInFolder = _notes.where((d) {
                      final f = _folderService.getDocFolder(d);
                      return f == folder.effectivePath || (f != null && f.startsWith('${folder.effectivePath}/'));
                    }).toList();
                    final subfolders = _customFolderNames.where((p) => p.startsWith('${folder.effectivePath}/')).toList();
                    final hasContent = notesInFolder.isNotEmpty || subfolders.isNotEmpty;

                    if (hasContent) {
                      final choice = await showDialog<String>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: const Color(0xFF18181B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Elimina cartella con contenuto', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          content: Text(
                            'La cartella "${folder.name}" contiene ${notesInFolder.length} note'
                            '${subfolders.isNotEmpty ? ' e ${subfolders.length} sottocartelle' : ''}.\n\n'
                            'Come desideri procedere?',
                            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, 'cancel'), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                              onPressed: () => Navigator.pop(c, 'move'),
                              child: const Text('Sposta note in "Personali"', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(c, 'delete_all'),
                              child: const Text('Elimina tutto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      );

                      if (choice == 'delete_all') {
                        await _folderService.deleteFolderRecursive(folder.effectivePath, _notes, deleteNotes: true);
                        await _loadCustomFolders();
                        if (mounted) setState(() => _selectedFolder = NoteFolder.all);
                      } else if (choice == 'move') {
                        await _folderService.deleteFolderRecursive(folder.effectivePath, _notes, deleteNotes: false);
                        await _loadCustomFolders();
                        if (mounted) setState(() => _selectedFolder = NoteFolder.all);
                      }
                    } else {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: const Color(0xFF18181B),
                          title: const Text('Elimina Cartella', style: TextStyle(color: Colors.white)),
                          content: Text('Vuoi davvero eliminare la cartella "${folder.name}"?', style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Elimina'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _folderService.deleteFolderRecursive(folder.effectivePath, _notes, deleteNotes: false);
                        await _loadCustomFolders();
                        if (mounted) setState(() => _selectedFolder = NoteFolder.all);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _renameFolder(NoteFolder folder, String newName) async {
    final newPath = await _folderService.renameFolder(folder.effectivePath, newName, _notes);
    await _loadCustomFolders();
    if (mounted) {
      setState(() {
        _selectedFolder = NoteFolder(id: newPath, fullPath: newPath, name: newName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideOrLarge = widget.def.size.crossAxisCellCount >= 3 || (widget.def.size.crossAxisCellCount >= 2 && widget.def.size.mainAxisCellCount >= 3);
    final folders = _folderService.buildFolderList(_notes, _customFolderNames);

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: widget.def.size,
      onExpand: () => context.push('/space/notes'),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B), strokeWidth: 2))
          : (isWideOrLarge ? _buildDualPaneExplorer(folders) : _buildSinglePaneExplorer(folders)),
    );
  }

  /// Visualizzazione a Due Livelli / Dual Pane per widget grandi
  Widget _buildDualPaneExplorer(List<NoteFolder> folders) {
    final notesInCurrent = _folderService.filterDocsByFolder(_notes, _selectedFolder);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget Header
          _buildWidgetHeader(),
          const SizedBox(height: 8),

          // Dual Column Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colonna 1: Cartelle (animata/collassabile)
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  child: _isFoldersSidebarOpen
                      ? SizedBox(
                          width: 135,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'CARTELLE',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: _showCreateFolderDialog,
                                        borderRadius: BorderRadius.circular(4),
                                        child: const Padding(
                                          padding: EdgeInsets.all(2.0),
                                          child: Icon(Icons.add, color: Color(0xFFF59E0B), size: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => setState(() => _isFoldersSidebarOpen = false),
                                        borderRadius: BorderRadius.circular(4),
                                        child: const Padding(
                                          padding: EdgeInsets.all(2.0),
                                          child: Icon(Icons.keyboard_double_arrow_left_rounded, color: Colors.white38, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: folders.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                                  itemBuilder: (context, i) {
                                    final folder = folders[i];
                                    final isSelected = folder.effectivePath == _selectedFolder.effectivePath ||
                                        (folder.isSpecialAll && _selectedFolder.isSpecialAll);

                                    return InkWell(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedFolder = folder;
                                          if (widget.def.size.crossAxisCellCount <= 2) {
                                            _isFoldersSidebarOpen = false;
                                          }
                                        });
                                      },
                                      onLongPress: () => _showFolderOptionsModal(folder),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFF59E0B).withOpacity(0.18) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFFF59E0B).withOpacity(0.4) : Colors.transparent,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              folder.icon,
                                              size: 13,
                                              color: isSelected ? const Color(0xFFF59E0B) : Colors.white60,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                folder.name,
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.white70,
                                                  fontSize: 11.5,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (folder.notesCount > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${folder.notesCount}',
                                                  style: const TextStyle(color: Colors.white60, fontSize: 9),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                if (_isFoldersSidebarOpen)
                  const VerticalDivider(color: Colors.white12, width: 16, thickness: 0.8),

                // Colonna 2: Note nella cartella selezionata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header cartella & Quick note
                      _buildQuickNoteRow(),
                      const SizedBox(height: 6),

                      // Lista Note
                      Expanded(
                        child: notesInCurrent.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                itemCount: notesInCurrent.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 4),
                                itemBuilder: (context, i) => _buildNoteListItem(notesInCurrent[i]),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Visualizzazione a Singolo Livello Navigabile (Breadcrumb Drill-Down) per widget compatti
  Widget _buildSinglePaneExplorer(List<NoteFolder> folders) {
    final isInsideFolder = !_selectedFolder.isSpecialAll;
    final notesInCurrent = _folderService.filterDocsByFolder(_notes, _selectedFolder);
    final customOnlyFolders = folders.where((f) => !f.isSpecialAll).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Breadcrumb
          if (isInsideFolder)
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _selectedFolder = NoteFolder.all),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 12, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text('Tutte', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFolder.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showFolderOptionsModal(_selectedFolder),
                  child: const Icon(Icons.more_horiz_rounded, color: Colors.white54, size: 16),
                ),
              ],
            )
          else
            _buildWidgetHeader(),

          const SizedBox(height: 8),

          // Quick note input
          _buildQuickNoteRow(),
          const SizedBox(height: 8),

          // Contenuto: Cartelle a chip (se a root) + Note
          if (!isInsideFolder && customOnlyFolders.isNotEmpty) ...[
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: customOnlyFolders.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  if (i == customOnlyFolders.length) {
                    return InkWell(
                      onTap: _showCreateFolderDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.create_new_folder_outlined, size: 14, color: Color(0xFFF59E0B)),
                      ),
                    );
                  }

                  final f = customOnlyFolders[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFolder = f),
                    onLongPress: () => _showFolderOptionsModal(f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(f.icon, size: 11, color: const Color(0xFFF59E0B)),
                          const SizedBox(width: 5),
                          Text(f.name, style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                          if (f.notesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text('(${f.notesCount})', style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Lista Note
          Expanded(
            child: notesInCurrent.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: notesInCurrent.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) => _buildNoteListItem(notesInCurrent[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.folder_copy_rounded, color: Color(0xFFF59E0B), size: 14),
            SizedBox(width: 6),
            Text(
              'ESPLORATORE NOTE',
              style: TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: _showCreateFolderDialog,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.create_new_folder_outlined, color: Color(0xFFF59E0B), size: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickNoteRow() {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10, width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // Se la sidebar cartelle è chiusa, l'item della cartella selezionata va in cima qui
          if (!_isFoldersSidebarOpen) ...[
            InkWell(
              onTap: () => setState(() => _isFoldersSidebarOpen = true),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_selectedFolder.icon, size: 12, color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 85),
                      child: Text(
                        _selectedFolder.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.menu_open_rounded, size: 12, color: Color(0xFFF59E0B)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 15),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: TextField(
              controller: _quickTitleController,
              focusNode: _quickTitleFocusNode,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              decoration: const InputDecoration(
                hintText: 'Nuova nota rapida...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 10.5),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onSubmitted: (val) => _createQuickNote(initialTitle: val),
            ),
          ),
          GestureDetector(
            onTap: () => _createQuickNote(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteListItem(NoteDocument doc) {
    final preview = _previews[doc.id] ?? '';

    return GestureDetector(
      onTap: () => context.push('/space/notes/${doc.id}'),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showNoteOptionsModal(doc);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.description_outlined, color: Color(0xFFF59E0B), size: 12),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    doc.title.isNotEmpty ? doc.title : 'Senza titolo',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Text(
                        _formatDate(doc.updatedAt),
                        style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                      ),
                      if (preview.isNotEmpty) ...[
                        const Text(' · ', style: TextStyle(color: Colors.white24, fontSize: 9.5)),
                        Expanded(
                          child: Text(
                            preview.replaceAll('\n', ' '),
                            style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Solo quando la tab cartelle è chiusa mostriamo i tre puntini, per risparmiare spazio quando è aperta
            if (!_isFoldersSidebarOpen)
              GestureDetector(
                onTap: () => _showNoteOptionsModal(doc),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.more_vert_rounded, color: Colors.white38, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notes_rounded, color: Colors.white24, size: 24),
          const SizedBox(height: 4),
          const Text('Nessuna nota in questa cartella', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
