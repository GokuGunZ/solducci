import 'dart:async';
import 'dart:ui';
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
import 'package:solducci/theme/todo_theme.dart';

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
  VoidCallback? _onStartInlineCreation; // Callback to start inline creation

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // CRITICAL: Allow background gradient to show through
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
            key: const ValueKey(
              'page_view_content',
            ), // Key stabile per evitare rebuild
            pageController: _pageController,
            document: _currentDocument!,
            onPageChanged: (page, tags, refreshCallback, inlineCreationCallback) {
              // Update state without triggering rebuild of StreamBuilder
              _currentPage = page;
              _currentTags = tags;
              _onTaskCreated = refreshCallback;
              _onStartInlineCreation = inlineCreationCallback;
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
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple[700]!.withValues(alpha: 0.3),
                  Colors.purple[900]!.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple[400]!.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple[700]!.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.purple[300]!.withValues(alpha: 0.4),
                  blurRadius: 3,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCreateTaskDialog,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.2),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial gradient effect behind icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                      // Icon with enhanced visibility
                      const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 32,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
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
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
    // Tags will be automatically refreshed via stream in _PageViewContent
  }

  void _showCreateTaskDialog() {
    if (_currentDocument == null) return;

    // If we're on "All Tasks" page (index 1) and have inline creation callback, use it
    if (_currentPage == 1 && _onStartInlineCreation != null) {
      _onStartInlineCreation!();
      return;
    }

    // Determine if we're on a tag page and get the corresponding tag
    Tag? initialTag;
    if (_currentPage >= 2 && _currentPage < 2 + _currentTags.length) {
      // We're on a tag page (pages 2 to N+1)
      initialTag = _currentTags[_currentPage - 2];
    }

    // For other pages (Completed, Tag views), use the full form
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
  final void Function(int page, List<Tag> tags, VoidCallback? refreshCallback, VoidCallback? inlineCreationCallback)
  onPageChanged;
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
  int _currentPage =
      1; // Start at "Tutte" page (matches PageController initialPage)

  // ValueNotifier for efficient property visibility updates
  final ValueNotifier<bool> _showAllTaskPropertiesNotifier = ValueNotifier(false);

  // Refresh key to force rebuild of pages
  int _refreshKey = 0;

  // Callback to start inline creation (set by child view)
  VoidCallback? _startInlineCreationCallback;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _showAllTaskPropertiesNotifier.dispose();
    super.dispose();
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
            widget.onPageChanged(_currentPage, _tags, _getRefreshCallback, _startInlineCreationCallback);
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
            widget.onPageChanged(_currentPage, _tags, _getRefreshCallback, _startInlineCreationCallback);
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

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Notify parent about page change
    widget.onPageChanged(page, _tags, _getRefreshCallback, _startInlineCreationCallback);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTags) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalPages = 2 + _tags.length; // All Tasks + Tags + Completed

    return Stack(
      children: [
        // Custom layered background (fixed, doesn't move with swipe)
        Positioned.fill(
          child: TodoTheme.customBackgroundGradient,
        ),
        // Main content
        Column(
          children: [
            // AppBar at the top with glass morphism
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: TodoTheme.glassAppBarDecoration(),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back button, title and tag management button
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Back button
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.purple[700],
                                ),
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
                              // Toggle button for showing all properties
                              ValueListenableBuilder<bool>(
                                valueListenable: _showAllTaskPropertiesNotifier,
                                builder: (context, showAll, child) {
                                  return IconButton(
                                    icon: Icon(
                                      showAll ? Icons.edit_off : Icons.edit,
                                      color: Colors.purple[700],
                                    ),
                                    onPressed: () {
                                      _showAllTaskPropertiesNotifier.value = !_showAllTaskPropertiesNotifier.value;
                                    },
                                    tooltip: showAll
                                        ? 'Nascondi proprietà vuote'
                                        : 'Mostra tutte le proprietà',
                                  );
                                },
                              ),
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
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),

        // PageView below the AppBar
        Expanded(
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
            child: Container(
              color: Colors.transparent, // CRITICAL: Prevent PageView default background
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
                    showAllPropertiesNotifier: _showAllTaskPropertiesNotifier,
                  );
                }

                // Page 1: All Tasks (second)
                if (index == 1) {
                  return AllTasksView(
                    key: ValueKey('all_tasks_$_refreshKey'),
                    document: widget.document,
                    showAllPropertiesNotifier: _showAllTaskPropertiesNotifier,
                    onInlineCreationCallbackChanged: (callback) {
                      _startInlineCreationCallback = callback;
                    },
                    availableTags: _tags,
                  );
                }

                // Pages 2 to N+1: Tag Views
                final tag = _tags[index - 2];
                return TagView(
                  key: ValueKey('tag_${tag.id}_$_refreshKey'),
                  document: widget.document,
                  tag: tag,
                  showAllPropertiesNotifier: _showAllTaskPropertiesNotifier,
                );
              },
              ),
            ),
          ),
        ),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
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
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    dotColor.withValues(alpha: 0.7),
                    dotColor.withValues(alpha: 0.5),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon inside glass circle
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: isActive ? 24 : 32,
                  height: isActive ? 24 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? [
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.2),
                            ]
                          : [
                              dotColor.withValues(alpha: 0.8),
                              dotColor.withValues(alpha: 0.6),
                            ],
                    ),
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.7)
                          : Color.lerp(dotColor, Colors.white, 0.3)!.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: isActive ? 0.3 : 0.5),
                        blurRadius: isActive ? 6 : 8,
                        offset: Offset(0, isActive ? 2 : 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon ?? Icons.list,
                    color: Colors.white,
                    size: isActive ? 14 : 18,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
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
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
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
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple[700]!.withValues(alpha: 0.8),
                  Colors.purple[900]!.withValues(alpha: 0.6),
                ],
              ),
              border: Border.all(
                color: Colors.purple[400]!.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 14,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
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
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
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
