import 'package:flutter/material.dart';
import 'package:solducci/theme/app_theme.dart';

/// Pedagogical onboarding & discovery sheet explaining LifeOS project mechanics,
/// graph vs. folder mental models, and gesture navigation.
class ProjectDiscoverySheet extends StatelessWidget {
  const ProjectDiscoverySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProjectDiscoverySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school_outlined, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Come Funzionano i Progetti in LifeOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 1: Il Progetto come Contenitore e Nodo Radice
            _buildConceptCard(
              icon: Icons.account_tree_outlined,
              title: '1. Il Progetto è una Radice Vivente',
              description:
                  'Invece di essere una cartella chiusa o una semplice nota, un Progetto è il nodo radice di un grafo. Contiene le sue sotto-idee, i materiali e le note, che ereditano automaticamente il suo contesto.',
            ),
            const SizedBox(height: 12),

            // Card 2: Cartelle vs Grafo
            _buildConceptCard(
              icon: Icons.swap_horiz_rounded,
              title: '2. Cartelle vs. Grafo: Due Proiezioni',
              description:
                  '• Vista Cartelle: per pianificare in ordine lineare, con livelli chiari e rami espandibili.\n'
                  '• Vista Grafo: per esplorare le associazioni radiali, vedere i collegamenti e i gruppi di appartenenza senza ingombro visivo.',
            ),
            const SizedBox(height: 12),

            // Card 3: I Gesti nel Grafo
            _buildConceptCard(
              icon: Icons.touch_app_outlined,
              title: '3. I Gesti nel Grafo Radiale',
              description:
                  '• 1 Tap: seleziona il nodo e apre l\'anteprima in basso (la mappa non si muove).\n'
                  '• 2 Tap (Doppio tocco): entra nel livello successivo, mettendo al centro il nodo selezionato.\n'
                  '• Swipe: scivola rapidamente tra i livelli antenati o discendenti.',
            ),
            const SizedBox(height: 12),

            // Card 4: Dashboard Progressiva
            _buildConceptCard(
              icon: Icons.auto_awesome_outlined,
              title: '4. Dashboard Progressiva',
              description:
                  'Nessun box vuoto. Se il progetto è appena nato, vedrai solo un foglio minimale per le note. Man mano che aggiungi elementi, la dashboard assemblerà automaticamente le sezioni dedicate.',
            ),
            const SizedBox(height: 24),

            // Close CTA
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ho Capito', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
