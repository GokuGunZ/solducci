import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_form.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';
import 'package:solducci/utils/task_filter_sort.dart';

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

    // No header bar, just the task list with gradient background
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.withValues(alpha: 0.03),
            Colors.blue.withValues(alpha: 0.02),
            Colors.white,
          ],
        ),
      ),
      child: _buildTaskList(),
    );
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
            });
          },
        ),

        // Task list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // Active tasks
                ...activeTasks.map((task) => TaskListItem(
                      task: task,
                      document: widget.document,
                      onTap: () => _showTaskDetails(context, task),
                      onTaskChanged: _loadTasks, // Refresh on task change
                      showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                      preloadedTags: _taskTagsMap[task.id],
                      taskTagsMap: _taskTagsMap, // Pass full map for subtasks
                    )),

                // Completed tasks (if enabled)
                if (widget.tag.showCompleted && completedTasks.isNotEmpty) ...[
                  const Divider(height: 32),
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
                        task: task,
                        document: widget.document,
                        onTap: () => _showTaskDetails(context, task),
                        onTaskChanged: _loadTasks, // Refresh on task change
                        showAllPropertiesNotifier: widget.showAllPropertiesNotifier,
                        preloadedTags: _taskTagsMap[task.id],
                        taskTagsMap: _taskTagsMap, // Pass full map for subtasks
                      )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskForm(
          document: widget.document,
          task: task,
          onTaskSaved: _loadTasks, // Refresh after task is saved
        ),
      ),
    );
  }
}
