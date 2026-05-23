import 'package:flutter/material.dart';

class AppTheme {
  // Paleta MindFlow
  static const Color primary     = Color(0xFF6C63FF); // roxo
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color secondary   = Color(0xFF03DAC6); // teal
  static const Color background  = Color(0xFF0F0E17); // fundo escuro
  static const Color surface     = Color(0xFF1C1B29); // card
  static const Color surfaceAlt  = Color(0xFF252438); // input
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecond  = Color(0xFFB0AEC8);
  static const Color error       = Color(0xFFCF6679);
  static const Color success     = Color(0xFF4CAF82);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
      titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecond),
      labelLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textSecond, fontSize: 14),
      labelStyle: const TextStyle(color: textSecond),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textPrimary,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}