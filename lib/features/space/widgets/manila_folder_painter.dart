import 'package:flutter/material.dart';

class ManilaFolderPainter extends CustomPainter {
  final Color baseColor;
  final bool isOpen;

  ManilaFolderPainter({
    required this.baseColor,
    required this.isOpen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Header color is always baseColor (dark)
    final headerPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // Body color is lighter if open
    final bodyPaint = Paint()
      ..color = isOpen ? baseColor.withValues(alpha: 0.5) : baseColor // Alpha blending makes it lighter against a white/light bg, wait OLED bg is black, so alpha blending makes it darker. Let's use a lighter color mathematically.
      ..style = PaintingStyle.fill;

    if (isOpen) {
      bodyPaint.color = Color.lerp(baseColor, Colors.white, 0.1) ?? baseColor; // 10% lighter
    }

    // The border for contrast
    final borderPaint = Paint()
      ..color = isOpen ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    
    // Header dimensions
    final headerWidth = size.width * 0.6;
    const headerHeight = 32.0;
    const radius = 12.0;

    // Start at bottom left
    path.moveTo(0, size.height - radius);
    path.arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius), clockwise: false);
    
    // Bottom edge
    path.lineTo(size.width - radius, size.height);
    path.arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius), clockwise: false);
    
    // Right edge
    path.lineTo(size.width, headerHeight + radius);
    path.arcToPoint(Offset(size.width - radius, headerHeight), radius: const Radius.circular(radius), clockwise: false);
    
    // Top edge right of header
    path.lineTo(headerWidth + radius, headerHeight);
    
    // Curve up to header
    path.arcToPoint(Offset(headerWidth, headerHeight - radius), radius: const Radius.circular(radius), clockwise: false);
    
    // Header right edge
    path.lineTo(headerWidth, radius);
    
    // Header top right corner
    path.arcToPoint(Offset(headerWidth - radius, 0), radius: const Radius.circular(radius), clockwise: false);
    
    // Header top edge
    path.lineTo(radius, 0);
    
    // Header top left corner
    path.arcToPoint(const Offset(0, radius), radius: const Radius.circular(radius), clockwise: false);
    
    // Left edge back to bottom
    path.close();

    // Shadow around the whole shape
    canvas.drawShadow(path, Colors.black, 8.0, true);
    
    // Draw body first
    final bodyPath = Path();
    bodyPath.moveTo(0, size.height - radius);
    bodyPath.arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius), clockwise: false);
    bodyPath.lineTo(size.width - radius, size.height);
    bodyPath.arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius), clockwise: false);
    bodyPath.lineTo(size.width, headerHeight + radius);
    bodyPath.arcToPoint(Offset(size.width - radius, headerHeight), radius: const Radius.circular(radius), clockwise: false);
    bodyPath.lineTo(radius, headerHeight);
    bodyPath.arcToPoint(const Offset(0, headerHeight + radius), radius: const Radius.circular(radius), clockwise: false);
    bodyPath.close();

    canvas.drawPath(bodyPath, bodyPaint);
    
    // Draw header
    final hPath = Path();
    hPath.moveTo(0, headerHeight + radius);
    hPath.arcToPoint(const Offset(radius, headerHeight), radius: const Radius.circular(radius), clockwise: true);
    hPath.lineTo(headerWidth - radius, headerHeight);
    hPath.arcToPoint(Offset(headerWidth, headerHeight - radius), radius: const Radius.circular(radius), clockwise: false);
    hPath.lineTo(headerWidth, radius);
    hPath.arcToPoint(Offset(headerWidth - radius, 0), radius: const Radius.circular(radius), clockwise: false);
    hPath.lineTo(radius, 0);
    hPath.arcToPoint(const Offset(0, radius), radius: const Radius.circular(radius), clockwise: false);
    hPath.close();

    canvas.drawPath(hPath, headerPaint);
    
    // Draw the border over the full shape
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ManilaFolderPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor || oldDelegate.isOpen != isOpen;
  }
}
