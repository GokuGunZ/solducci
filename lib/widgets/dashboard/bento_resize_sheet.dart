import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/dashboard_widget_factory.dart';
import 'package:solducci/widgets/dashboard/widget_gallery_sheet.dart';

/// Modal bottom sheet per il ridimensionamento visivo e interattivo di un widget (Direzione C)
class BentoResizeSheet extends StatelessWidget {
  final BentoWidgetDef widgetDef;
  final Function(BentoWidgetSize newSize) onSizeSelected;

  const BentoResizeSheet({
    super.key,
    required this.widgetDef,
    required this.onSizeSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required BentoWidgetDef widgetDef,
    required Function(BentoWidgetSize newSize) onSizeSelected,
  }) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BentoResizeSheet(
        widgetDef: widgetDef,
        onSizeSelected: onSizeSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = WidgetCatalog.findByType(widgetDef.type);
    final allowedSizes = DashboardWidgetFactory.getSupportedSizes(widgetDef.type);
    final currentSize = widgetDef.size;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // OLED Dark Surface
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (meta?.color ?? const Color(0xFF6366F1)).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  meta?.icon ?? Icons.widgets_rounded,
                  color: meta?.color ?? const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta?.name ?? widgetDef.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seleziona il formato del tile',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Size Selector Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: allowedSizes.map((size) {
              final isSelected = size == currentSize;
              final label = _getSizeLabel(size);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSizeSelected(size);
                  Navigator.of(context).pop();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withOpacity(0.2)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mini visual aspect ratio box
                      Container(
                        width: size.crossAxisCellCount * 14.0,
                        height: size.mainAxisCellCount * 10.5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${size.crossAxisCellCount}x${size.mainAxisCellCount}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getSizeLabel(BentoWidgetSize size) {
    if (size.crossAxisCellCount == 1 && size.mainAxisCellCount == 1) return 'Icona';
    if (size.crossAxisCellCount == 2 && size.mainAxisCellCount == 1) return 'Mini-Banner';
    if (size.crossAxisCellCount == 4 && size.mainAxisCellCount == 1) return 'Banner Sottile';
    if (size.crossAxisCellCount == 2 && size.mainAxisCellCount == 2) return 'Compatto';
    if (size.crossAxisCellCount == 4 && size.mainAxisCellCount == 2) return 'Banner Esteso';
    if (size.crossAxisCellCount == 2 && size.mainAxisCellCount == 3) return 'Medio';
    if (size.crossAxisCellCount == 3 && size.mainAxisCellCount == 2) return 'Panoramico';
    if (size.crossAxisCellCount == 2 && size.mainAxisCellCount == 4) return 'Lista Densa';
    if (size.crossAxisCellCount >= 3 && size.mainAxisCellCount >= 3) return 'Grande';
    return '${size.crossAxisCellCount}x${size.mainAxisCellCount}';
  }
}
