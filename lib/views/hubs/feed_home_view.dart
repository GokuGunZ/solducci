import 'package:flutter/material.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/time_scenario.dart';
import 'package:go_router/go_router.dart';

class FeedHomeView extends StatelessWidget {
  const FeedHomeView({super.key});

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
                const Text('Il tuo Feed'),
                Text(
                  contextManager.contextDisplayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6366F1)),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline), 
            onPressed: () {
              context.push('/profile'); // Route to profile instead of /home
            }
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('In evidenza', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          // Time Scenarios
          StreamBuilder<List<TimeScenario>>(
            stream: TimeManagementService().timeScenariosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Card(
                  color: const Color(0xFF1E1E1E),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Nessun evento in programma. Goditi il relax!', style: TextStyle(color: Colors.white70)),
                  ),
                );
              }
              final nextEvent = snapshot.data!.first; 
              return Card(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Color(0xFF6366F1)),
                  title: Text(nextEvent.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('Prossimo evento in programma', style: TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: () => context.push('/space/time_management/scenario/${nextEvent.scenarioType}/${nextEvent.documentId}'),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Situazione Finanziaria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
              title: const Text('Spese e Bilanci', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('Gestisci spese, debiti e rimborsi', style: TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () => context.push('/expenses_dashboard'), 
            ),
          ),
          const SizedBox(height: 24),
          const Text('Da fare oggi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF3B82F6)),
              title: const Text('Le tue Liste Task', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () => context.push('/space/tasks'),
            ),
          ),
        ],
      ),
    );
  }
}
