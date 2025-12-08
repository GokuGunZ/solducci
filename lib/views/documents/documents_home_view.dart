import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/views/documents/all_tasks_view.dart';
import 'package:solducci/views/documents/tag_view.dart';
import 'package:solducci/views/documents/completed_tasks_view.dart';
import 'package:solducci/views/documents/tag_management_view.dart';
import 'package:solducci/widgets/documents/task_form.dart';
import 'package:solducci/widgets/documents/tag_form_dialog.dart';

/// Main documents/todo home view with swipe-based navigation
/// Shows: All Tasks | Tag Views | Completed Tasks
class DocumentsHomeView extends StatefulWidget {
  const DocumentsHomeView({super.key});

  @override
  State<DocumentsHomeView> createState() => _DocumentsHomeViewState();
}

class _DocumentsHomeViewState extends State<DocumentsHomeView> {
  late final PageController _pageController;
  final _documentService = DocumentService();

  TodoDocument? _currentDocument;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      keepPage: true, // Mantiene la pagina corrente anche durante i rebuild
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _createFirstDocument() async {
    try {
      final doc = TodoDocument.create(
        userId: '', // Will be set by service
        title: 'My Tasks',
        description: 'Default todo list',
      );

      final created = await _documentService.createDocument(doc);
      setState(() {
        _currentDocument = created as TodoDocument;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Lists'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showCreateTagDialog,
            tooltip: 'Crea nuovo tag',
          ),
          TextButton.icon(
            icon: const Icon(Icons.label, color: Colors.white),
            label: const Text(
              'Tag',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TagManagementView(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TodoDocument>>(
        stream: _documentService.getTodoDocumentsStream(),
        builder: (context, docSnapshot) {
          // Loading state
          if (docSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (docSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Errore: ${docSnapshot.error}'),
                ],
              ),
            );
          }

          // No documents - show welcome screen
          final documents = docSnapshot.data ?? [];
          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna lista trovata',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea la tua prima lista di task',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createFirstDocument,
                    icon: const Icon(Icons.add),
                    label: const Text('Crea Lista'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // Set current document if not set
          if (_currentDocument == null && documents.isNotEmpty) {
            _currentDocument = documents.first;
          }

          // Build main UI with PageView
          return _PageViewContent(
            key: const ValueKey('page_view_content'), // Key stabile per evitare rebuild
            pageController: _pageController,
            document: _currentDocument!,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showCreateTagDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => const TagFormDialog(tag: null),
    );
    // Tags will be automatically refreshed via stream in _PageViewContent
  }

  void _showCreateTaskDialog() {
    if (_currentDocument == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskForm(document: _currentDocument!),
      ),
    );
  }
}

/// Stateful widget that holds the PageView and manages tags stream
/// This separation prevents infinite rebuild loops
class _PageViewContent extends StatefulWidget {
  final PageController pageController;
  final TodoDocument document;

  const _PageViewContent({
    super.key,
    required this.pageController,
    required this.document,
  });

  @override
  State<_PageViewContent> createState() => _PageViewContentState();
}

class _PageViewContentState extends State<_PageViewContent> {
  final _tagService = TagService();
  List<Tag> _tags = [];
  bool _isLoadingTags = true;
  int _currentPage = 0; // Stato della pagina corrente gestito internamente

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      // Carica i tag una sola volta invece di usare lo stream
      final tags = await _tagService.getRootTags();

      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tags = [];
          _isLoadingTags = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(_PageViewContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se il documento è cambiato, reset alla prima pagina
    if (oldWidget.document.id != widget.document.id) {
      widget.pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTags) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalPages = 2 + _tags.length; // All Tasks + Tags + Completed

    return Column(
      children: [
        // Page indicator
        _buildPageIndicator(totalPages, _tags),

        // PageView with swipe - using builder for lazy loading
        Expanded(
          child: PageView.builder(
            key: const ValueKey('main_page_view'),
            controller: widget.pageController,
            onPageChanged: _onPageChanged,
            itemCount: totalPages,
            itemBuilder: (context, index) {
              // Page 0: All Tasks
              if (index == 0) {
                return AllTasksView(document: widget.document);
              }

              // Pages 1 to N-1: Tag Views
              if (index <= _tags.length) {
                final tag = _tags[index - 1];
                return TagView(
                  document: widget.document,
                  tag: tag,
                );
              }

              // Last page: Completed Tasks
              return CompletedTasksView(document: widget.document);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int totalPages, List<Tag> tags) {
    return SizedBox(
      height: 56, // Fixed height to prevent vertical oscillation
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // All Tasks indicator
              _buildDot(0, 'Tutte', null, null),

              // Tag indicators with icons
              for (int i = 0; i < tags.length; i++)
                _buildDot(
                  i + 1,
                  tags[i].name,
                  tags[i].iconData,
                  tags[i].colorObject,
                ),

              // Completed indicator
              _buildDot(totalPages - 1, 'Completate', Icons.check_circle, null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index, String label, IconData? icon, Color? color) {
    final isActive = _currentPage == index;
    final dotColor = color ?? Colors.purple[700]!;

    return GestureDetector(
      onTap: () {
        widget.pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12 : 0,
          vertical: isActive ? 6 : 0,
        ),
        decoration: BoxDecoration(
          color: isActive ? dotColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon inside circle
            Container(
              width: isActive ? 24 : 32,
              height: isActive ? 24 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.white.withValues(alpha: 0.3) : dotColor,
              ),
              child: Icon(
                icon ?? Icons.list,
                color: Colors.white,
                size: isActive ? 14 : 18,
              ),
            ),

            // Label (only when active)
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
