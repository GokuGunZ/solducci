import 'package:flutter/material.dart';
import 'package:solducci/theme/app_theme.dart';

class HowLifeOsWorksSection extends StatefulWidget {
  final int seedCount;
  final int activeCount;

  const HowLifeOsWorksSection({
    super.key,
    required this.seedCount,
    required this.activeCount,
  });

  @override
  State<HowLifeOsWorksSection> createState() => _HowLifeOsWorksSectionState();
}

class _HowLifeOsWorksSectionState extends State<HowLifeOsWorksSection> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_stories_outlined, color: Colors.white54, size: 18),
            SizedBox(width: 8),
            Text(
              'Come Funziona LifeOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildPrincipleCard(
          index: 0,
          title: 'Strutturazione Progressiva',
          tagline: 'Cattura subito, decidi dopo.',
          body:
              'Non devi decidere subito se un pensiero sia un progetto, un\'attività o una lista.\n'
              'Catturalo come semplice Seme. Solo quando tornerai a riguardarlo deciderai se farlo crescere in un Progetto, una Pratica o archiviarlo.',
          liveFact: 'Hai ${widget.seedCount} semi grezzi in attesa di maturazione.',
        ),
        const SizedBox(height: 8),
        _buildPrincipleCard(
          index: 1,
          title: 'Rails, non calendari rigidi',
          tagline: 'Direzione chiara, micro-tempo flessibile.',
          body:
              'La vita reale non segue blocchi da 15 minuti.\n'
              'LifeOS usa i "Weekly Rails": scegli 2 o 3 fuochi prioritari per la settimana e lascia che l\'esecuzione si adatti alla realtà quotidiana.',
          liveFact: '${widget.activeCount} entità attualmente attive nel sistema.',
        ),
        const SizedBox(height: 8),
        _buildPrincipleCard(
          index: 2,
          title: 'Il Sistema come Specchio',
          tagline: 'Nessun rimprovero, solo chiarezza.',
          body:
              'Il sistema osserva fatti reali (sessioni, pause, attività significative) e te li rimanda con gentilezza.\n'
              'Nessun senso di colpa per l\'inattività: la ripresa di un progetto fermo è sempre accompagnata da un caldo riallineamento.',
          liveFact: 'L\'attività significativa è sempre derivata da eventi reali, mai da click artificiali.',
        ),
      ],
    );
  }

  Widget _buildPrincipleCard({
    required int index,
    required String title,
    required String tagline,
    required String body,
    required String liveFact,
  }) {
    final isExpanded = _expandedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded ? AppTheme.primary.withOpacity(0.4) : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                        tagline,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        liveFact,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
