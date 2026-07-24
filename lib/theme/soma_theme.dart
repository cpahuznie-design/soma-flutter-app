import 'package:flutter/material.dart';

class SomaTheme {
  // Colors
  static const Color bgDeep = Color(0xFF0f172a);
  static const Color bgMid = Color(0xFF1e3a5f);
  static const Color bgCard = Color(0xFF1e293b);
  static const Color teal = Color(0xFF0d9488);
  static const Color tealBright = Color(0xFF2dd4bf);
  static const Color lavender = Color(0xFFa5b4fc);
  static const Color lavenderLight = Color(0xFFc7d2fe);
  static const Color purple = Color(0xFF8b5cf6);
  static const Color softBlue = Color(0xFF38bdf8);
  static const Color text = Color(0xFFe2e8f0);
  static const Color textMuted = Color(0xFF94a3b8);
  static const Color white = Color(0xFFf8fafc);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDeep,
    primaryColor: teal,
    colorScheme: const ColorScheme.dark(
      primary: teal,
      secondary: lavender,
      surface: bgCard,
      onPrimary: white,
      onSecondary: bgDeep,
      onSurface: text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDeep,
      foregroundColor: text,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: teal.withOpacity(0.3), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tealBright,
        side: BorderSide(color: teal.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: teal.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: teal.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
      labelStyle: const TextStyle(color: textMuted),
      hintStyle: const TextStyle(color: textMuted),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: teal,
      inactiveTrackColor: bgCard,
      thumbColor: tealBright,
      overlayColor: teal.withOpacity(0.2),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 32),
      headlineMedium: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 24),
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: text, fontSize: 16),
      bodyMedium: TextStyle(color: textMuted, fontSize: 14),
      bodySmall: TextStyle(color: textMuted, fontSize: 12),
    ),
  );
}