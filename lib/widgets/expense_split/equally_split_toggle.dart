import 'package:flutter/material.dart';

/// Toggle inline nel testo "equamente diviso tra"
///
/// Comportamento:
/// - Testo normale: "equamente diviso tra"
/// - Quando disattivato: "~~equamente~~ diviso tra" (strikethrough)
/// - Clickabile solo sulla parola "equamente"
/// - Animazione di strikethrough (200ms)
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
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // "equamente" (clickable)
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isEqual ? Colors.blue.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isEqual ? Colors.blue.shade700 : Colors.grey.shade500,
                decoration: isEqual
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
                decorationThickness: 2,
              ),
              child: const Text('Equamente'),
            ),
          ),
        ),

        // " diviso tra:" (non clickable)
        Text(
          ' diviso tra:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
