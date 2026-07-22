import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:solducci/service/time_management_service.dart' as solducci_time_service;

class OutingDetailView extends StatelessWidget {
  final String scenarioId;

  const OutingDetailView({super.key, required this.scenarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: SolducciAppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Dettaglio Uscita', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              await solducci_time_service.TimeManagementService().deleteTimeScenario(scenarioId);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPollSection(),
        ],
      ),
    );
  }

  Widget _buildPollSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const [
          Text('Sondaggi (Time Polling)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Le uscite leggere hanno sondaggi per decidere quando e dove andare.', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
