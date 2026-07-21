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
    // The back flap (full folder shape)
    final backFlapPaint = Paint()
      ..color = isOpen ? Color.lerp(baseColor, Colors.white, 0.05)! : baseColor
      ..style = PaintingStyle.fill;

    // The front flap (only visible when open) is slightly lighter for depth
    final frontFlapPaint = Paint()
      ..color = isOpen ? Color.lerp(baseColor, Colors.white, 0.12)! : baseColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isOpen ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
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
    
    // Top edge of the body (right side of the tab)
    path.lineTo(headerWidth + 24, headerHeight);
    
    // Sinuous curve to the tab
    path.cubicTo(
      headerWidth + 12, headerHeight, // control point 1
      headerWidth + 12, 0,            // control point 2
      headerWidth, 0                  // end point
    );
    
    // Header top edge
    path.lineTo(radius, 0);
    
    // Header top left corner
    path.arcToPoint(const Offset(0, radius), radius: const Radius.circular(radius), clockwise: false);
    
    // Left edge back to bottom
    path.close();

    // Shadow around the whole shape
    canvas.drawShadow(path, Colors.black, isOpen ? 12.0 : 8.0, true);
    
    // Draw the full shape (Back flap)
    canvas.drawPath(path, backFlapPaint);
    
    // Draw front flap if open
    if (isOpen) {
      final frontFlapPath = Path();
      frontFlapPath.moveTo(0, size.height - radius);
      frontFlapPath.arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius), clockwise: false);
      frontFlapPath.lineTo(size.width - radius, size.height);
      frontFlapPath.arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius), clockwise: false);
      frontFlapPath.lineTo(size.width, headerHeight + radius);
      frontFlapPath.arcToPoint(Offset(size.width - radius, headerHeight), radius: const Radius.circular(radius), clockwise: false);
      frontFlapPath.lineTo(radius, headerHeight);
      frontFlapPath.arcToPoint(const Offset(0, headerHeight + radius), radius: const Radius.circular(radius), clockwise: false);
      frontFlapPath.close();

      canvas.drawPath(frontFlapPath, frontFlapPaint);
      
      // Inner shadow line for depth
      final innerBorderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(frontFlapPath, innerBorderPaint);
    }
    
    // Draw the outer border over the full shape
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ManilaFolderPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor || oldDelegate.isOpen != isOpen;
  }
}
