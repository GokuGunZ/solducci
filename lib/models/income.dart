import 'package:hive/hive.dart';
import 'package:solducci/core/cache/cacheable_model.dart';
import 'package:solducci/models/income_category.dart';

part 'income.g.dart';

@HiveType(typeId: 11)
class Income implements CacheableModel<String> {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String? walletId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final IncomeCategory category;

  @HiveField(7)
  final bool isRecurring;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String? portfolioId;

  @HiveField(11)
  final String? assetId;

  Income({
    required this.id,
    required this.userId,
    this.walletId,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    this.isRecurring = false,
    this.portfolioId,
    this.assetId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ====================================================================
  // CacheableModel Implementation
  // ====================================================================

  @override
  String get cacheKey => id;

  @override
  DateTime? get lastModified => updatedAt;

  @override
  bool get shouldCache => true;

  @override
  Income copyWith({
    String? id,
    String? userId,
    String? walletId,
    double? amount,
    String? description,
    DateTime? date,
    IncomeCategory? category,
    bool? isRecurring,
    String? portfolioId,
    String? assetId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      portfolioId: portfolioId ?? this.portfolioId,
      assetId: assetId ?? this.assetId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'category': category.dbValue,
      'is_recurring': isRecurring,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (portfolioId != null) map['portfolio_id'] = portfolioId;
    if (assetId != null) map['asset_id'] = assetId;
    return map;
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      walletId: map['wallet_id'] as String?,
      portfolioId: map['portfolio_id'] as String?,
      assetId: map['asset_id'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      category: IncomeCategory.fromDb(map['category'] as String? ?? 'stipendio'),
      isRecurring: map['is_recurring'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
