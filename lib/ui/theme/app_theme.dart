import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/color_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';

/// Duolingo-bold + Discord-gamer dark theme.
/// Uses Material 3 and design tokens.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorTokens.backgroundPrimary,
      colorScheme: const ColorScheme.dark(
        primary: ColorTokens.primaryAccent,
        onPrimary: Colors.white,
        secondary: ColorTokens.optionalAccent,
        onSecondary: ColorTokens.backgroundPrimary,
        surface: ColorTokens.surface,
        onSurface: ColorTokens.textPrimary,
        onSurfaceVariant: ColorTokens.textSecondary,
        error: ColorTokens.danger,
        onError: Colors.white,
      ),
      cardColor: ColorTokens.surface,
      textTheme: GoogleFonts.robotoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: ColorTokens.textPrimary,
            letterSpacing: 1.2,
          ),
          headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: ColorTokens.textPrimary,
            letterSpacing: 0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ColorTokens.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorTokens.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorTokens.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: ColorTokens.textPrimary,
          ),
        ),
      ).apply(
        bodyColor: ColorTokens.textPrimary,
        displayColor: ColorTokens.textPrimary,
        decoration: TextDecoration.none,
      ).copyWith(
        displayLarge: GoogleFonts.roboto(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: ColorTokens.textPrimary,
          letterSpacing: 1.2,
        ),
        headlineLarge: GoogleFonts.roboto(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: ColorTokens.textPrimary,
          letterSpacing: 1.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.textPrimary,
          side: const BorderSide(color: ColorTokens.borderSubtle),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.md,
        ),
        border: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(
            color: ColorTokens.primaryAccent,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: ColorTokens.textSecondary),
        hintStyle: const TextStyle(color: ColorTokens.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ColorTokens.backgroundPrimary,
        foregroundColor: ColorTokens.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ColorTokens.textPrimary,
          letterSpacing: 0.8,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorTokens.backgroundSecondary,
        selectedItemColor: ColorTokens.primaryAccent,
        unselectedItemColor: ColorTokens.textSecondary,
      ),
      dividerColor: ColorTokens.borderSubtle,
      useMaterial3: true,
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9FBFB),
      colorScheme: const ColorScheme.light(
        primary: ColorTokens.primaryAccent,
        onPrimary: Colors.white,
        secondary: ColorTokens.optionalAccent,
        onSecondary: Color(0xFF0F1117),
        surface: Colors.white,
        onSurface: Color(0xFF0F1117),
        onSurfaceVariant: Color(0xFF4E5A5B),
        error: ColorTokens.danger,
        onError: Colors.white,
      ),
      cardColor: Colors.white,
      textTheme: GoogleFonts.robotoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F1117),
            letterSpacing: 1.2,
          ),
          headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F1117),
            letterSpacing: 1.0,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F1117),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1117),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4E5A5B),
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F1117),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF0F1117),
          side: const BorderSide(color: Color(0xFFE8ECED)),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.md,
        ),
        border: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(
            color: ColorTokens.primaryAccent,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: Color(0xFF4E5A5B)),
        hintStyle: const TextStyle(color: Color(0xFF4E5A5B)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF9FBFB),
        foregroundColor: const Color(0xFF0F1117),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F1117),
          letterSpacing: 0.8,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: ColorTokens.primaryAccent,
        unselectedItemColor: Color(0xFF4E5A5B),
      ),
      dividerColor: const Color(0xFFE8ECED),
      useMaterial3: true,
    );
  }
}
