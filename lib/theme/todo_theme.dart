import 'package:flutter/material.dart';

/// Theme configuration for the ToDo section of the app
/// Centralizes colors, gradients, and styling for consistency
class TodoTheme {
  // Private constructor to prevent instantiation
  TodoTheme._();

  // ========== PRIMARY COLORS ==========

  /// Primary purple color used throughout the ToDo section
  static const Color primaryPurple = Color(0xFF7B1FA2); // purple[700]

  /// Light purple for backgrounds and subtle accents
  static const Color lightPurple = Color(0xFFF3E5F5); // purple[50]

  /// White color for text on colored backgrounds
  static const Color onPrimaryColor = Colors.white;

  // ========== GRADIENTS ==========

  /// Gradient for AppBar background (transparent to purple)
  /// Matches the design in DocumentsHomeView
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.9, 0.95, 1.0],
    colors: [
      Color(0x00000000), // Transparent
      Color(0x197B1FA2), // 10% opacity purple
      Color(0x337B1FA2), // 20% opacity purple
      Color(0x597B1FA2), // 35% opacity purple
    ],
  );

  /// Solid gradient for full-color backgrounds (dialogs, headers)
  static const LinearGradient solidGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9C27B0), // purple[600]
      Color(0xFF7B1FA2), // purple[700]
    ],
  );

  /// Light gradient for cards and containers
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF3E5F5), // purple[50]
      Color(0xFFE1BEE7), // purple[100]
    ],
  );

  /// Custom layered background gradient for ToDo list view
  /// Composed of three overlapping sweep and linear gradients
  static Widget customBackgroundGradient = Stack(
    children: [
      // Layer 1: Bottom-right sweep gradient (Black -> Green -> Light Blue)
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.bottomRight,
              startAngle: 75 * 3.14159 / 180,
              endAngle: 240 * 3.14159 / 180,
              colors: [
                Color(0x66000000), // Black with 40% opacity
                Color(0x664CAF50), // Green with 40% opacity
                Color.fromARGB(164, 3, 168, 244), // Light Blue with 40% opacity
              ],
            ),
          ),
        ),
      ),
      // Layer 2: Bottom-left sweep gradient (White -> Grey -> Purple)
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.bottomLeft,
              startAngle: 211.5 * 3.14159 / 180,
              endAngle: 333 * 3.14159 / 180,
              colors: [
                Color(0x4DFFFFFF), // White with 30% opacity
                Color(0x4D9E9E9E), // Grey with 30% opacity
                Color.fromARGB(214, 155, 39, 176), // Purple with 30% opacity
              ],
            ),
          ),
        ),
      ),
      // Layer 3: Linear gradient top to bottom (Purple -> Blue -> Black)
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(51, 155, 39, 176), // Purple with 10% opacity
                Color.fromARGB(65, 33, 149, 243), // Blue with 10% opacity
                Color.fromARGB(150, 0, 0, 0), // Black with 10% opacity
              ],
            ),
          ),
        ),
      ),
    ],
  );

  // ========== BORDER ==========

  /// Border for AppBar bottom (purple line)
  static BoxDecoration appBarDecoration = BoxDecoration(
    gradient: appBarGradient,
    border: Border(bottom: BorderSide(color: primaryPurple, width: 2)),
  );

  // ========== TEXT STYLES ==========

  /// AppBar title text style
  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryPurple,
  );

  /// Section header text style
  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryPurple,
  );

  /// Body text style on colored background
  static const TextStyle onPrimaryTextStyle = TextStyle(
    color: onPrimaryColor,
    fontWeight: FontWeight.w500,
  );

  // ========== BUTTON STYLES ==========

  /// Elevated button style with purple gradient background
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryPurple,
    foregroundColor: onPrimaryColor,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  /// Outlined button style with purple border
  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryPurple,
    side: BorderSide(color: primaryPurple, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  /// Text button style with purple color
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryPurple,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  /// Floating Action Button style
  static const Color fabBackgroundColor = primaryPurple;
  static const Color fabForegroundColor = onPrimaryColor;

  // ========== ICON STYLES ==========

  /// Icon color for primary elements
  static const Color iconColor = primaryPurple;

  /// Icon color on colored backgrounds
  static const Color onPrimaryIconColor = onPrimaryColor;

  // ========== FORM ELEMENTS ==========

  /// Checkbox active color
  static const Color checkboxActiveColor = primaryPurple;

  /// Switch active color
  static const Color switchActiveColor = primaryPurple;

  /// Chip selected color
  static const Color chipSelectedColor = primaryPurple;

  /// Filter bar background color
  static const Color filterBarBackgroundColor = lightPurple;

  // ========== DECORATIONS ==========

  /// Card decoration with subtle shadow
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: primaryPurple.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Dialog header decoration with gradient
  static const BoxDecoration dialogHeaderDecoration = BoxDecoration(
    gradient: solidGradient,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    ),
  );

  // ========== HELPER METHODS ==========

  /// Returns a color with specified opacity from primary purple
  static Color getPrimaryWithOpacity(double opacity) {
    return primaryPurple.withValues(alpha: opacity);
  }

  /// Returns a BoxDecoration with gradient background
  static BoxDecoration getGradientDecoration({
    LinearGradient? gradient,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      gradient: gradient ?? solidGradient,
      borderRadius: borderRadius,
      border: border,
    );
  }

  // ========== GLASS MORPHISM ==========

  /// Glass morphism decoration for containers
  /// Creates a frosted glass effect with blur backdrop, semi-transparent background, and luminous border
  /// TRUE GLASSMORPHISM: Very high transparency to let background gradient show through
  static BoxDecoration glassDecoration({
    double opacity = 0.05, // MUCH lower opacity for true glass effect
    double borderOpacity = 0.4,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      // Use a subtle gradient with VERY low opacity
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (backgroundColor ?? Colors.white).withValues(alpha: opacity * 1.5),
          (backgroundColor ?? Colors.white).withValues(alpha: opacity * 0.5),
        ],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: (borderColor ?? Colors.white).withValues(alpha: borderOpacity),
        width: 1.5,
      ),
      boxShadow: boxShadow ?? [
        BoxShadow(
          color: primaryPurple.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.3),
          blurRadius: 2,
          offset: const Offset(-1, -1),
        ),
      ],
    );
  }

  /// Glass morphism decoration for AppBar
  /// Lighter, more transparent variant for top navigation
  static BoxDecoration glassAppBarDecoration({
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.15),
        ],
      ),
      borderRadius: borderRadius,
      border: Border(
        bottom: BorderSide(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Glass morphism decoration for filter/sort bars
  /// Balanced opacity for interactive elements
  static BoxDecoration glassFilterBarDecoration({
    BorderRadius? borderRadius,
    Color? accentColor,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          (accentColor ?? Colors.white).withValues(alpha: 0.15),
        ],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (accentColor ?? primaryPurple).withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
