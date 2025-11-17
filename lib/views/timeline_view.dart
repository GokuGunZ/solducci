import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(title: const Text("Timeline Spese")),
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
                  Icon(Icons.timeline, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Nessuna spesa da visualizzare',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final sections = DashboardService.groupByDateSections(expenses);
          final sectionKeys = sections.keys.toList();

          return ListView.builder(
            itemCount: sectionKeys.length,
            itemBuilder: (context, sectionIndex) {
              final sectionLabel = sectionKeys[sectionIndex];
              final sectionExpenses = sections[sectionLabel]!;
              final sectionTotal = sectionExpenses.fold<double>(
                0.0,
                (sum, e) => sum + e.amount,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date separator header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[100]!, Colors.blue[50]!],
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.blue[300]!, width: 2),
                        bottom: BorderSide(color: Colors.blue[300]!, width: 2),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getDateIcon(sectionLabel),
                              color: Colors.blue[800],
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              sectionLabel,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${sectionTotal.toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            Text(
                              '${sectionExpenses.length} spese',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expenses in this section
                  ...sectionExpenses.asMap().entries.map((entry) {
                    final expenseIndex = entry.key;
                    final expense = entry.value;
                    final isLast = expenseIndex == sectionExpenses.length - 1;

                    return Column(
                      children: [
                        // Timeline connector
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Timeline line
                              Container(
                                width: 60,
                                child: Column(
                                  children: [
                                    // Top line
                                    if (expenseIndex > 0)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: Colors.blue[200],
                                        ),
                                      ),
                                    // Timeline dot
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(expense.type),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Bottom line
                                    if (!isLast)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: Colors.blue[200],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Expense card
                              Expanded(
                                child: Card(
                                  margin: EdgeInsets.only(
                                    right: 12,
                                    top: 8,
                                    bottom: isLast ? 16 : 8,
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getCategoryColor(
                                        expense.type,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(expense.type),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      expense.description,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'HH:mm',
                                          ).format(expense.date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      '${expense.amount.toStringAsFixed(2)} €',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _getDateIcon(String dateLabel) {
    if (dateLabel == 'Oggi') {
      return Icons.today;
    } else if (dateLabel == 'Ieri') {
      return Icons.history;
    } else {
      return Icons.calendar_today;
    }
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
