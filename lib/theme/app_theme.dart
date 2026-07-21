import 'package:flutter/material.dart';

class AppTheme {
  // Global Design Tokens
  static const Color background = Color(0xFF09090B); // Deep Dark OLED
  static const Color surface = Color(0xFF18181B); // Card Background
  static const Color primary = Color(0xFF6366F1); // Indigo Accent
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Colors.white54;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        background: background,
        error: error,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Modern squircle
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Inter', color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Inter', color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
