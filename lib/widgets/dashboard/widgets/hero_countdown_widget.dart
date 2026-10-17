import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/time_scenario.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

class HeroCountdownWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const HeroCountdownWidget({super.key, required this.def});

  @override
  State<HeroCountdownWidget> createState() => _HeroCountdownWidgetState();
}

class _HeroCountdownWidgetState extends State<HeroCountdownWidget> {
  Stream<List<TimeScenario>>? _scenarioStream;
  ExpenseContext? _lastContext;
  int _currentScenarioIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _scenarioStream = TimeManagementService().watchTimeScenariosForContext(currentContext);
    }
  }

  double _calculateAdaptiveTitleFontSize(String title, {required bool isCompact}) {
    final baseSize = isCompact ? 13.5 : 15.0;
    final minSize = isCompact ? 10.5 : 12.0;
    if (title.length <= 14) return baseSize;
    final factor = 14.0 / title.length;
    return (baseSize * factor).clamp(minSize, baseSize);
  }

  @override
  Widget build(BuildContext context) {
    final selectedSourceIds = (widget.def.customProps?['selectedSourceIds'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toSet() ??
        {};
    final customScenarioId = widget.def.customProps?['scenarioId'] as String?;

    return StreamBuilder<List<TimeScenario>>(
      stream: _scenarioStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final scenarios = snapshot.data ?? [];
        final now = DateTime.now();

        List<TimeScenario> activeScenarios = [];

        if (selectedSourceIds.isNotEmpty) {
          activeScenarios = scenarios
              .where((s) => selectedSourceIds.contains('scenario_${s.id}') || selectedSourceIds.contains(s.id))
              .toList();
        } else if (customScenarioId != null && customScenarioId.isNotEmpty) {
          activeScenarios = scenarios.where((s) => s.id == customScenarioId).toList();
        } else {
          // Sort scenarios: upcoming first, then past
          final upcoming = scenarios
              .where((s) => s.startDate.isAfter(now) || (s.endDate != null && s.endDate!.isAfter(now)))
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          final past = scenarios
              .where((s) => s.startDate.isBefore(now) && (s.endDate == null || s.endDate!.isBefore(now)))
              .toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));
          activeScenarios = [...upcoming, ...past];
        }

        final safeIndex = _currentScenarioIndex.clamp(
          0,
          activeScenarios.isNotEmpty ? activeScenarios.length - 1 : 0,
        );
        final targetScenario = activeScenarios.isNotEmpty ? activeScenarios[safeIndex] : null;

        void nextScenario() {
          if (activeScenarios.length <= 1) return;
          setState(() {
            _currentScenarioIndex = (_currentScenarioIndex + 1) % activeScenarios.length;
          });
        }

        void previousScenario() {
          if (activeScenarios.length <= 1) return;
          setState(() {
            _currentScenarioIndex = (_currentScenarioIndex - 1 + activeScenarios.length) % activeScenarios.length;
          });
        }

        void navigateToScenario() {
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
        }

        return BentoWidgetContainer(
          heroTag: widget.def.id,
          size: widget.def.size,
          isLoading: isLoading,
          onTap: navigateToScenario,
          onExpand: navigateToScenario,
          child: targetScenario == null
              ? _buildEmptyState(context)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -150) {
                        nextScenario();
                      } else if (details.primaryVelocity! > 150) {
                        previousScenario();
                      }
                    }
                  },
                  child: _buildCountdownContent(
                    context,
                    targetScenario,
                    now,
                    currentIndex: safeIndex,
                    totalScenarios: activeScenarios.length,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return BentoEmptyState(
      icon: Icons.event_available_rounded,
      title: 'Nessun evento futuro',
      subtitle: 'Pianifica un viaggio, uscita o traguardo',
      color: const Color(0xFF818CF8),
      actionLabel: 'Crea Evento',
      onAction: () => GoRouter.of(context).push('/space/time_management'),
      isCompact: widget.def.size.mainAxisCellCount <= 1,
    );
  }

  Widget _buildCountdownContent(
    BuildContext context,
    TimeScenario scenario,
    DateTime now, {
    required int currentIndex,
    required int totalScenarios,
  }) {
    final diff = scenario.startDate.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;

    final isPast = diff.isNegative;
    final isInProgress = isPast && scenario.endDate != null && scenario.endDate!.isAfter(now);

    final color = _getScenarioColor(scenario.scenarioType);
    final icon = _getScenarioIcon(scenario.scenarioType);

    if (widget.def.size.mainAxisCellCount <= 1) {
      String countdownText;
      if (isInProgress) {
        countdownText = 'IN CORSO';
      } else if (isPast) {
        countdownText = 'CONCLUSO';
      } else {
        countdownText = '-$days ${days == 1 ? "GIORNO" : "GIORNI"}';
      }

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
                    color: color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 13),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    scenario.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _calculateAdaptiveTitleFontSize(scenario.title, isCompact: true),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (totalScenarios > 1) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${currentIndex + 1}/$totalScenarios',
                      style: TextStyle(
                        color: color.withOpacity(0.9),
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                countdownText,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 130;

        return Padding(
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
                            if (totalScenarios > 1) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${currentIndex + 1}/$totalScenarios',
                                  style: TextStyle(
                                    color: color.withOpacity(0.9),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _calculateAdaptiveTitleFontSize(scenario.title, isCompact: isCompact),
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
