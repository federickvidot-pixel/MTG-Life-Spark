import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/color_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'app_color_tokens.dart';

/// Cool dark fantasy + modern sans body. Uses Material 3 and design tokens.
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
            fontWeight: FontWeight.w700,
            color: ColorTokens.textPrimary,
            letterSpacing: 0.4,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: ColorTokens.textPrimary,
          letterSpacing: 1.0,
        ),
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: ColorTokens.textPrimary,
          letterSpacing: 0.5,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ColorTokens.textPrimary,
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
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ColorTokens.textPrimary,
          letterSpacing: 0.6,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorTokens.surfaceElevated,
        selectedItemColor: ColorTokens.primaryAccent,
        unselectedItemColor: ColorTokens.textMuted,
      ),
      dividerColor: ColorTokens.borderSubtle,
      useMaterial3: true,
      extensions: const [AppColorTokens.dark],
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F7FF),
      colorScheme: const ColorScheme.light(
        primary: ColorTokens.primaryAccent,
        onPrimary: Colors.white,
        secondary: ColorTokens.optionalAccent,
        onSecondary: Color(0xFF0D1224),
        surface: Colors.white,
        onSurface: Color(0xFF0D1224),
        onSurfaceVariant: Color(0xFF3D4A6B),
        error: ColorTokens.danger,
        onError: Colors.white,
      ),
      cardColor: Colors.white,
      textTheme: GoogleFonts.robotoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1224),
            letterSpacing: 1.0,
          ),
          headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1224),
            letterSpacing: 0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1224),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1224),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D4A6B),
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D1224),
          ),
        ),
      ).copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D1224),
          letterSpacing: 0.8,
        ),
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D1224),
          letterSpacing: 0.5,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D1224),
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
          foregroundColor: const Color(0xFF0D1224),
          side: const BorderSide(color: Color(0xFFD4DBF0)),
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
        labelStyle: const TextStyle(color: Color(0xFF3D4A6B)),
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5F7FF),
        foregroundColor: const Color(0xFF0D1224),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D1224),
          letterSpacing: 0.6,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF0F2FC),
        selectedItemColor: ColorTokens.primaryAccent,
        unselectedItemColor: Color(0xFF6B7280),
      ),
      dividerColor: const Color(0xFFD4DBF0),
      useMaterial3: true,
      extensions: const [AppColorTokens.light],
    );
  }
}
