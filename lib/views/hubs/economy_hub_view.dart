import 'package:solducci/widgets/solducci_app_bar.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/models/expense.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/widgets/neon_wave_graph.dart';

class EconomyHubView extends StatelessWidget {
  const EconomyHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        title: const Text('Economy Hub', style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Color(0xFF10B981)),
            tooltip: 'Dashboard Analitica',
            onPressed: () => context.push('/expenses_dashboard'),
          )
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: ExpenseServiceCached().stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final expenses = snapshot.data ?? [];
          
          List<double> waveData;
          if (expenses.isEmpty) {
            waveData = [10.0, 30.0, 15.0, 45.0, 20.0, 60.0, 30.0, 55.0];
          } else {
            waveData = expenses.take(15).toList().reversed.map((e) => e.amount).toList();
            if (waveData.length < 2) waveData.add(waveData.first);
          }

          final totalRecent = expenses.take(15).fold(0.0, (sum, e) => sum + e.amount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Data Stream Animato
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ]
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: NeonWaveGraph(
                          color: const Color(0xFF10B981),
                          dataPoints: waveData,
                          height: 240,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 24,
                      left: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('FLUSSO SPESE', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('€${totalRecent.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('Transazioni', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Nessuna spesa trovata', style: TextStyle(color: Colors.white54)),
                )
              else
                ...expenses.take(10).map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                      child: const Icon(Icons.attach_money, color: Color(0xFF10B981)),
                    ),
                    title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(e.date), style: const TextStyle(color: Colors.white54)),
                    trailing: Text('€${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE0E0E0))),
                  ),
                )),
                
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.analytics, color: Color(0xFF10B981)),
                  label: const Text('Dashboard Analitica', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  onPressed: () => context.push('/expenses_dashboard'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
