import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/services/note_folder_service.dart';

/// Esploratore a 2 colonne in stile MacOS Finder (Miller Columns) per le Note.
///
/// - Colonna Sinistra: Elenco Cartelle e Sotto-cartelle con indentazione gerarchica.
/// - Colonna Destra: Sotto-cartelle dirette + Note della cartella selezionata con creazione inline.
class NotesMillerColumnsExplorer extends StatelessWidget {
  final List<NoteFolder> folders;
  final NoteFolder selectedFolder;
  final List<NoteDocument> notesInSelectedFolder;
  final String? activeNoteId;
  final String? editingNoteId;
  final Color accentColor;
  final ValueChanged<NoteFolder> onFolderSelected;
  final ValueChanged<NoteDocument> onNoteSelected;
  final VoidCallback onAddFolder;
  final VoidCallback onAddNote;
  final void Function(NoteFolder currentFolder)? onAddSubfolder;
  final void Function(NoteFolder folder)? onFolderOptions;
  final void Function(NoteDocument doc)? onNoteOptions;
  final void Function(NoteDocument note, String newTitle)? onCommitNoteTitle;

  const NotesMillerColumnsExplorer({
    super.key,
    required this.folders,
    required this.selectedFolder,
    required this.notesInSelectedFolder,
    required this.activeNoteId,
    this.editingNoteId,
    this.accentColor = const Color(0xFFF59E0B),
    required this.onFolderSelected,
    required this.onNoteSelected,
    required this.onAddFolder,
    required this.onAddNote,
    this.onAddSubfolder,
    this.onFolderOptions,
    this.onNoteOptions,
    this.onCommitNoteTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141417),
        border: Border(
          bottom: BorderSide(color: Colors.white10, width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========== COLONNA SINISTRA: CARTELLE ==========
          SizedBox(
            width: 155,
            child: _buildFoldersColumn(context),
          ),

          // Divisore verticale
          const VerticalDivider(
            color: Colors.white10,
            width: 1.0,
            thickness: 1.0,
          ),

          // ========== COLONNA DESTRA: SOTTOCARTELLE + NOTE ==========
          Expanded(
            child: _buildNotesColumn(context),
          ),
        ],
      ),
    );
  }

  /// Costruisce la colonna sinistra (elenco gerarchico cartelle)
  Widget _buildFoldersColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intestazione colonna sinistra
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CARTELLE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white38,
                ),
              ),
              InkWell(
                onTap: onAddFolder,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.create_new_folder_outlined,
                    size: 15,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista ad albero delle cartelle
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final isSelected = folder.id == selectedFolder.id ||
                  folder.effectivePath == selectedFolder.effectivePath;

              final indent = (folder.depth * 10.0).clamp(0.0, 30.0);

              return Padding(
                padding: EdgeInsets.only(left: indent, bottom: 2),
                child: InkWell(
                  onTap: () => onFolderSelected(folder),
                  onLongPress: folder.isSpecialAll || folder.isDefault
                      ? null
                      : () => onFolderOptions?.call(folder),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: accentColor.withOpacity(0.4),
                              width: 1.0,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          folder.icon,
                          size: folder.isSubfolder ? 14 : 15,
                          color: isSelected ? accentColor : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            folder.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Badge conteggio
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withOpacity(0.3)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${folder.notesCount}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Costruisce la colonna destra (sotto-cartelle dirette + note con creazione inline)
  Widget _buildNotesColumn(BuildContext context) {
    // Trova eventuali sotto-cartelle dirette di questa cartella
    final directSubfolders = NoteFolderService().getDirectSubfolders(selectedFolder, folders);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intestazione colonna destra con pulsanti di azione
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 6),
          child: Row(
            children: [
              // Se siamo in una sotto-cartella, mostra il pulsante indietro al genitore
              if (selectedFolder.isSubfolder) ...[
                InkWell(
                  onTap: () {
                    final parentPath = selectedFolder.parentPath;
                    final parentMatch = folders
                        .where((f) => f.effectivePath == parentPath)
                        .firstOrNull;
                    if (parentMatch != null) {
                      onFolderSelected(parentMatch);
                    } else {
                      onFolderSelected(NoteFolder.all);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4.0),
                    child: Icon(Icons.arrow_back_ios_new, size: 12, color: Colors.white54),
                  ),
                ),
              ],

              // Titolo cartella
              Expanded(
                child: Text(
                  selectedFolder.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.white38,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 4),

              // Pulsante (+ Cartella) per creare cartella dentro la cartella corrente
              InkWell(
                onTap: () {
                  if (onAddSubfolder != null) {
                    onAddSubfolder!(selectedFolder);
                  } else {
                    onAddFolder();
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12, width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.create_new_folder_outlined, size: 12, color: Colors.white70),
                      SizedBox(width: 3),
                      Text(
                        'Cartella',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Pulsante (+ Nuova) per creare subito una nota inline
              InkWell(
                onTap: onAddNote,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withOpacity(0.4), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 12, color: accentColor),
                      const SizedBox(width: 3),
                      Text(
                        'Nuova',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Corpo centrale: Sottocartelle (se presenti) + Note
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            children: [
              // Sezione Sotto-cartelle (stile Miller Column MacOS)
              if (directSubfolders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4, top: 2),
                  child: Text(
                    'SOTTOCARTELLE (${directSubfolders.length})',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                      color: Colors.white30,
                    ),
                  ),
                ),
                ...directSubfolders.map((subfolder) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => onFolderSelected(subfolder),
                      onLongPress: () => onFolderOptions?.call(subfolder),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF19191E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10, width: 1.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.folder_rounded, size: 16, color: accentColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subfolder.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${subfolder.notesCount}',
                                style: const TextStyle(fontSize: 9, color: Colors.white60),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 16, color: Colors.white38),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 6),
              ],

              // Sezione Note
              if (notesInSelectedFolder.isEmpty && directSubfolders.isEmpty)
                _buildEmptyNotesState()
              else ...[
                if (directSubfolders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'NOTE (${notesInSelectedFolder.length})',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ...notesInSelectedFolder.map((note) {
                  final isCurrentActive = note.id == activeNoteId;
                  final isInlineEditing = note.id == editingNoteId;
                  final formattedDate = DateFormat('dd/MM HH:mm').format(note.updatedAt);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => onNoteSelected(note),
                      onLongPress: () => onNoteOptions?.call(note),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrentActive
                              ? const Color(0xFF1E1E24)
                              : const Color(0xFF18181D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isInlineEditing
                                ? accentColor
                                : (isCurrentActive
                                    ? accentColor.withOpacity(0.6)
                                    : Colors.white10),
                            width: isInlineEditing ? 1.5 : 1.0,
                          ),
                          boxShadow: isCurrentActive
                              ? [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 18,
                              color: isCurrentActive ? accentColor : Colors.white60,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: isInlineEditing
                                  ? _InlineNoteTitleEditor(
                                      initialTitle: note.title,
                                      accentColor: accentColor,
                                      onCommit: (newTitle) {
                                        onCommitNoteTitle?.call(note, newTitle);
                                      },
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note.title.trim().isEmpty ? 'Senza titolo' : note.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isCurrentActive
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isCurrentActive ? Colors.white : Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            if (!isInlineEditing)
                              IconButton(
                                icon: const Icon(Icons.more_vert, size: 16, color: Colors.white38),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Opzioni',
                                onPressed: () => onNoteOptions?.call(note),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotesState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.note_alt_outlined,
            size: 28,
            color: Colors.white24,
          ),
          const SizedBox(height: 6),
          const Text(
            'Nessuna nota qui',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAddNote,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Crea la prima nota',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per l'editing inline del titolo di una nota con autofocus e selezione completa immediata
class _InlineNoteTitleEditor extends StatefulWidget {
  final String initialTitle;
  final Color accentColor;
  final ValueChanged<String> onCommit;

  const _InlineNoteTitleEditor({
    required this.initialTitle,
    required this.accentColor,
    required this.onCommit,
  });

  @override
  State<_InlineNoteTitleEditor> createState() => _InlineNoteTitleEditorState();
}

class _InlineNoteTitleEditorState extends State<_InlineNoteTitleEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    final text = widget.initialTitle.isEmpty ? 'Nuova nota' : widget.initialTitle;
    _controller = TextEditingController(text: text);
    _focusNode = FocusNode();

    // Seleziona tutto il testo automaticamente così digitando si sovrascrive subito
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );

    // Chiedi il focus al rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_committed) {
        _commit();
      }
    });
  }

  void _commit() {
    if (_committed) return;
    _committed = true;
    final val = _controller.text.trim();
    widget.onCommit(val.isEmpty ? 'Nuova nota' : val);
  }

  @override
  void dispose() {
    if (!_committed) {
      _commit();
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      cursorColor: widget.accentColor,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        hintText: 'Titolo nota...',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: widget.accentColor, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: widget.accentColor, width: 1.5),
        ),
      ),
      onSubmitted: (_) => _commit(),
      onTapOutside: (_) => _commit(),
    );
  }
}
