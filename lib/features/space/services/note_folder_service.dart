import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/document_service.dart';

/// Rappresenta una cartella nel sistema note con supporto a gerarchie a percorsi (path-based).
class NoteFolder {
  final String id;
  final String fullPath;
  final String name;
  final String? parentPath;
  final int depth;
  final int notesCount;
  final bool isSpecialAll;
  final bool isDefault;

  const NoteFolder({
    required this.id,
    required this.name,
    this.fullPath = '',
    this.parentPath,
    this.depth = 0,
    this.notesCount = 0,
    this.isSpecialAll = false,
    this.isDefault = false,
  });

  String get effectivePath => fullPath.isNotEmpty ? fullPath : (isSpecialAll || isDefault ? id : name);
  bool get isSubfolder => parentPath != null && parentPath!.isNotEmpty;

  static const NoteFolder all = NoteFolder(
    id: '__all__',
    name: 'Tutte le note',
    fullPath: '__all__',
    isSpecialAll: true,
  );

  static const NoteFolder personal = NoteFolder(
    id: '__default__',
    name: 'Note personali',
    fullPath: '__default__',
    isDefault: true,
  );

  IconData get icon {
    if (isSpecialAll) return Icons.layers_outlined;
    if (isDefault) return Icons.note_outlined;
    if (isSubfolder) return Icons.subdirectory_arrow_right_rounded;
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

/// Servizio per la gestione e l'aggregazione a cartelle e sotto-cartelle delle Note.
///
/// Memorizza le cartelle personalizzate in SharedPreferences e le sincronizza
/// con il campo metadata['folder'] (salvato come path Unix, es. "Progetti/Solducci").
class NoteFolderService {
  static const String _customFoldersKey = 'solducci_notes_custom_folders';
  static const String defaultFolderName = 'Note personali';
  final DocumentService _documentService = DocumentService();

  static final NoteFolderService _instance = NoteFolderService._internal();
  factory NoteFolderService() => _instance;
  NoteFolderService._internal();

  /// Carica i percorsi delle cartelle create dall'utente
  Future<List<String>> getCustomFolderNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customFoldersKey) ?? [];
  }

  /// Salva una nuova cartella o sotto-cartella
  Future<String> addCustomFolder(String name, {String? parentPath}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return '';

    String fullPath = trimmedName;
    if (parentPath != null &&
        parentPath.trim().isNotEmpty &&
        parentPath != '__all__' &&
        parentPath != '__default__' &&
        parentPath != defaultFolderName) {
      fullPath = '${parentPath.trim()}/$trimmedName';
    }

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customFoldersKey) ?? [];
    if (!current.contains(fullPath)) {
      current.add(fullPath);
      await prefs.setStringList(_customFoldersKey, current);
    }
    return fullPath;
  }

  /// Elimina una cartella personalizzata e tutte le relative sotto-cartelle
  Future<void> deleteCustomFolder(String fullPath) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customFoldersKey) ?? [];
    current.removeWhere((p) => p == fullPath || p.startsWith('$fullPath/'));
    await prefs.setStringList(_customFoldersKey, current);
  }

  /// Rinomina una cartella (e aggiorna ricorsivamente sotto-cartelle e note associate)
  Future<String> renameFolder(String oldPath, String newName, List<NoteDocument> allNotes) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return oldPath;

    // Se oldPath è es. "Progetti/Solducci", il nuovo path sarà "Progetti/$trimmedName"
    final segments = oldPath.split('/');
    segments[segments.length - 1] = trimmedName;
    final newPath = segments.join('/');

    if (oldPath == newPath) return oldPath;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customFoldersKey) ?? [];

    // Aggiorna cartella e sotto-cartelle in SharedPreferences
    final updatedFolders = current.map((p) {
      if (p == oldPath) return newPath;
      if (p.startsWith('$oldPath/')) {
        return '$newPath/${p.substring(oldPath.length + 1)}';
      }
      return p;
    }).toList();

    if (!updatedFolders.contains(newPath)) {
      updatedFolders.add(newPath);
    }
    await prefs.setStringList(_customFoldersKey, updatedFolders);

    // Aggiorna le note all'interno della cartella e delle relative sottocartelle
    for (final doc in allNotes) {
      final docFolder = getDocFolder(doc);
      if (docFolder == null) continue;

      if (docFolder == oldPath) {
        await moveNoteToFolder(doc, newPath);
      } else if (docFolder.startsWith('$oldPath/')) {
        final updatedSubPath = '$newPath/${docFolder.substring(oldPath.length + 1)}';
        await moveNoteToFolder(doc, updatedSubPath);
      }
    }

    return newPath;
  }

  /// Elimina una cartella personalizzata, con opzione di eliminazione ricorsiva del contenuto
  /// o di spostamento delle note nella cartella predefinita.
  Future<void> deleteFolderRecursive(
    String fullPath,
    List<NoteDocument> allNotes, {
    required bool deleteNotes,
  }) async {
    // 1. Rimuovi la cartella e tutte le sue sottocartelle da SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customFoldersKey) ?? [];
    current.removeWhere((p) => p == fullPath || p.startsWith('$fullPath/'));
    await prefs.setStringList(_customFoldersKey, current);

    // 2. Gestisci le note appartenenti a questa cartella o a sue sottocartelle
    final matchingNotes = allNotes.where((d) {
      final folder = getDocFolder(d);
      if (folder == null) return false;
      return folder == fullPath || folder.startsWith('$fullPath/');
    }).toList();

    for (final note in matchingNotes) {
      if (deleteNotes) {
        await _documentService.deleteDocument(note.id);
      } else {
        await moveNoteToFolder(note, null); // Sposta in Note personali
      }
    }
  }

  /// Restituisce il nome della cartella formattato per la visualizzazione
  String getFolderForNote(NoteDocument doc) => getDocFolder(doc) ?? defaultFolderName;

  /// Restituisce il path della cartella associata al documento
  String? getDocFolder(NoteDocument doc) {
    final folder = doc.metadata['folder'];
    if (folder is String && folder.trim().isNotEmpty) {
      return folder.trim();
    }
    return null;
  }

  /// Sposta una nota in una cartella specificata (null per Note personali)
  Future<void> moveNoteToFolder(NoteDocument doc, String? folderPath) async {
    final updatedMetadata = Map<String, dynamic>.from(doc.metadata);
    if (folderPath == null ||
        folderPath.trim().isEmpty ||
        folderPath == '__default__' ||
        folderPath == defaultFolderName ||
        folderPath == '__all__') {
      updatedMetadata.remove('folder');
    } else {
      updatedMetadata['folder'] = folderPath.trim();
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

  /// Alias per buildFolders
  List<NoteFolder> buildFolderList(
    List<NoteDocument> docs,
    List<String> customFolderPaths,
  ) => buildFolders(docs, customFolderPaths);

  /// Costruisce l'elenco aggregato delle cartelle disponibili con ordinamento ad albero
  List<NoteFolder> buildFolders(
    List<NoteDocument> docs,
    List<String> customFolderPaths,
  ) {
    final allFolderPaths = <String>{...customFolderPaths};
    for (final doc in docs) {
      final folder = getDocFolder(doc);
      if (folder != null) {
        allFolderPaths.add(folder);
      }
    }

    // Assicura che per ogni path 'A/B/C' esistano anche i parent 'A' e 'A/B'
    final expandedPaths = <String>{};
    for (final path in allFolderPaths) {
      final segments = path.split('/');
      var current = '';
      for (final segment in segments) {
        current = current.isEmpty ? segment : '$current/$segment';
        expandedPaths.add(current);
      }
    }

    // Calcola il conteggio per le cartelle predefinite
    final defaultFolderDocs = docs.where((d) => getDocFolder(d) == null).length;

    final folders = <NoteFolder>[
      // 1. Vista globale "Tutte le note"
      NoteFolder(
        id: '__all__',
        name: 'Tutte le note',
        fullPath: '__all__',
        notesCount: docs.length,
        isSpecialAll: true,
      ),
      // 2. Cartella predefinita "Note personali" (senza cartella esplicita)
      NoteFolder(
        id: '__default__',
        name: 'Note personali',
        fullPath: '__default__',
        notesCount: defaultFolderDocs,
        isDefault: true,
      ),
    ];

    // Costruzione albero gerarchico (DFS)
    final sortedPaths = expandedPaths.toList()..sort();
    final treeFolders = _buildTreeOrder(sortedPaths, docs);
    folders.addAll(treeFolders);

    return folders;
  }

  List<NoteFolder> _buildTreeOrder(List<String> paths, List<NoteDocument> docs) {
    final result = <NoteFolder>[];

    // Separa in root (depth 0) e subfolders
    final rootPaths = paths.where((p) => !p.contains('/')).toList()..sort();

    void addPathAndChildren(String path) {
      final segments = path.split('/');
      final name = segments.last;
      final depth = segments.length - 1;
      final parentPath = depth > 0 ? segments.sublist(0, depth).join('/') : null;
      final count = docs.where((d) => getDocFolder(d) == path).length;

      result.add(
        NoteFolder(
          id: path,
          fullPath: path,
          name: name,
          parentPath: parentPath,
          depth: depth,
          notesCount: count,
        ),
      );

      // Trova figli diretti di questo path
      final prefix = '$path/';
      final children = paths.where((p) {
        if (!p.startsWith(prefix)) return false;
        final remainder = p.substring(prefix.length);
        return !remainder.contains('/');
      }).toList()..sort();

      for (final child in children) {
        addPathAndChildren(child);
      }
    }

    for (final root in rootPaths) {
      addPathAndChildren(root);
    }

    return result;
  }

  /// Restituisce le sotto-cartelle dirette di una determinata cartella
  List<NoteFolder> getDirectSubfolders(
    NoteFolder parent,
    List<NoteFolder> allFolders,
  ) {
    if (parent.isSpecialAll || parent.isDefault) return [];
    return allFolders.where((f) => f.parentPath == parent.effectivePath).toList();
  }

  /// Filtra le note in base alla cartella selezionata (NoteFolder o String)
  List<NoteDocument> filterDocsByFolder(
    List<NoteDocument> docs,
    dynamic folderOrPath,
  ) {
    if (folderOrPath == null) return docs;
    if (folderOrPath is NoteFolder) {
      if (folderOrPath.isSpecialAll) return docs;
      if (folderOrPath.isDefault) {
        return docs.where((d) => getDocFolder(d) == null).toList();
      }
      return docs.where((d) => getDocFolder(d) == folderOrPath.effectivePath).toList();
    }
    if (folderOrPath is String) {
      if (folderOrPath == 'Tutte le note' || folderOrPath == '__all__') return docs;
      if (folderOrPath == defaultFolderName || folderOrPath == '__default__') {
        return docs.where((d) => getDocFolder(d) == null).toList();
      }
      return docs.where((d) => getDocFolder(d) == folderOrPath).toList();
    }
    return docs;
  }
}
