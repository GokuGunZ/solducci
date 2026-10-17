import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
import 'package:solducci/domain/repositories/task_repository.dart';
import 'package:solducci/core/di/service_locator.dart';

class DailyProgressWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const DailyProgressWidget({super.key, required this.def});

  @override
  State<DailyProgressWidget> createState() => _DailyProgressWidgetState();
}

class _DailyProgressWidgetState extends State<DailyProgressWidget> {
  Stream<List<Task>>? _taskStream;
  ExpenseContext? _lastContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _taskStream = getIt<TaskRepository>().watchByContext(currentContext);
    }
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

          final is1x1 = widget.def.size.crossAxisCellCount <= 1 && widget.def.size.mainAxisCellCount <= 1;
          final is2x1 = widget.def.size.crossAxisCellCount >= 2 && widget.def.size.mainAxisCellCount <= 1;

          return BentoWidgetContainer(
            heroTag: widget.def.id,
            size: widget.def.size,
            isLoading: false,
            onTap: () {
              GoRouter.of(context).push('/focus', extra: {'heroTag': widget.def.id});
            },
            onExpand: () {
              GoRouter.of(context).push('/focus', extra: {'heroTag': widget.def.id});
            },
            child: is1x1
                ? Center(
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 4.5,
                            color: const Color(0xFF10B981).withOpacity(0.15),
                          ),
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4.5,
                            strokeCap: StrokeCap.round,
                            color: const Color(0xFF10B981),
                            backgroundColor: Colors.transparent,
                          ),
                          Center(
                            child: Text(
                              '$completedToday/$totalToday',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : (is2x1
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 13),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'TASK DI OGGI',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 5,
                                      backgroundColor: Colors.white10,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$completedToday/$totalToday',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 12,
                            left: 12,
                            child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 68,
                                height: 68,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 7,
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                    ),
                                    CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 7,
                                      strokeCap: StrokeCap.round,
                                      color: const Color(0xFF10B981),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    Center(
                                      child: Text(
                                        '$completedToday/$totalToday',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'TASK DI OGGI',
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
                      )),
          );
      },
    );
  }
}
