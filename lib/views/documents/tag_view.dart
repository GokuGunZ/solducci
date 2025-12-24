import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/blocs/tag/tag_bloc_export.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/widgets/documents/task_list_item.dart';
import 'package:solducci/views/documents/task_detail_page.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';
import 'package:solducci/widgets/documents/compact_filter_sort_bar.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

/// View showing tasks filtered by a specific tag
class TagView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<TagBloc>();
        bloc.add(TagLoadRequested(
          tagId: tag.id,
          includeCompleted: tag.showCompleted,
        ));
        return bloc;
      },
      child: _TagViewContent(
        document: document,
        tag: tag,
        showAllPropertiesNotifier: showAllPropertiesNotifier,
      ),
    );
  }
}

class _TagViewContent extends StatefulWidget {
  final TodoDocument document;
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const _TagViewContent({
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
  });

  @override
  State<_TagViewContent> createState() => _TagViewContentState();
}

class _TagViewContentState extends State<_TagViewContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _taskService = TaskService();
  Map<String, List<Tag>> _taskTagsMap = {};

  Future<void> _preloadTagsForTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    _taskTagsMap = await _taskService.getEffectiveTagsForTasksWithSubtasks(tasks);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return BlocBuilder<TagBloc, TagState>(
      builder: (context, state) {
        return switch (state) {
          TagInitial() => const SizedBox.shrink(),

          TagLoading() => const Center(
            child: CircularProgressIndicator(),
          ),

          TagError(:final message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Errore nel caricamento'),
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<TagBloc>()
                      .add(const TagRefreshRequested()),
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),

          TagLoaded(:final tasks, :final filterConfig) => FutureBuilder<void>(
            future: _preloadTagsForTasks(tasks),
            builder: (context, tagsSnapshot) {
              if (tagsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

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
                        filterConfig.hasFilters
                            ? Icons.filter_alt_off
                            : Icons.label_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        filterConfig.hasFilters
                            ? 'Nessuna task trovata'
                            : 'Nessuna task con questo tag',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      if (filterConfig.hasFilters) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Prova a cambiare i filtri',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<TagBloc>().add(
                              const TagFilterChanged(FilterSortConfig()),
                            );
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Rimuovi filtri'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              // Task list with filter UI
              return Column(
                children: [
                  // Compact Filter & Sort Bar
                  CompactFilterSortBar(
                    key: const ValueKey('compact_filter_sort_bar'),
                    filterConfig: filterConfig,
                    onFilterChanged: (newConfig) {
                      context.read<TagBloc>().add(TagFilterChanged(newConfig));
                    },
                  ),

                  // Task list with AnimatedReorderableListView
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<TagBloc>().add(const TagRefreshRequested());
                      },
                      child: AnimatedReorderableListView<Task>(
                        items: activeTasks,
                        padding: const EdgeInsets.all(8),
                        isSameItem: (a, b) => a.id == b.id,
                        insertDuration: const Duration(milliseconds: 0),
                        removeDuration: const Duration(milliseconds: 0),
                        enterTransition: const [],
                        exitTransition: const [],
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          // Do nothing - reordering handled by sorting
                        },
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

                  // Completed tasks section
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
            },
          ),
        };
      },
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

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

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
        final highlightOpacity = _highlightAnimation.value <= 0.5
            ? _highlightAnimation.value * 2
            : (1.0 - _highlightAnimation.value) * 2;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: highlightOpacity > 0.05 ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: highlightOpacity * 0.3),
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
