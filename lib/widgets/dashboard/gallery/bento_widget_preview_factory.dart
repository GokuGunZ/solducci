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
    bool showBadge = true,
    double borderRadius = 18.0,
    EdgeInsets? contentPadding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(borderRadius),
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
            padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: _buildTypeContent(type, size, accentColor),
          ),
          // Size badge in bottom-right corner
          if (showBadge)
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
      case 'recurring_movements':
        return _buildRecurringMovementsPreview(size, color);
      case 'life_os_capture':
        return _buildLifeOsCapturePreview(size, color);
      case 'life_os_recent_seeds':
        return _buildLifeOsSeedsPreview(size, color);
      case 'life_os_active_entities':
        return _buildLifeOsActivePreview(size, color);
      case 'life_os_pinned_entity':
        return _buildLifeOsPinnedPreview(size, color);
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
            '+2.450,80 â‚¬',
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
                'LiquiditÃ  attiva',
                style: TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static Widget _buildRecurringMovementsPreview(BentoWidgetSize size, Color color) {
    final isCompact = size.crossAxisCellCount <= 2 && size.mainAxisCellCount <= 1;

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.repeat_rounded, size: 12, color: color),
                  const SizedBox(width: 4),
                  const Text(
                    'Ricorrenti',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Text(
                'â‚¬ 240/m',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Netflix Premium',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('tra 3gg', style: TextStyle(color: Colors.white70, fontSize: 8)),
              ),
              const SizedBox(width: 4),
              const Text('â‚¬ 17,99', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.repeat_rounded, size: 13, color: color),
                const SizedBox(width: 5),
                const Text(
                  'Ricorrenti',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '1 da confermare',
                style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Uscite: â‚¬ 320/m', style: TextStyle(color: Colors.white70, fontSize: 8.5)),
              Text('+â‚¬ 1.850/m', style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _buildPreviewRecurringRow('Affitto Casa', 'tra 2gg', '-â‚¬ 650,00', const Color(0xFF3B82F6)),
        const SizedBox(height: 4),
        _buildPreviewRecurringRow('Spotify Duo', 'tra 5gg', '-â‚¬ 14,99', const Color(0xFF10B981)),
      ],
    );
  }

  static Widget _buildPreviewRecurringRow(String title, String badge, String amount, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(Icons.circle, size: 6, color: iconColor),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(badge, style: const TextStyle(color: Colors.white60, fontSize: 7.5)),
        ),
        const SizedBox(width: 4),
        Text(
          amount,
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  static Widget _buildBurnRatePreview(BentoWidgetSize size, Color color) {
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, size: 16, color: color),
            const SizedBox(height: 2),
            const Text(
              '640 â‚¬',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              '68% mese',
              style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

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
            '640,00 â‚¬',
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top radial badges row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_rounded, size: 9, color: Colors.white70),
                      SizedBox(width: 3),
                      Text('Tu', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.people_outline_rounded, size: 9, color: Colors.white70),
                      SizedBox(width: 3),
                      Text('Tutti', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF97316).withOpacity(0.4), width: 0.8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shopping_cart_rounded, size: 9, color: Color(0xFFF97316)),
                  SizedBox(width: 3),
                  Text('Spesa', style: TextStyle(color: Color(0xFFF97316), fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),

        // Display Area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white10),
          ),
          alignment: Alignment.centerRight,
          child: const Text(
            '12,50 â‚¬',
            style: TextStyle(
              color: Color(0xFF818CF8),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),

        // Keypad representation
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniKeypadRow(['1', '2', '3']),
                      _buildMiniKeypadRow(['4', '5', '6']),
                      _buildMiniKeypadRow(['7', '8', '9']),
                      _buildMiniKeypadRow(['.', '0', 'âŒ«']),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Action column
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: const Text('C', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.check, size: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildMiniKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) {
        return Expanded(
          child: Container(
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              k,
              style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }).toList(),
    );
  }

  static Widget _buildInvestmentPreview(BentoWidgetSize size, Color color) {
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PORTAFOGLIO', style: TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            const Text(
              '14.320 â‚¬',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
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
      );
    }

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
            '14.320,50 â‚¬',
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
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: color),
            const SizedBox(height: 3),
            Text('3 task', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 1),
            const Text('Focus Oggi', style: TextStyle(color: Colors.white70, fontSize: 8.5)),
          ],
        ),
      );
    }

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
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded, size: 16, color: color),
            const SizedBox(height: 2),
            const Text('ðŸ”¥ 14 gg', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 1),
            const Text('Allenamento', style: TextStyle(color: Colors.white70, fontSize: 8.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

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
            const Text('ðŸ”¥ 14 gg', style: TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold)),
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
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('-12', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            Text('GIORNI', style: TextStyle(color: color.withOpacity(0.8), fontSize: 7, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            const Text('Giappone âœˆï¸', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

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
              Text('âœˆï¸ Viaggio in Giappone', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2),
              Text('24 Ottobre 2026', style: TextStyle(color: Colors.white38, fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildDailyProgressPreview(BentoWidgetSize size, Color color) {
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    backgroundColor: Colors.white10,
                    color: color,
                    strokeWidth: 2.8,
                  ),
                ),
                const Text('75%', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Routine', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Routine Oggi', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2),
              Text('3 di 4 completati', style: TextStyle(color: Colors.white38, fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // --- Casa & Spazio ---

  static Widget _buildShoppingPreview(BentoWidgetSize size, Color color) {
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 16, color: color),
            const SizedBox(height: 3),
            const Text('Spesa', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            const Text('4 da fare', style: TextStyle(color: Colors.white38, fontSize: 8.5)),
          ],
        ),
      );
    }

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
        _buildMiniShoppingItem('CaffÃ¨ espresso', '1 conf.'),
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
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: const Icon(Icons.kitchen_rounded, color: Color(0xFFF87171), size: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              '2 Scorte',
              style: TextStyle(color: Color(0xFFF87171), fontSize: 9.5, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

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
              Text('Scorte Dispensa', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2),
              Text('2 scorte in esaurimento', style: TextStyle(color: Color(0xFFF87171), fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildAsterisksPreview(BentoWidgetSize size, Color color) {
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 17, color: color),
            const SizedBox(height: 3),
            const Text('3 Note (*)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            const Text('In sospeso', style: TextStyle(color: Colors.white38, fontSize: 8.5)),
          ],
        ),
      );
    }

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
        const Text('3 note in sospeso', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 1),
        const Text('Scontrini da chiarire', style: TextStyle(color: Colors.white38, fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // --- Note & Idee ---

  static Widget _buildNoteStackPreview(BentoWidgetSize size, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Layer 2 behind (rotated)
        Positioned.fill(
          child: Transform.rotate(
            angle: -0.07,
            child: Transform.translate(
              offset: const Offset(-2, 3),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161618),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.12)),
                ),
              ),
            ),
          ),
        ),

        // Layer 1 behind (slightly rotated other way)
        Positioned.fill(
          child: Transform.rotate(
            angle: 0.04,
            child: Transform.translate(
              offset: const Offset(3, 2),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
              ),
            ),
          ),
        ),

        // Front Note
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF22201C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2_rounded, size: 11, color: color),
                        const SizedBox(width: 4),
                        const Text(
                          'Promemoria',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '1/3 â–¾',
                        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Oggi, 11:20',
                  style: TextStyle(color: Colors.white38, fontSize: 7.5),
                ),
                const SizedBox(height: 5),
                const Text(
                  'â€¢ Comprare regalo festa\nâ€¢ Revisione preventivo\nâ€¢ Prenotare treno',
                  style: TextStyle(color: Colors.white70, fontSize: 8.5, height: 1.3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildRecentNotesPreview(BentoWidgetSize size, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.description_outlined, size: 10, color: color),
                ),
                const SizedBox(width: 4),
                const Text(
                  'NOTE RECENTI',
                  style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '3 note',
                style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),

        // Quick add simulated row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 11, color: Colors.white38),
              SizedBox(width: 4),
              Expanded(
                child: Text('Nuova nota...', style: TextStyle(color: Colors.white38, fontSize: 8)),
              ),
              Icon(Icons.add_circle, size: 11, color: Color(0xFFF59E0B)),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // List item 1
        _buildMiniRecentNoteRow('Bozza budget 2026', 'Modificato 2 ore fa'),
        const Divider(color: Colors.white10, height: 5),
        // List item 2
        _buildMiniRecentNoteRow('Appunti riunione', 'Ieri, 16:30'),
      ],
    );
  }

  static Widget _buildMiniRecentNoteRow(String title, String subtitle) {
    return Row(
      children: [
        const Icon(Icons.article_outlined, size: 10, color: Colors.white38),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white30, fontSize: 7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildMarkdownPreview(BentoWidgetSize size, Color color) {
    final is1x1 = size.crossAxisCellCount <= 1;
    if (is1x1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('# MD', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 3),
            const Text('Docs', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

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
        const Text('## Specifiche', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 1),
        const Text('Architettura modulare...', style: TextStyle(color: Colors.white38, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // --- Life OS Previews (INT-D014 / Step 3.2 Dimension-Aware) ---

  static Widget _buildLifeOsCapturePreview(BentoWidgetSize size, Color color) {
    final isH1 = size.mainAxisCellCount == 1;
    if (isH1) {
      // 2x1 / 4x1: Pure single row composer
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.all_inclusive_rounded, size: 12, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                size.crossAxisCellCount >= 4 ? 'Cattura un pensiero...' : 'Scrivi qualcosa...',
                style: const TextStyle(color: Colors.white38, fontSize: 8.5),
                maxLines: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, size: 9, color: Color(0xFF8B5CF6)),
            ),
          ],
        ),
      );
    }

    // 2x2: Dominant composer with header
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(Icons.all_inclusive_rounded, size: 11, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 4),
            Text('CATTURA RAPIDA', style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 36,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: const Align(
            alignment: Alignment.topLeft,
            child: Text('Cattura un pensiero o intuizione...', style: TextStyle(color: Colors.white30, fontSize: 8)),
          ),
        ),
      ],
    );
  }

  static Widget _buildLifeOsSeedsPreview(BentoWidgetSize size, Color color) {
    final is2x1 = size.crossAxisCellCount == 2 && size.mainAxisCellCount == 1;
    final is4x2 = size.crossAxisCellCount == 4 && size.mainAxisCellCount == 2;

    if (is2x1) {
      // 2x1: Single horizontal row
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.eco_rounded, size: 12, color: color),
            const SizedBox(width: 5),
            const Expanded(
              child: Text('Comprare filo di rame', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w500), maxLines: 1),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
              child: Text('4', style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (is4x2) {
      // 4x2: Asymmetric split (35% left / 65% right)
      return Row(
        children: [
          Expanded(
            flex: 35,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SEMI', style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.bold)),
                  const Text('4', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('a riposo', style: TextStyle(color: Colors.white38, fontSize: 6.5)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ULTIME CATTURE', style: TextStyle(color: Colors.white30, fontSize: 6.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                const Text('• Comprare filo di rame', style: TextStyle(color: Colors.white, fontSize: 8), maxLines: 1),
                const SizedBox(height: 2),
                const Text('• Studiare meglio F2L', style: TextStyle(color: Colors.white70, fontSize: 8), maxLines: 1),
              ],
            ),
          ),
        ],
      );
    }

    // 2x2: Compact list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(Icons.eco_rounded, size: 11, color: color),
            const SizedBox(width: 4),
            Text('SEMI RECENTI', style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('4', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        const Text('• Comprare filo rame', style: TextStyle(color: Colors.white, fontSize: 8), maxLines: 1),
        const SizedBox(height: 2),
        const Text('• Studiare F2L', style: TextStyle(color: Colors.white70, fontSize: 8), maxLines: 1),
      ],
    );
  }

  static Widget _buildLifeOsActivePreview(BentoWidgetSize size, Color color) {
    final is4x2 = size.crossAxisCellCount == 4 && size.mainAxisCellCount == 2;

    if (is4x2) {
      // 4x2: Asymmetric split
      return Row(
        children: [
          Expanded(
            flex: 35,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ATTIVE', style: TextStyle(color: Color(0xFF6366F1), fontSize: 7, fontWeight: FontWeight.bold)),
                  const Text('3', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('2 prog · 1 prat', style: TextStyle(color: Colors.white38, fontSize: 6.5)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('IN CORSO', style: TextStyle(color: Colors.white30, fontSize: 6.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    Icon(Icons.rocket_launch_rounded, size: 9, color: Color(0xFF6366F1)),
                    SizedBox(width: 4),
                    Expanded(child: Text('Auth GDPR Solducci', style: TextStyle(color: Colors.white, fontSize: 8), maxLines: 1)),
                  ],
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    Icon(Icons.repeat_rounded, size: 9, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Expanded(child: Text('Stretching serale', style: TextStyle(color: Colors.white70, fontSize: 8), maxLines: 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 2x2: Top active entities
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(Icons.all_inclusive_rounded, size: 11, color: Color(0xFF6366F1)),
            const SizedBox(width: 4),
            Text('ENTITÀ ATTIVE', style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        const Row(
          children: [
            Icon(Icons.rocket_launch_rounded, size: 9, color: Color(0xFF6366F1)),
            SizedBox(width: 4),
            Expanded(child: Text('Auth GDPR', style: TextStyle(color: Colors.white, fontSize: 8), maxLines: 1)),
          ],
        ),
        const SizedBox(height: 3),
        const Row(
          children: [
            Icon(Icons.repeat_rounded, size: 9, color: Color(0xFF10B981)),
            SizedBox(width: 4),
            Expanded(child: Text('Stretching', style: TextStyle(color: Colors.white70, fontSize: 8), maxLines: 1)),
          ],
        ),
      ],
    );
  }

  static Widget _buildLifeOsPinnedPreview(BentoWidgetSize size, Color color) {
    final is2x1 = size.crossAxisCellCount == 2 && size.mainAxisCellCount == 1;
    final is4x2 = size.crossAxisCellCount == 4 && size.mainAxisCellCount == 2;

    if (is2x1) {
      // 2x1: Mini banner row
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.push_pin_rounded, size: 10, color: color),
            const SizedBox(width: 4),
            const Icon(Icons.rocket_launch_rounded, size: 10, color: Color(0xFF6366F1)),
            const SizedBox(width: 5),
            const Expanded(
              child: Text('LifeOS Core', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold), maxLines: 1),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: const Text('PROG', style: TextStyle(color: Color(0xFF6366F1), fontSize: 7, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (is4x2) {
      // 4x2: Asymmetric split
      return Row(
        children: [
          Expanded(
            flex: 35,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.push_pin_rounded, size: 9, color: color),
                      const SizedBox(width: 3),
                      const Text('PROGETTO', style: TextStyle(color: Color(0xFF6366F1), fontSize: 6.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('LifeOS Core', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
                  const SizedBox(height: 2),
                  const Text('Apri Vitrine →', style: TextStyle(color: Color(0xFF6366F1), fontSize: 6.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ULTIMA NOTA', style: TextStyle(color: Colors.white30, fontSize: 6.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('Rifinitura architettura Bento e code integrity.', style: TextStyle(color: Colors.white70, fontSize: 7.5), maxLines: 2),
              ],
            ),
          ),
        ],
      );
    }

    // 2x2: Regular card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(Icons.push_pin_rounded, size: 10, color: color),
            const SizedBox(width: 4),
            Text('IN EVIDENZA', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('LifeOS Core', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold), maxLines: 1),
        const SizedBox(height: 2),
        const Text('Progetto · Ultimo appunto aggiunto...', style: TextStyle(color: Colors.white38, fontSize: 7.5), maxLines: 1),
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
