import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'asset_class.g.dart';

@HiveType(typeId: 15)
enum AssetClass {
  @HiveField(0)
  etf('ETF', 'etf'),
  @HiveField(1)
  stock('Azioni', 'stock'),
  @HiveField(2)
  crypto('Criptovalute', 'crypto'),
  @HiveField(3)
  bond('Obbligazioni / BTP', 'bond'),
  @HiveField(4)
  commodity('Materie Prime / Oro', 'commodity'),
  @HiveField(5)
  realEstate('Immobili', 'real_estate'),
  @HiveField(6)
  pension('Fondo Pensione', 'pension'),
  @HiveField(7)
  cashEquivalent('Liquidità Vincolata / Deposito', 'cash_equivalent'),
  @HiveField(8)
  other('Altro', 'other'),
  @HiveField(9)
  collectible('Collezionismo & Carte TCG', 'collectible'),
  @HiveField(10)
  luxury('Beni di Lusso & Orologi', 'luxury');

  final String label;
  final String dbValue;
  const AssetClass(this.label, this.dbValue);

  bool get isPhysical {
    switch (this) {
      case AssetClass.collectible:
      case AssetClass.luxury:
      case AssetClass.commodity:
      case AssetClass.realEstate:
        return true;
      default:
        return false;
    }
  }

  IconData get icon {
    switch (this) {
      case AssetClass.etf:
        return Icons.pie_chart_rounded;
      case AssetClass.stock:
        return Icons.show_chart_rounded;
      case AssetClass.crypto:
        return Icons.currency_bitcoin_rounded;
      case AssetClass.bond:
        return Icons.account_balance_rounded;
      case AssetClass.commodity:
        return Icons.diamond_rounded;
      case AssetClass.realEstate:
        return Icons.apartment_rounded;
      case AssetClass.pension:
        return Icons.shield_rounded;
      case AssetClass.cashEquivalent:
        return Icons.lock_clock_rounded;
      case AssetClass.collectible:
        return Icons.style_rounded;
      case AssetClass.luxury:
        return Icons.watch_rounded;
      case AssetClass.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AssetClass.etf:
        return const Color(0xFF6366F1); // Indigo
      case AssetClass.stock:
        return const Color(0xFF3B82F6); // Blue
      case AssetClass.crypto:
        return const Color(0xFFF59E0B); // Amber
      case AssetClass.bond:
        return const Color(0xFF10B981); // Emerald
      case AssetClass.commodity:
        return const Color(0xFFEAB308); // Yellow
      case AssetClass.realEstate:
        return const Color(0xFFEC4899); // Pink
      case AssetClass.pension:
        return const Color(0xFF8B5CF6); // Purple
      case AssetClass.cashEquivalent:
        return const Color(0xFF06B6D4); // Cyan
      case AssetClass.collectible:
        return const Color(0xFFF97316); // Orange
      case AssetClass.luxury:
        return const Color(0xFFD946EF); // Fuchsia
      case AssetClass.other:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  static AssetClass fromDb(String? val) {
    if (val == null) return AssetClass.other;
    return AssetClass.values.firstWhere(
      (e) => e.dbValue == val || e.name == val,
      orElse: () => AssetClass.other,
    );
  }
}
