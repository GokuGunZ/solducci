import 'package:flutter/material.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:go_router/go_router.dart';

class SpaceHomeView extends StatelessWidget {
  const SpaceHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final contextManager = ContextManager();
    
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: contextManager,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Spazio'),
                Text(
                  contextManager.contextDisplayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SpaceCard(
            title: 'Time Management',
            description: 'Eventi, viaggi, uscite e radar',
            icon: Icons.calendar_month,
            color: Colors.pinkAccent,
            onTap: () => context.push('/space/time_management'),
          ),
          const SizedBox(height: 12),
          _SpaceCard(
            title: 'Task',
            description: 'To-do list e attività condivise',
            icon: Icons.checklist,
            color: Colors.blue,
            onTap: () => context.push('/space/tasks'),
          ),
          const SizedBox(height: 12),
          _SpaceCard(
            title: 'Note',
            description: 'Appunti e note testuali',
            icon: Icons.notes,
            color: Colors.orange,
            onTap: () => context.push('/space/notes'),
          ),
          const SizedBox(height: 12),
          _SpaceCard(
            title: 'Asterischi',
            description: 'Argomenti da discutere',
            icon: Icons.star_outline,
            color: Colors.amber,
            onTap: () => context.push('/space/asterisks'),
          ),
          const SizedBox(height: 12),
          _SpaceCard(
            title: 'Risorse',
            description: 'Link, video e documenti condivisi',
            icon: Icons.link,
            color: Colors.purple,
            onTap: () => context.push('/space/resources'),
          ),
          const SizedBox(height: 12),
          _SpaceCard(
            title: 'Dispensa',
            description: 'Inventario e giacenze',
            icon: Icons.kitchen_outlined,
            color: Colors.green,
            onTap: () => context.push('/space/pantry'),
          ),
          const SizedBox(height: 12),
          _SpaceCard(
            title: 'Liste della spesa',
            description: 'Gestione acquisti e spesa',
            icon: Icons.shopping_basket_outlined,
            color: Colors.teal,
            onTap: () => context.push('/space/shopping'),
          ),
        ],
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SpaceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
