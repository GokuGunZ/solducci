import 'package:flutter/material.dart';
import 'package:solducci/core/components/text/inline_toggle.dart';

/// Toggle inline per la visualizzazione percentuale
///
/// A domain-specific implementation of [InlineToggle] for toggling between
/// percentage and currency display.
///
/// ## Comportamento
/// - Testo normale: "(%) diviso tra"
/// - Quando attivo: mostra importi in percentuale (es: 33.33%)
/// - Quando disattivo: mostra importi in euro (es: 10.00€)
/// - Clickabile solo sul simbolo "(%)"
/// - Animazione di strikethrough quando disattivo (200ms)
/// - Compatibile con "Equamente" toggle
///
/// ## Example
/// ```dart
/// PercentageToggle(
///   isPercentage: splitState.isPercentageView,
///   onToggle: () {
///     splitState.togglePercentageView();
///   },
/// )
/// ```
class PercentageToggle extends StatelessWidget {
  final bool isPercentage;
  final VoidCallback onToggle;

  const PercentageToggle({
    super.key,
    required this.isPercentage,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InlineToggle(
      isActive: isPercentage,
      toggleText: '(%)',
      remainingText: '', // No remaining text, used inline before "Equamente"
      style: InlineToggleStyle(
        activeColor: Colors.purple.shade700,
        inactiveColor: Colors.grey.shade500,
        activeBackgroundColor: Colors.purple.shade50,
        inactiveBackgroundColor: Colors.transparent,
        fontSize: 13,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      onToggle: onToggle,
    );
  }
}
