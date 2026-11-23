import 'package:flutter/material.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/presentation/controllers/entity_vitrine_state.dart';

/// Modal sheet for selecting the human nature (SemanticRole)
class HumanRoleActionSheet extends StatelessWidget {
  final ValueChanged<SemanticRole> onSelectRole;
  final SemanticRole currentRole;

  const HumanRoleActionSheet({
    super.key,
    required this.onSelectRole,
    required this.currentRole,
  });

  static void show(
    BuildContext context, {
    required ValueChanged<SemanticRole> onSelectRole,
    required SemanticRole currentRole,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HumanRoleActionSheet(
        onSelectRole: onSelectRole,
        currentRole: currentRole,
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
            'Che natura ha quest\'entità?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Descrive cosa rappresenta prevalentemente nella tua vita.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildRoleTile(
            context,
            role: SemanticRole.seed,
            icon: Icons.eco_outlined,
            iconColor: Colors.white54,
            title: 'Seme grezzo',
            subtitle: 'Un pensiero a riposo senza impegni né urgenza.',
          ),
          const SizedBox(height: 8),
          _buildRoleTile(
            context,
            role: SemanticRole.project,
            icon: Icons.rocket_launch_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Progetto',
            subtitle: 'Un\'iniziativa chiara orientata al raggiungimento di un traguardo.',
          ),
          const SizedBox(height: 8),
          _buildRoleTile(
            context,
            role: SemanticRole.practice,
            icon: Icons.repeat_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Pratica',
            subtitle: 'Un\'abitudine, una disciplina o un allenamento continuo nel tempo.',
          ),
          const SizedBox(height: 8),
          _buildRoleTile(
            context,
            role: SemanticRole.concept,
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Conoscenza',
            subtitle: 'Un concetto, una memoria o un modello mentale utile da consultare.',
          ),
          const SizedBox(height: 8),
          _buildRoleTile(
            context,
            role: SemanticRole.idea,
            icon: Icons.lightbulb_outline_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Idea',
            subtitle: 'Uno spunto aperto in fase di germogliazione e maturazione.',
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTile(
    BuildContext context, {
    required SemanticRole role,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = currentRole == role;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSelectRole(role);
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

/// Modal sheet for selecting the current operational posture (OperationMode)
class HumanModeActionSheet extends StatelessWidget {
  final ValueChanged<OperationMode?> onSelectMode;
  final OperationMode? currentMode;

  const HumanModeActionSheet({
    super.key,
    required this.onSelectMode,
    required this.currentMode,
  });

  static void show(
    BuildContext context, {
    required ValueChanged<OperationMode?> onSelectMode,
    required OperationMode? currentMode,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HumanModeActionSheet(
        onSelectMode: onSelectMode,
        currentMode: currentMode,
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
            'Come la stai affrontando adesso?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Descrive la postura operativa temporanea, non la natura permanente.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildModeTile(
            context,
            mode: null,
            icon: Icons.pause_circle_outline_rounded,
            iconColor: Colors.white38,
            title: 'Nessuna modalità attiva (A riposo)',
            subtitle: 'L\'entità è presente ma non assorbe attenzione operativa attiva.',
          ),
          const SizedBox(height: 8),
          _buildModeTile(
            context,
            mode: OperationMode.exploration,
            icon: Icons.search_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Esplora',
            subtitle: 'Ricerca aperta, studio, prototipazione o raccolta di informazioni.',
          ),
          const SizedBox(height: 8),
          _buildModeTile(
            context,
            mode: OperationMode.execution,
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Lavora (Esecuzione)',
            subtitle: 'Azione diretta e focalizzata per completare compiti o rilasciare.',
          ),
          const SizedBox(height: 8),
          _buildModeTile(
            context,
            mode: OperationMode.practice,
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Pratica',
            subtitle: 'Svolgimento di routine, allenamento di abilità o ripetizioni.',
          ),
          const SizedBox(height: 8),
          _buildModeTile(
            context,
            mode: OperationMode.reflection,
            icon: Icons.self_improvement_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Rifletti',
            subtitle: 'Revisione retrospettiva, sintesi o riorganizzazione del quadro.',
          ),
        ],
      ),
    );
  }

  Widget _buildModeTile(
    BuildContext context, {
    required OperationMode? mode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSelectMode(mode);
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

/// Backwards compatibility intention sheet
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
            'Esprimi l\'intenzione: la natura e la modalità rimangono indipendenti.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildTile(context, HumanIntention.treatAsProject, Icons.rocket_launch_rounded, const Color(0xFF6366F1), 'Trattalo come progetto', 'Imposta la natura come Progetto (modalità invariata).'),
          const SizedBox(height: 8),
          _buildTile(context, HumanIntention.cultivatePractice, Icons.repeat_rounded, const Color(0xFF10B981), 'Coltivalo come pratica', 'Imposta la natura come Pratica continua (modalità invariata).'),
          const SizedBox(height: 8),
          _buildTile(context, HumanIntention.organizeKnowledge, Icons.menu_book_rounded, const Color(0xFF3B82F6), 'Organizzalo come conoscenza', 'Imposta la natura come Conoscenza/Concetto (modalità invariata).'),
          const SizedBox(height: 8),
          _buildTile(context, HumanIntention.explore, Icons.search_rounded, const Color(0xFFF59E0B), 'Metti in esplorazione', 'Imposta la modalità su Esplora (natura invariata).'),
          const SizedBox(height: 8),
          _buildTile(context, HumanIntention.keepAsSeed, Icons.eco_outlined, Colors.white54, 'Lascialo come seme', 'Riporta a Seme grezzo a riposo.'),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, HumanIntention intention, IconData icon, Color color, String title, String subtitle) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSelectIntention(intention);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
