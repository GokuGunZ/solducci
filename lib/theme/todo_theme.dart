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

  // ========== BORDER ==========

  /// Border for AppBar bottom (purple line)
  static BoxDecoration appBarDecoration = BoxDecoration(
    gradient: appBarGradient,
    border: Border(
      bottom: BorderSide(
        color: primaryPurple,
        width: 2,
      ),
    ),
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  /// Outlined button style with purple border
  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryPurple,
    side: BorderSide(color: primaryPurple, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
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
}
