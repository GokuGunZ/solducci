import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Stream<List<Task>>? _taskStream;
  ExpenseContext? _lastContext;
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

  StreamSubscription? _docSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _updateTaskStream();
      _loadSources(currentContext);

      _docSubscription?.cancel();
      _docSubscription = DocumentService()
          .watchDocumentsForContext(currentContext, 'todo')
          .listen((_) => _loadSources(currentContext));
    }
  }

  void _updateTaskStream() {
    final activeSource = _sources.isNotEmpty && _currentSourceIndex < _sources.length
        ? _sources[_currentSourceIndex]
        : _sources.first;

    if (activeSource.type == 'document') {
      _taskStream = TaskService()
          .getTasksForDocument(activeSource.id)
          .asBroadcastStream();
    } else {
      final currentContext = _lastContext ?? ContextManager().currentContext;
      _taskStream = getIt<TaskRepository>()
          .watchByContext(currentContext)
          .asBroadcastStream();
    }
  }

  final Set<String> _completingTaskIds = {};
  final Set<String> _collapsedTaskIds = {};

  bool _isTaskExpanded(Task task) {
    if (!task.hasSubtasks) return false;
    return !_collapsedTaskIds.contains(task.id);
  }

  void _toggleTaskExpanded(String taskId) {
    setState(() {
      if (_collapsedTaskIds.contains(taskId)) {
        _collapsedTaskIds.remove(taskId);
      } else {
        _collapsedTaskIds.add(taskId);
      }
    });
  }

  Future<void> _toggleTask(Task task) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _completingTaskIds.add(task.id);
    });

    try {
      if (task.status == TaskStatus.completed) {
        await TaskService().uncompleteTask(task.id);
      } else {
        // Complete any incomplete subtasks first to avoid validation errors
        if (task.subtasks != null && task.subtasks!.isNotEmpty) {
          final incompleteSubs = task.subtasks!.where((s) => s.status != TaskStatus.completed).toList();
          for (final sub in incompleteSubs) {
            setState(() => _completingTaskIds.add(sub.id));
            try {
              await TaskService().completeTask(sub.id);
            } catch (_) {}
          }
        }
        await TaskService().completeTask(task.id);
      }
    } catch (e) {
      debugPrint('Error toggling task completion: $e');
    } finally {
      if (mounted) {
        setState(() {
          _completingTaskIds.remove(task.id);
          if (task.subtasks != null) {
            for (final sub in task.subtasks!) {
              _completingTaskIds.remove(sub.id);
            }
          }
        });
      }
    }
  }

  Future<void> _toggleSubtask(Task subtask, Task parentTask) async {
    HapticFeedback.lightImpact();
    setState(() {
      _completingTaskIds.add(subtask.id);
    });

    try {
      if (subtask.status == TaskStatus.completed) {
        await TaskService().uncompleteTask(subtask.id);
      } else {
        await TaskService().completeTask(subtask.id);
      }
    } catch (e) {
      debugPrint('Error toggling subtask completion: $e');
    } finally {
      if (mounted) {
        setState(() {
          _completingTaskIds.remove(subtask.id);
        });
      }
    }
  }

  Future<void> _showAddSubtaskDialog(BuildContext context, Task parentTask) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: Color(0xFF818CF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Nuovo Sotto-Elemento',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aggiungi a: ${parentTask.title}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nome del sotto-elemento...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF818CF8)),
                  ),
                ),
                onSubmitted: (val) {
                  Navigator.of(ctx).pop(val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Aggiungi', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      final subTitle = result.trim();
      try {
        final newSubtask = Task.create(
          documentId: parentTask.documentId,
          parentTaskId: parentTask.id,
          title: subTitle,
        );
        await TaskService().createTask(newSubtask);
        if (mounted) {
          setState(() {
            _collapsedTaskIds.remove(parentTask.id);
          });
        }
      } catch (e) {
        debugPrint('Error creating subtask: $e');
      }
    }
  }

  @override
  void dispose() {
    _docSubscription?.cancel();
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
        final currentContext = _lastContext ?? ContextManager().currentContext;
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
      _loadSources(_lastContext);
    }
  }

  Future<void> _loadSources([ExpenseContext? contextOverride]) async {
    final currentContext = contextOverride ?? _lastContext ?? ContextManager().currentContext;
    final contextDocs = await DocumentService().getDocumentsForContext(currentContext, 'todo');
    List<Document> userDocs = [];
    try {
      userDocs = await DocumentService().getDocumentsByType('todo').first.timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => [],
      );
    } catch (_) {}

    final Map<String, Document> uniqueDocs = {};
    for (final doc in contextDocs) {
      uniqueDocs[doc.id] = doc;
    }
    for (final doc in userDocs) {
      uniqueDocs[doc.id] = doc;
    }

    final allSources = <_TaskFilterSource>[
      const _TaskFilterSource(
        id: 'focus_today',
        title: 'Focus Oggi',
        type: 'focus_today',
        icon: Icons.bolt,
        color: Color(0xFFF59E0B),
      ),
    ];

    for (final doc in uniqueDocs.values) {
      final isGroupDoc = doc.groupId != null;
      final displayTitle = isGroupDoc &&
              (doc.title.toLowerCase() == 'my tasks' ||
                  doc.title.toLowerCase() == 'le mie task')
          ? 'Task di Gruppo'
          : doc.title;

      allSources.add(_TaskFilterSource(
        id: doc.id,
        title: displayTitle,
        type: 'document',
        icon: isGroupDoc ? Icons.group_rounded : Icons.checklist_rounded,
        color: isGroupDoc ? const Color(0xFF10B981) : const Color(0xFF6366F1),
      ));
    }

    // Filter by selectedSourceIds if configured
    final customProps = widget.def.customProps;
    final rawSelected = customProps?['selectedSourceIds'] as List?;
    final selectedIds = rawSelected?.map((e) => e.toString()).toSet();

    List<_TaskFilterSource> filtered;
    if (selectedIds != null && selectedIds.isNotEmpty) {
      filtered = allSources.where((s) {
        if (s.type == 'focus_today') {
          return selectedIds.contains('focus_today');
        } else {
          return selectedIds.contains('doc_${s.id}') || selectedIds.contains(s.id);
        }
      }).toList();
      if (filtered.isEmpty) filtered = allSources;
    } else {
      filtered = allSources;
    }

    if (mounted) {
      setState(() {
        _sources = filtered;
        if (_currentSourceIndex >= _sources.length) {
          _currentSourceIndex = 0;
        }
        _updateTaskStream();
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

        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        bool isDueTodayOrOverdue(DateTime? date) {
          if (date == null) return false;
          final local = date.toLocal();
          final day = DateTime(local.year, local.month, local.day);
          return day.isBefore(today) || day.isAtSameMomentAs(today);
        }

        bool isTaskMatchingFocus(Task task) {
          if (task.status == TaskStatus.completed) return false;
          // Filter out tasks assigned to someone else
          if (task.assignedTo != null && currentUserId != null && task.assignedTo != currentUserId) {
            return false;
          }
          final isUrgentOrHigh = task.priority == TaskPriority.urgent || task.priority == TaskPriority.high;
          final isDue = isDueTodayOrOverdue(task.dueDate);
          return isUrgentOrHigh || isDue;
        }

        var displayTasks = allTasks.where((task) {
          if (activeSource.type == 'document') {
            if (task.documentId != activeSource.id) return false;
            // If the root task is completed and all its subtasks (if any) are completed, filter it out
            if (task.status == TaskStatus.completed) {
              final hasActiveSub = task.subtasks?.any((s) => s.status != TaskStatus.completed) ?? false;
              if (!hasActiveSub) return false;
            }
            return true;
          }

          // Focus Oggi (urgent or due today)
          final selfMatches = isTaskMatchingFocus(task);
          final subMatches = task.subtasks?.any((s) => isTaskMatchingFocus(s)) ?? false;
          return selfMatches || subMatches;
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

        return BaseListWidget<Task>(
          heroTag: widget.def.id,
          size: widget.def.size,
          isLoading: isLoading,
          onExpand: () {
            if (activeSource.type == 'document') {
              GoRouter.of(context).push('/space/tasks/${activeSource.id}', extra: {'heroTag': widget.def.id});
            } else {
              GoRouter.of(context).push('/space/tasks', extra: {'heroTag': widget.def.id});
            }
          },
          currentSource: activeSource.title,
          currentSourceIndex: _currentSourceIndex,
          totalSources: _sources.length,
          color: activeSource.color,
          icon: activeSource.icon,
          onPreviousSource: () {
            if (_sources.length > 1) {
              setState(() {
                _currentSourceIndex = (_currentSourceIndex - 1) < 0
                    ? _sources.length - 1
                    : _currentSourceIndex - 1;
                _updateTaskStream();
              });
            }
          },
          onNextSource: () {
            if (_sources.length > 1) {
              setState(() {
                _currentSourceIndex = (_currentSourceIndex + 1) % _sources.length;
                _updateTaskStream();
              });
            }
          },
          items: displayTasks,
          emptyMessage: 'Nessun task in questa lista 🎉',
          emptySubtitle: 'Sei in pari con tutte le tue attività',
          emptyActionLabel: 'Aggiungi Task',
          onEmptyAction: () => _taskFocusNode.requestFocus(),
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
            final isCompleting = _completingTaskIds.contains(task.id);
            final isParentCompleted = task.status == TaskStatus.completed;
            final isDone = isCompleting || isParentCompleted;
            final hasSubtasks = task.hasSubtasks;
            final isExpanded = _isTaskExpanded(task);

            final subtasks = task.subtasks ?? [];
            final completedSubCount = subtasks.where((s) => s.status == TaskStatus.completed).length;
            final totalSubCount = subtasks.length;
            final allSubsCompleted = totalSubCount > 0 && completedSubCount == totalSubCount;

            final isAssignedToOther = task.assignedTo != null &&
                currentUserId != null &&
                task.assignedTo != currentUserId;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Checkbox
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggleTask(task),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? activeSource.color : Colors.transparent,
                            border: Border.all(
                              color: isDone ? activeSource.color : Colors.white54,
                              width: 1.5,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check, size: 13, color: Colors.black)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Title
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: hasSubtasks ? () => _toggleTaskExpanded(task.id) : () => _toggleTask(task),
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: isDone ? Colors.white38 : Colors.white,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              fontSize: 13,
                              fontWeight: hasSubtasks ? FontWeight.w600 : FontWeight.normal,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Assigned to someone else indicator
                      if (isAssignedToOther) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.person_outline, size: 11, color: Colors.white60),
                        ),
                      ],

                      // Priority Dot
                      if (task.priority != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: task.priority!.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],

                      // Subtasks Pill / Counter
                      if (hasSubtasks) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _toggleTaskExpanded(task.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: allSubsCompleted
                                  ? const Color(0xFF10B981).withOpacity(0.18)
                                  : activeSource.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: allSubsCompleted
                                    ? const Color(0xFF10B981).withOpacity(0.4)
                                    : activeSource.color.withOpacity(0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$completedSubCount/$totalSubCount',
                                  style: TextStyle(
                                    color: allSubsCompleted ? const Color(0xFF34D399) : activeSource.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                  size: 13,
                                  color: allSubsCompleted ? const Color(0xFF34D399) : activeSource.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Add Subtask button (+)
                      const SizedBox(width: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showAddSubtaskDialog(context, task),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 13, color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtasks section (if expanded)
                if (hasSubtasks && isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, top: 2.0, bottom: 4.0),
                    child: Column(
                      children: subtasks.map((sub) {
                        final isSubCompleting = _completingTaskIds.contains(sub.id);
                        final isSubDone = isSubCompleting || sub.status == TaskStatus.completed;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            children: [
                              // Guide line / connector icon
                              const Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                size: 13,
                                color: Colors.white24,
                              ),
                              const SizedBox(width: 6),

                              // Subtask Checkbox
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _toggleSubtask(sub, task),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSubDone ? activeSource.color.withOpacity(0.8) : Colors.transparent,
                                    border: Border.all(
                                      color: isSubDone ? activeSource.color : Colors.white38,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: isSubDone
                                      ? const Icon(Icons.check, size: 10, color: Colors.black)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Subtask Title
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _toggleSubtask(sub, task),
                                  child: Text(
                                    sub.title,
                                    style: TextStyle(
                                      color: isSubDone ? Colors.white30 : Colors.white70,
                                      decoration: isSubDone ? TextDecoration.lineThrough : null,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              // Subtask priority dot
                              if (sub.priority != null) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: sub.priority!.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
