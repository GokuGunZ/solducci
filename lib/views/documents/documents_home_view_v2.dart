import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/tag_service.dart';
import 'package:solducci/theme/todo_theme.dart';
import 'package:solducci/widgets/documents/tag_form_dialog.dart';
import 'package:solducci/widgets/documents/task_form.dart';
import 'package:solducci/views/documents/tag_management_view.dart';
import 'package:solducci/widgets/common/glassmorphic_fab.dart';

// NEW: Import new components
import 'package:solducci/core/components/category_scroll_bar/controllers/category_scroll_bar_controller.dart';
import 'package:solducci/views/documents/all_tasks_view.dart';
import 'package:solducci/views/documents/tag_view.dart';

/// DocumentsHomeView V2 - Using new CategoryScrollBar component
///
/// This is a reimplementation of DocumentsHomeView using the new
/// composable component architecture while maintaining identical UI/UX.
///
/// Key differences from original:
/// - Uses CategoryScrollBarController for coordination
/// - Same theme, same glassmorphism, same animations
/// - Identical user experience
class DocumentsHomeViewV2 extends StatefulWidget {
  const DocumentsHomeViewV2({super.key});

  @override
  State<DocumentsHomeViewV2> createState() => _DocumentsHomeViewV2State();
}

class _DocumentsHomeViewV2State extends State<DocumentsHomeViewV2> {
  final _documentService = DocumentService();
  final _tagService = TagService();

  TodoDocument? _currentDocument;
  List<Tag> _tags = [];
  bool _isLoadingTags = true;
  late CategoryScrollBarController<Task, Tag> _categoryController;
  final ValueNotifier<bool> _showAllTaskPropertiesNotifier =
      ValueNotifier<bool>(false);

  StreamSubscription<List<Tag>>? _tagsSubscription;

  // Refresh key to force rebuild of pages
  int _refreshKey = 0;

  // Callback for inline creation (set by AllTasksView)
  VoidCallback? _onStartInlineCreation;

  // Map of tag ID -> inline creation callback (set by TagView instances)
  final Map<String, VoidCallback?> _tagViewCallbacks = {};

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadTags();
  }

  void _initializeController() {
    _categoryController = CategoryScrollBarController<Task, Tag>(
      pageController: PageController(initialPage: 0),
      categories: _tags,
      showAllCategory: true,
      onCategoryChanged: (tag, index) {
        debugPrint('Selected category: ${tag?.name ?? "All"}');
      },
      // Don't pass callback - we handle it manually in _buildAddTagButton
    );
  }

  Future<void> _loadTags() async {
    setState(() => _isLoadingTags = true);

    _tagsSubscription?.cancel();

    // Create a completer to wait for first stream emission
    final completer = Completer<void>();
    bool isFirstEmission = true;

    _tagsSubscription = _tagService.stream.listen(
      (tags) {
        if (mounted) {
          setState(() {
            _tags = tags;
            _isLoadingTags = false;
          });
          _categoryController.updateCategories(tags);

          // Complete on first emission
          if (isFirstEmission) {
            isFirstEmission = false;
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Error loading tags: $error');
        if (mounted) {
          setState(() => _isLoadingTags = false);
        }
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    // Wait for first emission
    return completer.future;
  }

  void _refreshCurrentPage() {
    setState(() {
      _refreshKey++;
    });
  }

  Future<dynamic> _showCreateTagDialog() async {
    return await showGeneralDialog<dynamic>(
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
  }

  Future<void> _createFirstDocument() async {
    try {
      final doc = TodoDocument.create(
        userId: '',
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
  void dispose() {
    _tagsSubscription?.cancel();
    _categoryController.dispose();
    _showAllTaskPropertiesNotifier.dispose();
    super.dispose();
  }

  void _showCreateTaskDialog() {
    if (_currentDocument == null) return;

    final currentIndex = _categoryController.currentIndex;

    // If we're on "All Tasks" page (index 0) and have inline creation callback, use it
    if (currentIndex == 0 && _onStartInlineCreation != null) {
      _onStartInlineCreation!();
      return;
    }

    // If we're on a tag page (index > 0) and have inline creation callback for that tag, use it
    if (currentIndex > 0 && currentIndex <= _tags.length) {
      final tag = _tags[currentIndex - 1];
      final tagCallback = _tagViewCallbacks[tag.id];
      if (tagCallback != null) {
        tagCallback();
        return;
      }
    }

    // Fallback: Get current tag if we're on a tag page
    Tag? initialTag;
    if (currentIndex > 0 && currentIndex <= _tags.length) {
      // We're on a tag page (index 1-N are tags)
      initialTag = _tags[currentIndex - 1];
    }

    // For tag pages without inline creation, open the full form with the tag pre-selected
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskForm(
          document: _currentDocument!,
          initialTags: initialTag != null ? [initialTag] : null,
          onTaskSaved: _refreshCurrentPage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<TodoDocument>>(
        stream: _documentService.getTodoDocumentsStream(),
        builder: (context, docSnapshot) {
          // Loading
          if (docSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
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

          // No documents
          final documents = docSnapshot.data ?? [];
          if (documents.isEmpty) {
            return _buildWelcomeScreen();
          }

          // Get first document
          _currentDocument ??= documents.first;

          // Loading tags
          if (_isLoadingTags) {
            return const Center(child: CircularProgressIndicator());
          }

          // Main UI with CategoryScrollBar
          return _buildMainUI();
        },
      ),
      floatingActionButton: GlassmorphicFAB(
        onPressed: _showCreateTaskDialog,
        primaryColor: Colors.purple,
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 120, color: Colors.purple[300]),
            const SizedBox(height: 32),
            Text(
              'Benvenuto in ToDo Lists V2!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Questa versione usa i nuovi componenti riutilizzabili',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createFirstDocument,
              child: const Text('Crea la tua prima lista'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainUI() {
    return Stack(
      children: [
        // Background gradient (same as original)
        Positioned.fill(child: TodoTheme.customBackgroundGradient),

        // Main content
        Column(
          children: [
            // AppBar with integrated page indicators (same as V1)
            _buildAppBar(),

            // PageView with lists (using controller from CategoryScrollBar)
            Expanded(
              child: PageView.builder(
                key: ValueKey('page_view_$_refreshKey'),
                controller: _categoryController.pageController,
                onPageChanged: _categoryController.onPageChanged,
                itemCount: _categoryController.totalPages,
                itemBuilder: (context, index) {
                  // Get category for this page
                  final category = _categoryController.getCategoryAtIndex(index);

                  // All tasks
                  if (category == null) {
                    return AllTasksView(
                      key: ValueKey('all_tasks_${_currentDocument?.id}_$_refreshKey'),
                      document: _currentDocument!,
                      showAllPropertiesNotifier: _showAllTaskPropertiesNotifier,
                      availableTags: _tags,
                      onInlineCreationCallbackChanged: (callback) {
                        _onStartInlineCreation = callback;
                      },
                    );
                  }

                  // Tag-specific view
                  return TagView(
                    key: ValueKey('tag_view_${category.id}_$_refreshKey'),
                    document: _currentDocument!,
                    tag: category,
                    showAllPropertiesNotifier: _showAllTaskPropertiesNotifier,
                    onInlineCreationCallbackChanged: (callback) {
                      _tagViewCallbacks[category.id] = callback;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: TodoTheme.glassAppBarDecoration(),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back button, title and toggle button
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
                      // Title with V2 badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ToDo Lists V2',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          Text(
                            'Nuovi Componenti',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple[400],
                            ),
                          ),
                        ],
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
                              _showAllTaskPropertiesNotifier.value = !showAll;
                            },
                            tooltip: showAll
                                ? 'Nascondi proprietà vuote'
                                : 'Mostra tutte le proprietà',
                          );
                        },
                      ),
                      // Tag management button
                      TextButton.icon(
                        icon: Icon(
                          Icons.label,
                          color: Colors.purple[700],
                        ),
                        label: Text(
                          'Tag',
                          style: TextStyle(color: Colors.purple[700]),
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
                ),
                // Page indicators (integrated, same as V1)
                _buildPageIndicator(),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 56, // Fixed height to prevent vertical oscillation
        child: Center(
          child: ListenableBuilder(
            listenable: _categoryController,
            builder: (context, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // "Tutte" indicator (page 0)
                    _buildDot(0, 'Tutte', null, null),

                    // Tag indicators (pages 1 to N)
                    for (int i = 0; i < _tags.length; i++)
                      _buildDot(
                        i + 1,
                        _tags[i].name,
                        _tags[i].iconData,
                        _tags[i].colorObject,
                      ),

                    // Add tag button
                    _buildAddTagButton(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index, String label, IconData? icon, Color? color) {
    final isActive = _categoryController.currentIndex == index;
    final dotColor = color ?? Colors.purple[700]!;

    return GestureDetector(
      onTap: () {
        _categoryController.selectCategoryByIndex(index);
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
                          : Color.lerp(
                              dotColor,
                              Colors.white,
                              0.3,
                            )!.withValues(alpha: 0.7),
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
        // Store current tag IDs before opening dialog
        final tagIdsBefore = _tags.map((t) => t.id).toSet();

        final result = await _showCreateTagDialog();

        // If dialog returned true (success), reload tags and navigate
        if (result == true && mounted) {
          debugPrint('Tag created successfully, reloading tags...');

          // Force reload tags (like AllTasksView does with TaskListRefreshRequested)
          // This will wait for the stream to emit updated tags
          await _loadTags();

          debugPrint('Tags reloaded, searching for new tag...');

          // Now find the new tag and navigate to it
          try {
            final newTag = _tags.firstWhere((t) => !tagIdsBefore.contains(t.id));
            final newTagIndex = _tags.indexOf(newTag) + 1; // +1 because index 0 is "All"
            debugPrint('New tag found: ${newTag.name} at index $newTagIndex');
            _categoryController.selectCategoryByIndex(newTagIndex);
          } catch (e) {
            debugPrint('New tag not found after reload: $e');
          }
        }
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
}
