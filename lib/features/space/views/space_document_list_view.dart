import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/core/widgets/donut_progress_indicator.dart';
import 'package:solducci/models/space_items.dart';

class SpaceDocumentListView extends StatefulWidget {
  final String type;
  final String sectionLabel;

  const SpaceDocumentListView({
    super.key,
    required this.type,
    required this.sectionLabel,
  });

  @override
  State<SpaceDocumentListView> createState() => _SpaceDocumentListViewState();
}

class _SpaceDocumentListViewState extends State<SpaceDocumentListView> {
  final _documentService = DocumentService();
  final _contextManager = ContextManager();

  @override
  void initState() {
    super.initState();
    _contextManager.addListener(_onContextChanged);
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentContext = _contextManager.currentContext;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Document>>(
        stream: _documentService.watchDocumentsForContext(
          currentContext,
          widget.type,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          final documents = snapshot.data ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna lista ${widget.sectionLabel.toLowerCase()} trovata',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contesto: ${_contextManager.contextDisplayName}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showCreateDialog(context),
                    child: const Text('Crea la prima'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                child: ListTile(
                  title: Text(doc.title),
                  subtitle: Text('Aggiornato il ${_formatDate(doc.updatedAt)}'),
                  trailing: widget.type == 'shopping_list' 
                    ? _ShoppingListProgress(documentId: doc.id)
                    : const Icon(Icons.chevron_right),
                  onTap: () => _navigateToDocument(context, doc),
                  onLongPress: () => _showDeleteConfirm(context, doc),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDocument(BuildContext context, Document doc) {
    final path = '/space/${_getSectionPath()}/${doc.id}';
    context.push(path);
  }

  String _getSectionPath() {
    switch (widget.type) {
      case 'todo':
        return 'tasks';
      case 'note':
        return 'notes';
      case 'asterisk':
        return 'asterisks';
      case 'resource_list':
        return 'resources';
      case 'dispensa':
        return 'pantry';
      case 'shopping_list':
        return 'shopping';
      default:
        return 'unknown';
    }
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    if (widget.type == 'shopping_list') {
      _createDocument('Spesa');
      return;
    }

    final titleController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nuova lista ${widget.sectionLabel}'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Titolo',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context);
              _createDocument(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;

              final title = titleController.text.trim();
              Navigator.pop(context);

              _createDocument(title);
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDocument(String title) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final context = _contextManager.currentContext;
    
    if (context.isView) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seleziona un gruppo o il contesto Personale per creare una nuova lista',
            ),
          ),
        );
      }
      return;
    }

    final effectiveUserId = context.isPersonal ? userId : null;
    final groupId = context.groupId;

    Document newDoc;
    switch (widget.type) {
      case 'todo':
        // If it's for a group, we need to override the userId/groupId manually 
        if (context.isGroup) {
          await _documentService.createDocument(TodoDocument(
            id: '',
            userId: null,
            groupId: groupId,
            title: title,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
          return;
        } else {
          newDoc = TodoDocument.create(
            userId: userId,
            title: title,
          );
        }
        break;
      case 'note':
        newDoc = NoteDocument.create(
          userId: effectiveUserId,
          groupId: groupId,
          title: title,
        );
        break;
      case 'asterisk':
        newDoc = AsteriskDocument.create(
          userId: effectiveUserId,
          groupId: groupId,
          title: title,
        );
        break;
      case 'resource_list':
        newDoc = ResourceListDocument.create(
          userId: effectiveUserId,
          groupId: groupId,
          title: title,
        );
        break;
      case 'dispensa':
        newDoc = DispensaDocument.create(
          userId: effectiveUserId,
          groupId: groupId,
          title: title,
        );
        break;
      case 'shopping_list':
        newDoc = ShoppingListDocument.create(
          userId: effectiveUserId,
          groupId: groupId,
          title: title,
        );
        break;
      default:
        return;
    }

    try {
      final createdDoc = await _documentService.createDocument(newDoc);
      if (mounted && widget.type == 'shopping_list') {
        _navigateToDocument(this.context, createdDoc);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Errore durante la creazione: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirm(BuildContext context, Document doc) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina lista'),
        content: Text('Sei sicuro di voler eliminare "${doc.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _documentService.deleteDocument(doc.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

class _ShoppingListProgress extends StatelessWidget {
  final String documentId;

  const _ShoppingListProgress({required this.documentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShoppingListItem>>(
      stream: SpaceService().watchShoppingListItems(documentId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final total = items.length;
        final completed = items.where((i) => i.isBought).length;

        return DonutProgressIndicator(
          total: total,
          completed: completed,
          size: 40,
        );
      },
    );
  }
}
