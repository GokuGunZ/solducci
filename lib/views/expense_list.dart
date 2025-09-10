import 'package:flutter/material.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:solducci/ui_elements/solducci_logo.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  ExpenseService expenseService = ExpenseService();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List of Expenses"),
      ),
      body: 
          StreamBuilder(
            stream: expenseService.stream, 
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final expenses = snapshot.data!;

              return 
                  ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];

                    return expense.getTile();
                },);
                
            }),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add),),
    );
  }
}