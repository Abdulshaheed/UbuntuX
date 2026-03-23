import 'package:flutter/material.dart';

class UbuntuXTheme {
  // Palette
  static const Color darkBlue = Color(0xFF0D1B2A);
  static const Color deepNavy = Color(0xFF1B263B);
  static const Color slateBlue = Color(0xFF415A77);
  static const Color silverGray = Color(0xFF778DA9);
  static const Color offWhite = Color(0xFFE0E1DD);
  static const Color accentCyan = Color(0xFF00B4D8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkBlue,
      scaffoldBackgroundColor: darkBlue,
      cardColor: deepNavy,
      colorScheme: ColorScheme.dark(
        primary: accentCyan,
        secondary: slateBlue,
        surface: deepNavy,
        onSurface: offWhite,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: offWhite,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        bodyLarge: TextStyle(
          color: silverGray,
          fontSize: 16,
        ),
        labelLarge: TextStyle(
          color: offWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: darkBlue,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
