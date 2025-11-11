import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense_form.dart';

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
          ? SplitType.fromString(map['split_type'] as String)
          : null,
      splitData: map['split_data'] != null
          ? Map<String, double>.from(map['split_data'] as Map)
          : null,
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

    // NEW: Multi-user fields
    if (groupId != null) {
      map['group_id'] = groupId!;
    }
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

/// How an expense is split among group members
enum SplitType {
  equal('equal'), // Split equally among all members
  custom('custom'), // Custom amounts per member (use splitData)
  full('full'), // One person pays everything (no split)
  none('none'); // No split (personal expense in group context)

  final String value;
  const SplitType(this.value);

  static SplitType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'equal':
        return SplitType.equal;
      case 'custom':
        return SplitType.custom;
      case 'full':
        return SplitType.full;
      case 'none':
        return SplitType.none;
      default:
        if (kDebugMode) {
          print('⚠️ Unknown SplitType: $value, defaulting to equal');
        }
        return SplitType.equal;
    }
  }

  String get label {
    switch (this) {
      case SplitType.equal:
        return 'Diviso Equamente';
      case SplitType.custom:
        return 'Diviso Custom';
      case SplitType.full:
        return 'Pagato da Uno';
      case SplitType.none:
        return 'Personale';
    }
  }
}
