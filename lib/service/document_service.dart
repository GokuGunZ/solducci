import 'package:solducci/models/document.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing documents (TodoDocument, ShoppingList, etc.)
/// Follows singleton pattern for consistent state management
class DocumentService {
  // Singleton pattern
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  final _supabase = Supabase.instance.client;

  /// Get real-time stream of all user's documents
  Stream<List<Document>> get stream {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .map((data) => _parseDocuments(data));
  }

  /// Get real-time stream of documents filtered by type
  Stream<List<Document>> getDocumentsByType(String documentType) {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .map((data) {
          // Filter by document type after receiving data
          final filtered = data
              .where((doc) => doc['document_type'] == documentType)
              .toList();
          return _parseDocuments(filtered);
        });
  }

  /// Get real-time stream of TodoDocuments only
  Stream<List<TodoDocument>> getTodoDocumentsStream() {
    return getDocumentsByType('todo').map((docs) => docs.cast<TodoDocument>());
  }

  /// Get a single document by ID
  Future<Document?> getDocumentById(String documentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('documents')
          .select()
          .eq('id', documentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return Document.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Create a new document
  Future<Document> createDocument(Document document) async {
    try {
      // Ensure user_id is set
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a document with the current user ID
      Document documentToInsert = document;
      if (documentToInsert.userId != userId) {
        // Recreate document with correct userId
        if (documentToInsert is TodoDocument) {
          documentToInsert = TodoDocument(
            id: '',
            userId: userId,
            title: documentToInsert.title,
            description: documentToInsert.description,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            metadata: documentToInsert.metadata,
          );
        }
      }

      final dataToInsert = documentToInsert.toInsertMap();
      dataToInsert['user_id'] = userId; // Force user_id

      final response = await _supabase
          .from('documents')
          .insert(dataToInsert)
          .select()
          .single();

      return Document.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing document
  Future<void> updateDocument(Document document) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership
      if (document.userId != userId) {
        throw Exception('Cannot update document owned by another user');
      }

      final dataToUpdate = document.toUpdateMap();

      await _supabase
          .from('documents')
          .update(dataToUpdate)
          .eq('id', document.id)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a document (cascades to tasks via DB constraints)
  Future<void> deleteDocument(String documentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('documents')
          .delete()
          .eq('id', documentId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Duplicate a document (creates a copy with new ID)
  Future<Document> duplicateDocument(String documentId) async {
    try {
      final original = await getDocumentById(documentId);
      if (original == null) {
        throw Exception('Document not found');
      }

      // Create a copy with new ID and updated title
      if (original is TodoDocument) {
        final copy = TodoDocument(
          id: '',
          userId: original.userId,
          groupId: original.groupId,
          title: '${original.title} (Copy)',
          description: original.description,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          metadata: Map.from(original.metadata),
        );

        return await createDocument(copy);
      }

      throw UnimplementedError(
        'Duplication not implemented for ${original.runtimeType}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Search documents by title
  Future<List<Document>> searchDocuments(String query) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('documents')
          .select()
          .eq('user_id', userId)
          .ilike('title', '%$query%')
          .order('updated_at', ascending: false);

      return _parseDocuments(response);
    } catch (e) {
      return [];
    }
  }

  /// Get document count by type
  Future<Map<String, int>> getDocumentCountByType() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('documents')
          .select('document_type')
          .eq('user_id', userId);

      final counts = <String, int>{};
      for (final row in response) {
        final type = row['document_type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  /// Parse list of document maps to Document objects
  List<Document> _parseDocuments(List<Map<String, dynamic>> data) {
    final documents = <Document>[];
    for (final map in data) {
      try {
        documents.add(Document.fromMap(map));
      } catch (e) {
        // Skip documents that fail to parse (logged to debug console)
        // In production, consider using a proper logging framework
      }
    }
    return documents;
  }
}
