import 'dart:math';
import 'package:solducci/models/dashboard_config.dart';

/// Rappresenta un tile calcolato e posizionato sulla griglia bento
class BentoPlacedTile {
  final BentoWidgetDef widgetDef;
  final int col; // Colonna di partenza (0 .. columns-1)
  final int row; // Riga di partenza (0 .. N)
  final int colSpan; // Larghezza in colonne
  final int rowSpan; // Altezza in righe

  const BentoPlacedTile({
    required this.widgetDef,
    required this.col,
    required this.row,
    required this.colSpan,
    required this.rowSpan,
  });

  @override
  String toString() => 'PlacedTile(${widgetDef.id}, col: $col, row: $row, ${colSpan}x$rowSpan)';
}

/// Motore intelligente di posizionamento a Mosaico e Breakpoint per Bento Dashboard
class BentoMosaicEngine {
  /// Determina il numero di colonne in base alla larghezza disponibile
  static int getColumnCount(double screenWidth) {
    if (screenWidth >= 1000) return 8;
    if (screenWidth >= 640) return 6;
    return 4; // Mobile default
  }

  /// Risolve l'incastro a Mosaico (Bin Packing 2D) per un elenco di definizioni di widget.
  /// Se [packHoles] è true, cerca attivamente di colmare i vuoti anticipando widget compatibili
  /// più piccoli prima di avanzare a nuove righe, evitando i classici "buchi neri".
  static List<BentoPlacedTile> computePlacedTiles({
    required List<BentoWidgetDef> widgets,
    required int columns,
    bool packHoles = true,
  }) {
    if (widgets.isEmpty) return [];

    final List<BentoPlacedTile> placedTiles = [];
    final Set<String> occupiedCells = {}; // Format: "col,row"
    final List<BentoWidgetDef> remaining = List.from(widgets);

    int currentRow = 0;
    int currentCol = 0;

    bool isOccupied(int c, int r) => occupiedCells.contains('$c,$r');

    void occupy(int startCol, int startRow, int cSpan, int rSpan) {
      for (int r = 0; r < rSpan; r++) {
        for (int c = 0; c < cSpan; c++) {
          occupiedCells.add('${startCol + c},${startRow + r}');
        }
      }
    }

    bool canFitAt(int startCol, int startRow, int cSpan, int rSpan) {
      if (startCol + cSpan > columns) return false;
      for (int r = 0; r < rSpan; r++) {
        for (int c = 0; c < cSpan; c++) {
          if (isOccupied(startCol + c, startRow + r)) {
            return false;
          }
        }
      }
      return true;
    }

    // Limita la larghezza massima del widget alle colonne effettive disponibili
    int normalizeColSpan(BentoWidgetDef def) {
      return min(def.size.crossAxisCellCount, columns);
    }

    int normalizeRowSpan(BentoWidgetDef def) {
      return max(1, def.size.mainAxisCellCount);
    }

    // Scansione e posizionamento a mosaico
    while (remaining.isNotEmpty) {
      // 1. Avanza se la cella corrente è già occupata
      while (isOccupied(currentCol, currentRow)) {
        currentCol++;
        if (currentCol >= columns) {
          currentCol = 0;
          currentRow++;
        }
      }

      int candidateIndex = -1;

      if (packHoles) {
        // Cerca il primo elemento tra i rimanenti che entra esattamente nello slot libero attuale
        for (int i = 0; i < remaining.length; i++) {
          final item = remaining[i];
          final cSpan = normalizeColSpan(item);
          final rSpan = normalizeRowSpan(item);
          if (canFitAt(currentCol, currentRow, cSpan, rSpan)) {
            candidateIndex = i;
            break;
          }
        }
      } else {
        // Modalità rigida: prende solo il primo in lista se entra
        final item = remaining.first;
        final cSpan = normalizeColSpan(item);
        final rSpan = normalizeRowSpan(item);
        if (canFitAt(currentCol, currentRow, cSpan, rSpan)) {
          candidateIndex = 0;
        }
      }

      if (candidateIndex != -1) {
        final def = remaining.removeAt(candidateIndex);
        final cSpan = normalizeColSpan(def);
        final rSpan = normalizeRowSpan(def);

        placedTiles.add(BentoPlacedTile(
          widgetDef: def,
          col: currentCol,
          row: currentRow,
          colSpan: cSpan,
          rowSpan: rSpan,
        ));

        occupy(currentCol, currentRow, cSpan, rSpan);

        // Avanza oltre il widget appena piazzato
        currentCol += cSpan;
        if (currentCol >= columns) {
          currentCol = 0;
          currentRow++;
        }
      } else {
        // Nessun elemento entra nello spazio rimasto in questa riga:
        // Avanza alla colonna successiva o riga successiva
        currentCol++;
        if (currentCol >= columns) {
          currentCol = 0;
          currentRow++;
        }
      }
    }

    return placedTiles;
  }

  /// Ritorna la lista riordinata dei widget risultante dal calcolo del Mosaico
  static List<BentoWidgetDef> reorderForMosaic({
    required List<BentoWidgetDef> widgets,
    required int columns,
  }) {
    final placed = computePlacedTiles(widgets: widgets, columns: columns, packHoles: true);
    return placed.map((t) => t.widgetDef).toList();
  }

  /// Calcola il layout con Ghost Displacement durante il Drag & Drop.
  /// Inserisce un placeholder fantasma alla posizione bersaglio mantenendo la coerenza del mosaico.
  static List<BentoWidgetDef> previewDisplacement({
    required List<BentoWidgetDef> currentLayout,
    required BentoWidgetDef draggingItem,
    required int targetIndex,
  }) {
    final cleanLayout = List<BentoWidgetDef>.from(currentLayout)
      ..removeWhere((w) => w.id == draggingItem.id);

    final safeIndex = targetIndex.clamp(0, cleanLayout.length);
    cleanLayout.insert(safeIndex, draggingItem);
    return cleanLayout;
  }
}
