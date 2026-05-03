import 'package:solducci/models/document.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/service/context_manager.dart';
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

  /// Get real-time stream of documents for a specific context and type
  Stream<List<Document>> watchDocumentsForContext(
    ExpenseContext context,
    String documentType,
  ) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    // We use a stream of the whole documents table and filter client-side
    // for complex contexts (Views) or specific contexts.
    // Optimization: we could use different stream filters for Personal vs Group.
    
    var stream = _supabase.from('documents').stream(primaryKey: ['id']);

    return stream.map((data) {
      final documents = _parseDocuments(data);
      return documents.where((doc) {
        // Filter by type
        if (doc.documentType != documentType) return false;

        // Filter by context
        if (context.isPersonal) {
          return doc.userId == userId && doc.groupId == null;
        } else if (context.isGroup) {
          return doc.groupId == context.groupId;
        } else if (context.isView) {
          final inGroups = context.groupIds.contains(doc.groupId);
          final isPersonalInView = context.includesPersonal && 
                                  doc.userId == userId && 
                                  doc.groupId == null;
          return inGroups || isPersonalInView;
        }
        return false;
      }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  /// Get documents for a specific context and type (Future)
  Future<List<Document>> getDocumentsForContext(
    ExpenseContext context,
    String documentType,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _supabase
        .from('documents')
        .select()
        .eq('document_type', documentType);

    if (context.isPersonal) {
      query = query.eq('user_id', userId).isFilter('group_id', null);
    } else if (context.isGroup) {
      query = query.eq('group_id', context.groupId!);
    } else if (context.isView) {
      // For views, we use 'in' filter for groups
      // Note: if includesPersonal is true, we need a complex OR which Supabase
      // syntax makes tricky. Simplest is to fetch and filter if includesPersonal is true,
      // or use two queries.
      if (context.includesPersonal) {
        // Fetch everything for these groups OR my personal ones
        // Using PostgREST syntax for OR: (group_id.in.(...),and(user_id.eq.my_id,group_id.is.null))
        final groupList = context.groupIds.map((id) => id).join(',');
        query = query.or('group_id.in.($groupList),and(user_id.eq.$userId,group_id.is.null)');
      } else {
        query = query.inFilter('group_id', context.groupIds);
      }
    }

    final response = await query.order('updated_at', ascending: false);
    return _parseDocuments(response);
  }

  /// Get real-time stream of documents filtered by type (Legacy - personal only)
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

      // Note: we don't filter by user_id here to allow members of a group to see shared docs
      final response = await _supabase
          .from('documents')
          .select()
          .eq('id', documentId)
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
      final userId = AuthService().currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final dataToInsert = document.toInsertMap();
      
      // Ensure user_id is set to creator only if it's a personal document
      // and not explicitly provided. If it's a group document (groupId != null),
      // user_id MUST be null to satisfy the database constraint.
      if (dataToInsert['group_id'] == null) {
        dataToInsert['user_id'] ??= userId;
      } else {
        dataToInsert['user_id'] = null;
      }

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

      final dataToUpdate = document.toUpdateMap();

      // Owners or group members can update (RLS handles this)
      await _supabase
          .from('documents')
          .update(dataToUpdate)
          .eq('id', document.id);
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

      // RLS will ensure the user has permission to delete
      await _supabase
          .from('documents')
          .delete()
          .eq('id', documentId);
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

      // We don't filter by user_id here to allow searching group docs
      // RLS will handle visibility.
      final response = await _supabase
          .from('documents')
          .select()
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

      // We don't filter by user_id here to include group docs
      // RLS will handle visibility.
      final response = await _supabase
          .from('documents')
          .select('document_type');

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
