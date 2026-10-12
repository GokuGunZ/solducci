import 'dart:math';
import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_mosaic_engine.dart';
import 'package:solducci/widgets/dashboard/widget_gallery_sheet.dart';

/// Mini-canvas blueprint che renderizza una simulazione visiva in scala dell'intera Bento Dashboard
/// per preset e modelli, senza invocare widget complessi o chiamate di rete.
class BentoDashboardBlueprint extends StatelessWidget {
  final List<BentoWidgetDef> layout;
  final Color? accentColor;
  final double maxHeight;
  final int columns;

  const BentoDashboardBlueprint({
    super.key,
    required this.layout,
    this.accentColor,
    this.maxHeight = 155.0,
    this.columns = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (layout.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(
          child: Text(
            'Nessun widget nel preset',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      );
    }

    // Risolve la griglia a Mosaico a 4 colonne per ottenere coordinate col e row
    final placedTiles = BentoMosaicEngine.computePlacedTiles(
      widgets: layout,
      columns: columns,
      packHoles: true,
    );

    int totalRows = 0;
    for (final t in placedTiles) {
      totalRows = max(totalRows, t.row + t.rowSpan);
    }
    totalRows = max(totalRows, 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const double gap = 5.0;
        const double padding = 8.0;

        // Larghezza e altezza scalata di ciascuna cella unitaria
        final innerWidth = max(availableWidth - (padding * 2), 100.0);
        final cellW = (innerWidth - ((columns - 1) * gap)) / columns;
        final cellH = cellW * 0.72; // Proporzione armoniosa della cella Bento

        final totalGridHeight = (totalRows * cellH) + ((totalRows - 1) * gap) + (padding * 2);

        Widget gridContent = Container(
          width: availableWidth,
          height: totalGridHeight,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (accentColor ?? const Color(0xFF6366F1)).withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Top specular highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        (accentColor ?? Colors.white).withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Placed mini tiles
              for (final tile in placedTiles)
                _buildMiniTile(tile, cellW, cellH, gap),
            ],
          ),
        );

        // Se l'altezza calcolata supera maxHeight, scalamo uniformemente
        if (totalGridHeight > maxHeight) {
          return SizedBox(
            height: maxHeight,
            width: availableWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: availableWidth,
                height: totalGridHeight,
                child: gridContent,
              ),
            ),
          );
        }

        return gridContent;
      },
    );
  }

  Widget _buildMiniTile(BentoPlacedTile tile, double cellW, double cellH, double gap) {
    final meta = WidgetCatalog.findByType(tile.widgetDef.type);
    final color = meta?.color ?? const Color(0xFF818CF8);
    final icon = meta?.icon ?? Icons.widgets_rounded;
    final name = meta?.name ?? tile.widgetDef.type;

    final left = tile.col * (cellW + gap);
    final top = tile.row * (cellH + gap);
    final width = (tile.colSpan * cellW) + ((tile.colSpan - 1) * gap);
    final height = (tile.rowSpan * cellH) + ((tile.rowSpan - 1) * gap);

    final isSingleCell = tile.colSpan <= 1 && tile.rowSpan <= 1;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF18181D),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: color.withOpacity(0.32),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Ambient micro glow in corner
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                ),
              ),
            ),
            // Top mini specular line
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 0.8,
              child: Container(
                color: color.withOpacity(0.2),
              ),
            ),
            // Tile content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
              child: isSingleCell
                  ? Center(
                      child: Icon(icon, size: 14, color: color),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Micro Header: Icon + Name
                        Row(
                          children: [
                            Icon(icon, size: 11, color: color),
                            const SizedBox(width: 3.5),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Micro Graphic representation based on widget type
                        _buildMicroGraphic(tile.widgetDef.type, color, tile.colSpan, tile.rowSpan),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroGraphic(String type, Color color, int colSpan, int rowSpan) {
    switch (type) {
      case 'balance':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: color.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Container(
              width: 14,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );

      case 'monthly_burn_rate':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: 0.65,
                minHeight: 3,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );

      case 'focus_tasks':
      case 'shopping_quick_list':
        return Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1.5),
                border: Border.all(color: color, width: 0.8),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ],
        );

      case 'hero_countdown':
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '-14 gg',
                style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                color: Colors.white24,
              ),
            ),
          ],
        );

      case 'habit_tracker':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            5,
            (i) => Container(
              width: 4.5,
              height: 4.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < 4 ? color : Colors.white12,
              ),
            ),
          ),
        );

      default:
        return Row(
          children: [
            Container(
              width: 18,
              height: 3.5,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 3.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        );
    }
  }
}
