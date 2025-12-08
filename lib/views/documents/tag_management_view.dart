import 'package:flutter/material.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/widgets/documents/tag_form_dialog.dart';
import 'package:solducci/widgets/common/todo_app_bar.dart';
import 'package:solducci/theme/todo_theme.dart';

/// View for managing tags (CRUD operations)
class TagManagementView extends StatefulWidget {
  const TagManagementView({super.key});

  @override
  State<TagManagementView> createState() => _TagManagementViewState();
}

class _TagManagementViewState extends State<TagManagementView> {
  final _tagService = TagService();
  List<Tag> _tags = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tags = await _tagService.getRootTags();

      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Tag'),
        content: Text(
          'Sei sicuro di voler eliminare il tag "${tag.name}"?\n\nQuesto rimuoverà il tag da tutte le task associate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _tagService.deleteTag(tag.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "${tag.name}" eliminato')),
        );
        _loadTags(); // Reload tags
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TodoAppBar(
        title: 'Gestione Tag',
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagFormDialog(null),
        backgroundColor: TodoTheme.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Errore: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTags,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessun tag',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea il tuo primo tag per organizzare le task',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Tag list
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _tags.length,
      itemBuilder: (context, index) {
        final tag = _tags[index];
        return _buildTagCard(tag);
      },
    );
  }

  Widget _buildTagCard(Tag tag) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: tag.colorObject ?? Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            tag.iconData ?? Icons.label,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          tag.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag.description != null) ...[
              const SizedBox(height: 4),
              Text(tag.description!),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  tag.showCompleted
                    ? Icons.visibility
                    : Icons.visibility_off,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  tag.showCompleted
                    ? 'Mostra completate'
                    : 'Nascondi completate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showTagFormDialog(tag),
              tooltip: 'Modifica',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTag(tag),
              tooltip: 'Elimina',
            ),
          ],
        ),
        onTap: () => _showTagFormDialog(tag),
      ),
    );
  }

  Future<void> _showTagFormDialog(Tag? tag) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TagFormDialog(tag: tag),
    );

    // Reload tags if changes were saved
    if (result == true) {
      _loadTags();
    }
  }
}
