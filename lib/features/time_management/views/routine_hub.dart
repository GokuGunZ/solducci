import 'package:flutter/material.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/routine.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineHub extends StatelessWidget {
  const RoutineHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Hub Sveglie',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<List<RoutineTemplate>>(
        stream: TimeManagementService().routinesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final routines = snapshot.data ?? [];

          if (routines.isEmpty) {
            return const Center(
              child: Text('Nessuna routine impostata.', style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return RoutineCard(template: routines[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDummyRoutine(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuovo Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  void _createDummyRoutine(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final templateId = const Uuid().v4();
    final template = RoutineTemplate(
      id: templateId,
      userId: userId,
      name: 'Nuova Sveglia Base',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final schedule = RoutineSchedule(
      id: const Uuid().v4(),
      routineTemplateId: templateId,
      targetTime: const TimeOfDay(hour: 8, minute: 0),
      dayOfWeek: 1, // Lunedì
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await TimeManagementService().createRoutineTemplate(template, [schedule]);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sveglia creata!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }
}

class RoutineCard extends StatelessWidget {
  final RoutineTemplate template;

  const RoutineCard({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final color = template.isActive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: template.isActive ? color.withOpacity(0.5) : Colors.transparent, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Dettaglio Routine
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: template.isActive ? Colors.white : Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<List<RoutineSchedule>>(
                          stream: TimeManagementService().getSchedulesStream(template.id),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('Nessuna programmazione', style: TextStyle(color: Colors.white30));
                            }

                            final schedules = snapshot.data!;
                            final firstSchedule = schedules.first;
                            final targetTimeStr = '${firstSchedule.targetTime.hour.toString().padLeft(2, '0')}:${firstSchedule.targetTime.minute.toString().padLeft(2, '0')}';
                            
                            final days = schedules.map((s) => s.dayOfWeek).toSet().toList()..sort();
                            String daysStr = '${days.length} giorni'; 
                            if (days.length == 7) daysStr = 'Tutti i giorni';
                            else if (days.length == 5 && days.contains(1) && days.contains(5)) daysStr = 'Lun - Ven';
                            else if (days.length == 2 && days.contains(6) && days.contains(7)) daysStr = 'Sab - Dom';
                            else if (days.length == 1) daysStr = '1 giorno a settimana';

                            final now = DateTime.now();
                            final isPausedToday = firstSchedule.isPausedForToday != null && 
                                firstSchedule.isPausedForToday!.year == now.year &&
                                firstSchedule.isPausedForToday!.month == now.month &&
                                firstSchedule.isPausedForToday!.day == now.day;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      targetTimeStr,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: template.isActive ? color : Colors.white30,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(daysStr, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    ),
                                  ],
                                ),
                                if (template.isActive)
                                  TextButton.icon(
                                    onPressed: () {
                                      TimeManagementService().toggleRoutinePauseForToday(firstSchedule);
                                    },
                                    icon: Icon(isPausedToday ? Icons.play_circle_outline : Icons.pause_circle_outline, size: 16),
                                    label: Text(isPausedToday ? 'Riprendi Oggi' : 'Pausa Oggi', style: const TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: isPausedToday ? Colors.greenAccent : Colors.orangeAccent,
                                      padding: EdgeInsets.zero,
                                    ),
                                  )
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: template.isActive,
                    onChanged: (val) {
                      // TODO: Toggle DB State
                    },
                    activeColor: color,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
