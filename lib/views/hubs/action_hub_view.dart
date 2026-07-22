import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/time_scenario.dart';
import 'package:solducci/models/routine.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/widgets/time_dial.dart';

class ActionHubView extends StatefulWidget {
  const ActionHubView({super.key});

  @override
  State<ActionHubView> createState() => _ActionHubViewState();
}

class _ActionHubViewState extends State<ActionHubView> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  late final Stream<List<TimeScenario>> _scenariosStream;
  late final Stream<List<RoutineTemplate>> _routinesStream;

  @override
  void initState() {
    super.initState();
    _scenariosStream = TimeManagementService().timeScenariosStream;
    _routinesStream = TimeManagementService().routinesStream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SolducciAppBar(
        title: const Text('Tempo & Azione'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TimeDialWidget(
            initialTime: _selectedTime,
            onTimeChanged: (time) {
              setState(() {
                _selectedTime = time;
              });
            },
            events: [
              TimeDialEvent(time: const TimeOfDay(hour: 8, minute: 0), title: 'Sveglia', color: const Color(0xFFEF4444)),
              TimeDialEvent(time: const TimeOfDay(hour: 13, minute: 30), title: 'Pranzo', color: const Color(0xFF3B82F6)),
              TimeDialEvent(time: const TimeOfDay(hour: 18, minute: 0), title: 'Palestra', color: const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(context, 'Scenari', Icons.event, const Color(0xFF6366F1), () => context.push('/space/time_management')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(context, 'Routine', Icons.alarm, const Color(0xFFEF4444), () => context.push('/space/time_management/routines')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(context, 'Task', Icons.check_circle, const Color(0xFF3B82F6), () => context.push('/space/tasks')),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Programmi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          StreamBuilder<List<TimeScenario>>(
            stream: _scenariosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('Nessuno scenario in vista', style: TextStyle(color: Colors.white54));
              
              return Column(
                children: snapshot.data!.take(3).map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month, color: Color(0xFF6366F1)),
                    title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(s.scenarioType.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            TimeManagementService().deleteTimeScenario(s.id);
                          },
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                    onTap: () => context.push('/space/time_management/scenario/${s.scenarioType}/${s.id}'),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text('I Tuoi Set di Sveglie', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          StreamBuilder<List<RoutineTemplate>>(
            stream: _routinesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('Nessuna routine impostata', style: TextStyle(color: Colors.white54));
              
              return Column(
                children: snapshot.data!.take(3).map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.alarm, color: Color(0xFFEF4444)),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        TimeManagementService().deleteRoutine(r.id);
                      },
                    ),
                    onTap: () => context.push('/space/time_management/routines'),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
