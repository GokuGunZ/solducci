import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_form.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/utils/task_filter_sort.dart';

/// View showing tasks filtered by a specific tag
class TagView extends StatefulWidget {
  final TodoDocument document;
  final Tag tag;

  const TagView({
    super.key,
    required this.document,
    required this.tag,
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

  Future<void> _showFilterDialog() async {
    final result = await showDialog<FilterSortConfig>(
      context: context,
      builder: (context) => FilterSortDialog(initialConfig: _filterConfig),
    );

    if (result != null) {
      setState(() {
        _filterConfig = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    // No header bar, just the task list
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
        // Filter bar
        if (_filterConfig.hasFilters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.purple[50],
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 20, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  '${_filterConfig.activeFiltersCount} filtri attivi',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterConfig = const FilterSortConfig();
                    });
                  },
                  child: const Text('Rimuovi'),
                ),
              ],
            ),
          ),

        // Filter button
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: Badge(
                    isLabelVisible: _filterConfig.hasFilters,
                    label: Text('${_filterConfig.activeFiltersCount}'),
                    child: const Icon(Icons.filter_list),
                  ),
                  label: const Text('Filtri e ordinamento'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _filterConfig.hasFilters
                        ? Colors.purple[700]
                        : null,
                  ),
                ),
              ),
            ],
          ),
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
