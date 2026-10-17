import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/features/space/services/note_folder_service.dart';
import 'package:solducci/features/space/views/note_detail_view.dart';
import 'package:solducci/features/space/widgets/notes_collapsible_header.dart';
import 'package:solducci/widgets/common/view_group_picker_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Vista unificata per le Note con sistema a Cartelle, Sotto-cartelle e Finder a due stati (stile MacOS).
///
/// - Stato compresso (Focus Mode): Header con carosello orizzontale a chips con solo le note
///   della cartella corrente, ed editor note a schermo intero.
/// - Stato espanso (Split Explorer Mode): Miller Columns a due colonne (Cartelle e Sotto-cartelle
///   a sinistra, Sottocartelle e Note a destra con creazione inline del titolo).
class NotesHubView extends StatefulWidget {
  final String? initialDocumentId;

  const NotesHubView({super.key, this.initialDocumentId});

  @override
  State<NotesHubView> createState() => _NotesHubViewState();
}

class _NotesHubViewState extends State<NotesHubView> {
  final DocumentService _documentService = DocumentService();
  final ContextManager _contextManager = ContextManager();
  final NoteFolderService _folderService = NoteFolderService();

  List<NoteDocument> _allNotes = [];
  List<String> _customFolderNames = [];
  late NoteFolder _selectedFolder;
  NoteDocument? _activeNote;
  String? _editingNoteId;

  bool _isLoading = true;
  bool _isHeaderExpanded = false;
  StreamSubscription? _notesSubscription;

  @override
  void initState() {
    super.initState();
    _selectedFolder = NoteFolder.all;
    _contextManager.addListener(_onContextChanged);
    _initData();
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) {
      _subscribeToNotes();
    }
  }

  Future<void> _initData() async {
    await _loadCustomFolders();
    await _subscribeToNotes();
  }

  Future<void> _loadCustomFolders() async {
    final customFolders = await _folderService.getCustomFolderNames();
    if (mounted) {
      setState(() {
        _customFolderNames = customFolders;
      });
    }
  }

  Future<void> _subscribeToNotes() async {
    _notesSubscription?.cancel();
    setState(() => _isLoading = true);

    final currentContext = _contextManager.currentContext;

    // Load initial documents from cache/service
    try {
      final initialDocs = await _documentService.getDocumentsForContext(
        currentContext,
        'note',
      );
      if (mounted) {
        _handleNewNotesList(initialDocs.whereType<NoteDocument>().toList());
      }
    } catch (e) {
      debugPrint('[NotesHubView] Error loading initial notes: $e');
    }

    // Subscribe to real-time changes
    _notesSubscription = _documentService
        .watchDocumentsForContext(currentContext, 'note')
        .listen(
          (docs) {
            if (mounted) {
              _handleNewNotesList(docs.whereType<NoteDocument>().toList());
            }
          },
          onError: (e) {
            debugPrint('[NotesHubView] Stream error: $e');
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        );
  }

  void _handleNewNotesList(List<NoteDocument> notes) {
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    NoteDocument? nextActive = _activeNote;

    // If an initial document was requested on first load
    if (nextActive == null && widget.initialDocumentId != null) {
      final match = notes.where((n) => n.id == widget.initialDocumentId).firstOrNull;
      if (match != null) {
        nextActive = match;
        _isHeaderExpanded = true;
        final docFolder = _folderService.getDocFolder(match);
        if (docFolder != null) {
          final folders = _folderService.buildFolderList(notes, _customFolderNames);
          final folderMatch = folders.where((f) => f.effectivePath == docFolder).firstOrNull;
          if (folderMatch != null) {
            _selectedFolder = folderMatch;
          }
        }
      }
    }

    // If active note is still valid, get the newest instance
    if (nextActive != null) {
      final currentMatch = notes.where((n) => n.id == nextActive!.id).firstOrNull;
      nextActive = currentMatch;
    }

    // If active note is null or no longer exists, select first in current folder or first overall
    if (nextActive == null && notes.isNotEmpty) {
      final inFolder = _folderService.filterDocsByFolder(notes, _selectedFolder);
      if (inFolder.isNotEmpty) {
        nextActive = inFolder.first;
      } else {
        nextActive = notes.first;
      }
    }

    setState(() {
      _allNotes = notes;
      _activeNote = nextActive;
      _isLoading = false;
    });
  }

  /// Salva una nuova cartella o sotto-cartella creata inline senza popup
  /// Mantiene la cartella corrente senza forzare il reindirizzamento
  Future<void> _commitNewFolder(String name, {String? parentPath}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    HapticFeedback.lightImpact();
    await _folderService.addCustomFolder(trimmed, parentPath: parentPath);
    await _loadCustomFolders();
    // Non modifichiamo _selectedFolder: l'utente rimane esattamente dove si trova
  }

  /// Crea una nuova cartella o sotto-cartella (dialog fallback)
  Future<void> _showAddFolderDialog({NoteFolder? parentFolder}) async {
    final controller = TextEditingController();
    final isSubfolder = parentFolder != null &&
        !parentFolder.isSpecialAll &&
        !parentFolder.isDefault;

    final titleText = isSubfolder
        ? 'Nuova Sotto-cartella in "${parentFolder.name}"'
        : 'Nuova Cartella';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Row(
          children: [
            const Icon(Icons.create_new_folder_outlined, color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titleText,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isSubfolder ? 'Es. Solducci, Meeting...' : 'Es. Progetti, Idee...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1C1C22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF59E0B)),
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
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final parentPath = isSubfolder ? parentFolder.effectivePath : null;
      final fullPath = await _folderService.addCustomFolder(result, parentPath: parentPath);
      await _loadCustomFolders();

      // Auto-seleziona la cartella appena creata
      setState(() {
        _selectedFolder = NoteFolder(
          id: fullPath,
          fullPath: fullPath,
          name: result,
          parentPath: parentPath,
        );
      });
    }
  }

  /// Crea istantaneamente una nuova nota inline senza popup, selezionandola subito per la digitazione
  Future<void> _createInlineNote() async {
    HapticFeedback.mediumImpact();
    final currentContext = _contextManager.currentContext;

    String targetFolderPath = _selectedFolder.effectivePath;
    if (_selectedFolder.isSpecialAll) {
      targetFolderPath = NoteFolderService.defaultFolderName;
    }

    String? targetGroupId = currentContext.groupId;
    String? targetUserId = currentContext.isPersonal ? Supabase.instance.client.auth.currentUser?.id : null;

    if (currentContext.isView) {
      final choice = await ViewGroupPickerSheet.show(
        context,
        title: 'Nuova Nota',
        subtitle: 'Scegli in quale contesto creare questa nota',
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
      'document_type': 'note',
      'title': 'Nuova nota',
      'metadata': {'folder': targetFolderPath},
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final created = await _documentService.createDocument(newDoc);
    if (created is NoteDocument && mounted) {
      setState(() {
        _allNotes.removeWhere((n) => n.id == created.id);
        _allNotes.insert(0, created);
        _activeNote = created;
        _editingNoteId = created.id;

        // Se eravamo in "Tutte le note", rimaniamo in "Tutte le note",
        // altrimenti assicuriamoci che la cartella attiva corrisponda
        if (!_selectedFolder.isSpecialAll && _selectedFolder.effectivePath != targetFolderPath) {
          _selectedFolder = NoteFolder(
            id: targetFolderPath,
            fullPath: targetFolderPath,
            name: targetFolderPath.split('/').last,
          );
        }
      });
    }
  }

  /// Salva il titolo modificato inline della nota
  Future<void> _commitNoteTitle(NoteDocument note, String newTitle) async {
    final trimmed = newTitle.trim().isEmpty ? 'Nuova nota' : newTitle.trim();
    if (note.title != trimmed) {
      final updated = NoteDocument(
        id: note.id,
        userId: note.userId,
        groupId: note.groupId,
        title: trimmed,
        description: note.description,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        metadata: note.metadata,
      );

      await _documentService.updateDocument(updated);

      if (mounted) {
        setState(() {
          final index = _allNotes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _allNotes[index] = updated;
          }
          if (_activeNote?.id == note.id) {
            _activeNote = updated;
          }
        });
      }
    }

    if (mounted) {
      setState(() {
        if (_editingNoteId == note.id) {
          _editingNoteId = null;
        }
      });
    }
  }

  void _showNoteOptionsDialog(NoteDocument note) {
    final folders = _folderService.buildFolderList(_allNotes, _customFolderNames);
    final assignableFolders = folders.where((f) => !f.isSpecialAll).toList();
    final currentFolderName = _folderService.getFolderForNote(note);
    final titleController = TextEditingController(text: note.title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141417),
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

                // Titolo Nota modificabile (Merged Form)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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
                              await _commitNoteTitle(note, trimmed);
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
                            await _commitNoteTitle(note, trimmed);
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
                    'Cartella: $currentFolderName',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),

                // Sposta in altra cartella
                const Text(
                  'SPOSTA IN CARTELLA',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
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
                      backgroundColor: const Color(0xFF1E1E24),
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
                              if (mounted) {
                                await _subscribeToNotes();
                              }
                            },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white10),

                // Elimina Nota
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text(
                    'Elimina Nota',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF141417),
                        title: const Text('Elimina Nota', style: TextStyle(color: Colors.white)),
                        content: Text(
                          'Vuoi davvero eliminare "${note.title}"?',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Elimina'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await _documentService.deleteDocument(note.id);
                      if (mounted) {
                        setState(() {
                          _allNotes.removeWhere((n) => n.id == note.id);
                          if (_activeNote?.id == note.id) {
                            _activeNote = _allNotes.firstOrNull;
                          }
                        });
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
    final newPath = await _folderService.renameFolder(folder.effectivePath, newName, _allNotes);
    await _loadCustomFolders();
    await _subscribeToNotes();
    if (mounted) {
      setState(() {
        _selectedFolder = NoteFolder(
          id: newPath,
          fullPath: newPath,
          name: newName.trim(),
          parentPath: folder.parentPath,
        );
      });
    }
  }

  void _showFolderOptionsDialog(NoteFolder folder) {
    if (folder.isSpecialAll || folder.isDefault) return;
    final folderController = TextEditingController(text: folder.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141417),
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

                // Nome Cartella modificabile (Merged Form)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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

                // Elimina cartella (con logica ricorsiva e conferma esplicita per contenuti)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text(
                    'Elimina Cartella',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Elimina questa cartella ed eventualmente tutte le sue note.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final notesInFolder = _allNotes.where((d) {
                      final f = _folderService.getDocFolder(d);
                      return f == folder.effectivePath || (f != null && f.startsWith('${folder.effectivePath}/'));
                    }).toList();
                    final subfolders = _customFolderNames.where((p) => p.startsWith('${folder.effectivePath}/')).toList();
                    final hasContent = notesInFolder.isNotEmpty || subfolders.isNotEmpty;

                    if (hasContent) {
                      // Conferma esplicita per cartella con note o sottocartelle
                      final choice = await showDialog<String>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: const Color(0xFF141417),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
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
                          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, 'cancel'),
                              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(c, 'move'),
                              child: const Text('Sposta note in "Personali"', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(c, 'delete_all'),
                              child: const Text('Elimina tutto ricorsivamente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                            ),
                          ],
                        ),
                      );

                      if (choice == 'delete_all') {
                        await _folderService.deleteFolderRecursive(folder.effectivePath, _allNotes, deleteNotes: true);
                        await _loadCustomFolders();
                        await _subscribeToNotes();
                        if (mounted) {
                          setState(() => _selectedFolder = NoteFolder.all);
                        }
                      } else if (choice == 'move') {
                        await _folderService.deleteFolderRecursive(folder.effectivePath, _allNotes, deleteNotes: false);
                        await _loadCustomFolders();
                        await _subscribeToNotes();
                        if (mounted) {
                          setState(() => _selectedFolder = NoteFolder.all);
                        }
                      }
                    } else {
                      // Cartella vuota
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: const Color(0xFF141417),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white10),
                          ),
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
                        await _folderService.deleteFolderRecursive(folder.effectivePath, _allNotes, deleteNotes: false);
                        await _loadCustomFolders();
                        if (mounted) {
                          setState(() => _selectedFolder = NoteFolder.all);
                        }
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

  @override
  Widget build(BuildContext context) {
    final folders = _folderService.buildFolderList(_allNotes, _customFolderNames);

    // Sync selectedFolder instance to get live count
    final activeFolderMatch = folders
        .where((f) => f.effectivePath == _selectedFolder.effectivePath || f.id == _selectedFolder.id)
        .firstOrNull;
    final currentSelectedFolder = activeFolderMatch ?? folders.first;

    final notesInCurrentFolder = _folderService.filterDocsByFolder(
      _allNotes,
      currentSelectedFolder,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Column(
        children: [
          // 2-State Collapsible Header (Compact Focus <-> Expanded Miller Columns)
          NotesCollapsibleHeader(
            folders: folders,
            selectedFolder: currentSelectedFolder,
            notesInSelectedFolder: notesInCurrentFolder,
            activeNoteId: _activeNote?.id,
            editingNoteId: _editingNoteId,
            onFolderSelected: (folder) {
              setState(() {
                _selectedFolder = folder;
                final inFolder = _folderService.filterDocsByFolder(_allNotes, folder);
                if (inFolder.isNotEmpty &&
                    !_allNotes.any((n) =>
                        n.id == _activeNote?.id &&
                        _folderService.getFolderForNote(n) == folder.effectivePath)) {
                  _activeNote = inFolder.first;
                }
              });
            },
            onNoteSelected: (note) {
              HapticFeedback.selectionClick();
              setState(() {
                _activeNote = note;
              });
            },
            onAddFolder: () => _showAddFolderDialog(),
            onAddSubfolder: (parent) => _showAddFolderDialog(parentFolder: parent),
            onAddNote: _createInlineNote,
            onFolderOptions: _showFolderOptionsDialog,
            onNoteOptions: _showNoteOptionsDialog,
            onCommitNoteTitle: _commitNoteTitle,
            onCommitNewFolder: _commitNewFolder,
            isExpanded: _isHeaderExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _isHeaderExpanded = expanded);
            },
          ),

          // Lower Screen: Document preview / Live editor
          Expanded(
            child: _buildBody(notesInCurrentFolder),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<NoteDocument> notesInCurrentFolder) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF59E0B),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_activeNote != null) {
      return NoteDetailView(
        key: ValueKey('note_${_activeNote!.id}'),
        documentId: _activeNote!.id,
        isEmbeddedMode: true,
      );
    }

    // Empty state when there are no notes
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141417),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.note_alt_outlined,
                size: 40,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _allNotes.isEmpty
                  ? 'Nessuna nota presente'
                  : 'Nessuna nota in "${_selectedFolder.name}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _allNotes.isEmpty
                  ? 'Crea la tua prima nota per iniziare a scrivere pensieri, appunti e progetti.'
                  : 'Aggiungi una nuova nota a questa cartella o esplora le altre cartelle in alto.',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _createInlineNote,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Nuova Nota',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
