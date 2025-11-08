import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/expense_service.dart';

class BalanceView extends StatelessWidget {
  const BalanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saldo Carl & Pit"),
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
                  Icon(Icons.balance, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Nessuna spesa da calcolare',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final debtBalance = DebtBalance.calculate(expenses);

          // Determine who owes whom
          final bool carlOwes = debtBalance.netBalance > 0;
          final bool balanced = debtBalance.netBalance == 0;
          final double absoluteBalance = debtBalance.netBalance.abs();

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main balance card
                Card(
                  elevation: 6,
                  color: balanced
                      ? Colors.green[50]
                      : (carlOwes ? Colors.orange[50] : Colors.blue[50]),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          balanced
                              ? Icons.check_circle
                              : Icons.swap_horiz,
                          size: 60,
                          color: balanced
                              ? Colors.green[700]
                              : (carlOwes ? Colors.orange[700] : Colors.blue[700]),
                        ),
                        SizedBox(height: 16),
                        Text(
                          balanced ? 'Saldo in Pareggio' : 'Saldo Attivo',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        if (!balanced) ...[
                          Text(
                            '${absoluteBalance.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: carlOwes ? Colors.orange[900] : Colors.blue[900],
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            debtBalance.balanceLabel,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Icon(
                            Icons.favorite,
                            color: Colors.green[700],
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tutto apposto!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Breakdown cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.orange[100],
                                radius: 30,
                                child: Text(
                                  '👨',
                                  style: TextStyle(fontSize: 30),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Carl',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Deve',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${debtBalance.carlOwes.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                radius: 30,
                                child: Text(
                                  '👨',
                                  style: TextStyle(fontSize: 30),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Pit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Deve',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${debtBalance.pitOwes.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Explanation card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            SizedBox(width: 8),
                            Text(
                              'Come funziona il calcolo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildExplanationRow(
                          'Carl → Pit:',
                          'Carl ha pagato per Pit',
                        ),
                        _buildExplanationRow(
                          'Pit → Carl:',
                          'Pit ha pagato per Carl',
                        ),
                        _buildExplanationRow(
                          'Carl ÷ 2:',
                          'Carl ha pagato, spesa divisa 50/50',
                        ),
                        _buildExplanationRow(
                          'Pit ÷ 2:',
                          'Pit ha pagato, spesa divisa 50/50',
                        ),
                        _buildExplanationRow(
                          'Personali:',
                          'Nessun debito (Carlucci/Pit)',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExplanationRow(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
