import 'package:hive/hive.dart';

part 'asset_price_snapshot.g.dart';

@HiveType(typeId: 17)
class AssetPriceSnapshot {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String assetId;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String source; // 'manual', 'purchase', 'sale', 'adjustment', 'api'

  @HiveField(5)
  final String? note;

  @HiveField(6)
  final String transactionType; // 'snapshot', 'purchase', 'sale', 'adjustment'

  @HiveField(7)
  final double? quantityDelta;

  @HiveField(8)
  final double? totalAmount;

  AssetPriceSnapshot({
    required this.id,
    required this.assetId,
    required this.price,
    DateTime? timestamp,
    this.source = 'manual',
    this.note,
    String? transactionType,
    this.quantityDelta,
    this.totalAmount,
  })  : transactionType = transactionType ?? (source == 'purchase' ? 'purchase' : (source == 'sale' ? 'sale' : 'snapshot')),
        timestamp = timestamp ?? DateTime.now();

  bool get isPurchase => transactionType == 'purchase';
  bool get isSale => transactionType == 'sale';
  bool get isAdjustment => transactionType == 'adjustment';
  bool get isSnapshot => transactionType == 'snapshot';

  factory AssetPriceSnapshot.fromMap(Map<String, dynamic> map) {
    return AssetPriceSnapshot(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      price: (map['price'] as num).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      source: map['source'] as String? ?? 'manual',
      note: map['note'] as String?,
      transactionType: map['transaction_type'] as String?,
      quantityDelta: (map['quantity_delta'] as num?)?.toDouble(),
      totalAmount: (map['total_amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'note': note,
      'transaction_type': transactionType,
      'quantity_delta': quantityDelta,
      'total_amount': totalAmount,
    };
  }
}
