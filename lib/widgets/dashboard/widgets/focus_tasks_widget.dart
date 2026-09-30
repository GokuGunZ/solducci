import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/context_manager.dart';

import 'package:solducci/widgets/dashboard/base_list_widget.dart';

class _TaskFilterSource {
  final String id;
  final String title;
  final String type; // 'focus_today', 'document', 'tag'
  final IconData icon;
  final Color color;

  const _TaskFilterSource({
    required this.id,
    required this.title,
    required this.type,
    required this.icon,
    required this.color,
  });
}

class FocusTasksWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const FocusTasksWidget({super.key, required this.def});

  @override
  State<FocusTasksWidget> createState() => _FocusTasksWidgetState();
}

class _FocusTasksWidgetState extends State<FocusTasksWidget> {
  late Stream<List<Task>> _taskStream;
  List<_TaskFilterSource> _sources = [
    const _TaskFilterSource(
      id: 'focus_today',
      title: 'Focus Oggi',
      type: 'focus_today',
      icon: Icons.bolt,
      color: Color(0xFFF59E0B),
    ),
  ];
  int _currentSourceIndex = 0;
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _taskFocusNode = FocusNode();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _taskStream = getIt<TaskRepository>().watchAll().asBroadcastStream();
    _loadSources();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }

  Future<void> _quickAddTask(String text) async {
    final title = text.trim();
    if (title.isEmpty || _isCreating) return;

    final activeSource = _sources.isNotEmpty && _currentSourceIndex < _sources.length
        ? _sources[_currentSourceIndex]
        : _sources.first;

    String? targetDocId;
    if (activeSource.type == 'document') {
      targetDocId = activeSource.id;
    } else {
      // If in "Focus Oggi", target the first available todo document
      final docSource = _sources.where((s) => s.type == 'document').firstOrNull;
      targetDocId = docSource?.id;
    }

    if (targetDocId == null) {
      // Try to create or find document
      try {
        final currentContext = ContextManager().currentContext;
        final docs = await DocumentService().getDocumentsForContext(currentContext, 'todo');
        if (docs.isNotEmpty) {
          targetDocId = docs.first.id;
        }
      } catch (_) {}
    }

    if (targetDocId == null) return;

    setState(() => _isCreating = true);

    try {
      final now = DateTime.now();
      final newTask = Task.create(
        documentId: targetDocId,
        title: title,
        priority: activeSource.type == 'focus_today' ? TaskPriority.high : null,
        dueDate: activeSource.type == 'focus_today' ? DateTime(now.year, now.month, now.day, 23, 59) : null,
      );

      await TaskService().createTask(newTask);
      _taskController.clear();
      _taskFocusNode.unfocus();
    } catch (e) {
      debugPrint('Error quick adding task: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  void didUpdateWidget(FocusTasksWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.def.customProps != widget.def.customProps) {
      _loadSources();
    }
  }

  Future<void> _loadSources() async {
    final sources = <_TaskFilterSource>[
      const _TaskFilterSource(
        id: 'focus_today',
        title: 'Focus Oggi',
        type: 'focus_today',
        icon: Icons.bolt,
        color: Color(0xFFF59E0B),
      ),
    ];

    try {
      final currentContext = ContextManager().currentContext;
      final docs = await DocumentService().getDocumentsForContext(currentContext, 'todo');
      for (final doc in docs) {
        sources.add(_TaskFilterSource(
          id: doc.id,
          title: doc.title,
          type: 'document',
          icon: Icons.checklist_rounded,
          color: const Color(0xFF6366F1),
        ));
      }
    } catch (e) {
      debugPrint('Error loading task sources: $e');
    }

    if (mounted) {
      setState(() {
        _sources = sources;
        final customProps = widget.def.customProps;
        if (customProps != null) {
          final requestedDocId = customProps['documentId'] as String?;
          if (requestedDocId != null) {
            final idx = _sources.indexWhere((s) => s.type == 'document' && s.id == requestedDocId);
            if (idx != -1) _currentSourceIndex = idx;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSource = _sources.isNotEmpty && _currentSourceIndex < _sources.length
        ? _sources[_currentSourceIndex]
        : _sources.first;

    return StreamBuilder<List<Task>>(
      stream: _taskStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final allTasks = snapshot.data ?? [];

        List<Task> flattenTasks(List<Task> tasks) {
          List<Task> flat = [];
          for (var task in tasks) {
            flat.add(task);
            if (task.subtasks != null) {
              flat.addAll(flattenTasks(task.subtasks!));
            }
          }
          return flat;
        }

        final flatTasks = flattenTasks(allTasks);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        var displayTasks = flatTasks.where((task) {
          if (task.status == TaskStatus.completed) return false;

          if (activeSource.type == 'document') {
            return task.documentId == activeSource.id;
          }

          // Default: Focus Oggi (urgent or due today)
          bool isUrgentOrHigh = task.priority == TaskPriority.urgent || task.priority == TaskPriority.high;
          bool isDueTodayOrOverdue = false;

          if (task.dueDate != null) {
            final dueDate = task.dueDate!.toLocal();
            final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
            if (dueDay.isBefore(today) || dueDay.isAtSameMomentAs(today)) {
              isDueTodayOrOverdue = true;
            }
          }

          return isUrgentOrHigh || isDueTodayOrOverdue;
        }).toList();

        displayTasks.sort((a, b) {
          final pA = a.priority?.index ?? 99;
          final pB = b.priority?.index ?? 99;
          if (pA != pB) return pA.compareTo(pB);
          if (a.dueDate != null && b.dueDate != null) {
            return a.dueDate!.compareTo(b.dueDate!);
          }
          if (a.dueDate != null) return -1;
          if (b.dueDate != null) return 1;
          return 0;
        });

        if (displayTasks.length > 5) {
          displayTasks = displayTasks.sublist(0, 5);
        }

        return BaseListWidget<Task>(
          heroTag: widget.def.id,
          isLoading: isLoading,
          onExpand: () {
            GoRouter.of(context).push('/space/tasks', extra: {'heroTag': widget.def.id});
          },
          currentSource: activeSource.title,
          color: activeSource.color,
          icon: activeSource.icon,
          onPreviousSource: () {
            if (_sources.length > 1) {
              setState(() {
                _currentSourceIndex = (_currentSourceIndex - 1) < 0
                    ? _sources.length - 1
                    : _currentSourceIndex - 1;
              });
            }
          },
          onNextSource: () {
            if (_sources.length > 1) {
              setState(() {
                _currentSourceIndex = (_currentSourceIndex + 1) % _sources.length;
              });
            }
          },
          items: displayTasks,
          emptyMessage: 'Nessun task in questa lista 🎉',
          quickActionRow: Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  color: activeSource.color.withOpacity(0.7),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    focusNode: _taskFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: activeSource.type == 'focus_today' ? 'Nuovo task per oggi...' : 'Aggiungi task...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _quickAddTask,
                    onChanged: (text) => setState(() {}),
                  ),
                ),
                if (_isCreating)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: activeSource.color),
                  )
                else if (_taskController.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: () => _quickAddTask(_taskController.text),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: activeSource.color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
          itemBuilder: (context, task, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        await TaskService().completeTask(task.id);
                      } catch (e) {
                        debugPrint('Error completing task: $e');
                      }
                    },
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.priority != null)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: task.priority!.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
