import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GroupManagementHubView extends StatelessWidget {
  const GroupManagementHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Gestione Gruppi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGroupCard(context, 'Famiglia', '3 membri', const Color(0xFF6366F1)),
          _buildGroupCard(context, 'Coinquilini', '4 membri', const Color(0xFF10B981)),
          _buildGroupCard(context, 'Vacanze Estive', '6 membri', const Color(0xFFF59E0B)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/create'),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text('Nuovo Gruppo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, String name, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.group, color: color),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {
          // Placeholder per la pagina di dettaglio gruppo
        },
      ),
    );
  }
}
