import 'package:flutter/material.dart';
import 'package:solducci/features/life_os/presentation/controllers/entity_vitrine_state.dart';

class HumanIntentionActionSheet extends StatelessWidget {
  final ValueChanged<HumanIntention> onSelectIntention;
  final HumanIntention? currentIntention;

  const HumanIntentionActionSheet({
    super.key,
    required this.onSelectIntention,
    this.currentIntention,
  });

  static void show(
    BuildContext context, {
    required ValueChanged<HumanIntention> onSelectIntention,
    HumanIntention? currentIntention,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HumanIntentionActionSheet(
        onSelectIntention: onSelectIntention,
        currentIntention: currentIntention,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cosa vuoi farne?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Esprimi l\'intenzione umana: la struttura tecnica si adatterà da sola.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildIntentionTile(
            context,
            intention: HumanIntention.explore,
            icon: Icons.search_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Esplora',
            subtitle: 'Approfondisci l\'idea liberamente, senza scadenze o impegni rigidi.',
          ),
          const SizedBox(height: 8),
          _buildIntentionTile(
            context,
            intention: HumanIntention.treatAsProject,
            icon: Icons.rocket_launch_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Trattalo come progetto',
            subtitle: 'Definisci un traguardo chiaro e orienta le azioni verso il completamento.',
          ),
          const SizedBox(height: 8),
          _buildIntentionTile(
            context,
            intention: HumanIntention.cultivatePractice,
            icon: Icons.repeat_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Coltivalo come pratica',
            subtitle: 'Un\'abitudine, una disciplina o un allenamento continuativo nel tempo.',
          ),
          const SizedBox(height: 8),
          _buildIntentionTile(
            context,
            intention: HumanIntention.organizeKnowledge,
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Organizzalo come conoscenza',
            subtitle: 'Un concetto, una memoria di riferimento o un modello mentale utile.',
          ),
          const SizedBox(height: 8),
          _buildIntentionTile(
            context,
            intention: HumanIntention.keepAsSeed,
            icon: Icons.eco_outlined,
            iconColor: Colors.white54,
            title: 'Lascialo come seme',
            subtitle: 'Mantieni il pensiero a riposo senza applicare nessuna modalità operativa.',
          ),
        ],
      ),
    );
  }

  Widget _buildIntentionTile(
    BuildContext context, {
    required HumanIntention intention,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = currentIntention == intention;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSelectIntention(intention);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? iconColor.withOpacity(0.4) : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }
}
