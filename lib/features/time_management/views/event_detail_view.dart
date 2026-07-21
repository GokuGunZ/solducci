import 'package:flutter/material.dart';
import 'package:solducci/service/time_management_service.dart' as solducci_time_service;

class EventDetailView extends StatelessWidget {
  final String scenarioId;

  const EventDetailView({super.key, required this.scenarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Dettaglio Evento', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              // Delete the scenario and pop the view
              await solducci_time_service.TimeManagementService().deleteTimeScenario(scenarioId);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRsvpSection(),
        ],
      ),
    );
  }

  Widget _buildRsvpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const [
          Text('RSVP (Appello Evento)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Eventi generici avranno RSVP e gestione promemoria.', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
