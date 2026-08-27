import 'dart:math';
import 'package:flutter/material.dart';

class DonutProgressIndicator extends StatelessWidget {
  final int total;
  final int completed;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  const DonutProgressIndicator({
    super.key,
    required this.total,
    required this.completed,
    this.size = 44,
    this.strokeWidth = 5,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.primaryColor;
    final inactiveColor = backgroundColor ?? theme.dividerColor.withValues(alpha: 0.1);
    
    // Total is 0 or completed is 0, still show the donut as requested
    final double progress = total > 0 ? completed / total : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          progress: progress,
          total: total,
          completed: completed,
          strokeWidth: strokeWidth,
          color: activeColor,
          backgroundColor: inactiveColor,
          textColor: theme.textTheme.bodySmall?.color ?? Colors.black,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final int total;
  final int completed;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final Color textColor;

  _DonutPainter({
    required this.progress,
    required this.total,
    required this.completed,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Draw background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }

    // Draw text (fraction)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$completed/$total',
        style: TextStyle(
          color: textColor,
          fontSize: size.width * 0.25,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.total != total ||
        oldDelegate.completed != completed;
  }
}
