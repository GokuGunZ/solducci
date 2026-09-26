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
  final String source; // 'manual', 'purchase', 'api'

  @HiveField(5)
  final String? note;

  AssetPriceSnapshot({
    required this.id,
    required this.assetId,
    required this.price,
    DateTime? timestamp,
    this.source = 'manual',
    this.note,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AssetPriceSnapshot.fromMap(Map<String, dynamic> map) {
    return AssetPriceSnapshot(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      price: (map['price'] as num).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      source: map['source'] as String? ?? 'manual',
      note: map['note'] as String?,
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
    };
  }
}
