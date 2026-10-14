import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';

class RealCashflowTimelineGraph extends StatelessWidget {
  final List<Expense> expenses;
  final Color accentColor;
  final String title;

  const RealCashflowTimelineGraph({
    super.key,
    required this.expenses,
    this.accentColor = const Color(0xFF10B981),
    this.title = 'Flusso spese nel tempo',
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.show_chart_rounded, color: accentColor.withOpacity(0.5), size: 24),
            const SizedBox(width: 12),
            const Text(
              'Nessun dato di spesa disponibile per il grafico',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Raggruppa le spese per giorno (ultimi 14 giorni o dalle spese disponibili)
    final now = DateTime.now();
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Mappa giorno -> totale
    final Map<String, double> dailyTotals = {};
    for (int i = 13; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKey = DateFormat('yyyy-MM-dd').format(day);
      dailyTotals[dayKey] = 0.0;
    }

    for (final exp in sortedExpenses) {
      final key = DateFormat('yyyy-MM-dd').format(exp.date);
      if (dailyTotals.containsKey(key)) {
        dailyTotals[key] = (dailyTotals[key] ?? 0.0) + exp.amount;
      }
    }

    final points = dailyTotals.values.toList();
    final maxAmount = points.reduce(max);
    final totalInWindow = points.reduce((a, b) => a + b);

    final startDateStr = DateFormat('dd MMM', 'it_IT').format(now.subtract(const Duration(days: 13)));
    final endDateStr = DateFormat('dd MMM', 'it_IT').format(now);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
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
                  Icon(Icons.timeline_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Text(
                '$startDateStr - $endDateStr',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '€ ${totalInWindow.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Picco max: €${maxAmount.toStringAsFixed(0)}',
                style: TextStyle(color: accentColor.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Grafico CustomPaint
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _TimelineGraphPainter(
                points: points,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineGraphPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _TimelineGraphPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.reduce(max);
    final normalized = maxVal > 0 ? points.map((p) => p / maxVal).toList() : points.map((_) => 0.0).toList();

    final stepX = size.width / (points.length - 1);

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < normalized.length; i++) {
      final x = i * stepX;
      // Invert Y coordinate so 0 is at bottom
      final y = size.height - (normalized[i] * (size.height - 12)) - 6;

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (normalized[i - 1] * (size.height - 12)) - 6;
        final midX = (prevX + x) / 2;
        linePath.cubicTo(midX, prevY, midX, y, x, y);
        fillPath.cubicTo(midX, prevY, midX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Sfumatura di riempimento neon
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.25),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Linea principale con glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, strokePaint);

    // Pallino sull'ultimo punto
    final lastX = size.width;
    final lastY = size.height - (normalized.last * (size.height - 12)) - 6;
    final dotPaint = Paint()..color = Colors.white;
    final dotRingPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset(lastX, lastY), 4, dotPaint);
    canvas.drawCircle(Offset(lastX, lastY), 6, dotRingPaint);
  }

  @override
  bool shouldRepaint(covariant _TimelineGraphPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
