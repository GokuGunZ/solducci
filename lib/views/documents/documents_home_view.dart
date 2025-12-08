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
  int _currentPage = 1; // Start at "Tutte" page
  List<Tag> _currentTags = [];
  VoidCallback? _onTaskCreated; // Callback to refresh current page

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 1, // Start at "Tutte" page instead of "Completate"
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

          // Build main UI with CustomScrollView
          return _PageViewContent(
            key: const ValueKey('page_view_content'), // Key stabile per evitare rebuild
            pageController: _pageController,
            document: _currentDocument!,
            onPageChanged: (page, tags, refreshCallback) {
              // Update state without triggering rebuild of StreamBuilder
              _currentPage = page;
              _currentTags = tags;
              _onTaskCreated = refreshCallback;
            },
            onCreateTag: _showCreateTagDialog,
            onNavigateToTagManagement: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TagManagementView(),
                ),
              );
            },
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
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const TagFormDialog(tag: null);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
    // Tags will be automatically refreshed via stream in _PageViewContent
  }

  void _showCreateTaskDialog() {
    if (_currentDocument == null) return;

    // Determine if we're on a tag page and get the corresponding tag
    Tag? initialTag;
    if (_currentPage >= 2 && _currentPage < 2 + _currentTags.length) {
      // We're on a tag page (pages 2 to N+1)
      initialTag = _currentTags[_currentPage - 2];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskForm(
          document: _currentDocument!,
          initialTags: initialTag != null ? [initialTag] : null,
          onTaskSaved: _onTaskCreated, // Trigger refresh after task creation
        ),
      ),
    );
  }
}

/// Stateful widget that holds the PageView and manages tags stream
/// This separation prevents infinite rebuild loops
class _PageViewContent extends StatefulWidget {
  final PageController pageController;
  final TodoDocument document;
  final void Function(int page, List<Tag> tags, VoidCallback? refreshCallback) onPageChanged;
  final Future<void> Function() onCreateTag;
  final VoidCallback onNavigateToTagManagement;

  const _PageViewContent({
    super.key,
    required this.pageController,
    required this.document,
    required this.onPageChanged,
    required this.onCreateTag,
    required this.onNavigateToTagManagement,
  });

  @override
  State<_PageViewContent> createState() => _PageViewContentState();
}

class _PageViewContentState extends State<_PageViewContent> {
  final _tagService = TagService();
  List<Tag> _tags = [];
  bool _isLoadingTags = true;
  int _currentPage = 1; // Start at "Tutte" page (matches PageController initialPage)

  // Refresh key to force rebuild of pages
  int _refreshKey = 0;

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
        // Notify parent about initial tags load after the frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged(_currentPage, _tags, _getRefreshCallback);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tags = [];
          _isLoadingTags = false;
        });
        // Notify parent even on error after the frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged(_currentPage, _tags, _getRefreshCallback);
          }
        });
      }
    }
  }

  void _getRefreshCallback() {
    // Increment key to force rebuild of current page
    setState(() {
      _refreshKey++;
    });
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
    // Notify parent about page change
    widget.onPageChanged(page, _tags, _getRefreshCallback);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTags) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalPages = 2 + _tags.length; // All Tasks + Tags + Completed

    return Stack(
      children: [
        // PageView with top padding for the AppBar
        Positioned.fill(
          top: 160, // Initial expanded height of AppBar
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Detect overscroll at the end (after last tag)
              if (notification is ScrollUpdateNotification) {
                final metrics = notification.metrics;
                // Check if we're at the last page and trying to scroll further
                if (metrics.pixels > metrics.maxScrollExtent + 50) {
                  // User is trying to swipe beyond the last page
                  _handleSwipeBeyondLastPage();
                }
              }
              return false;
            },
            child: PageView.builder(
              key: ValueKey('main_page_view_$_refreshKey'),
              controller: widget.pageController,
              onPageChanged: _onPageChanged,
              itemCount: totalPages,
              itemBuilder: (context, index) {
                // Page 0: Completed Tasks (first)
                if (index == 0) {
                  return CompletedTasksView(
                    key: ValueKey('completed_$_refreshKey'),
                    document: widget.document,
                  );
                }

                // Page 1: All Tasks (second)
                if (index == 1) {
                  return AllTasksView(
                    key: ValueKey('all_tasks_$_refreshKey'),
                    document: widget.document,
                  );
                }

                // Pages 2 to N+1: Tag Views
                final tag = _tags[index - 2];
                return TagView(
                  key: ValueKey('tag_${tag.id}_$_refreshKey'),
                  document: widget.document,
                  tag: tag,
                );
              },
            ),
          ),
        ),

        // AppBar overlay with gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.9, 1.0],
                colors: [
                  Colors.purple.withValues(alpha: 0.0),
                  Colors.purple.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.35),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.purple[700]!,
                  width: 2,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back button, title and tag management button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Back button
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.purple[700]),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ToDo Lists',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: Icon(Icons.label, color: Colors.purple[700]),
                          label: Text(
                            'Tag',
                            style: TextStyle(color: Colors.purple[700]),
                          ),
                          onPressed: widget.onNavigateToTagManagement,
                        ),
                      ],
                    ),
                  ),
                  // Page indicators
                  _buildPageIndicator(totalPages, _tags),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isShowingDialog = false;

  void _handleSwipeBeyondLastPage() {
    // Prevent multiple dialogs from opening
    if (_isShowingDialog) return;

    final lastTagPage = 2 + _tags.length - 1;
    // Only trigger if we're on the last tag page
    if (_currentPage == lastTagPage) {
      _isShowingDialog = true;
      _showCreateTagDialogWithFade(context).then((_) {
        _isShowingDialog = false;
      });
    }
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
              // Completed indicator (page 0)
              _buildDot(0, 'Completate', Icons.check_circle, null),

              // All Tasks indicator (page 1)
              _buildDot(1, 'Tutte', null, null),

              // Tag indicators (pages 2 to N+1)
              for (int i = 0; i < tags.length; i++)
                _buildDot(
                  i + 2,
                  tags[i].name,
                  tags[i].iconData,
                  tags[i].colorObject,
                ),

              // Add tag button (smaller, after tags)
              _buildAddTagButton(),
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

  Widget _buildAddTagButton() {
    return GestureDetector(
      onTap: () async {
        await widget.onCreateTag();
        // Reload tags after creating a new one
        _loadTags();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.purple[700],
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withAlpha(100),
              blurRadius: 3,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }

  Future<void> _showCreateTagDialogWithFade(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const TagFormDialog(tag: null);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );

    if (result == true) {
      // Reload tags and navigate back to the last tag view
      await _loadTags();
      if (mounted && _tags.isNotEmpty) {
        // Navigate to the newly created tag (last one before the add page)
        widget.pageController.animateToPage(
          2 + _tags.length - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}
