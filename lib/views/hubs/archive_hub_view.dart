import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArchiveHubView extends StatelessWidget {
  const ArchiveHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Esploratore Spazi', style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildArchiveCard(
            context,
            'Infinite Canvas (Alpha)',
            'Il nuovo esploratore infinito',
            Icons.account_tree_outlined,
            const Color(0xFF6366F1),
            '/space/infinite_canvas',
            'infinite_canvas',
          ),
          const SizedBox(height: 16),
          _buildArchiveCard(
            context,
            'Note e Appunti',
            'Idee, liste, pensieri condivisi',
            Icons.notes,
            const Color(0xFFF59E0B),
            '/space/notes',
            'note',
          ),
          const SizedBox(height: 16),
          _buildArchiveCard(
            context,
            'Asterischi',
            'Argomenti salvati da discutere',
            Icons.star_outline,
            const Color(0xFFEAB308),
            '/space/asterisks',
            'asterisk',
          ),
          const SizedBox(height: 16),
          _buildArchiveCard(
            context,
            'Risorse e Link',
            'Siti web, documenti, bollette',
            Icons.link,
            const Color(0xFF8B5CF6),
            '/space/resources',
            'resource_list',
          ),
          const SizedBox(height: 16),
          _buildArchiveCard(
            context,
            'Liste Spesa',
            'Cosa comprare',
            Icons.shopping_cart_outlined,
            const Color(0xFF10B981),
            '/space/shopping',
            'shopping_list',
          ),
          const SizedBox(height: 16),
          _buildArchiveCard(
            context,
            'Dispensa',
            'Prodotti in casa',
            Icons.kitchen,
            const Color(0xFF10B981),
            '/space/pantry',
            'dispensa',
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(BuildContext context, String title, String subtitle, IconData icon, Color color, String route, String heroType) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Hero(
        tag: 'hero_space_$heroType',
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color, width: 1.5),
            ),
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
      ),
    );
  }
}
