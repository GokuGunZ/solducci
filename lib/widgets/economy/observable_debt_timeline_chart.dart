import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_split.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/theme/app_theme.dart';

class ObservableDebtTimelinePoint {
  final DateTime date;
  final double netBalance; // > 0 credit, < 0 debt, 0 settled
  final List<Expense> dayExpenses;

  const ObservableDebtTimelinePoint({
    required this.date,
    required this.netBalance,
    required this.dayExpenses,
  });

  bool get isCredit => netBalance > 0.001;
  bool get isDebt => netBalance < -0.001;
  bool get isSettled => netBalance.abs() <= 0.001;
}

class ObservableDebtTimelineChart extends StatefulWidget {
  final List<Expense> expenses;
  final String? groupId;

  const ObservableDebtTimelineChart({
    super.key,
    required this.expenses,
    this.groupId,
  });

  @override
  State<ObservableDebtTimelineChart> createState() => _ObservableDebtTimelineChartState();
}

class _ObservableDebtTimelineChartState extends State<ObservableDebtTimelineChart> {
  final _expenseService = ExpenseServiceCached();
  List<ObservableDebtTimelinePoint> _points = [];
  bool _isLoading = true;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _computeTimeline();
  }

  @override
  void didUpdateWidget(covariant ObservableDebtTimelineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses || oldWidget.groupId != widget.groupId) {
      _computeTimeline();
    }
  }

  Future<void> _computeTimeline() async {
    final currentUserId = AuthService().currentUserId;
    if (currentUserId == null || widget.expenses.isEmpty) {
      if (mounted) setState(() {
        _points = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Pre-calculate bulk balances for all group expenses
      final balances = await _expenseService.calculateBulkUserBalances(widget.expenses);

      // 2. Sort expenses chronologically (oldest first) to replay history
      final chronological = List<Expense>.from(widget.expenses)
        ..sort((a, b) => a.date.compareTo(b.date));

      // 3. Group by calendar day
      final expensesByDay = <String, List<Expense>>{};
      final dateObjectsByDay = <String, DateTime>{};

      for (final exp in chronological) {
        final key = DateFormat('yyyy-MM-dd').format(exp.date);
        expensesByDay.putIfAbsent(key, () => []).add(exp);
        dateObjectsByDay.putIfAbsent(key, () => DateTime(exp.date.year, exp.date.month, exp.date.day));
      }

      // 4. Running cumulative balance
      double runningBalance = 0.0;
      final points = <ObservableDebtTimelinePoint>[];

      // Initial point before first transaction (starting at 0)
      if (dateObjectsByDay.isNotEmpty) {
        final firstDate = dateObjectsByDay.values.first.subtract(const Duration(days: 1));
        points.add(ObservableDebtTimelinePoint(
          date: firstDate,
          netBalance: 0.0,
          dayExpenses: const [],
        ));
      }

      for (final entry in expensesByDay.entries) {
        final date = dateObjectsByDay[entry.key]!;
        final dayExpenses = entry.value;

        // Sum net delta of day's expenses
        for (final exp in dayExpenses) {
          final expBalance = balances[exp.id] ?? 0.0;
          runningBalance += expBalance;
        }

        points.add(ObservableDebtTimelinePoint(
          date: date,
          netBalance: runningBalance,
          dayExpenses: dayExpenses,
        ));
      }

      // If last point date is before today, add today's point holding balance
      final today = DateTime.now();
      final todayTrunc = DateTime(today.year, today.month, today.day);
      if (points.isNotEmpty && points.last.date.isBefore(todayTrunc)) {
        points.add(ObservableDebtTimelinePoint(
          date: todayTrunc,
          netBalance: runningBalance,
          dayExpenses: const [],
        ));
      }

      if (mounted) {
        setState(() {
          _points = points;
          _selectedIndex = points.isNotEmpty ? points.length - 1 : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ObservableDebtTimelineChart] Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onInteraction(Offset localPosition, double width) {
    if (_points.length < 2 || width <= 0) return;
    final step = width / (_points.length - 1);
    final index = (localPosition.dx / step).round().clamp(0, _points.length - 1);
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Color(0xFF8B5CF6), strokeWidth: 2),
      );
    }

    if (_points.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Nessuna transazione per costruire la cronologia del debito.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    final selectedPoint = (_selectedIndex != null && _selectedIndex! < _points.length)
        ? _points[_selectedIndex!]
        : _points.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo sezione
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Text(
                'Andamento del Debito nel Tempo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),

        // Grafico canvas
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Indicatori estremi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text('CREDITO (Ti devono)', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text('Linea di Pareggio (0,00 €)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFFF59E0B)),
                      SizedBox(width: 4),
                      Text('DEBITO (Devi)', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Canvas con GestureDetector
              SizedBox(
                height: 180,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => _onInteraction(details.localPosition, constraints.maxWidth),
                      onHorizontalDragUpdate: (details) => _onInteraction(details.localPosition, constraints.maxWidth),
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, 180),
                        painter: _DebtTimelinePainter(
                          points: _points,
                          selectedIndex: _selectedIndex,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Date range footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(_points.first.date),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const Text(
                    'Tocca o trascina per ispezionare',
                    style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(_points.last.date),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scheda ispezione data osservabile
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selectedPoint.isCredit
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : (selectedPoint.isDebt ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.white10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: selectedPoint.isCredit
                            ? const Color(0xFF10B981)
                            : (selectedPoint.isDebt ? const Color(0xFFF59E0B) : Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE d MMMM yyyy', 'it_IT').format(selectedPoint.date),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selectedPoint.isCredit
                          ? const Color(0xFF10B981).withOpacity(0.18)
                          : (selectedPoint.isDebt ? const Color(0xFFF59E0B).withOpacity(0.18) : Colors.white10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      selectedPoint.isCredit
                          ? '+${selectedPoint.netBalance.toStringAsFixed(2)} € Credito'
                          : (selectedPoint.isDebt
                              ? '${selectedPoint.netBalance.toStringAsFixed(2)} € Debito'
                              : '0.00 € Pareggio'),
                      style: TextStyle(
                        color: selectedPoint.isCredit
                            ? const Color(0xFF10B981)
                            : (selectedPoint.isDebt ? const Color(0xFFF59E0B) : Colors.white70),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (selectedPoint.dayExpenses.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 10),
                Text(
                  '${selectedPoint.dayExpenses.length} ${selectedPoint.dayExpenses.length == 1 ? "movimento in questa data" : "movimenti in questa data"}:',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 6),
                ...selectedPoint.dayExpenses.map((exp) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            exp.description,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${exp.amount.toStringAsFixed(2)} €',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DebtTimelinePainter extends CustomPainter {
  final List<ObservableDebtTimelinePoint> points;
  final int? selectedIndex;

  _DebtTimelinePainter({required this.points, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final centerY = size.height / 2;

    // 1. Draw Zero center baseline
    final zeroPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw dashed zero line
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(math.min(startX + dashWidth, size.width), centerY),
        zeroPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 2. Determine max amplitude to symmetrically scale Y-axis
    double maxAmp = 10.0;
    for (final p in points) {
      if (p.netBalance.abs() > maxAmp) {
        maxAmp = p.netBalance.abs();
      }
    }
    maxAmp *= 1.2; // 20% breathing room

    final stepX = points.length > 1 ? size.width / (points.length - 1) : size.width;

    // Helper: convert balance to canvas Y
    // Positive balance (credit) -> above center (Y < centerY)
    // Negative balance (debt) -> below center (Y > centerY)
    double getY(double balance) {
      final ratio = balance / maxAmp;
      return centerY - (ratio * (centerY - 8));
    }

    // 3. Construct continuous step-line path
    final linePath = Path();
    final fillAbovePath = Path();
    final fillBelowPath = Path();

    fillAbovePath.moveTo(0, centerY);
    fillBelowPath.moveTo(0, centerY);

    final renderedOffsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = getY(points[i].netBalance);
      renderedOffsets.add(Offset(x, y));

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = getY(points[i - 1].netBalance);
        // Step interpolation: horizontal line then vertical step
        linePath.lineTo(x, prevY);
        linePath.lineTo(x, y);
      }
    }

    // 4. Fill paths
    for (int i = 0; i < renderedOffsets.length; i++) {
      final cur = renderedOffsets[i];
      if (i == 0) {
        fillAbovePath.lineTo(cur.dx, cur.dy);
        fillBelowPath.lineTo(cur.dx, cur.dy);
      } else {
        final prev = renderedOffsets[i - 1];
        fillAbovePath.lineTo(cur.dx, prev.dy);
        fillAbovePath.lineTo(cur.dx, cur.dy);

        fillBelowPath.lineTo(cur.dx, prev.dy);
        fillBelowPath.lineTo(cur.dx, cur.dy);
      }
    }

    fillAbovePath.lineTo(size.width, centerY);
    fillAbovePath.close();

    fillBelowPath.lineTo(size.width, centerY);
    fillBelowPath.close();

    // Paint positive area (credit - green)
    final greenGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF10B981).withOpacity(0.35),
        const Color(0xFF10B981).withOpacity(0.0),
      ],
    );
    final abovePaint = Paint()
      ..shader = greenGradient.createShader(Rect.fromLTRB(0, 0, size.width, centerY))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillAbovePath, abovePaint);

    // Paint negative area (debt - amber)
    final amberGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFF59E0B).withOpacity(0.0),
        const Color(0xFFF59E0B).withOpacity(0.35),
      ],
    );
    final belowPaint = Paint()
      ..shader = amberGradient.createShader(Rect.fromLTRB(0, centerY, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillBelowPath, belowPaint);

    // 5. Draw main line
    final linePaint = Paint()
      ..color = const Color(0xFFA78BFA)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 6. Draw selected interactive cursor & crosshair
    if (selectedIndex != null && selectedIndex! < renderedOffsets.length) {
      final sel = renderedOffsets[selectedIndex!];
      final selPoint = points[selectedIndex!];

      // Vertical cursor line
      final cursorPaint = Paint()
        ..color = Colors.white54
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(sel.dx, 0), Offset(sel.dx, size.height), cursorPaint);

      // Glowing dot
      final dotColor = selPoint.isCredit
          ? const Color(0xFF10B981)
          : (selPoint.isDebt ? const Color(0xFFF59E0B) : Colors.white);

      final glowPaint = Paint()
        ..color = dotColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(sel, 8, glowPaint);

      final corePaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sel, 4.5, corePaint);

      final whiteInner = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sel, 2, whiteInner);
    }
  }

  @override
  bool shouldRepaint(covariant _DebtTimelinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.selectedIndex != selectedIndex;
  }
}
