import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/service/task_service.dart';

class FocusTasksWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const FocusTasksWidget({super.key, required this.def});

  @override
  State<FocusTasksWidget> createState() => _FocusTasksWidgetState();
}

class _FocusTasksWidgetState extends State<FocusTasksWidget> {
  late Stream<List<Task>> _taskStream;

  @override
  void initState() {
    super.initState();
    _taskStream = getIt<TaskRepository>().watchAll();
  }

  @override
  Widget build(BuildContext context) {
    return BentoWidgetContainer(
      isLoading: false,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text(
                  'FOCUS OGGI',
                  style: TextStyle(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Task>>(
                stream: _taskStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
                  }

                  final allTasks = snapshot.data ?? [];
                  
                  // Flatten tree to just a flat list of tasks for the dashboard
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

                  // Sort by priority then due date
                  focusTasks.sort((a, b) {
                    // Priority sorting (urgent first)
                    final pA = a.priority?.index ?? 99;
                    final pB = b.priority?.index ?? 99;
                    if (pA != pB) return pA.compareTo(pB);
                    
                    // Date sorting
                    if (a.dueDate != null && b.dueDate != null) {
                      return a.dueDate!.compareTo(b.dueDate!);
                    }
                    if (a.dueDate != null) return -1;
                    if (b.dueDate != null) return 1;
                    return 0;
                  });

                  if (focusTasks.isEmpty) {
                    return const Center(
                      child: Text('Nessun task urgente\no in scadenza 🎉', style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: focusTasks.length > 5 ? 5 : focusTasks.length, // max 5 tasks
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final task = focusTasks[index];
                      return _buildTaskRow(task);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskRow(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              try {
                await TaskService().completeTask(task.id);
              } catch (e) {
                // Ignore silent error
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
  }
}
