import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';

/// Renderer per le anteprime visive in tempo reale dei widget dentro la Gallery
class BentoWidgetPreviewFactory {
  /// Restituisce le dimensioni geometriche proporzionali del widget da visualizzare nella Gallery
  static Size getPreviewSize(BentoWidgetSize size, double maxWidth) {
    final int cols = size.crossAxisCellCount;
    final int rows = size.mainAxisCellCount;

    if (cols <= 1 && rows <= 1) {
      // 1x1: compatto e squadrato
      return const Size(115.0, 95.0);
    } else if (cols == 2 && rows == 1) {
      // 2x1: pillola orizzontale
      return Size((maxWidth * 0.62).clamp(180.0, 225.0), 85.0);
    } else if (cols == 2 && rows == 2) {
      // 2x2: quadrato medio
      return Size((maxWidth * 0.62).clamp(180.0, 225.0), 125.0);
    } else if (cols == 2 && rows >= 3) {
      // 2x3: verticale alto
      return Size((maxWidth * 0.62).clamp(180.0, 225.0), 150.0);
    } else if (cols == 3) {
      // 3x2: medio-largo
      return Size((maxWidth * 0.85).clamp(240.0, 300.0), 125.0);
    } else if (cols >= 4) {
      // 4x2: panoramico intero
      return Size(maxWidth.clamp(260.0, 360.0), 125.0);
    } else {
      return Size((maxWidth * 0.62).clamp(180.0, 220.0), 115.0);
    }
  }

  static Widget buildPreview({
    required String type,
    required BentoWidgetSize size,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background soft ambient glow
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.08),
              ),
            ),
          ),
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
                    accentColor.withOpacity(0.35),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Body content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: _buildTypeContent(type, size, accentColor),
          ),
          // Size badge in bottom-right corner
          Positioned(
            bottom: 5,
            right: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                '${size.crossAxisCellCount}x${size.mainAxisCellCount}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTypeContent(String type, BentoWidgetSize size, Color color) {
    switch (type) {
      case 'balance':
        return _buildBalancePreview(size, color);
      case 'monthly_burn_rate':
        return _buildBurnRatePreview(size, color);
      case 'quick_expense':
        return _buildQuickExpensePreview(size, color);
      case 'investment_summary':
        return _buildInvestmentPreview(size, color);
      case 'focus_tasks':
        return _buildFocusTasksPreview(size, color);
      case 'habit_tracker':
        return _buildHabitPreview(size, color);
      case 'hero_countdown':
        return _buildCountdownPreview(size, color);
      case 'daily_progress':
        return _buildDailyProgressPreview(size, color);
      case 'shopping_quick_list':
        return _buildShoppingPreview(size, color);
      case 'pantry_alert':
        return _buildPantryPreview(size, color);
      case 'note_stack':
        return _buildNoteStackPreview(size, color);
      case 'recent_notes':
        return _buildRecentNotesPreview(size, color);
      case 'recent_markdown':
        return _buildMarkdownPreview(size, color);
      case 'unresolved_asterisks':
        return _buildAsterisksPreview(size, color);
      default:
        return _buildGenericPreview(type, size, color);
    }
  }

  // --- Finanze ---

  static Widget _buildBalancePreview(BentoWidgetSize size, Color color) {
    final is1x1 = size.crossAxisCellCount <= 1 && size.mainAxisCellCount <= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              'TOTALE CONTI',
              style: TextStyle(
                color: Colors.white54,
                fontSize: is1x1 ? 8.5 : 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '+2.450,80 €',
            style: TextStyle(
              color: color,
              fontSize: is1x1 ? 15 : 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (!is1x1) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 4),
              const Text(
                'Liquidità attiva',
                style: TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static Widget _buildBurnRatePreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded, size: 13, color: color),
                const SizedBox(width: 4),
                const Text(
                  'BURN RATE',
                  style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text('68% mese', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: const Text(
            '640,00 €',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: 0.68,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  static Widget _buildQuickExpensePreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.flash_on_rounded, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+ Registra Spesa',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tap rapido a 1-click',
                  style: TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildInvestmentPreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PORTAFOGLIO ETF', style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('+5.8%', style: TextStyle(color: Color(0xFF34D399), fontSize: 8.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: const Text(
            '14.320,50 €',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        const Text('3 asset monitorati', style: TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  // --- Tempo & Focus ---

  static Widget _buildFocusTasksPreview(BentoWidgetSize size, Color color) {
    final showMultiple = size.mainAxisCellCount >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_rounded, size: 13, color: color),
            const SizedBox(width: 4),
            const Text('FOCUS OGGI', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('3 task', style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildMiniTaskRow('Inviare report mensile', true),
        if (showMultiple) ...[
          const SizedBox(height: 4),
          _buildMiniTaskRow('Call pianificazione Q4', false),
        ],
      ],
    );
  }

  static Widget _buildMiniTaskRow(String title, bool done) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: done ? const Color(0xFF10B981) : Colors.white24,
              width: 1.1,
            ),
          ),
          child: done ? const Icon(Icons.check, size: 7, color: Color(0xFF10B981)) : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: done ? Colors.white38 : Colors.white70,
              fontSize: 10.5,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _buildHabitPreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.repeat_rounded, size: 13, color: color),
            const SizedBox(width: 4),
            const Text('ABITUDINI', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('🔥 14 gg', style: TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        const Text('Allenamento 30m', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['L', 'M', 'M', 'G', 'V', 'S', 'D'].map((day) {
            final isDone = day != 'D';
            return Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: isDone ? color.withOpacity(0.25) : Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: isDone ? color : Colors.white12),
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: isDone ? Colors.white : Colors.white38,
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget _buildCountdownPreview(BentoWidgetSize size, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('-12', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
              Text('GIORNI', style: TextStyle(color: color.withOpacity(0.8), fontSize: 6.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✈️ Viaggio in Giappone', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2),
              Text('24 Ottobre 2026', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildDailyProgressPreview(BentoWidgetSize size, Color color) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                value: 0.75,
                backgroundColor: Colors.white10,
                color: color,
                strokeWidth: 3.0,
              ),
            ),
            const Text('75%', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Routine Oggi', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text('3 di 4 completati', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
          ],
        ),
      ],
    );
  }

  // --- Casa & Spazio ---

  static Widget _buildShoppingPreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 13, color: color),
            const SizedBox(width: 4),
            const Text('LISTA SPESA', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('4 da fare', style: TextStyle(color: Colors.white38, fontSize: 8.5)),
          ],
        ),
        const SizedBox(height: 6),
        _buildMiniShoppingItem('Latte d\'avena', 'x2'),
        const SizedBox(height: 3),
        _buildMiniShoppingItem('Caffè espresso', '1 conf.'),
      ],
    );
  }

  static Widget _buildMiniShoppingItem(String name, String qty) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(qty, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
      ],
    );
  }

  static Widget _buildPantryPreview(BentoWidgetSize size, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.18),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
          ),
          child: const Icon(Icons.kitchen_rounded, color: Color(0xFFF87171), size: 16),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scorte Dispensa', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text('2 scorte in esaurimento', style: TextStyle(color: Color(0xFFF87171), fontSize: 9.5)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildAsterisksPreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline_rounded, size: 13, color: color),
            const SizedBox(width: 4),
            const Text('DA RISOLVERE (*)', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        const Text('3 note in sospeso', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 1),
        const Text('Scontrini da chiarire', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
      ],
    );
  }

  // --- Note & Idee ---

  static Widget _buildNoteStackPreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 5),
            const Text('STICKY NOTE', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Promemoria veloce', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 1),
        const Text('Idee e scadenze personali...', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
      ],
    );
  }

  static Widget _buildRecentNotesPreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, size: 12, color: color),
            const SizedBox(width: 4),
            const Text('NOTE RECENTI', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        const Text('Bozza budget 2026', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        const Text('Modificato 2 ore fa', style: TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  static Widget _buildMarkdownPreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('# MD', style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 5),
            const Text('DOCUMENTI', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        const Text('## Specifiche', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 1),
        const Text('Architettura modulare...', style: TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  static Widget _buildGenericPreview(String type, BentoWidgetSize size, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.widgets_outlined, size: 22, color: color),
          const SizedBox(height: 3),
          Text(type.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
