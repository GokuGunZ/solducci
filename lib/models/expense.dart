import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense_form.dart';

class Expense {
  int id;
  String description;
  double amount;
  MoneyFlow moneyFlow;
  DateTime date;
  Tipologia type;
  String? userId; // User ID from Supabase auth

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.moneyFlow,
    required this.date,
    required this.type,
    this.userId,
  });

  // map(entity) -> expense(model)
  factory Expense.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] as String;

    // Try to parse date with multiple formats
    DateTime parsedDate;
    try {
      // Try ISO 8601 format first (e.g., "2025-01-08T10:30:00Z")
      parsedDate = DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Fallback to Italian format (e.g., "08/01/2025")
        final italianFormat = DateFormat('dd/MM/yyyy');
        parsedDate = italianFormat.parse(dateStr);
        if (kDebugMode) {
          print('⚠️ Parsed legacy date format: $dateStr -> $parsedDate');
        }
      } catch (e2) {
        // If both fail, log error and use current date
        if (kDebugMode) {
          print('❌ ERROR parsing date: $dateStr');
          print('   Error details: $e2');
        }
        parsedDate = DateTime.now();
      }
    }

    return Expense(
      id: map['id'] as int,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(), // match your DB column
      moneyFlow: MoneyFlow.values.firstWhere(
        (f) => f.label == map['money_flow'] || f.name == map['money_flow'],
        orElse: () {
          if (kDebugMode) {
            print('⚠️ Unknown money_flow: ${map['money_flow']}, using default');
          }
          return MoneyFlow.carlToPit;
        },
      ),
      date: parsedDate,
      type: Tipologia.values.firstWhere(
        (t) => t.label == map['type'] || t.name == map['type'],
        orElse: () {
          if (kDebugMode) {
            print('⚠️ Unknown type: ${map['type']}, using default');
          }
          return Tipologia.altro;
        },
      ),
      userId: map['user_id'] as String?,
    );
  }

  // expense(model) -> map(entity)
  Map<String, dynamic> toMap() {
    final map = {
      'description': description,
      'amount': amount,
      'money_flow': moneyFlow.name, // enum -> string
      'date': date.toIso8601String(), // DateTime -> string
      'type': type.name, // enum -> string
    };

    // Only include user_id if it's not null
    if (userId != null) {
      map['user_id'] = userId!;
    }

    // Don't send ID for new records (let Supabase auto-generate)
    // Only include it for updates
    if (id > 0) {
      map['id'] = id;
    }

    return map;
  }

  String formatAmount(double amount) {
    return "${amount.toStringAsFixed(2)} €";
  }

  ListTile getTile() {
    return ListTile(
      title: Text(description),
      leading: Text(formatAmount(amount)),
      trailing: Text(type.label),
      subtitle: Text("${date.toString()} -- ${moneyFlow.label}"),
    );
  }
}
