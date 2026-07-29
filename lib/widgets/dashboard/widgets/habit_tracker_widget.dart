import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class HabitTrackerWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const HabitTrackerWidget({super.key, required this.def});

  @override
  State<HabitTrackerWidget> createState() => _HabitTrackerWidgetState();
}

class _HabitTrackerWidgetState extends State<HabitTrackerWidget> {
  // Placeholder routines for UI demonstration
  final List<Color> _routineColors = [
    const Color(0xFF10B981), // Green
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF59E0B), // Orange
  ];

  @override
  Widget build(BuildContext context) {
    // Determine the widget's layout size based on the bento size
    final int crossAxisCellCount = widget.def.size.crossAxisCellCount;

    return BentoWidgetContainer(
      isLoading: false,
      onExpand: () {
        GoRouter.of(context).push('/habits');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              const Color(0xFF8B5CF6).withValues(alpha: 0.02),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.loop, color: Color(0xFF8B5CF6), size: 16),
                const SizedBox(width: 6),
                Text(
                  'ROUTINE',
                  style: TextStyle(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: crossAxisCellCount >= 4
                  ? _buildContributionHeatmap() // GitHub-style heatmap for wider widgets
                  : _buildWeeklyStacks(), // Stacked weekly items for smaller widgets
            ),
          ],
        ),
      ),
    );
  }

  // A stack of weekly progress bars for up to 4 routines
  Widget _buildWeeklyStacks() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (routineIndex) {
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _routineColors[routineIndex],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (dayIndex) {
                  // Randomize completion for placeholder
                  final bool isCompleted = (dayIndex * routineIndex) % 3 != 0;
                  return Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? _routineColors[routineIndex]
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  // A GitHub style contribution heatmap spanning 5 weeks
  Widget _buildContributionHeatmap() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(8, (weekIndex) { // 8 weeks for wider view
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (dayIndex) {
                // Mock multiple routines completing on the same day using gradients
                final int routinesCompleted = ((weekIndex + dayIndex) % 5);
                
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: routinesCompleted == 0
                        ? Colors.white.withValues(alpha: 0.05)
                        : null,
                    gradient: routinesCompleted > 0
                        ? LinearGradient(
                            colors: _routineColors.sublist(0, routinesCompleted.clamp(1, 4)),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
