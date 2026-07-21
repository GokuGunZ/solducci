import 'package:flutter/material.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/models/expense.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EconomyHubView extends StatelessWidget {
  const EconomyHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Economia Globale'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildShortcut(context, 'Dashboard', Icons.account_balance, const Color(0xFF10B981), () {
                  context.push('/expenses_dashboard'); 
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildShortcut(context, 'Dispensa', Icons.kitchen, const Color(0xFFF59E0B), () {
                  context.push('/space/pantry');
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildShortcut(context, 'Liste Spesa', Icons.shopping_basket, const Color(0xFF3B82F6), () {
                  context.push('/space/shopping');
                }),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Ultime Transazioni', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          StreamBuilder<List<Expense>>(
            stream: ExpenseServiceCached().stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('Nessuna spesa trovata', style: TextStyle(color: Colors.white54));
              
              final recent = snapshot.data!.take(5).toList();
              return Column(
                children: recent.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                      child: const Icon(Icons.attach_money, color: Color(0xFF10B981)),
                    ),
                    title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(e.date), style: const TextStyle(color: Colors.white54)),
                    trailing: Text('€${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/expenses_dashboard'),
            child: const Text('Vedi tutti i bilanci e le spese', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcut(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
