import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dashboard hub with grid of analytics cards
/// Enhanced version with additional features for recurring expenses and charts
class DashboardHub extends StatelessWidget {
  const DashboardHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard"), elevation: 2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            // Existing analytics cards
            _buildDashboardCard(
              context: context,
              title: 'Per Mese',
              subtitle: 'Raggruppa per mese',
              icon: Icons.calendar_month,
              color: Colors.blue,
              onTap: () => context.push('/dashboard/monthly'),
            ),
            _buildDashboardCard(
              context: context,
              title: 'Per Categoria',
              subtitle: 'Breakdown categorie',
              icon: Icons.category,
              color: Colors.green,
              onTap: () => context.push('/dashboard/category'),
            ),
            _buildDashboardCard(
              context: context,
              title: 'Timeline',
              subtitle: 'Vista temporale',
              icon: Icons.timeline,
              color: Colors.purple,
              onTap: () => context.push('/dashboard/timeline'),
            ),
            // New cards for future features
            _buildDashboardCard(
              context: context,
              title: 'Spese Ricorrenti',
              subtitle: 'Gestione abbonamenti',
              icon: Icons.repeat,
              color: Colors.pink,
              onTap: () => context.push('/recurring-expenses'),
              badge: 'Nuovo',
            ),
            _buildDashboardCard(
              context: context,
              title: 'Grafici Avanzati',
              subtitle: 'Trends e analisi',
              icon: Icons.trending_up,
              color: Colors.teal,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Grafici avanzati in arrivo presto!'),
                  ),
                );
              },
              badge: 'Presto',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Badge overlay
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
