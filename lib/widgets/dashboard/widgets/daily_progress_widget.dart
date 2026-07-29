import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/di/service_locator.dart';

class DailyProgressWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const DailyProgressWidget({super.key, required this.def});

  @override
  State<DailyProgressWidget> createState() => _DailyProgressWidgetState();
}

class _DailyProgressWidgetState extends State<DailyProgressWidget> {
  late Stream<List<Task>> _taskStream;

  @override
  void initState() {
    super.initState();
    _taskStream = getIt<TaskRepository>().watchAll();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: _taskStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return BentoWidgetContainer(
            heroTag: widget.def.id,
            isLoading: true,
            onExpand: () {
              GoRouter.of(context).push('/focus', extra: {'heroTag': widget.def.id});
            },
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
          );
        }

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
          
          int totalToday = 0;
          int completedToday = 0;
          
          for (var task in flatTasks) {
            bool isDueToday = false;
            if (task.dueDate != null) {
              final dueDate = task.dueDate!.toLocal();
              final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
              if (dueDay.isAtSameMomentAs(today)) {
                isDueToday = true;
              }
            }
            
            bool completedRecently = false;
            if (task.status == TaskStatus.completed && task.completedAt != null) {
              final compDate = task.completedAt!.toLocal();
              final compDay = DateTime(compDate.year, compDate.month, compDate.day);
              if (compDay.isAtSameMomentAs(today)) {
                completedRecently = true;
              }
            }

            if (isDueToday || completedRecently) {
              totalToday++;
              if (task.status == TaskStatus.completed) {
                completedToday++;
              }
            }
          }

          final double progress = totalToday > 0 ? (completedToday / totalToday) : 0.0;

          return BentoWidgetContainer(
            heroTag: widget.def.id,
            isLoading: false,
            onExpand: () {
              GoRouter.of(context).push('/focus', extra: {'heroTag': widget.def.id});
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 12,
                  left: 12,
                  child: const Icon(Icons.track_changes, color: Color(0xFF10B981), size: 16),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          ),
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            color: const Color(0xFF10B981),
                            backgroundColor: Colors.transparent,
                          ),
                          Center(
                            child: Text(
                              '$completedToday/$totalToday',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PROGRESSO OGGI',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
      },
    );
  }
}
