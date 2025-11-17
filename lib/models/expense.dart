import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/split_type.dart';

class Expense {
  int id;
  String description;
  double amount;
  MoneyFlow moneyFlow; // Legacy field - kept for backward compatibility
  DateTime date;
  Tipologia type;
  String? userId; // User ID for personal expenses

  // NEW: Multi-user support
  String? groupId; // Group ID for group expenses
  String? paidBy; // UUID of user who paid
  SplitType? splitType; // How expense is split
  Map<String, double>? splitData; // Custom split amounts per user

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.moneyFlow,
    required this.date,
    required this.type,
    this.userId,
    this.groupId,
    this.paidBy,
    this.splitType,
    this.splitData,
  });

  /// Check if expense is personal (not in a group)
  bool get isPersonal => groupId == null;

  /// Check if expense is for a group
  bool get isGroup => groupId != null;

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
      // NEW: Multi-user fields
      groupId: map['group_id'] as String?,
      paidBy: map['paid_by'] as String?,
      splitType: map['split_type'] != null
          ? SplitType.fromValue(map['split_type'] as String)
          : null,
      splitData: map['split_data'] != null
          ? Map<String, double>.from(map['split_data'] as Map)
          : null,
    );
  }

  // expense(model) -> map(entity)
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'description': description,
      'amount': amount,
      'money_flow': moneyFlow.name, // enum -> string
      'date': date.toIso8601String(), // DateTime -> string
      'type': type.name, // enum -> string
    };

    // EXPLICIT: Always include user_id and group_id
    // Use dynamic type to allow null values
    map['user_id'] = userId;  // Can be null for group expenses
    map['group_id'] = groupId;  // Can be null for personal expenses

    // Multi-user fields
    if (paidBy != null) {
      map['paid_by'] = paidBy!;
    }
    if (splitType != null) {
      map['split_type'] = splitType!.value;
    }
    if (splitData != null) {
      map['split_data'] = splitData as Object;
    }

    // Don't send ID for new records (let Supabase auto-generate)
    // Only include it for updates (positive IDs only)
    if (id > 0) {
      map['id'] = id;
    }

    if (kDebugMode) {
      print('🔍 [EXPENSE.toMap] Serialized expense:');
      print('   - user_id: ${map['user_id']}');
      print('   - group_id: ${map['group_id']}');
      print('   - paid_by: ${map['paid_by']}');
      print('   - split_type: ${map['split_type']}');
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
