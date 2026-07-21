import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArchiveHubView extends StatelessWidget {
  const ArchiveHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivio & Spazio'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildArchiveCard(
            context,
            'Note e Appunti',
            'Idee, liste, pensieri condivisi',
            Icons.notes,
            const Color(0xFFF59E0B),
            '/space/notes',
          ),
          const SizedBox(height: 16),
          _buildArchiveCard(
            context,
            'Asterischi',
            'Argomenti salvati da discutere',
            Icons.star_outline,
            const Color(0xFFEAB308),
            '/space/asterisks',
          ),
          const SizedBox(height: 16),
          _buildArchiveCard(
            context,
            'Risorse e Link',
            'Siti web, documenti, bollette',
            Icons.link,
            const Color(0xFF8B5CF6),
            '/space/resources',
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(BuildContext context, String title, String subtitle, IconData icon, Color color, String route) {
    return Card(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}
