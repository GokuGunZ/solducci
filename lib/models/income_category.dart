import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'income_category.g.dart';

@HiveType(typeId: 12)
enum IncomeCategory {
  @HiveField(0)
  stipendio('Stipendio / Salario', 'stipendio'),
  @HiveField(1)
  regalo('Regalo / Extra', 'regalo'),
  @HiveField(2)
  rimborso('Rimborso', 'rimborso'),
  @HiveField(3)
  rendita('Rendita / Dividendi', 'rendita'),
  @HiveField(4)
  vendite('Vendite Second-hand', 'vendite'),
  @HiveField(5)
  altro('Altro', 'altro');

  final String label;
  final String dbValue;
  const IncomeCategory(this.label, this.dbValue);

  IconData get icon {
    switch (this) {
      case IncomeCategory.stipendio:
        return Icons.work_outline_rounded;
      case IncomeCategory.regalo:
        return Icons.card_giftcard_rounded;
      case IncomeCategory.rimborso:
        return Icons.replay_rounded;
      case IncomeCategory.rendita:
        return Icons.trending_up_rounded;
      case IncomeCategory.vendite:
        return Icons.storefront_rounded;
      case IncomeCategory.altro:
        return Icons.attach_money_rounded;
    }
  }

  Color get color {
    switch (this) {
      case IncomeCategory.stipendio:
        return const Color(0xFF10B981); // Emerald
      case IncomeCategory.regalo:
        return const Color(0xFFEC4899); // Pink
      case IncomeCategory.rimborso:
        return const Color(0xFF3B82F6); // Blue
      case IncomeCategory.rendita:
        return const Color(0xFF8B5CF6); // Purple
      case IncomeCategory.vendite:
        return const Color(0xFFF59E0B); // Amber
      case IncomeCategory.altro:
        return const Color(0xFF6B7280); // Gray
    }
  }

  static IncomeCategory fromDb(String val) {
    switch (val.toLowerCase()) {
      case 'regalo':
        return IncomeCategory.regalo;
      case 'rimborso':
        return IncomeCategory.rimborso;
      case 'rendita':
        return IncomeCategory.rendita;
      case 'vendite':
        return IncomeCategory.vendite;
      case 'altro':
        return IncomeCategory.altro;
      case 'stipendio':
      default:
        return IncomeCategory.stipendio;
    }
  }
}
