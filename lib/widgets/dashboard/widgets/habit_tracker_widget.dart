import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/routine.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class HabitTrackerWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const HabitTrackerWidget({super.key, required this.def});

  @override
  State<HabitTrackerWidget> createState() => _HabitTrackerWidgetState();
}

class _HabitTrackerWidgetState extends State<HabitTrackerWidget> {
  Set<String> _completedTodayIds = {};

  @override
  void initState() {
    super.initState();
    _loadTodayCompletions();
  }

  String get _todayKey {
    final now = DateTime.now();
    return 'habit_done_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTodayCompletions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_todayKey) ?? [];
      if (mounted) {
        setState(() {
          _completedTodayIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleHabit(String id) async {
    HapticFeedback.lightImpact();
    setState(() {
      if (_completedTodayIds.contains(id)) {
        _completedTodayIds.remove(id);
      } else {
        _completedTodayIds.add(id);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_todayKey, _completedTodayIds.toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final specificRoutineId = widget.def.customProps?['routineId'] as String?;

    return StreamBuilder<List<RoutineTemplate>>(
      stream: TimeManagementService().routinesStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final allRoutines = snapshot.data ?? [];
        final routines = specificRoutineId != null
            ? allRoutines.where((r) => r.id == specificRoutineId).toList()
            : allRoutines;

        final size = widget.def.size;
        final isHeight1 = size.mainAxisCellCount <= 1;
        final isWide = size.crossAxisCellCount >= 3;
        final isHeight3 = size.mainAxisCellCount == 3;

        void navigateToRoutines() {
          GoRouter.of(context).push('/space/time_management/routines');
        }

        return BentoWidgetContainer(
          heroTag: widget.def.id,
          size: size,
          isLoading: isLoading,
          onTap: navigateToRoutines,
          onExpand: navigateToRoutines,
          child: isHeight1
              ? _buildMiniBanner(routines)
              : isWide
                  ? _buildPanoramicView(routines, navigateToRoutines)
                  : isHeight3
                      ? _buildHeight3View(routines, navigateToRoutines)
                      : _buildCompactView(routines, navigateToRoutines),
        );
      },
    );
  }

  Widget _buildMiniBanner(List<RoutineTemplate> routines) {
    final completedCount = routines.where((r) => _completedTodayIds.contains(r.id)).length;

    return Padding(
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
                  color: const Color(0xFF8B5CF6).withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.loop_rounded, color: Color(0xFF8B5CF6), size: 13),
              ),
              const SizedBox(width: 8),
              Text(
                (widget.def.customProps?['title'] as String? ?? 'ROUTINE').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
            ),
            child: Text(
              routines.isEmpty ? 'Nessuna' : '$completedCount/${routines.length} oggi',
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanoramicView(List<RoutineTemplate> routines, VoidCallback onNavigate) {
    const weekLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    final todayWeekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final topRoutines = routines.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.loop_rounded, color: Color(0xFF8B5CF6), size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'WEEKLY MATRIX',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                '${_completedTodayIds.length}/${routines.length} OGGI',
                style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: routines.isEmpty
                ? _buildEmptyState()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: topRoutines.map((routine) {
                      final isDoneToday = _completedTodayIds.contains(routine.id);

                      return Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              routine.name,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (dayIndex) {
                                final dayNum = dayIndex + 1;
                                final isCurrentDay = dayNum == todayWeekday;
                                final isPast = dayNum < todayWeekday;

                                Color dotColor;
                                if (isCurrentDay) {
                                  dotColor = isDoneToday ? const Color(0xFF10B981) : Colors.white24;
                                } else if (isPast) {
                                  dotColor = const Color(0xFF8B5CF6).withOpacity(0.4);
                                } else {
                                  dotColor = Colors.white.withOpacity(0.06);
                                }

                                return GestureDetector(
                                  onTap: isCurrentDay ? () => _toggleHabit(routine.id) : null,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        weekLabels[dayIndex],
                                        style: TextStyle(
                                          color: isCurrentDay ? Colors.white : Colors.white24,
                                          fontSize: 8.5,
                                          fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        width: isCurrentDay ? 14 : 10,
                                        height: isCurrentDay ? 14 : 10,
                                        decoration: BoxDecoration(
                                          color: dotColor,
                                          shape: BoxShape.circle,
                                          border: isCurrentDay
                                              ? Border.all(
                                                  color: isDoneToday ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                                                  width: 1.5,
                                                )
                                              : null,
                                        ),
                                        child: isCurrentDay && isDoneToday
                                            ? const Icon(Icons.check, size: 9, color: Colors.black)
                                            : null,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeight3View(List<RoutineTemplate> routines, VoidCallback onNavigate) {
    final completedCount = routines.where((r) => _completedTodayIds.contains(r.id)).length;
    final total = routines.length;
    final progress = total > 0 ? (completedCount / total).clamp(0.0, 1.0) : 0.0;
    final topRoutines = routines.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.loop_rounded, color: Color(0xFF8B5CF6), size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'ROUTINE & ABITUDINI',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$completedCount di $total',
                  style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Livello 1: Barra di completamento globale
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    color: progress >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: progress >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 0.8, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 6),

          // Livello 2: Routine con cerchietti interattivi
          Expanded(
            child: routines.isEmpty
                ? _buildEmptyState()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: topRoutines.map((routine) {
                      final isDone = _completedTodayIds.contains(routine.id);

                      return InkWell(
                        onTap: () => _toggleHabit(routine.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDone ? const Color(0xFF10B981).withOpacity(0.08) : const Color(0xFF18181D),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDone ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDone ? const Color(0xFF10B981) : Colors.transparent,
                                  border: Border.all(
                                    color: isDone ? const Color(0xFF10B981) : Colors.white38,
                                    width: 1.5,
                                  ),
                                ),
                                child: isDone
                                    ? const Icon(Icons.check, size: 11, color: Colors.black)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  routine.name,
                                  style: TextStyle(
                                    color: isDone ? Colors.white60 : Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                isDone ? Icons.done_all_rounded : Icons.radio_button_unchecked_rounded,
                                size: 14,
                                color: isDone ? const Color(0xFF10B981) : Colors.white24,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(List<RoutineTemplate> routines, VoidCallback onNavigate) {
    final completedCount = routines.where((r) => _completedTodayIds.contains(r.id)).length;
    final top2 = routines.take(2).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.loop_rounded, color: Color(0xFF8B5CF6), size: 13),
                  const SizedBox(width: 6),
                  const Text(
                    'ROUTINE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$completedCount/${routines.length}',
                  style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (routines.isEmpty)
            Expanded(child: _buildEmptyState())
          else
            ...top2.map((routine) {
              final isDone = _completedTodayIds.contains(routine.id);

              return InkWell(
                onTap: () => _toggleHabit(routine.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFF10B981).withOpacity(0.08) : const Color(0xFF18181D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDone ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? const Color(0xFF10B981) : Colors.transparent,
                          border: Border.all(
                            color: isDone ? const Color(0xFF10B981) : Colors.white38,
                            width: 1.5,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, size: 10, color: Colors.black)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          routine.name,
                          style: TextStyle(
                            color: isDone ? Colors.white60 : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: InkWell(
        onTap: () => GoRouter.of(context).push('/space/time_management/create_routine'),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_alarm_rounded, color: Colors.white.withOpacity(0.4), size: 20),
              const SizedBox(height: 4),
              Text(
                'Tocca per creare una routine',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
