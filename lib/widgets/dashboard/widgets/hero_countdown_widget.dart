import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/time_scenario.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class HeroCountdownWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const HeroCountdownWidget({super.key, required this.def});

  @override
  State<HeroCountdownWidget> createState() => _HeroCountdownWidgetState();
}

class _HeroCountdownWidgetState extends State<HeroCountdownWidget> {
  late Stream<List<TimeScenario>> _scenarioStream;

  @override
  void initState() {
    super.initState();
    _scenarioStream = TimeManagementService().timeScenariosStream;
  }

  @override
  Widget build(BuildContext context) {
    final customScenarioId = widget.def.customProps?['scenarioId'] as String?;

    return StreamBuilder<List<TimeScenario>>(
      stream: _scenarioStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final scenarios = snapshot.data ?? [];
        final now = DateTime.now();

        TimeScenario? targetScenario;

        if (customScenarioId != null && customScenarioId.isNotEmpty) {
          targetScenario = scenarios.where((s) => s.id == customScenarioId).firstOrNull;
        }

        // If not found or not specified, pick the closest future scenario
        if (targetScenario == null) {
          final upcoming = scenarios
              .where((s) => s.startDate.isAfter(now) || (s.endDate != null && s.endDate!.isAfter(now)))
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

          if (upcoming.isNotEmpty) {
            targetScenario = upcoming.first;
          } else if (scenarios.isNotEmpty) {
            // Fallback to most recent scenario
            targetScenario = scenarios.first;
          }
        }

        return BentoWidgetContainer(
          heroTag: widget.def.id,
          isLoading: isLoading,
          onExpand: () {
            if (targetScenario != null) {
              final type = targetScenario.scenarioType.toLowerCase();
              if (type == 'trip') {
                GoRouter.of(context).push('/space/time_management/scenario/trip/${targetScenario.id}');
              } else if (type == 'event') {
                GoRouter.of(context).push('/space/time_management/scenario/event/${targetScenario.id}');
              } else if (type == 'outing') {
                GoRouter.of(context).push('/space/time_management/scenario/outing/${targetScenario.id}');
              } else {
                GoRouter.of(context).push('/space/time_management');
              }
            } else {
              GoRouter.of(context).push('/space/time_management');
            }
          },
          child: targetScenario == null
              ? _buildEmptyState(context)
              : _buildCountdownContent(context, targetScenario, now),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, color: Color(0xFF818CF8), size: 22),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nessun evento futuro',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tocca per creare un evento o viaggio',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownContent(BuildContext context, TimeScenario scenario, DateTime now) {
    final diff = scenario.startDate.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;

    final isPast = diff.isNegative;
    final isInProgress = isPast && scenario.endDate != null && scenario.endDate!.isAfter(now);

    final color = _getScenarioColor(scenario.scenarioType);
    final icon = _getScenarioIcon(scenario.scenarioType);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 130;

        return Stack(
          children: [
            // Ambient neon glow in top right
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header: Type badge & date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              scenario.scenarioType.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM').format(scenario.startDate),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Center: Title & Location
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.title,
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (scenario.location != null && scenario.location!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, color: Colors.white38, size: 11),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                scenario.location!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Bottom: Countdown value
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (isInProgress) ...[
                        const Text(
                          'IN CORSO',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ] else if (isPast) ...[
                        const Text(
                          'CONCLUSO',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '$days',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 24 : 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          days == 1 ? 'GIORNO' : 'GIORNI',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (days < 3) ...[
                          const SizedBox(width: 6),
                          Text(
                            'e $hours h',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getScenarioColor(String type) {
    switch (type.toLowerCase()) {
      case 'trip':
        return const Color(0xFF38BDF8); // Sky blue
      case 'event':
        return const Color(0xFFF472B6); // Pink
      case 'outing':
        return const Color(0xFFFBBF24); // Amber
      default:
        return const Color(0xFF818CF8); // Indigo
    }
  }

  IconData _getScenarioIcon(String type) {
    switch (type.toLowerCase()) {
      case 'trip':
        return Icons.flight_takeoff_rounded;
      case 'event':
        return Icons.celebration_rounded;
      case 'outing':
        return Icons.restaurant_rounded;
      default:
        return Icons.event_rounded;
    }
  }
}
