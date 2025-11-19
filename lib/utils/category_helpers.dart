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
    }
  }
}
