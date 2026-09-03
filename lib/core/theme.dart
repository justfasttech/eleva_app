import 'package:flutter/material.dart';

abstract class ElevaColors {
  static const Color gold = Color(0xFFE8B84B);
  static const Color goldLight = Color(0xFFF2D68A);
  static const Color goldDark = Color(0xFFD4A43A);
  static const Color white = Colors.white;
  static const Color offWhite = Color(0xFFFAF6EE);
  static const Color textDark = Color(0xFF3D3D3D);
  static const Color textMuted = Color(0xFF8A8A8A);
}

final elevaTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ElevaColors.gold,
    brightness: Brightness.light,
    primary: ElevaColors.gold,
    onPrimary: ElevaColors.white,
    surface: ElevaColors.white,
  ),
  scaffoldBackgroundColor: ElevaColors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: ElevaColors.white,
    foregroundColor: ElevaColors.textDark,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ElevaColors.gold,
      foregroundColor: ElevaColors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ElevaColors.gold,
      minimumSize: const Size(double.infinity, 52),
      side: const BorderSide(color: ElevaColors.gold, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ElevaColors.offWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ElevaColors.gold, width: 1.5),
    ),
    hintStyle: const TextStyle(color: ElevaColors.textMuted),
  ),
);
