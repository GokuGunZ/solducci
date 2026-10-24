import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

/// Hub unificato per tutti i documenti, liste e strumenti di Spazio
class SpaceHomeView extends StatelessWidget {
  const SpaceHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final contextManager = ContextManager();

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        title: ListenableBuilder(
          listenable: contextManager,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Spazio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  contextManager.contextDisplayName,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          },
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSpaceTile(
            context,
            title: 'LifeOS Center',
            subtitle: 'Centro operativo, cattura rapida e orientamento',
            icon: Icons.all_inclusive_rounded,
            color: const Color(0xFF6366F1),
            route: '/life_os',
            heroTag: 'hero_space_life_os',
          ),
          const SizedBox(height: 18),
          _buildSectionHeader('Pensieri & AttivitÃ '),
          _buildSpaceTile(
            context,
            title: 'Note e Appunti',
            subtitle: 'Idee, bozze, pensieri veloci',
            icon: Icons.notes_rounded,
            color: const Color(0xFFF59E0B),
            route: '/space/notes',
            heroTag: 'hero_space_note',
          ),
          const SizedBox(height: 10),
          _buildSpaceTile(
            context,
            title: 'Task e AttivitÃ ',
            subtitle: 'To-do list e cose da fare',
            icon: Icons.checklist_rounded,
            color: const Color(0xFF6366F1),
            route: '/space/tasks',
            heroTag: 'hero_space_todo',
          ),
          const SizedBox(height: 10),
          _buildSpaceTile(
            context,
            title: 'Asterischi',
            subtitle: 'Argomenti salvati da discutere',
            icon: Icons.star_outline_rounded,
            color: const Color(0xFFEAB308),
            route: '/space/asterisks',
            heroTag: 'hero_space_asterisk',
          ),
          const SizedBox(height: 10),
          _buildSpaceTile(
            context,
            title: 'Risorse e Link',
            subtitle: 'Documenti, link e allegati',
            icon: Icons.link_rounded,
            color: const Color(0xFF8B5CF6),
            route: '/space/resources',
            heroTag: 'hero_space_resource_list',
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Casa & Quotidiano'),
          _buildSpaceTile(
            context,
            title: 'Liste della Spesa',
            subtitle: 'Cosa comprare e liste spuntate',
            icon: Icons.shopping_cart_outlined,
            color: const Color(0xFF14B8A6),
            route: '/space/shopping',
            heroTag: 'hero_space_shopping_list',
          ),
          const SizedBox(height: 10),
          _buildSpaceTile(
            context,
            title: 'Dispensa',
            subtitle: 'Giacenze e prodotti in casa',
            icon: Icons.kitchen_outlined,
            color: const Color(0xFF10B981),
            route: '/space/pantry',
            heroTag: 'hero_space_dispensa',
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Laboratorio & Visuale'),
          _buildSpaceTile(
            context,
            title: 'Infinite Canvas (Alpha)',
            subtitle: 'Esploratore a grafo infinito',
            icon: Icons.account_tree_outlined,
            color: const Color(0xFF0EA5E9),
            route: '/space/infinite_canvas',
            heroTag: 'hero_space_infinite_canvas',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSpaceTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
    required String heroTag,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(route);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141417),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
