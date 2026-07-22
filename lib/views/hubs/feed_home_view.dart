import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/models/time_scenario.dart';
import 'package:solducci/widgets/context_switcher.dart';
import 'package:go_router/go_router.dart';

class FeedHomeView extends StatelessWidget {
  const FeedHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final contextManager = ContextManager();
    return Scaffold(
      appBar: SolducciAppBar(
        titleText: 'Feed',
        centerTitle: true,
        elevation: 2,
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
                  onTap: () => context.push('/space/time_management/scenario/${nextEvent.scenarioType}/${nextEvent.id}'),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Situazione Finanziaria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: contextManager,
            builder: (context, _) {
              if (contextManager.isPersonalContext) {
                 return Card(
                   child: ListTile(
                     leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
                     title: const Text('Bilancio Personale', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                     subtitle: const Text('Visualizza le tue spese personali', style: TextStyle(color: Colors.white70)),
                     trailing: const Icon(Icons.chevron_right, color: Colors.white),
                     onTap: () => context.push('/expenses_dashboard'),
                   ),
                 );
              }

              // Group or View context
              final groupIds = contextManager.currentContext.groupIds;
              if (groupIds.isEmpty) return const SizedBox.shrink();

              return Column(
                children: groupIds.map((groupId) {
                  final group = contextManager.userGroups.firstWhere(
                    (g) => g.id == groupId, 
                    orElse: () => contextManager.userGroups.first
                  );
                  return FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: ExpenseServiceCached().calculateGroupBalanceMultiPerson(groupId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Card(child: ListTile(title: Text('Calcolo bilancio...', style: TextStyle(color: Colors.white54))));
                      }
                      
                      final balances = snapshot.data!;
                      double myNet = 0;
                      for (final entry in balances.values) {
                        myNet += (entry['balance'] as double);
                      }
                      
                      final color = myNet > 0 ? Colors.green : (myNet < 0 ? Colors.red : Colors.white54);
                      final sign = myNet > 0 ? '+' : '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                            child: const Icon(Icons.group, color: Color(0xFF10B981)),
                          ),
                          title: Text('Bilancio ${group.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text('Il tuo saldo netto: $sign${myNet.toStringAsFixed(2)} €', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white),
                          onTap: () async {
                            final previousContext = contextManager.currentContext;
                            
                            // Switch to specific group for the drill-down
                            contextManager.switchToGroup(group);
                            
                            // Wait for the user to pop the dashboard
                            await context.push('/expenses_dashboard');
                            
                            // When returning, if the context is still the drilled-down group
                            // (meaning they didn't manually change it while inside), restore the old context
                            if (contextManager.currentContext.isGroup && 
                                contextManager.currentContext.groupId == group.id) {
                              if (previousContext.isView) {
                                contextManager.switchToView(previousContext.view!);
                              } else if (previousContext.isPersonal) {
                                contextManager.switchToPersonal();
                              } else if (previousContext.isGroup) {
                                contextManager.switchToGroup(previousContext.group!);
                              }
                            }
                          }, 
                        ),
                      );
                    }
                  );
                }).toList(),
              );
            }
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
