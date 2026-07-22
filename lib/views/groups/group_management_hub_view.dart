import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/models/group.dart';

class GroupManagementHubView extends StatelessWidget {
  const GroupManagementHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Gestione Gruppi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<ExpenseGroup>>(
        stream: GroupServiceCached().groupsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }
          
          final groups = snapshot.data ?? [];
          
          if (groups.isEmpty) {
            return const Center(
              child: Text(
                'Non fai ancora parte di alcun gruppo.\nCreane uno!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _buildGroupCard(
                context,
                group.id,
                group.name,
                '${group.memberCount ?? group.members?.length ?? 1} membri',
                const Color(0xFF6366F1), // Può essere dinamico basato sul gruppo
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/create'),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text('Nuovo Gruppo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, String groupId, String name, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.group, color: color),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {
          context.push('/groups/$groupId');
        },
      ),
    );
  }
}
