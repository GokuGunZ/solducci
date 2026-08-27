import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TimeDialEvent {
  final TimeOfDay time;
  final String title;
  final Color color;

  TimeDialEvent({required this.time, required this.title, required this.color});
}

class TimeDialWidget extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final List<TimeDialEvent> events;

  const TimeDialWidget({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.events = const [],
  });

  @override
  State<TimeDialWidget> createState() => _TimeDialWidgetState();
}

class _TimeDialWidgetState extends State<TimeDialWidget> {
  late TimeOfDay _currentTime;
  bool _isMinutesMode = false;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.initialTime;
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final position = details.localPosition;
    final vector = position - center;
    final distance = vector.distance;
    final angle = atan2(vector.dy, vector.dx);

    var normalizedAngle = (angle + pi / 2) / (2 * pi);
    if (normalizedAngle < 0) normalizedAngle += 1.0;

    final isMinutesMode = distance < size.width * 0.30;

    if (_isMinutesMode != isMinutesMode) {
      setState(() {
        _isMinutesMode = isMinutesMode;
      });
    }

    if (isMinutesMode) {
      final minute = (normalizedAngle * 60).round() % 60;
      if (minute != _currentTime.minute) {
        setState(() {
          _currentTime = TimeOfDay(hour: _currentTime.hour, minute: minute);
        });
        widget.onTimeChanged(_currentTime);
      }
    } else {
      final hour = (normalizedAngle * 24).round() % 24;
      if (hour != _currentTime.hour) {
        setState(() {
          _currentTime = TimeOfDay(hour: hour, minute: _currentTime.minute);
        });
        widget.onTimeChanged(_currentTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, 350.0);
        return Center(
          child: GestureDetector(
            onPanUpdate: (details) => _handlePanUpdate(details, Size(size, size)),
            onPanDown: (details) => _handlePanUpdate(DragUpdateDetails(globalPosition: details.globalPosition, localPosition: details.localPosition), Size(size, size)),
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _TimeDialPainter(
                  currentTime: _currentTime,
                  isMinutesMode: _isMinutesMode,
                  events: widget.events,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _isMinutesMode ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                          shadows: [
                            Shadow(
                              color: (_isMinutesMode ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)).withValues(alpha: 0.5),
                              blurRadius: 20,
                            )
                          ],
                        ),
                      ).animate(target: _isMinutesMode ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        _isMinutesMode ? 'MINUTI' : 'ORE',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 4,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeDialPainter extends CustomPainter {
  final TimeOfDay currentTime;
  final bool isMinutesMode;
  final List<TimeDialEvent> events;

  _TimeDialPainter({
    required this.currentTime,
    required this.isMinutesMode,
    required this.events,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 * 0.9;
    final innerRadius = size.width / 2 * 0.6;

    final paintBg = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, paintBg);

    _drawRing(canvas, center, outerRadius, 24, currentTime.hour, const Color(0xFF3B82F6), !isMinutesMode);
    _drawRing(canvas, center, innerRadius, 60, currentTime.minute, const Color(0xFFF59E0B), isMinutesMode);

    // Disegna i pin degli eventi sull'anello esterno
    for (var event in events) {
      final angle = (event.time.hour + event.time.minute / 60) / 24 * 2 * pi - pi / 2;
      final x = center.dx + outerRadius * cos(angle);
      final y = center.dy + outerRadius * sin(angle);

      final pinPaint = Paint()
        ..color = event.color
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

      canvas.drawCircle(Offset(x, y), 6, pinPaint);
      
      final whiteDot = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(x, y), 2, whiteDot);
    }
  }

  void _drawRing(Canvas canvas, Offset center, double radius, int ticks, int selectedTick, Color activeColor, bool isActiveRing) {
    final tickPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, isActiveRing ? 8 : 0);

    for (int i = 0; i < ticks; i++) {
      final angle = (i / ticks) * 2 * pi - pi / 2;
      final isSelected = i == selectedTick;
      final isMajor = ticks == 24 ? (i % 6 == 0) : (i % 15 == 0);

      final length = isSelected ? 16.0 : (isMajor ? 12.0 : 6.0);
      
      final start = Offset(
        center.dx + (radius - length/2) * cos(angle),
        center.dy + (radius - length/2) * sin(angle),
      );
      final end = Offset(
        center.dx + (radius + length/2) * cos(angle),
        center.dy + (radius + length/2) * sin(angle),
      );

      canvas.drawLine(start, end, isSelected ? activePaint : tickPaint);
      
      // Draw text for major ticks
      if (isMajor && isActiveRing) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: i.toString().padLeft(2, '0'),
            style: TextStyle(color: isSelected ? activeColor : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        final textOffset = Offset(
          center.dx + (radius - 24) * cos(angle) - textPainter.width / 2,
          center.dy + (radius - 24) * sin(angle) - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimeDialPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
           oldDelegate.isMinutesMode != isMinutesMode ||
           oldDelegate.events != events;
  }
}
