import 'package:flutter/material.dart';

/// Rappresenta una sorgente dati selezionabile per un widget
class BentoConfigOption {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final Map<String, dynamic> props;
  final String? preview;

  const BentoConfigOption({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.props,
    this.preview,
  });
}

/// Dati aggregati per il modal di configurazione di un widget
class BentoWidgetConfigData {
  final String title;
  final String description;
  final List<BentoConfigOption> options;
  final String? defaultOptionId;
  final bool isMultiSelect;

  const BentoWidgetConfigData({
    required this.title,
    required this.description,
    required this.options,
    this.defaultOptionId,
    this.isMultiSelect = false,
  });
}
