import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';
import 'package:solducci/utils/task_filter_sort.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

/// View showing tasks filtered by a specific tag
class TagView extends StatefulWidget {
  final TodoDocument document;
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const TagView({
    super.key,
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
  });

  @override
  State<TagView> createState() => _TagViewState();
}

class _TagViewState extends State<TagView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Task>? _tasks;
  bool _isLoading = true;
  String? _error;
  final _taskService = TaskService();
  FilterSortConfig _filterConfig = const FilterSortConfig();
  Map<String, List<Tag>> _taskTagsMap = {}; // Cache for preloaded tags

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _taskService.getTasksByTag(
        widget.tag.id,
        includeCompleted: widget.tag.showCompleted,
      );

      // Preload tags for all tasks including subtasks
      if (tasks.isNotEmpty) {
        _taskTagsMap = await _taskService.getEffectiveTagsForTasksWithSubtasks(tasks);
      }

      if (mounted) {
        setState(() {
          _tasks = tasks;
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    // No header bar, just the task list (transparent to show background gradient)
    return _buildTaskList();
  }

  Widget _buildTaskList() {
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Errore: $_error'),
          ],
        ),
      );
    }

    var tasks = _tasks ?? [];

    // Apply filters and sorting to all tasks
    tasks = tasks.applyFilterSort(_filterConfig);

    // Separate completed and non-completed tasks
    final activeTasks = tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();
    final completedTasks = tasks
        .where((t) => t.status == TaskStatus.completed)
        .toList();

    // Empty state
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filterConfig.hasFilters
                  ? Icons.filter_alt_off
                  : Icons.label_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _filterConfig.hasFilters
                  ? 'Nessuna task trovata'
                  : 'Nessuna task con questo tag',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_filterConfig.hasFilters) ...[
              const SizedBox(height: 8),
              Text(
                'Prova a cambiare i filtri',
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _filterConfig = const FilterSortConfig();
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Rimuovi filtri'),
              ),
            ],
          ],
        ),
      );
    }

    // Task list with filter UI, completed at bottom and pull-to-refresh
    return Column(
      children: [
        // Compact Filter & Sort Bar
        CompactFilterSortBar(
          key: const ValueKey('compact_filter_sort_bar'),
          filterConfig: _filterConfig,
          onFilterChanged: (newConfig) {
            setState(() {
              _filterConfig = newConfig;
              // AnimatedReorderableListView automatically detects reorder changes
            });
          },
        ),

        // Task list with AnimatedReorderableListView for tile-sliding animations
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            child: AnimatedReorderableListView<Task>(
              items: activeTasks,
              padding: const EdgeInsets.all(8),
              // Comparator to identify same items across list updates
              isSameItem: (a, b) => a.id == b.id,
              // Disable insert/remove animations (we only want reorder sliding)
              insertDuration: const Duration(milliseconds: 0),
              removeDuration: const Duration(milliseconds: 0),
              // Empty transitions for insert/remove
              enterTransition: const [],
              exitTransition: const [],
              // Disable drag-and-drop functionality (we only use this for sorting animations)
              buildDefaultDragHandles: false,
              // Dummy onReorder callback (required but unused)
              onReorder: (oldIndex, newIndex) {
                // Do nothing - reordering is handled by filters/sorting logic
              },
              // Item builder with highlight effect
              itemBuilder: (context, index) {
                final task = activeTasks[index];
                return _HighlightedTaskItem(
                  key: ValueKey('task_${task.id}'),
                  task: task,
                  document: widget.document,
                  onTap: () => _showTaskDetails(context, task),
                  showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                  preloadedTags: _taskTagsMap[task.id],
                  taskTagsMap: _taskTagsMap,
                );
              },
            ),
          ),
        ),

        // Completed tasks section (if enabled) - separate non-animated list
        if (widget.tag.showCompleted && completedTasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Completate',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ...completedTasks.map((task) => TaskListItem(
                      key: ValueKey('task_${task.id}'),
                      task: task,
                      document: widget.document,
                      onTap: () => _showTaskDetails(context, task),
                      showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                      preloadedTags: _taskTagsMap[task.id],
                      taskTagsMap: _taskTagsMap,
                    )),
              ],
            ),
          ),
      ],
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(
          document: widget.document,
          task: task,
          showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
        ),
      ),
    );
  }
}

/// Wrapper widget that adds a highlight effect when the task item is created
/// This provides visual feedback when items are reordered
class _HighlightedTaskItem extends StatefulWidget {
  final Task task;
  final TodoDocument document;
  final VoidCallback onTap;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final List<Tag>? preloadedTags;
  final Map<String, List<Tag>> taskTagsMap;

  const _HighlightedTaskItem({
    super.key,
    required this.task,
    required this.document,
    required this.onTap,
    this.showAllPropertiesNotifier,
    this.preloadedTags,
    required this.taskTagsMap,
  });

  @override
  State<_HighlightedTaskItem> createState() => _HighlightedTaskItemState();
}

class _HighlightedTaskItemState extends State<_HighlightedTaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();

    // Setup highlight animation controller
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    // Trigger highlight animation on init (when item appears during reorder)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _highlightController.forward().then((_) => _highlightController.reverse());
    });
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        // Calculate highlight opacity (fade in, then fade out)
        final highlightOpacity = _highlightAnimation.value <= 0.5
            ? _highlightAnimation.value * 2  // 0.0 -> 1.0 in first half
            : (1.0 - _highlightAnimation.value) * 2;  // 1.0 -> 0.0 in second half

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: highlightOpacity > 0.05 ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(highlightOpacity * 0.3),
                blurRadius: 12 * highlightOpacity,
                spreadRadius: 2 * highlightOpacity,
              ),
            ] : null,
          ),
          child: child,
        );
      },
      child: TaskListItem(
        task: widget.task,
        document: widget.document,
        onTap: widget.onTap,
        showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
        preloadedTags: widget.preloadedTags,
        taskTagsMap: widget.taskTagsMap,
      ),
    );
  }
}
