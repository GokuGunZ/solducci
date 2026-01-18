import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/core/cache/cacheable_model.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
class Expense implements CacheableModel<int> {
  @HiveField(0)
  int id;

  @HiveField(1)
  String description;

  @HiveField(2)
  double amount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  Tipologia type;

  @HiveField(6)
  String? userId; // User ID for personal expenses

  // NEW: Multi-user support
  @HiveField(7)
  String? groupId; // Group ID for group expenses

  @HiveField(8)
  String? paidBy; // UUID of user who paid

  @HiveField(9)
  SplitType? splitType; // How expense is split

  @HiveField(10)
  Map<String, double>? splitData; // Custom split amounts per user

  Expense({
    required this.id,
    required this.description,
    required this.amount,
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

  // ====================================================================
  // CacheableModel Implementation
  // ====================================================================

  @override
  int get cacheKey => id;

  @override
  DateTime? get lastModified => date;

  @override
  bool get shouldCache => true;

  @override
  Expense copyWith({
    int? id,
    String? description,
    double? amount,
    DateTime? date,
    Tipologia? type,
    String? userId,
    String? groupId,
    String? paidBy,
    SplitType? splitType,
    Map<String, double>? splitData,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      paidBy: paidBy ?? this.paidBy,
      splitType: splitType ?? this.splitType,
      splitData: splitData ?? this.splitData,
    );
  }

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
      } catch (e2) {
        // If both fail, use current date
        parsedDate = DateTime.now();
      }
    }

    return Expense(
      id: map['id'] as int,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(), // match your DB column
      date: parsedDate,
      type: Tipologia.values.firstWhere(
        (t) => t.label == map['type'] || t.name == map['type'],
        orElse: () => Tipologia.altro,
      ),
      userId: map['user_id'] as String?,
      // NEW: Multi-user fields
      groupId: map['group_id'] as String?,
      paidBy: map['paid_by'] as String?,
      splitType: map['split_type'] != null
          ? SplitType.fromValue(map['split_type'] as String)
          : null,
      splitData: map['split_data'] != null
          ? _parseSplitData(map['split_data'] as Map)
          : null,
    );
  }

  /// Helper method to safely parse split_data from database
  /// Handles both int and double values from JSON/database
  static Map<String, double> _parseSplitData(Map rawMap) {
    final result = <String, double>{};
    rawMap.forEach((key, value) {
      if (value is int) {
        result[key.toString()] = value.toDouble();
      } else if (value is double) {
        result[key.toString()] = value;
      } else if (value is num) {
        result[key.toString()] = value.toDouble();
      } else {
        // Fallback: try to parse as double, or use 0.0
        result[key.toString()] = double.tryParse(value.toString()) ?? 0.0;
      }
    });
    return result;
  }

  // expense(model) -> map(entity)
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'description': description,
      'amount': amount,
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
      subtitle: Text(date.toString()),
    );
  }
}
