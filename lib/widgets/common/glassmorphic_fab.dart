import 'package:flutter/material.dart';

/// Floating Action Button with modern dark OLED styling and neon glow.
///
/// Features:
/// - Rich vibrant gradient matching [primaryColor]
/// - Clean high-contrast border
/// - Neon glow box shadow
/// - Crisp white icon with high contrast
class GlassmorphicFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color primaryColor;
  final double size;

  const GlassmorphicFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.primaryColor = const Color(0xFF6366F1),
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final darkerShade = Color.lerp(primaryColor, Colors.black, 0.22) ?? primaryColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            darkerShade,
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.15),
          child: Tooltip(
            message: tooltip ?? '',
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: size * 0.48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

