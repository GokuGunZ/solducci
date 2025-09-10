import 'package:flutter/material.dart';
import 'package:solducci/models/expense_form.dart';

class Expense {
  int id;
  String description;
  double money;
  MoneyFlow flow;
  DateTime date;
  Tipologia type;

  Expense({
    required this.id,
    required this.description,
    required this.money,
    required this.flow,
    required this.date,
    required this.type,
  });

  // map(entity) -> expense(model)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int,
      description: map['description'] as String,
      money: map['money'] as double,
      flow: map['flow'] as MoneyFlow,
      date: map['date'] as DateTime,
      type: map['type'] as Tipologia,
    );
  }

  // expense(model) -> map(entity)
  Map<String, dynamic> toMap() {
    return {
      'id': id,      
      'description': description,
      'money': money,
      'flow': flow,
      'date': date,
      'type': type,      
    };
  }

  String formatAmount(double amount) {
    return "${amount.toString()} €";
  }
  
  ListTile getTile() {
    return ListTile(
                      title: Text(description),
                      leading: Text(formatAmount(money)),
                      trailing: Text(type.label),
                      subtitle: Text("${date.toString()} -- ${flow.label}"),
                    );
  }

}