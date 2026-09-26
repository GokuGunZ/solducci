import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:solducci/core/cache/cacheable_model.dart';

part 'investment_portfolio.g.dart';

@HiveType(typeId: 14)
class InvestmentPortfolio implements CacheableModel<String> {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String? groupId;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String? brokerName;

  @HiveField(5)
  final String colorHex;

  @HiveField(6)
  final String icon;

  @HiveField(7)
  final String? description;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  InvestmentPortfolio({
    required this.id,
    required this.userId,
    this.groupId,
    required this.name,
    this.brokerName,
    this.colorHex = '#6366F1',
    this.icon = 'trending_up',
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isShared => groupId != null;

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'pie_chart':
        return Icons.pie_chart_rounded;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin_rounded;
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'apartment':
        return Icons.apartment_rounded;
      case 'trending_up':
      default:
        return Icons.trending_up_rounded;
    }
  }

  @override
  String get cacheKey => id;

  @override
  DateTime? get lastModified => updatedAt;

  @override
  bool get shouldCache => true;

  @override
  InvestmentPortfolio copyWith({
    String? id,
    String? userId,
    String? groupId,
    bool clearGroupId = false,
    String? name,
    String? brokerName,
    String? colorHex,
    String? icon,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentPortfolio(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      name: name ?? this.name,
      brokerName: brokerName ?? this.brokerName,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InvestmentPortfolio.fromMap(Map<String, dynamic> map) {
    return InvestmentPortfolio(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      groupId: map['group_id'] as String?,
      name: map['name'] as String,
      brokerName: map['broker_name'] as String?,
      colorHex: map['color_hex'] as String? ?? '#6366F1',
      icon: map['icon'] as String? ?? 'trending_up',
      description: map['description'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'name': name,
      'broker_name': brokerName,
      'color_hex': colorHex,
      'icon': icon,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
