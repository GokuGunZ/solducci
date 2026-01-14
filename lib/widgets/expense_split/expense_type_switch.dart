import 'package:flutter/material.dart';
import 'package:solducci/core/components/switches/slidable_switch.dart';

/// Tipo di spesa: personale o di gruppo
enum ExpenseType {
  personal,
  group;

  String get label {
    switch (this) {
      case ExpenseType.personal:
        return 'Personale';
      case ExpenseType.group:
        return 'Di Gruppo';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseType.personal:
        return Icons.person;
      case ExpenseType.group:
        return Icons.group;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseType.personal:
        return const Color(0xFF9333EA); // Purple-600 for Personal
      case ExpenseType.group:
        return const Color(0xFF10B981); // Green-500 for Group
    }
  }
}

/// Expense type switch using the generic [SlidableSwitch] component
///
/// A domain-specific implementation of [SlidableSwitch] for selecting between
/// personal and group expenses.
///
/// ## Features
/// - Clean, minimal design with pill-shaped chip
/// - Click on either side to switch
/// - Drag the colored chip to switch
/// - Smooth color gradient during drag
/// - Bidirectional animations
///
/// ## Example
/// ```dart
/// ExpenseTypeSwitch(
///   initialType: ExpenseType.personal,
///   onTypeChanged: (type) {
///     setState(() => selectedType = type);
///   },
/// )
/// ```
class ExpenseTypeSwitch extends StatelessWidget {
  final ExpenseType initialType;
  final ValueChanged<ExpenseType> onTypeChanged;
  final bool enabled;

  const ExpenseTypeSwitch({
    super.key,
    required this.initialType,
    required this.onTypeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SlidableSwitch<ExpenseType>(
      options: [
        SlidableSwitchOption(
          value: ExpenseType.personal,
          label: ExpenseType.personal.label,
          icon: ExpenseType.personal.icon,
          color: ExpenseType.personal.color,
        ),
        SlidableSwitchOption(
          value: ExpenseType.group,
          label: ExpenseType.group.label,
          icon: ExpenseType.group.icon,
          color: ExpenseType.group.color,
        ),
      ],
      initialValue: initialType,
      onChanged: onTypeChanged,
      enabled: enabled,
    );
  }
}
