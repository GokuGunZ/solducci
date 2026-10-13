import 'dart:math';
import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_mosaic_engine.dart';
import 'package:solducci/widgets/dashboard/gallery/bento_widget_preview_factory.dart';
import 'package:solducci/widgets/dashboard/widget_gallery_sheet.dart';

/// Canvas blueprint che renderizza una simulazione visiva in scala dell'intera Bento Dashboard
/// per preset e modelli, utilizzando i veri layout grafici di BentoWidgetPreviewFactory.
class BentoDashboardBlueprint extends StatefulWidget {
  final List<BentoWidgetDef> layout;
  final Color? accentColor;
  final double maxHeight;
  final int columns;
  final bool allowScroll;
  final Function(BentoPlacedTile tile)? onTileTap;

  const BentoDashboardBlueprint({
    super.key,
    required this.layout,
    this.accentColor,
    this.maxHeight = 330.0,
    this.columns = 4,
    this.allowScroll = true,
    this.onTileTap,
  });

  @override
  State<BentoDashboardBlueprint> createState() => _BentoDashboardBlueprintState();
}

class _BentoDashboardBlueprintState extends State<BentoDashboardBlueprint> {
  String? _selectedTileId;

  @override
  Widget build(BuildContext context) {
    if (widget.layout.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: const Center(
          child: Text(
            'Nessun widget nel preset',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }

    // Risolve la griglia a Mosaico a 4 colonne per ottenere coordinate col e row
    final placedTiles = BentoMosaicEngine.computePlacedTiles(
      widgets: widget.layout,
      columns: widget.columns,
      packHoles: true,
    );

    int totalRows = 0;
    for (final t in placedTiles) {
      totalRows = max(totalRows, t.row + t.rowSpan);
    }
    totalRows = max(totalRows, 1);

    final selectedTile = _selectedTileId == null
        ? null
        : placedTiles.cast<BentoPlacedTile?>().firstWhere(
            (t) => t?.widgetDef.id == _selectedTileId,
            orElse: () => null,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const double gap = 6.0;
        const double padding = 10.0;

        // Larghezza e altezza scalata di ciascuna cella unitaria
        final innerWidth = max(availableWidth - (padding * 2), 120.0);
        final cellW = (innerWidth - ((widget.columns - 1) * gap)) / widget.columns;
        final cellH = cellW * 0.78; // Proporzione bilanciata per il Bento design

        final totalGridHeight = (totalRows * cellH) + ((totalRows - 1) * gap) + (padding * 2);

        Widget gridContent = Container(
          width: availableWidth,
          height: totalGridHeight,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (widget.accentColor ?? const Color(0xFF6366F1)).withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top specular highlight line
              Positioned(
                top: -padding + 1,
                left: -padding,
                right: -padding,
                height: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        (widget.accentColor ?? Colors.white).withOpacity(0.4),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Placed high-fidelity mini tiles
              for (final tile in placedTiles)
                _buildRealPreviewTile(tile, cellW, cellH, gap),
            ],
          ),
        );

        Widget finalGridWidget;
        if (totalGridHeight > widget.maxHeight) {
          if (widget.allowScroll) {
            finalGridWidget = SizedBox(
              height: widget.maxHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: gridContent,
                    ),
                    // Sfumatura di scroll in basso per indicare altro contenuto
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            finalGridWidget = SizedBox(
              height: widget.maxHeight,
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
        } else {
          finalGridWidget = gridContent;
        }

        // Se è selezionata una tessera, mostriamo una micro-barra informativa sotto
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            finalGridWidget,
            if (selectedTile != null) ...[
              const SizedBox(height: 8),
              _buildSelectedTileBanner(selectedTile),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRealPreviewTile(
    BentoPlacedTile tile,
    double cellW,
    double cellH,
    double gap,
  ) {
    final meta = WidgetCatalog.findByType(tile.widgetDef.type);
    final color = meta?.color ?? (widget.accentColor ?? const Color(0xFF818CF8));

    final left = tile.col * (cellW + gap);
    final top = tile.row * (cellH + gap);
    final width = (tile.colSpan * cellW) + ((tile.colSpan - 1) * gap);
    final height = (tile.rowSpan * cellH) + ((tile.rowSpan - 1) * gap);
    final size = BentoWidgetSize(tile.colSpan, tile.rowSpan);

    final isSelected = _selectedTileId == tile.widgetDef.id;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedTileId = isSelected ? null : tile.widgetDef.id;
          });
          widget.onTileTap?.call(tile);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // Vero widget in preview Dark OLED ad alta fedeltà
              BentoWidgetPreviewFactory.buildPreview(
                type: tile.widgetDef.type,
                size: size,
                accentColor: color,
                showBadge: false,
                borderRadius: 12.0,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tile.colSpan <= 1 ? 6.0 : 9.0,
                  vertical: 5.0,
                ),
              ),

              // Bordo specular reattivo al tocco / selezione
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTileBanner(BentoPlacedTile tile) {
    final meta = WidgetCatalog.findByType(tile.widgetDef.type);
    final color = meta?.color ?? const Color(0xFF818CF8);
    final icon = meta?.icon ?? Icons.widgets_rounded;
    final name = meta?.name ?? tile.widgetDef.type;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF18181D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$name (${tile.colSpan}x${tile.rowSpan})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => setState(() => _selectedTileId = null),
            child: const Icon(Icons.close, size: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
