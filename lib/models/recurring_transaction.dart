import 'package:solducci/core/context/context_bound.dart';
import 'package:solducci/models/split_type.dart';

enum RecurringFrequency {
  weekly('Settimanale', 'week'),
  biweekly('Ogni 2 settimane', '2weeks'),
  monthly('Mensile', 'month'),
  bimonthly('Bimestrale (2 mesi)', '2months'),
  quarterly('Trimestrale (3 mesi)', 'quarter'),
  semiannual('Semestrale (6 mesi)', '6months'),
  yearly('Annuale', 'year');

  final String label;
  final String code;
  const RecurringFrequency(this.label, this.code);

  static RecurringFrequency fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'weekly':
        return RecurringFrequency.weekly;
      case 'biweekly':
        return RecurringFrequency.biweekly;
      case 'bimonthly':
        return RecurringFrequency.bimonthly;
      case 'quarterly':
        return RecurringFrequency.quarterly;
      case 'semiannual':
        return RecurringFrequency.semiannual;
      case 'yearly':
        return RecurringFrequency.yearly;
      case 'monthly':
      default:
        return RecurringFrequency.monthly;
    }
  }

  String get dbValue {
    switch (this) {
      case RecurringFrequency.weekly:
        return 'weekly';
      case RecurringFrequency.biweekly:
        return 'biweekly';
      case RecurringFrequency.monthly:
        return 'monthly';
      case RecurringFrequency.bimonthly:
        return 'bimonthly';
      case RecurringFrequency.quarterly:
        return 'quarterly';
      case RecurringFrequency.semiannual:
        return 'semiannual';
      case RecurringFrequency.yearly:
        return 'yearly';
    }
  }
}

class RecurringTransaction with DirectContextBound {
  final String id;
  @override
  final String userId;
  final bool isIncome;
  final String title;
  final double amount;
  final bool isVariableAmount;
  final String category;
  final String? walletId;
  final String? portfolioId;
  @override
  final String? groupId;
  final String? paidBy;
  final SplitType splitType;
  final Map<String, double>? splitData;
  final RecurringFrequency frequency;
  final int intervalCount;
  final int? dayOfMonth;
  final int? dayOfWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;
  final DateTime? lastGeneratedAt;
  final bool isActive;
  final bool requiresConfirmation;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringTransaction({
    required this.id,
    required this.userId,
    this.isIncome = false,
    required this.title,
    required this.amount,
    this.isVariableAmount = false,
    required this.category,
    this.walletId,
    this.portfolioId,
    this.groupId,
    this.paidBy,
    this.splitType = SplitType.equal,
    this.splitData,
    this.frequency = RecurringFrequency.monthly,
    this.intervalCount = 1,
    this.dayOfMonth,
    this.dayOfWeek,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    this.lastGeneratedAt,
    this.isActive = true,
    this.requiresConfirmation = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isGroup => groupId != null;
  bool get isPersonal => groupId == null;

  /// Verifica se la ricorrenza è scaduta o pronta oggi
  bool get isDueTodayOrOverdue {
    if (!isActive) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.isBefore(today) || due.isAtSameMomentAs(today);
  }

  /// Quanti giorni mancano al prossimo addebito
  int get daysUntilNextDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }

  /// Stima costo mensile normalizzato (utile per statistiche di cashflow)
  double get monthlyEquivalentAmount {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return amount * 4.33;
      case RecurringFrequency.biweekly:
        return amount * 2.16;
      case RecurringFrequency.monthly:
        return amount;
      case RecurringFrequency.bimonthly:
        return amount / 2.0;
      case RecurringFrequency.quarterly:
        return amount / 3.0;
      case RecurringFrequency.semiannual:
        return amount / 6.0;
      case RecurringFrequency.yearly:
        return amount / 12.0;
    }
  }

  RecurringTransaction copyWith({
    String? id,
    String? userId,
    bool? isIncome,
    String? title,
    double? amount,
    bool? isVariableAmount,
    String? category,
    String? walletId,
    String? portfolioId,
    String? groupId,
    String? paidBy,
    SplitType? splitType,
    Map<String, double>? splitData,
    RecurringFrequency? frequency,
    int? intervalCount,
    int? dayOfMonth,
    int? dayOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    DateTime? lastGeneratedAt,
    bool? isActive,
    bool? requiresConfirmation,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isIncome: isIncome ?? this.isIncome,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      isVariableAmount: isVariableAmount ?? this.isVariableAmount,
      category: category ?? this.category,
      walletId: walletId ?? this.walletId,
      portfolioId: portfolioId ?? this.portfolioId,
      groupId: groupId ?? this.groupId,
      paidBy: paidBy ?? this.paidBy,
      splitType: splitType ?? this.splitType,
      splitData: splitData ?? this.splitData,
      frequency: frequency ?? this.frequency,
      intervalCount: intervalCount ?? this.intervalCount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      isActive: isActive ?? this.isActive,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      return DateTime.parse(val.toString()).toLocal();
    }

    Map<String, double>? parseSplit(dynamic val) {
      if (val == null) return null;
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
      }
      return null;
    }

    return RecurringTransaction(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      isIncome: map['is_income'] == true,
      title: map['title']?.toString() ?? 'Senza Titolo',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isVariableAmount: map['is_variable_amount'] == true,
      category: map['category']?.toString() ?? 'generale',
      walletId: map['wallet_id']?.toString(),
      portfolioId: map['portfolio_id']?.toString(),
      groupId: map['group_id']?.toString(),
      paidBy: map['paid_by']?.toString(),
      splitType: map['split_type'] != null ? SplitType.fromValue(map['split_type'].toString()) : SplitType.equal,
      splitData: parseSplit(map['split_data']),
      frequency: RecurringFrequency.fromString(map['frequency']?.toString()),
      intervalCount: (map['interval_count'] as num?)?.toInt() ?? 1,
      dayOfMonth: (map['day_of_month'] as num?)?.toInt(),
      dayOfWeek: (map['day_of_week'] as num?)?.toInt(),
      startDate: parseDate(map['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: map['end_date'] != null ? parseDate(map['end_date']) : null,
      nextDueDate: parseDate(map['next_due_date'] ?? DateTime.now().toIso8601String()),
      lastGeneratedAt: map['last_generated_at'] != null ? parseDate(map['last_generated_at']) : null,
      isActive: map['is_active'] ?? true,
      requiresConfirmation: map['requires_confirmation'] ?? false,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null ? parseDate(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? parseDate(map['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    String formatDate(DateTime d) {
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'is_income': isIncome,
      'title': title,
      'amount': amount,
      'is_variable_amount': isVariableAmount,
      'category': category,
      'wallet_id': walletId,
      'portfolio_id': portfolioId,
      'group_id': groupId,
      'paid_by': paidBy,
      'split_type': splitType.name,
      'split_data': splitData,
      'frequency': frequency.dbValue,
      'interval_count': intervalCount,
      'day_of_month': dayOfMonth,
      'day_of_week': dayOfWeek,
      'start_date': formatDate(startDate),
      'end_date': endDate != null ? formatDate(endDate!) : null,
      'next_due_date': formatDate(nextDueDate),
      'last_generated_at': lastGeneratedAt?.toIso8601String(),
      'is_active': isActive,
      'requires_confirmation': requiresConfirmation,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
