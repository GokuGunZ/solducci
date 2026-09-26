import 'package:hive/hive.dart';
import 'package:solducci/core/cache/cacheable_model.dart';

part 'wallet_transfer.g.dart';

@HiveType(typeId: 13)
class WalletTransfer implements CacheableModel<String> {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String fromWalletId;

  @HiveField(3)
  final String toWalletId;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final DateTime createdAt;

  WalletTransfer({
    required this.id,
    required this.userId,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  String get cacheKey => id;

  @override
  DateTime? get lastModified => createdAt;

  @override
  bool get shouldCache => true;

  @override
  WalletTransfer copyWith({
    String? id,
    String? userId,
    String? fromWalletId,
    String? toWalletId,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return WalletTransfer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'date': date.toIso8601String().split('T').first,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WalletTransfer.fromMap(Map<String, dynamic> map) {
    return WalletTransfer(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      fromWalletId: map['from_wallet_id'] as String? ?? '',
      toWalletId: map['to_wallet_id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
