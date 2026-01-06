import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/widgets/documents/tag_form_dialog.dart';
import 'package:solducci/theme/todo_theme.dart';
import 'package:solducci/widgets/common/glassmorphic_fab.dart';

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
    return Stack(
      children: [
        // Background gradient - covers entire screen
        Positioned.fill(
          child: TodoTheme.customBackgroundGradient,
        ),
        // Scaffold on top
        Scaffold(
          backgroundColor: Colors.transparent, // CRITICAL: Allow background gradient to show through
          extendBodyBehindAppBar: true, // Extend body behind AppBar
          appBar: _buildGlassAppBar(),
          body: SafeArea(
            child: _buildBody(),
          ),
          floatingActionButton: GlassmorphicFAB(
            onPressed: () => _showTagFormDialog(null),
            primaryColor: Colors.purple,
          ),
        ),
      ],
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
    return Container(
      color: Colors.transparent, // CRITICAL: Prevent ListView default white background
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          final tag = _tags[index];
          return _buildTagCard(tag);
        },
      ),
    );
  }

  Widget _buildTagCard(Tag tag) {
    final tagColor = tag.colorObject ?? Colors.grey[300]!;
    final borderColor = Color.lerp(tagColor, Colors.white, 0.3)!.withValues(alpha: 0.7);
    final highlightColor = Color.lerp(tagColor, Colors.white, 0.5)!.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: TodoTheme.primaryPurple.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 2,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showTagFormDialog(tag),
                borderRadius: BorderRadius.circular(16),
                splashColor: tagColor.withValues(alpha: 0.1),
                highlightColor: tagColor.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Tag icon with glassmorphism
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tagColor.withValues(alpha: 0.9),
                              tagColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tagColor.withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: highlightColor,
                              blurRadius: 1,
                              offset: const Offset(-1, -1),
                            ),
                          ],
                        ),
                        child: Icon(
                          tag.iconData ?? Icons.label,
                          color: Colors.white,
                          size: 28,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tag info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tag.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: TodoTheme.primaryPurple,
                                shadows: [
                                  Shadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            if (tag.description != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                tag.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  tag.showCompleted
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 16,
                                  color: TodoTheme.primaryPurple.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tag.showCompleted
                                      ? 'Mostra completate'
                                      : 'Nascondi completate',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: TodoTheme.primaryPurple.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.blue,
                            onPressed: () => _showTagFormDialog(tag),
                            tooltip: 'Modifica',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _deleteTag(tag),
                            tooltip: 'Elimina',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return AppBar(
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: TodoTheme.glassAppBarDecoration(),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: TodoTheme.primaryPurple),
      title: const Text(
        'Gestione Tag',
        style: TextStyle(
          color: TodoTheme.primaryPurple,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TodoTheme.primaryPurple.withValues(alpha: 0.3),
                TodoTheme.primaryPurple,
                TodoTheme.primaryPurple.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
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
