import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/services/note_folder_service.dart';

/// Esploratore a 2 colonne in stile MacOS Finder (Miller Columns) per le Note.
///
/// - Colonna Sinistra: Elenco Cartelle (Tutte le note, Note personali, cartelle custom).
/// - Colonna Destra: Note contenute nella cartella selezionata con preview e azioni rapide.
class NotesMillerColumnsExplorer extends StatelessWidget {
  final List<NoteFolder> folders;
  final NoteFolder selectedFolder;
  final List<NoteDocument> notesInSelectedFolder;
  final String? activeNoteId;
  final Color accentColor;
  final ValueChanged<NoteFolder> onFolderSelected;
  final ValueChanged<NoteDocument> onNoteSelected;
  final VoidCallback onAddFolder;
  final VoidCallback onAddNote;
  final void Function(NoteFolder folder)? onFolderOptions;
  final void Function(NoteDocument doc)? onNoteOptions;

  const NotesMillerColumnsExplorer({
    super.key,
    required this.folders,
    required this.selectedFolder,
    required this.notesInSelectedFolder,
    required this.activeNoteId,
    this.accentColor = const Color(0xFFF59E0B),
    required this.onFolderSelected,
    required this.onNoteSelected,
    required this.onAddFolder,
    required this.onAddNote,
    this.onFolderOptions,
    this.onNoteOptions,
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

          // ========== COLONNA DESTRA: NOTE ==========
          Expanded(
            child: _buildNotesColumn(context),
          ),
        ],
      ),
    );
  }

  /// Costruisce la colonna sinistra (elenco cartelle)
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

        // Lista cartelle
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final isSelected = folder.id == selectedFolder.id;

              IconData icon;
              if (folder.isSpecialAll) {
                icon = Icons.all_inbox_rounded;
              } else if (folder.isDefault) {
                icon = Icons.note_outlined;
              } else {
                icon = isSelected ? Icons.folder_open_rounded : Icons.folder_rounded;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: InkWell(
                  onTap: () => onFolderSelected(folder),
                  onLongPress: folder.isSpecialAll || folder.isDefault
                      ? null
                      : () => onFolderOptions?.call(folder),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
                          icon,
                          size: 16,
                          color: isSelected ? accentColor : Colors.white54,
                        ),
                        const SizedBox(width: 8),
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
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withOpacity(0.3)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${folder.notesCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.white54,
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

  /// Costruisce la colonna destra (note della cartella selezionata)
  Widget _buildNotesColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intestazione colonna destra
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              InkWell(
                onTap: onAddNote,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

        // Lista delle note
        Expanded(
          child: notesInSelectedFolder.isEmpty
              ? _buildEmptyNotesState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  itemCount: notesInSelectedFolder.length,
                  itemBuilder: (context, index) {
                    final note = notesInSelectedFolder[index];
                    final isCurrentActive = note.id == activeNoteId;
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
                              color: isCurrentActive
                                  ? accentColor.withOpacity(0.6)
                                  : Colors.white10,
                              width: 1.0,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title.trim().isEmpty ? 'Nuova nota' : note.title,
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
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
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
      ),
    );
  }
}
