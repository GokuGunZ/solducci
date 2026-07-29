import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/service/task_service.dart';

import 'package:solducci/widgets/dashboard/data_source_switcher_header.dart';

import 'package:solducci/widgets/dashboard/base_list_widget.dart';

class FocusTasksWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const FocusTasksWidget({super.key, required this.def});

  @override
  State<FocusTasksWidget> createState() => _FocusTasksWidgetState();
}

class _FocusTasksWidgetState extends State<FocusTasksWidget> {
  late Stream<List<Task>> _taskStream;
  final List<String> _sources = ['Focus Oggi', 'Lavoro', 'Casa', 'Progetti Personali'];
  int _currentSourceIndex = 0;

  @override
  void initState() {
    super.initState();
    _taskStream = getIt<TaskRepository>().watchAll().asBroadcastStream();
    
    if (widget.def.customProps != null && widget.def.customProps!['source'] != null) {
      final initialSource = widget.def.customProps!['source'] as String;
      if (initialSource == 'Tutte le attività') {
         _currentSourceIndex = 0;
      } else {
        if (!_sources.contains(initialSource)) {
          _sources.insert(1, initialSource);
        }
        _currentSourceIndex = _sources.indexOf(initialSource);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        
        var focusTasks = flatTasks.where((task) {
          if (task.status == TaskStatus.completed) return false;
          
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

        focusTasks.sort((a, b) {
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

        // Limit to top 5
        final displayTasks = focusTasks.length > 5 ? focusTasks.sublist(0, 5) : focusTasks;

        return BaseListWidget<Task>(
          heroTag: widget.def.id,
          isLoading: isLoading,
          onExpand: () {
            GoRouter.of(context).push('/space/tasks', extra: {'heroTag': widget.def.id});
          },
          currentSource: _sources[_currentSourceIndex],
          color: const Color(0xFFF59E0B),
          icon: Icons.bolt,
          onPreviousSource: () {
            setState(() {
              _currentSourceIndex = (_currentSourceIndex - 1) < 0 ? _sources.length - 1 : _currentSourceIndex - 1;
            });
          },
          onNextSource: () {
            setState(() {
              _currentSourceIndex = (_currentSourceIndex + 1) % _sources.length;
            });
          },
          items: displayTasks,
          emptyMessage: 'Nessun task urgente\no in scadenza 🎉',
          itemBuilder: (context, task, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        await TaskService().completeTask(task.id);
                      } catch (e) {}
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
