import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/document_service.dart';

/// Rappresenta una cartella nel sistema note.
class NoteFolder {
  final String id;
  final String name;
  final int notesCount;
  final bool isSpecialAll;
  final bool isDefault;

  const NoteFolder({
    required this.id,
    required this.name,
    this.notesCount = 0,
    this.isSpecialAll = false,
    this.isDefault = false,
  });

  static const NoteFolder all = NoteFolder(
    id: '__all__',
    name: 'Tutte le note',
    isSpecialAll: true,
  );

  static const NoteFolder personal = NoteFolder(
    id: '__default__',
    name: 'Note personali',
    isDefault: true,
  );

  IconData get icon {
    if (isSpecialAll) return Icons.layers_outlined;
    if (isDefault) return Icons.note_outlined;
    return Icons.folder_rounded;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteFolder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Servizio per la gestione e l'aggregazione a cartelle delle Note.
///
/// Memorizza le cartelle personalizzate create dall'utente in SharedPreferences
/// e le sincronizza dinamicamente con il campo metadata['folder'] dei NoteDocument.
class NoteFolderService {
  static const String _customFoldersKey = 'solducci_notes_custom_folders';
  static const String defaultFolderName = 'Note personali';
  final DocumentService _documentService = DocumentService();

  static final NoteFolderService _instance = NoteFolderService._internal();
  factory NoteFolderService() => _instance;
  NoteFolderService._internal();

  /// Carica i nomi delle cartelle create dall'utente
  Future<List<String>> getCustomFolderNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customFoldersKey) ?? [];
  }

  /// Salva una nuova cartella
  Future<void> addCustomFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customFoldersKey) ?? [];
    if (!current.contains(trimmed)) {
      current.add(trimmed);
      await prefs.setStringList(_customFoldersKey, current);
    }
  }

  /// Elimina una cartella personalizzata dalla lista salvata
  Future<void> deleteCustomFolder(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customFoldersKey) ?? [];
    current.remove(name);
    await prefs.setStringList(_customFoldersKey, current);
  }

  /// Restituisce il nome della cartella formattato per la visualizzazione
  String getFolderForNote(NoteDocument doc) => getDocFolder(doc) ?? defaultFolderName;

  /// Alias per buildFolders
  List<NoteFolder> buildFolderList(
    List<NoteDocument> docs,
    List<String> customFolderNames,
  ) => buildFolders(docs, customFolderNames);

  /// Rimuove una cartella e sposta le relative note nella cartella predefinita
  Future<void> deleteFolder(String name, List<NoteDocument> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customFoldersKey) ?? [];
    current.remove(name);
    await prefs.setStringList(_customFoldersKey, current);

    // Sposta le note di questa cartella in 'Note personali' (cartella null)
    for (final doc in docs) {
      if (getDocFolder(doc) == name) {
        await moveNoteToFolder(doc, null);
      }
    }
  }

  /// Rinomina una cartella e aggiorna le relative note
  Future<void> renameFolder(
    String oldName,
    String newName,
    List<NoteDocument> docs,
  ) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || oldName == trimmed) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customFoldersKey) ?? [];
    final index = current.indexOf(oldName);
    if (index != -1) {
      current[index] = trimmed;
      await prefs.setStringList(_customFoldersKey, current);
    } else if (!current.contains(trimmed)) {
      current.add(trimmed);
      await prefs.setStringList(_customFoldersKey, current);
    }

    // Aggiorna le note associate
    for (final doc in docs) {
      if (getDocFolder(doc) == oldName) {
        await moveNoteToFolder(doc, trimmed);
      }
    }
  }

  /// Restituisce il nome della cartella associata al documento
  String? getDocFolder(NoteDocument doc) {
    final folder = doc.metadata['folder'];
    if (folder is String && folder.trim().isNotEmpty) {
      return folder.trim();
    }
    return null;
  }

  /// Sposta una nota in una cartella specificata (null per Note personali)
  Future<void> moveNoteToFolder(NoteDocument doc, String? folderName) async {
    final updatedMetadata = Map<String, dynamic>.from(doc.metadata);
    if (folderName == null || folderName.trim().isEmpty) {
      updatedMetadata.remove('folder');
    } else {
      updatedMetadata['folder'] = folderName.trim();
    }

    final updatedDoc = NoteDocument(
      id: doc.id,
      userId: doc.userId,
      groupId: doc.groupId,
      title: doc.title,
      description: doc.description,
      createdAt: doc.createdAt,
      updatedAt: DateTime.now(),
      metadata: updatedMetadata,
    );

    await _documentService.updateDocument(updatedDoc);
  }

  /// Costruisce l'elenco aggregato delle cartelle disponibili
  List<NoteFolder> buildFolders(
    List<NoteDocument> docs,
    List<String> customFolderNames,
  ) {
    // Raccoglie tutti i nomi univoci di cartelle presenti nei documenti
    final allFolderNames = <String>{...customFolderNames};
    for (final doc in docs) {
      final folder = getDocFolder(doc);
      if (folder != null) {
        allFolderNames.add(folder);
      }
    }

    // Calcola il conteggio per le cartelle predefinite
    final defaultFolderDocs = docs.where((d) => getDocFolder(d) == null).length;

    final folders = <NoteFolder>[
      // 1. Vista globale "Tutte le note"
      NoteFolder(
        id: '__all__',
        name: 'Tutte le note',
        notesCount: docs.length,
        isSpecialAll: true,
      ),
      // 2. Cartella predefinita "Note personali" (senza cartella esplicita)
      NoteFolder(
        id: '__default__',
        name: 'Note personali',
        notesCount: defaultFolderDocs,
        isDefault: true,
      ),
    ];

    // 3. Cartelle dell'utente ordinate alfabeticamente
    final sortedCustomNames = allFolderNames.toList()..sort((a, b) => a.compareTo(b));
    for (final name in sortedCustomNames) {
      final count = docs.where((d) => getDocFolder(d) == name).length;
      folders.add(
        NoteFolder(
          id: name,
          name: name,
          notesCount: count,
        ),
      );
    }

    return folders;
  }

  /// Filtra le note in base alla cartella selezionata (NoteFolder o String)
  List<NoteDocument> filterDocsByFolder(
    List<NoteDocument> docs,
    dynamic folderOrName,
  ) {
    if (folderOrName == null) return docs;
    if (folderOrName is NoteFolder) {
      if (folderOrName.isSpecialAll) return docs;
      if (folderOrName.isDefault) {
        return docs.where((d) => getDocFolder(d) == null).toList();
      }
      return docs.where((d) => getDocFolder(d) == folderOrName.name).toList();
    }
    if (folderOrName is String) {
      if (folderOrName == 'Tutte le note' || folderOrName == '__all__') return docs;
      if (folderOrName == defaultFolderName || folderOrName == '__default__') {
        return docs.where((d) => getDocFolder(d) == null).toList();
      }
      return docs.where((d) => getDocFolder(d) == folderOrName).toList();
    }
    return docs;
  }
}
