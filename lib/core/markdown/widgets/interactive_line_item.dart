import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/line_element.dart';

/// Single interactive line element widget with touch-accessible hit-area
/// and non-destructive styling modifiers.
class InteractiveLineItem extends StatelessWidget {
  final LineElement element;
  final LineModifierStyle? modifier;
  final bool isDataBound;
  final ValueChanged<int>? onToggleCheckbox;
  final ValueChanged<LineElement>? onLongPressMarker;

  const InteractiveLineItem({
    super.key,
    required this.element,
    this.modifier,
    this.isDataBound = false,
    this.onToggleCheckbox,
    this.onLongPressMarker,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve active modifier based on condition
    final activeMod = _resolveModifier();

    // Base text style depending on element classification
    TextStyle baseStyle = _resolveBaseTextStyle(theme);

    // Apply active non-destructive modifiers
    if (activeMod != null) {
      final decorations = <TextDecoration>[];
      if (activeMod.strikethrough) decorations.add(TextDecoration.lineThrough);
      if (activeMod.underline) decorations.add(TextDecoration.underline);

      baseStyle = baseStyle.copyWith(
        decoration: decorations.isNotEmpty ? TextDecoration.combine(decorations) : null,
        fontWeight: activeMod.bold ? FontWeight.bold : baseStyle.fontWeight,
        color: activeMod.textColor ?? baseStyle.color,
        backgroundColor: activeMod.backgroundColor,
      );
    }

    final double indentPadding = element.indentLevel * 20.0;

    return Padding(
      padding: EdgeInsets.only(left: indentPadding, top: 3.0, bottom: 3.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: activeMod?.opacity ?? 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Touch-accessible marker hit-area (minimum 44x44pt)
            _buildMarkerHitArea(context, isDark),
            const SizedBox(width: 8),

            // Line Text Body
            Expanded(
              child: Text(
                element.textContent,
                style: baseStyle,
              ),
            ),

            // Discrete Data-Binding Synchronized Indicator
            if (isDataBound || element.syncState != LineSyncState.none)
              _buildSyncIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncIndicator() {
    Color color;
    String message;
    IconData? icon;

    switch (element.syncState) {
      case LineSyncState.synced:
      case LineSyncState.certain:
      case LineSyncState.probable:
        color = const Color(0xFF10B981);
        message = 'Sincronizzato con fonte dati';
        break;
      case LineSyncState.pending:
        color = const Color(0xFFF59E0B);
        message = 'Modifiche in attesa di sincronizzazione';
        break;
      case LineSyncState.ambiguous:
        color = const Color(0xFFF97316);
        message = 'Associazione ambigua: sincronizzazione sospesa per sicurezza';
        icon = Icons.help_outline;
        break;
      case LineSyncState.conflict:
        color = const Color(0xFFEF4444);
        message = 'Conflitto di sincronizzazione con la fonte dati';
        icon = Icons.warning_amber_rounded;
        break;
      case LineSyncState.unlinked:
        color = const Color(0xFF9CA3AF);
        message = 'Elemento scollegato dalla fonte dati';
        break;
      case LineSyncState.none:
        color = const Color(0xFF10B981);
        message = 'Collegato e sincronizzato con fonte dati';
        break;
    }

    return Tooltip(
      message: message,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: icon != null
            ? Icon(icon, size: 12, color: color)
            : Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  LineModifierStyle? _resolveModifier() {
    if (modifier == null) {
      return element.isChecked ? LineModifierStyle.checkedDefault : null;
    }
    if (modifier!.applyCondition == ModifierCondition.whenChecked) {
      return element.isChecked ? modifier : null;
    }
    return modifier;
  }

  Widget _buildMarkerHitArea(BuildContext context, bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (element.markerType == LineMarkerType.checkbox) {
          HapticFeedback.lightImpact();
          onToggleCheckbox?.call(element.lineIndex);
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPressMarker?.call(element);
      },
      child: Semantics(
        button: true,
        label: _semanticLabel(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: _buildMarkerIcon(isDark),
        ),
      ),
    );
  }

  Widget _buildMarkerIcon(bool isDark) {
    switch (element.markerType) {
      case LineMarkerType.checkbox:
        return Icon(
          element.isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: element.isChecked ? const Color(0xFF10B981) : (isDark ? Colors.white54 : Colors.black45),
        );
      case LineMarkerType.bullet:
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            shape: BoxShape.circle,
          ),
        );
      case LineMarkerType.numbered:
        return Text(
          element.markerRaw,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        );
      case LineMarkerType.quote:
        return Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case LineMarkerType.header:
        return Text(
          'H${element.headerLevel}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF818CF8),
          ),
        );
      case LineMarkerType.codeFence:
        return const Icon(Icons.code, size: 16, color: Color(0xFF38BDF8));
      case LineMarkerType.rawText:
        return const SizedBox(width: 8);
    }
  }

  TextStyle _resolveBaseTextStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    switch (element.markerType) {
      case LineMarkerType.header:
        final sizes = [24.0, 20.0, 18.0, 16.0, 14.0, 13.0];
        final size = (element.headerLevel >= 1 && element.headerLevel <= 6)
            ? sizes[element.headerLevel - 1]
            : 16.0;
        return TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        );
      case LineMarkerType.codeFence:
        return const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(0xFF38BDF8),
          height: 1.4,
        );
      case LineMarkerType.quote:
        return TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 14,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          height: 1.4,
        );
      default:
        return TextStyle(
          fontSize: 14,
          color: defaultColor,
          height: 1.4,
        );
    }
  }

  String _semanticLabel() {
    switch (element.markerType) {
      case LineMarkerType.checkbox:
        return element.isChecked
            ? 'Elemento completato. Tocca per deselezionare, tieni premuto per personalizzare.'
            : 'Elemento da fare. Tocca per completare, tieni premuto per personalizzare.';
      case LineMarkerType.bullet:
        return 'Punto elenco. Tieni premuto per personalizzare lo stile.';
      case LineMarkerType.numbered:
        return 'Elemento numerato ${element.markerRaw}. Tieni premuto per personalizzare.';
      default:
        return 'Elemento di linea. Tieni premuto per opzioni.';
    }
  }
}
