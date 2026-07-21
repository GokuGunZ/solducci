import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/core/widgets/donut_progress_indicator.dart';
import 'package:solducci/models/space_items.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solducci/features/space/views/vectorial_notes_view.dart';

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
  bool _isVectorial = false;

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

  Color _getColorForType(String type) {
    switch (type) {
      case 'note': return const Color(0xFFF59E0B);
      case 'asterisk': return const Color(0xFFEAB308);
      case 'resource_list': return const Color(0xFF8B5CF6);
      case 'dispensa': return const Color(0xFF10B981);
      case 'shopping_list': return const Color(0xFF10B981);
      case 'todo': return const Color(0xFF3B82F6);
      default: return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'note': return Icons.notes;
      case 'asterisk': return Icons.star_outline;
      case 'resource_list': return Icons.link;
      case 'dispensa': return Icons.kitchen;
      case 'shopping_list': return Icons.shopping_cart_outlined;
      case 'todo': return Icons.check_circle_outline;
      default: return Icons.folder_open;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentContext = _contextManager.currentContext;
    final color = _getColorForType(widget.type);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: 'hero_space_${widget.type}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(widget.sectionLabel, style: const TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold)),
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    if (widget.type == 'note')
                      IconButton(
                        icon: Icon(_isVectorial ? Icons.view_list : Icons.view_in_ar, color: color),
                        tooltip: _isVectorial ? 'Vista Lista' : 'Vista Vettoriale 3D',
                        onPressed: () {
                          setState(() {
                            _isVectorial = !_isVectorial;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showCreateDialog(context),
                    ),
                  ],
                ),
                Expanded(
                  child: StreamBuilder<List<Document>>(
                    stream: _documentService.watchDocumentsForContext(
                      currentContext,
                      widget.type,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Errore: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }

                      final documents = snapshot.data ?? [];

                      if (documents.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    )
                                  ]
                                ),
                                child: Icon(_getIconForType(widget.type), size: 80, color: color),
                              )
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 2.seconds)
                              .fade(begin: 0.7, end: 1.0),
                              
                              const SizedBox(height: 32),
                              Text(
                                'Spazio vuoto',
                                style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contesto: ${_contextManager.contextDisplayName}',
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                                onPressed: () => _showCreateDialog(context),
                                child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (_isVectorial) {
                        return VectorialNotesView(
                          documents: documents,
                          themeColor: color,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final doc = documents[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withOpacity(0.3), width: 1),
                            ),
                            child: ListTile(
                              title: Text(doc.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('Aggiornato il ${_formatDate(doc.updatedAt)}', style: const TextStyle(color: Colors.white54)),
                              trailing: widget.type == 'shopping_list' 
                                ? _ShoppingListProgress(documentId: doc.id)
                                : Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
                              onTap: () => _navigateToDocument(context, doc),
                              onLongPress: () => _showDeleteConfirm(context, doc),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
