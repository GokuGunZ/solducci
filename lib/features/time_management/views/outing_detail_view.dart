import 'package:flutter/material.dart';

class OutingDetailView extends StatelessWidget {
  final String scenarioId;

  const OutingDetailView({super.key, required this.scenarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Dettaglio Uscita', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
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
