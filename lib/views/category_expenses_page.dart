import 'package:flutter/material.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/widgets/expense_list_item_optimized.dart';
import 'package:solducci/widgets/quick_add/unified_transaction_modal.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class CategoryExpensesPage extends StatefulWidget {
  final Tipologia category;

  const CategoryExpensesPage({super.key, required this.category});

  @override
  State<CategoryExpensesPage> createState() => _CategoryExpensesPageState();
}

class _CategoryExpensesPageState extends State<CategoryExpensesPage> {
  final _expenseService = ExpenseServiceCached();

  @override
  Widget build(BuildContext context) {
    final color = CategoryHelpers.getCategoryColor(widget.category);
    final icon = CategoryHelpers.getCategoryIcon(widget.category);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              widget.category.label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color,
        foregroundColor: Colors.black,
        onPressed: () => UnifiedTransactionModal.show(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: color));
          }

          final allExpenses = snapshot.data ?? [];
          final categoryExpenses = allExpenses
              .where((e) => e.type == widget.category)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (categoryExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141417),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Icon(icon, size: 40, color: color.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna spesa in ${widget.category.label}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Registra una nuova spesa per questa categoria',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final total = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final avg = total / categoryExpenses.length;

          return Column(
            children: [
              // Hero Summary Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('TOTALE SPESO', '€${total.toStringAsFixed(2)}', color),
                    Container(height: 36, width: 1, color: Colors.white10),
                    _buildStatCol('TRANSAZIONI', '${categoryExpenses.length}', Colors.white),
                    Container(height: 36, width: 1, color: Colors.white10),
                    _buildStatCol('MEDIA', '€${avg.toStringAsFixed(2)}', Colors.white70),
                  ],
                ),
              ),

              // Lista Spese
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: categoryExpenses.length,
                  itemBuilder: (context, index) {
                    final exp = categoryExpenses[index];
                    return ExpenseListItemOptimized(
                      expense: exp,
                      dismissible: true,
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

  Widget _buildStatCol(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
