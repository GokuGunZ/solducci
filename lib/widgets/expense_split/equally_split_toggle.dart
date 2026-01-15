import 'package:flutter/material.dart';
import 'package:solducci/core/components/text/inline_toggle.dart';

/// Toggle inline nel testo "equamente diviso tra"
///
/// A domain-specific implementation of [InlineToggle] for expense splitting context.
///
/// ## Comportamento
/// - Testo normale: "equamente diviso tra"
/// - Quando disattivato: "~~equamente~~ diviso tra" (strikethrough)
/// - Clickabile solo sulla parola "equamente"
/// - Animazione di strikethrough (200ms)
///
/// ## Example
/// ```dart
/// EquallySplitToggle(
///   isEqual: splitState.isEqualSplit,
///   onToggle: () {
///     splitState.toggleEqualSplit();
///   },
/// )
/// ```
class EquallySplitToggle extends StatelessWidget {
  final bool isEqual;
  final VoidCallback onToggle;

  const EquallySplitToggle({
    super.key,
    required this.isEqual,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InlineToggle(
      isActive: isEqual,
      toggleText: 'Equamente',
      remainingText: ' diviso tra:',
      style: InlineToggleStyle(
        activeColor: Colors.blue.shade700,
        inactiveColor: Colors.grey.shade500,
        activeBackgroundColor: Colors.blue.shade50,
        inactiveBackgroundColor: Colors.transparent,
      ),
      onToggle: onToggle,
    );
  }
}
