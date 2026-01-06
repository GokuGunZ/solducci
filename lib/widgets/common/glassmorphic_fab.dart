import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Glassmorphic Floating Action Button
///
/// Provides a consistent FAB design across the app with enhanced glassmorphism:
/// - Strong blur effect
/// - Gradient background with transparency
/// - Border with glow
/// - Multiple shadow layers
/// - Radial gradient behind icon
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
    this.primaryColor = Colors.purple,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Increased blur
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withValues(alpha: 0.4), // Increased transparency
                primaryColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.7), // Brighter border
              width: 1.5,
            ),
            boxShadow: [
              // Main glow shadow
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.6), // Stronger glow
                blurRadius: 28,
                spreadRadius: 3,
                offset: const Offset(0, 8),
              ),
              // Highlight shadow
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5), // Brighter highlight
                blurRadius: 4,
                offset: const Offset(-2, -2),
              ),
              // Subtle depth shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(size / 2),
              splashColor: Colors.white.withValues(alpha: 0.4),
              highlightColor: Colors.white.withValues(alpha: 0.3),
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Radial gradient effect behind icon
                    Container(
                      width: size * 0.7,
                      height: size * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.5), // Brighter center
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                    // Icon with enhanced visibility
                    Icon(
                      icon,
                      color: Colors.white,
                      size: size * 0.55,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
