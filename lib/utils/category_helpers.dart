import 'package:flutter/material.dart';
import '../models/expense_form.dart';

/// Centralized helper utilities for category styling and display
class CategoryHelpers {
  /// Get color for a given category type
  static Color getCategoryColor(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Colors.purple;
      case Tipologia.cibo:
        return Colors.green;
      case Tipologia.utenze:
        return Colors.blue;
      case Tipologia.prodottiCasa:
        return Colors.orange;
      case Tipologia.ristorante:
        return Colors.red;
      case Tipologia.tempoLibero:
        return Colors.pink;
      case Tipologia.altro:
        return Colors.grey;
      case Tipologia.investimento:
        return const Color(0xFF6366F1);
    }
  }

  /// Get icon for a given category type
  static IconData getCategoryIcon(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Icons.home;
      case Tipologia.cibo:
        return Icons.shopping_cart;
      case Tipologia.utenze:
        return Icons.bolt;
      case Tipologia.prodottiCasa:
        return Icons.cleaning_services;
      case Tipologia.ristorante:
        return Icons.restaurant;
      case Tipologia.tempoLibero:
        return Icons.sports_esports;
      case Tipologia.altro:
        return Icons.more_horiz;
      case Tipologia.investimento:
        return Icons.trending_up_rounded;
    }
  }

  /// Convert string to Tipologia safely
  static Tipologia fromString(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    for (final t in Tipologia.values) {
      if (t.name.toLowerCase() == lower || t.label.toLowerCase() == lower) {
        return t;
      }
    }
    if (lower.contains('casa') || lower.contains('affitto')) return Tipologia.affitto;
    if (lower.contains('utenze') || lower.contains('bollett')) return Tipologia.utenze;
    if (lower.contains('cibo') || lower.contains('spesa')) return Tipologia.cibo;
    if (lower.contains('ristorante')) return Tipologia.ristorante;
    if (lower.contains('invest')) return Tipologia.investimento;
    return Tipologia.altro;
  }

  /// Get icon from category string (used across transactions, recurring, etc.)
  static IconData getIconForCategory(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    if (lower == 'stipendio' || lower.contains('salario')) return Icons.payments_rounded;
    if (lower == 'rendita' || lower.contains('invest')) return Icons.trending_up_rounded;
    if (lower == 'rimborso') return Icons.reply_rounded;
    if (lower == 'regalo') return Icons.card_giftcard_rounded;
    if (lower == 'bonus') return Icons.star_rounded;

    final tipologia = fromString(categoryName);
    return getCategoryIcon(tipologia);
  }

  /// Get color from category string
  static Color getColorForCategory(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    if (lower == 'stipendio' || lower.contains('salario')) return const Color(0xFF10B981);
    if (lower == 'rendita' || lower.contains('invest')) return const Color(0xFF6366F1);
    if (lower == 'rimborso') return const Color(0xFF06B6D4);
    if (lower == 'regalo') return const Color(0xFFEC4899);

    final tipologia = fromString(categoryName);
    return getCategoryColor(tipologia);
  }
}
