import 'package:hive/hive.dart';
import 'package:solducci/core/cache/cacheable_model.dart';
import 'package:solducci/models/asset_class.dart';

part 'investment_asset.g.dart';

@HiveType(typeId: 16)
class InvestmentAsset implements CacheableModel<String> {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String portfolioId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? ticker;

  @HiveField(4)
  final AssetClass assetClass;

  @HiveField(5)
  final double totalQuantity;

  @HiveField(6)
  final double investedCapital;

  @HiveField(7)
  final double currentPrice;

  @HiveField(8)
  final DateTime lastPriceUpdate;

  @HiveField(9)
  final String? note;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final String? editionOrSet;

  @HiveField(13)
  final String? conditionOrGrading;

  @HiveField(14)
  final String? serialOrCertNumber;

  @HiveField(15)
  final String? storageLocation;

  @HiveField(16)
  final bool isPhysical;

  InvestmentAsset({
    required this.id,
    required this.portfolioId,
    required this.name,
    this.ticker,
    this.assetClass = AssetClass.etf,
    this.totalQuantity = 0.0,
    this.investedCapital = 0.0,
    this.currentPrice = 0.0,
    DateTime? lastPriceUpdate,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.editionOrSet,
    this.conditionOrGrading,
    this.serialOrCertNumber,
    this.storageLocation,
    bool? isPhysical,
  })  : isPhysical = isPhysical ?? assetClass.isPhysical,
        lastPriceUpdate = lastPriceUpdate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get currentValue => totalQuantity * currentPrice;

  double get averageBuyPrice =>
      totalQuantity > 0 ? (investedCapital / totalQuantity) : 0.0;

  double get unrealizedPnl => currentValue - investedCapital;

  double get roiPercent =>
      investedCapital > 0 ? ((unrealizedPnl / investedCapital) * 100) : 0.0;

  bool get isProfitable => unrealizedPnl >= 0;

  String get formattedQuantity {
    if (totalQuantity == totalQuantity.roundToDouble()) {
      return totalQuantity.toInt().toString();
    }
    return totalQuantity.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String get quantityUnitLabel {
    if (isPhysical) {
      return totalQuantity == 1 ? 'esemplare' : 'esemplari';
    }
    return totalQuantity == 1 ? 'quota' : 'quote';
  }

  @override
  String get cacheKey => id;

  @override
  DateTime? get lastModified => updatedAt;

  @override
  bool get shouldCache => true;

  @override
  InvestmentAsset copyWith({
    String? id,
    String? portfolioId,
    String? name,
    String? ticker,
    bool clearTicker = false,
    AssetClass? assetClass,
    double? totalQuantity,
    double? investedCapital,
    double? currentPrice,
    DateTime? lastPriceUpdate,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? editionOrSet,
    bool clearEditionOrSet = false,
    String? conditionOrGrading,
    bool clearConditionOrGrading = false,
    String? serialOrCertNumber,
    bool clearSerialOrCertNumber = false,
    String? storageLocation,
    bool clearStorageLocation = false,
    bool? isPhysical,
  }) {
    return InvestmentAsset(
      id: id ?? this.id,
      portfolioId: portfolioId ?? this.portfolioId,
      name: name ?? this.name,
      ticker: clearTicker ? null : (ticker ?? this.ticker),
      assetClass: assetClass ?? this.assetClass,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      investedCapital: investedCapital ?? this.investedCapital,
      currentPrice: currentPrice ?? this.currentPrice,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editionOrSet: clearEditionOrSet ? null : (editionOrSet ?? this.editionOrSet),
      conditionOrGrading: clearConditionOrGrading ? null : (conditionOrGrading ?? this.conditionOrGrading),
      serialOrCertNumber: clearSerialOrCertNumber ? null : (serialOrCertNumber ?? this.serialOrCertNumber),
      storageLocation: clearStorageLocation ? null : (storageLocation ?? this.storageLocation),
      isPhysical: isPhysical ?? this.isPhysical,
    );
  }

  factory InvestmentAsset.fromMap(Map<String, dynamic> map) {
    final aClass = AssetClass.fromDb(map['asset_class'] as String?);
    return InvestmentAsset(
      id: map['id'] as String,
      portfolioId: map['portfolio_id'] as String,
      name: map['name'] as String,
      ticker: map['ticker'] as String?,
      assetClass: aClass,
      totalQuantity: (map['total_quantity'] as num?)?.toDouble() ?? 0.0,
      investedCapital: (map['invested_capital'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (map['current_price'] as num?)?.toDouble() ?? 0.0,
      lastPriceUpdate: DateTime.tryParse(map['last_price_update'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      editionOrSet: map['edition_or_set'] as String?,
      conditionOrGrading: map['condition_or_grading'] as String?,
      serialOrCertNumber: map['serial_or_cert_number'] as String?,
      storageLocation: map['storage_location'] as String?,
      isPhysical: (map['is_physical'] as bool?) ?? aClass.isPhysical,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'portfolio_id': portfolioId,
      'name': name,
      'ticker': ticker,
      'asset_class': assetClass.dbValue,
      'total_quantity': totalQuantity,
      'invested_capital': investedCapital,
      'current_price': currentPrice,
      'last_price_update': lastPriceUpdate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'edition_or_set': editionOrSet,
      'condition_or_grading': conditionOrGrading,
      'serial_or_cert_number': serialOrCertNumber,
      'storage_location': storageLocation,
      'is_physical': isPhysical,
    };
  }
}
