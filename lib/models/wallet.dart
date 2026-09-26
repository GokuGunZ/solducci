import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:solducci/core/cache/cacheable_model.dart';
import 'package:solducci/models/wallet_type.dart';

part 'wallet.g.dart';

@HiveType(typeId: 9)
class Wallet implements CacheableModel<String> {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final WalletType type;

  @HiveField(4)
  final double initialBalance;

  @HiveField(5)
  final String colorHex;

  @HiveField(6)
  final String iconName;

  @HiveField(7)
  final bool isDefault;

  @HiveField(8)
  final bool isArchived;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  // Saldo corrente calcolato dinamicamente (non memorizzato come colonna statica)
  double currentBalance;

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.initialBalance,
    this.colorHex = '#10B981',
    this.iconName = 'account_balance',
    this.isDefault = false,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? currentBalance,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        currentBalance = currentBalance ?? initialBalance;

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

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
  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    WalletType? type,
    double? initialBalance,
    String? colorHex,
    String? iconName,
    bool? isDefault,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? currentBalance,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.dbValue,
      'initial_balance': initialBalance,
      'color_hex': colorHex,
      'icon_name': iconName,
      'is_default': isDefault,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Senza Nome',
      type: WalletType.fromDb(map['type'] as String? ?? 'bank'),
      initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0.0,
      colorHex: map['color_hex'] as String? ?? '#10B981',
      iconName: map['icon_name'] as String? ?? 'account_balance',
      isDefault: map['is_default'] as bool? ?? false,
      isArchived: map['is_archived'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
