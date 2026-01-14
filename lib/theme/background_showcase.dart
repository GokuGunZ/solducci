import 'package:flutter/material.dart';

/// A showcase of modern, elegant background gradients
/// Featuring clean, light color palettes with sophisticated aesthetics
class BackgroundShowcase {
  BackgroundShowcase._();

  // ========== SOFT PASTELS ==========

  /// Soft Lavender Dreams - Gentle purple to pink gradient
  /// Perfect for: Relaxing, feminine, dreamy interfaces
  static const LinearGradient softLavenderDreams = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8F3FF), // Very light lavender
      Color(0xFFFFF0F8), // Very light pink
      Color(0xFFF0F4FF), // Very light blue
    ],
  );

  /// Pearl Essence - Iridescent white with subtle color shifts
  /// Perfect for: Luxury, minimalist, premium feel
  static const LinearGradient pearlEssence = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFDFA), // Warm white
      Color(0xFFF8FAFB), // Cool white
      Color(0xFFFFFAF6), // Peachy white
    ],
  );

  /// Mint Cream - Fresh and airy green-tinted whites
  /// Perfect for: Health, wellness, nature-focused apps
  static const LinearGradient mintCream = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5FFF9), // Mint white
      Color(0xFFFFFFFD), // Pure white
      Color(0xFFF0FFFA), // Aqua white
    ],
  );

  // ========== ELEGANT SOPHISTICATION ==========

  /// Champagne Glow - Warm, luxurious beige gradient
  /// Perfect for: Elegance, sophistication, high-end feel
  static const LinearGradient champagneGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFBF5), // Cream
      Color(0xFFFFF8F0), // Champagne
      Color(0xFFFFF5EB), // Warm beige
    ],
  );

  /// Rose Quartz - Delicate pink with warm undertones
  /// Perfect for: Romance, beauty, fashion apps
  static const LinearGradient roseQuartz = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8F9), // Blush white
      Color(0xFFFFF0F3), // Rose white
      Color(0xFFFFF5F7), // Pink tint
    ],
  );

  /// Silk Mist - Soft gray with purple hints
  /// Perfect for: Modern, professional, clean design
  static const LinearGradient silkMist = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF9F9FB), // Light lavender gray
      Color(0xFFFBFBFD), // Almost white
      Color(0xFFF6F6F9), // Soft gray
    ],
  );

  // ========== FRESH & MODERN ==========

  /// Sky Whisper - Light blue with cloud-like softness
  /// Perfect for: Clarity, trust, openness
  static const LinearGradient skyWhisper = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF7FBFF), // Sky white
      Color(0xFFFFFFFE), // Pure white
      Color(0xFFF0F7FF), // Light blue tint
    ],
  );

  /// Peach Sorbet - Warm peachy gradient
  /// Perfect for: Friendly, energetic, welcoming
  static const LinearGradient peachSorbet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFAF5), // Peach cream
      Color(0xFFFFF8F3), // Light peach
      Color(0xFFFFFBF7), // Warm white
    ],
  );

  /// Morning Dew - Fresh green-blue morning feel
  /// Perfect for: Nature, freshness, new beginnings
  static const LinearGradient morningDew = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5FFFC), // Mint fresh
      Color(0xFFF8FFFD), // Aqua tint
      Color(0xFFF0FBFF), // Light cyan
    ],
  );

  // ========== RADIAL GRADIENTS (CENTER GLOW) ==========

  /// Soft Glow - Radial gradient with gentle center illumination
  /// Perfect for: Focus, spotlight effects, hero sections
  static const RadialGradient softGlow = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [
      Color(0xFFFFFFFE), // Center white
      Color(0xFFF8F5FF), // Light lavender
      Color(0xFFF0ECF9), // Soft purple
    ],
  );

  /// Ethereal Halo - Radial with pink-purple glow
  /// Perfect for: Dreamy, magical, enchanting feel
  static const RadialGradient etherealHalo = RadialGradient(
    center: Alignment(0.3, -0.4),
    radius: 1.8,
    colors: [
      Color(0xFFFFFAFD), // Light pink center
      Color(0xFFF8F3FF), // Lavender mid
      Color(0xFFF5F5FF), // Light blue edge
    ],
  );

  // ========== DIAGONAL ELEGANCE ==========

  /// Diagonal Grace - Angled gradient for dynamic feel
  /// Perfect for: Movement, energy, modernity
  static const LinearGradient diagonalGrace = LinearGradient(
    begin: Alignment(-0.8, -0.8),
    end: Alignment(0.8, 0.8),
    colors: [
      Color(0xFFFFF8FA), // Pink white
      Color(0xFFFFFFFE), // Pure white
      Color(0xFFF8F8FF), // Blue white
    ],
  );

  /// Sunlight Cascade - Warm diagonal sweep
  /// Perfect for: Warmth, optimism, vitality
  static const LinearGradient sunlightCascade = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFFFFDF8), // Warm glow
      Color(0xFFFFFAF3), // Golden tint
      Color(0xFFFFF8EE), // Soft amber
    ],
  );

  // ========== MULTI-STOP GRADIENTS ==========

  /// Cloud Nine - Multi-stop gradient with color transitions
  /// Perfect for: Depth, richness, sophistication
  static const LinearGradient cloudNine = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
    colors: [
      Color(0xFFF8F9FF), // Light periwinkle
      Color(0xFFFFFFFE), // White center
      Color(0xFFFFF9FA), // Blush
      Color(0xFFF8F8FD), // Soft lavender
    ],
  );

  /// Pastel Rainbow - Subtle multi-color elegance
  /// Perfect for: Playful, creative, joyful
  static const LinearGradient pastelRainbow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    colors: [
      Color(0xFFFFF8F8), // Light pink
      Color(0xFFFFFAF0), // Peach
      Color(0xFFFFFFF8), // Light yellow
      Color(0xFFF8FFFA), // Mint
      Color(0xFFF8F9FF), // Lavender
    ],
  );

  // ========== STACK-BASED GRADIENTS (LAYERED) ==========

  /// Layered Elegance - Multiple overlapping gradients
  /// Creates depth and visual interest
  static Widget layeredElegance = Stack(
    children: [
      // Base layer: Soft pink
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF5F7),
                Color(0xFFFFF8FA),
              ],
            ),
          ),
        ),
      ),
      // Overlay: Subtle radial glow
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.5, -0.3),
              radius: 1.2,
              colors: [
                Color(0x30FFFFFF), // White overlay with transparency
                Color(0x00FFFFFF), // Transparent edge
              ],
            ),
          ),
        ),
      ),
    ],
  );

  /// Frosted Glass - Modern glassmorphism background
  /// Combines subtle gradient with transparency
  static Widget frostedGlass = Stack(
    children: [
      // Base gradient
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5F7FA),
                Color(0xFFFBFCFD),
                Color(0xFFF0F3F7),
              ],
            ),
          ),
        ),
      ),
      // Overlay circles for depth
      Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFE8E8FF).withValues(alpha: 0.15),
                const Color(0xFFFFFFFF).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -150,
        left: -150,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFF0F5).withValues(alpha: 0.15),
                const Color(0xFFFFFFFF).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  /// Flowing Silk - Organic, flowing gradient effect
  /// Uses sweep gradients for smooth transitions
  static Widget flowingSilk = Stack(
    children: [
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.topRight,
              startAngle: 0,
              endAngle: 3.14159 * 2,
              colors: [
                Color(0xFFFFF8FB),
                Color(0xFFFFFFFE),
                Color(0xFFF8F8FF),
                Color(0xFFFFFAF8),
                Color(0xFFFFF8FB),
              ],
            ),
          ),
        ),
      ),
      // Softening overlay
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFFFFF).withValues(alpha: 0.4),
                const Color(0xFFFFFFFF).withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  // ========== ANIMATED CANDIDATES (STATIC VERSIONS) ==========

  /// Aurora Whisper - Northern lights inspired
  /// Perfect for: Magic, wonder, creativity
  static const LinearGradient auroraWhisper = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.6, 1.0],
    colors: [
      Color(0xFFF5F8FF), // Ice blue
      Color(0xFFF8F5FF), // Lavender
      Color(0xFFFFF5F8), // Rose
      Color(0xFFF5FFFA), // Mint
    ],
  );

  /// Moonlit Satin - Cool, serene evening palette
  /// Perfect for: Calm, tranquility, meditation
  static const LinearGradient moonlitSatin = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF5F8FB), // Moonlight blue
      Color(0xFFF8F8FA), // Silver
      Color(0xFFF5F6F9), // Cool gray
    ],
  );

  // ========== USAGE HELPER ==========

  /// Returns a Container with the specified background gradient
  static Widget withBackground(Widget child, {required dynamic gradient}) {
    if (gradient is Widget) {
      return Stack(
        children: [
          gradient,
          child,
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }

  /// List of all available simple gradients with names
  static final Map<String, Gradient> allGradients = {
    'Soft Lavender Dreams': softLavenderDreams,
    'Pearl Essence': pearlEssence,
    'Mint Cream': mintCream,
    'Champagne Glow': champagneGlow,
    'Rose Quartz': roseQuartz,
    'Silk Mist': silkMist,
    'Sky Whisper': skyWhisper,
    'Peach Sorbet': peachSorbet,
    'Morning Dew': morningDew,
    'Soft Glow': softGlow,
    'Ethereal Halo': etherealHalo,
    'Diagonal Grace': diagonalGrace,
    'Sunlight Cascade': sunlightCascade,
    'Cloud Nine': cloudNine,
    'Pastel Rainbow': pastelRainbow,
    'Aurora Whisper': auroraWhisper,
    'Moonlit Satin': moonlitSatin,
  };

  /// List of all available complex (Widget) backgrounds with names
  static final Map<String, Widget> allComplexBackgrounds = {
    'Layered Elegance': layeredElegance,
    'Frosted Glass': frostedGlass,
    'Flowing Silk': flowingSilk,
  };
}
