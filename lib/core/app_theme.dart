import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors from "Academic Vitality" Design System
  static const Color primaryRed = Color(0xFFBE1E2D);
  static const Color secondaryGold = Color(0xFFFBB03B);
  static const Color tertiaryIndigo = Color(0xFF4A47A3);
  static const Color neutralColor = Color(0xFF1A1C1E);

  static const Color background = Color(0xFFF9F9FC);
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color outline = Color(0xFF8F6F6E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: secondaryGold,
        tertiary: tertiaryIndigo,
        surface: background,
        onSurface: onSurface,
        outline: outline,
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontWeight: FontWeight.bold,
          fontSize: 30,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontWeight: FontWeight.normal,
          fontSize: 16,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFEEEFF0)),
        ),
      ),
    );
  }
}
