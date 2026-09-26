import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'wallet_type.g.dart';

@HiveType(typeId: 10)
enum WalletType {
  @HiveField(0)
  bank('Conto Bancario', 'bank'),
  @HiveField(1)
  cash('Contanti', 'cash'),
  @HiveField(2)
  savings('Salvadanaio / Risparmi', 'savings'),
  @HiveField(3)
  creditCard('Carta di Credito', 'credit_card');

  final String label;
  final String dbValue;
  const WalletType(this.label, this.dbValue);

  IconData get icon {
    switch (this) {
      case WalletType.bank:
        return Icons.account_balance_rounded;
      case WalletType.cash:
        return Icons.payments_rounded;
      case WalletType.savings:
        return Icons.savings_rounded;
      case WalletType.creditCard:
        return Icons.credit_card_rounded;
    }
  }

  Color get color {
    switch (this) {
      case WalletType.bank:
        return const Color(0xFF10B981); // Emerald
      case WalletType.cash:
        return const Color(0xFFF59E0B); // Amber
      case WalletType.savings:
        return const Color(0xFF3B82F6); // Blue
      case WalletType.creditCard:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  static WalletType fromDb(String val) {
    switch (val.toLowerCase()) {
      case 'cash':
        return WalletType.cash;
      case 'savings':
        return WalletType.savings;
      case 'credit_card':
        return WalletType.creditCard;
      case 'bank':
      default:
        return WalletType.bank;
    }
  }
}
