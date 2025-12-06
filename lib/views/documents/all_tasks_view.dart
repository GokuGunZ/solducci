import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/widgets/documents/task_form.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/utils/task_filter_sort.dart';

/// View showing all tasks (pending + in progress + assigned) for a document
class AllTasksView extends StatefulWidget {
  final TodoDocument document;

  const AllTasksView({
    super.key,
    required this.document,
  });

  @override
  State<AllTasksView> createState() => _AllTasksViewState();
}

class _AllTasksViewState extends State<AllTasksView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _taskService = TaskService();
  Stream<List<Task>>? _taskStream;
  FilterSortConfig _filterConfig = const FilterSortConfig();

  @override
  void initState() {
    super.initState();
    _taskStream = _taskService.getTasksForDocument(widget.document.id);
  }

  void _refreshTasks() {
    setState(() {
      _taskStream = _taskService.getTasksForDocument(widget.document.id);
    });
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

    return StreamBuilder<List<Task>>(
      stream: _taskStream,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Errore: ${snapshot.error}'),
              ],
            ),
          );
        }

        // Get tasks and filter out completed ones
        final allTasks = snapshot.data ?? [];
        var tasks = allTasks
            .where((t) => t.status != TaskStatus.completed)
            .toList();

        // Apply filters and sorting
        tasks = tasks.applyFilterSort(_filterConfig);

        // Empty state
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _filterConfig.hasFilters
                      ? Icons.filter_alt_off
                      : Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _filterConfig.hasFilters
                      ? 'Nessuna task trovata'
                      : 'Nessuna task',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _filterConfig.hasFilters
                      ? 'Prova a cambiare i filtri'
                      : 'Aggiungi la tua prima task!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                if (_filterConfig.hasFilters) ...[
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

        // Task list with pull-to-refresh and filter button
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
                onRefresh: () async {
                  _refreshTasks();
                  // Wait a bit for the stream to update
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskListItem(
                      task: task,
                      document: widget.document,
                      onTap: () => _showTaskDetails(context, task),
                      onTaskChanged: _refreshTasks, // Refresh on task change
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskForm(
          document: widget.document,
          task: task,
          onTaskSaved: _refreshTasks, // Refresh after task is saved
        ),
      ),
    );
  }
}
