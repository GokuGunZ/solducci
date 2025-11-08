import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spese per Categoria"),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Nessuna spesa da visualizzare',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final categoryBreakdowns = DashboardService.categoryBreakdown(expenses);
          final total = categoryBreakdowns.fold<double>(
            0.0,
            (sum, breakdown) => sum + breakdown.total,
          );

          return Column(
            children: [
              // Summary card
              Card(
                margin: EdgeInsets.all(16),
                elevation: 4,
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Totale Spese',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${total.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '${expenses.length} spese in ${categoryBreakdowns.length} categorie',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category list
              Expanded(
                child: ListView.builder(
                  itemCount: categoryBreakdowns.length,
                  itemBuilder: (context, index) {
                    final breakdown = categoryBreakdowns[index];

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getCategoryColor(breakdown.category),
                                  child: Icon(
                                    _getCategoryIcon(breakdown.category),
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        breakdown.category.label,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${breakdown.count} spese',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${breakdown.total.toStringAsFixed(2)} €',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    Text(
                                      '${breakdown.percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: breakdown.percentage / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getCategoryColor(breakdown.category),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getCategoryColor(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Colors.purple;
      case Tipologia.cibo:
        return Colors.green;
      case Tipologia.utenze:
        return Colors.blue;
      case Tipologia.prodottiCasa:
        return Colors.orange;
      case Tipologia.ristorante:
        return Colors.red;
      case Tipologia.tempoLibero:
        return Colors.pink;
      case Tipologia.altro:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Icons.home;
      case Tipologia.cibo:
        return Icons.shopping_cart;
      case Tipologia.utenze:
        return Icons.bolt;
      case Tipologia.prodottiCasa:
        return Icons.cleaning_services;
      case Tipologia.ristorante:
        return Icons.restaurant;
      case Tipologia.tempoLibero:
        return Icons.sports_esports;
      case Tipologia.altro:
        return Icons.more_horiz;
    }
  }
}
