import 'dart:math';
import 'package:flutter/material.dart';

class NeonWaveGraph extends StatefulWidget {
  final Color color;
  final double height;
  final List<double> dataPoints;

  const NeonWaveGraph({
    super.key,
    required this.color,
    this.height = 150,
    required this.dataPoints,
  });

  @override
  State<NeonWaveGraph> createState() => _NeonWaveGraphState();
}

class _NeonWaveGraphState extends State<NeonWaveGraph> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _NeonWavePainter(
            animationValue: _controller.value,
            color: widget.color,
            dataPoints: widget.dataPoints,
          ),
        );
      },
    );
  }
}

class _NeonWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final List<double> dataPoints;

  _NeonWavePainter({
    required this.animationValue,
    required this.color,
    required this.dataPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.4),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    
    final widthStep = size.width / (dataPoints.length - 1);
    final maxData = dataPoints.reduce(max) <= 0 ? 1.0 : dataPoints.reduce(max);
    
    path.moveTo(0, size.height);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * widthStep;
      
      final normalizedY = size.height - (dataPoints[i] / maxData * size.height * 0.5) - 20; 
      
      // Onde fluide che respirano
      final waveOffset = sin((x / size.width * 2 * pi) + (animationValue * 2 * pi)) * 12;
      final y = normalizedY + waveOffset;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * widthStep;
        final prevNormalizedY = size.height - (dataPoints[i - 1] / maxData * size.height * 0.5) - 20;
        final prevY = prevNormalizedY + sin((prevX / size.width * 2 * pi) + (animationValue * 2 * pi)) * 12;
        
        final controlX1 = prevX + widthStep / 2;
        final controlX2 = x - widthStep / 2;
        path.cubicTo(controlX1, prevY, controlX2, y, x, y);
      }
    }

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.dataPoints != dataPoints;
  }
}
