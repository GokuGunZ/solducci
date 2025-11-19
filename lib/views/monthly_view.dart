import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:solducci/utils/category_helpers.dart';

class MonthlyView extends StatelessWidget {
  const MonthlyView({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(title: const Text("Spese per Mese")),
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
                  Icon(Icons.calendar_month, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Nessuna spesa da visualizzare',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final monthlyGroups = DashboardService.groupByMonth(expenses);

          return ListView.builder(
            itemCount: monthlyGroups.length,
            itemBuilder: (context, index) {
              final group = monthlyGroups[index];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.calendar_month, color: Colors.white),
                  ),
                  title: Text(
                    group.monthLabel,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${group.expenses.length} spese',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    '${group.total.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  children: [
                    Divider(),
                    ...group.expenses.map(
                      (expense) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: CategoryHelpers.getCategoryColor(expense.type),
                          radius: 20,
                          child: Icon(
                            CategoryHelpers.getCategoryIcon(expense.type),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(expense.description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(expense.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
                    SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
