import 'package:flutter/material.dart';

class TripDetailView extends StatelessWidget {
  final String scenarioId;

  const TripDetailView({super.key, required this.scenarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Dettaglio Viaggio', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRsvpSection(),
          const SizedBox(height: 24),
          _buildGhostPantrySection(),
        ],
      ),
    );
  }

  Widget _buildRsvpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const <Widget>[
          Text('RSVP (Appello Viaggio)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Qui andranno i pulsanti Espliciti (Vengo, Non vengo, Forse) cablati al BLoC', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildGhostPantrySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const <Widget>[
          Text('Dispensa Specifica (Viaggio)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Qui vivrà la Ghost Pantry, isolata dal gruppo principale, per organizzare cosa portare', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
