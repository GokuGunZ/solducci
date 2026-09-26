import 'package:hive/hive.dart';

part 'expense_asset_allocation.g.dart';

@HiveType(typeId: 18)
class ExpenseAssetAllocation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int expenseId;

  @HiveField(2)
  final String assetId;

  @HiveField(3)
  final double amount; // Quota in euro della spesa

  @HiveField(4)
  final double quantity; // Quote/Unità comprate

  @HiveField(5)
  final double pricePerUnit; // Prezzo unitario pagato

  @HiveField(6)
  final DateTime createdAt;

  ExpenseAssetAllocation({
    required this.id,
    required this.expenseId,
    required this.assetId,
    required this.amount,
    required this.quantity,
    required this.pricePerUnit,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExpenseAssetAllocation.fromMap(Map<String, dynamic> map) {
    return ExpenseAssetAllocation(
      id: map['id'] as String,
      expenseId: map['expense_id'] as int,
      assetId: map['asset_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      pricePerUnit: (map['price_per_unit'] as num).toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'asset_id': assetId,
      'amount': amount,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
