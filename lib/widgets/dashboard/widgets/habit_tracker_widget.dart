import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final List<Color> _routineColors = const [
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
  ];

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

        return BentoWidgetContainer(
          heroTag: widget.def.id,
          isLoading: isLoading,
          onExpand: () {
            GoRouter.of(context).push('/space/time_management/routines');
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.12),
                  const Color(0xFF8B5CF6).withOpacity(0.02),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.loop_rounded, color: Color(0xFF8B5CF6), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.def.customProps?['title'] as String? ?? 'ROUTINE',
                          style: TextStyle(
                            color: const Color(0xFF8B5CF6).withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    if (routines.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${routines.length} attive',
                          style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: routines.isEmpty
                      ? Center(
                          child: InkWell(
                            onTap: () => GoRouter.of(context).push('/space/time_management/create_routine'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_alarm_rounded, color: Colors.white.withOpacity(0.4), size: 24),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Nessuna routine attiva\nTocca per crearne una',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: routines.length,
                          separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 10),
                          itemBuilder: (context, index) {
                            final routine = routines[index];
                            final color = _routineColors[index % _routineColors.length];

                            return Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        routine.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (routine.description != null && routine.description!.isNotEmpty)
                                        Text(
                                          routine.description!,
                                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
