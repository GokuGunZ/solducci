import 'package:flutter/material.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/routine.dart';

class HabitHubView extends StatelessWidget {
  const HabitHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Abitudini / Routine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<RoutineTemplate>>(
        stream: TimeManagementService().routinesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
          }

          final routines = snapshot.data ?? [];

          if (routines.isEmpty) {
            return const Center(
              child: Text(
                'Non hai ancora creato nessuna routine.\nCreala dal tasto "+"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              // Utilizziamo un colore ciclico per distinguerle
              final colors = [
                const Color(0xFFF59E0B),
                const Color(0xFF10B981),
                const Color(0xFF6366F1),
                const Color(0xFF3B82F6),
              ];
              final color = colors[index % colors.length];

              // Mock streak per ora, dato che il tracking giornaliero non è ancora modellato
              final mockStreak = (routine.name.length % 5) + 1;

              return _buildHabitCard(
                routine.name,
                mockStreak,
                color,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHabitCard(String title, int streak, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: streak > 0 ? Colors.orange : Colors.grey, size: 20),
                  const SizedBox(width: 4),
                  Text('$streak giorni', style: TextStyle(color: streak > 0 ? Colors.orange : Colors.grey, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isCompleted = index < streak;
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? color.withValues(alpha: 0.8) : const Color(0xFF2A2A2D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              );
            }),
          ),
        ],
      ),
    );
  }
}
