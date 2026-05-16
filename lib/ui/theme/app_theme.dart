import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/color_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'app_color_tokens.dart';

/// M3-compliant theme: near-black base (#0E0E0E), brand red accent (#D41414),
/// warm orange (#FF6D00) for secondary highlights (often at reduced opacity).
/// Typography uses **Lato** (Google Fonts) across display through label roles.
class AppTheme {
  AppTheme._();

  // ── Dark ──────────────────────────────────────────────────────────────────

  static ThemeData dark() {
    final textTheme = _buildTextTheme(
      primary: ColorTokens.textPrimary,
      secondary: ColorTokens.textSecondary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorTokens.backgroundPrimary,

      // ── Full M3 ColorScheme ────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: ColorTokens.primaryAccent,
        onPrimary: ColorTokens.onAccent,
        primaryContainer: ColorTokens.darkPrimaryContainer,
        onPrimaryContainer: ColorTokens.darkOnPrimaryContainer,
        secondary: ColorTokens.optionalAccent,
        onSecondary: ColorTokens.backgroundPrimary,
        secondaryContainer: ColorTokens.darkSecondaryContainer,
        onSecondaryContainer: ColorTokens.darkOnSecondaryContainer,
        tertiary: ColorTokens.blueprintOrange,
        onTertiary: ColorTokens.darkOnTertiary,
        tertiaryContainer: ColorTokens.darkTertiaryContainer,
        onTertiaryContainer: ColorTokens.darkOnTertiaryContainer,
        error: ColorTokens.danger,
        onError: Colors.white,
        errorContainer: ColorTokens.darkErrorContainer,
        onErrorContainer: ColorTokens.darkOnErrorContainer,
        surface: ColorTokens.surface,
        onSurface: ColorTokens.textPrimary,
        onSurfaceVariant: ColorTokens.textSecondary,
        outline: ColorTokens.borderSubtle,
        outlineVariant: ColorTokens.darkOutlineVariant,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: ColorTokens.darkInverseSurface,
        onInverseSurface: ColorTokens.darkOnInverseSurface,
        inversePrimary: ColorTokens.darkInversePrimary,
        surfaceContainerLowest: ColorTokens.darkSurfaceContainerLowest,
        surfaceContainerLow: ColorTokens.darkSurfaceContainerLow,
        surfaceContainer: ColorTokens.surface,
        surfaceContainerHigh: ColorTokens.surfaceElevated,
        surfaceContainerHighest: ColorTokens.darkSurfaceContainerHighest,
      ),

      // ── Full M3 TextTheme ──────────────────────────────────────────────
      textTheme: textTheme,

      // ── Component themes ──────────────────────────────────────────────

      // Card — M3 elevated surface
      cardTheme: CardThemeData(
        color: ColorTokens.surface,
        elevation: 1,
        surfaceTintColor: ColorTokens.blueprintOrange.withValues(alpha: 0.14),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.radiusMd,
          side: BorderSide(
            color: ColorTokens.borderSubtle.withValues(alpha: 0.5),
          ),
        ),
      ),

      // Divider — replaces deprecated dividerColor
      dividerTheme: const DividerThemeData(
        color: ColorTokens.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: ColorTokens.backgroundPrimary,
        foregroundColor: ColorTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ColorTokens.textPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: ColorTokens.textPrimary),
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: ColorTokens.textPrimary,
        size: 24,
      ),

      // NavigationBar (M3 bottom navigation)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorTokens.surface,
        surfaceTintColor: ColorTokens.blueprintOrange.withValues(alpha: 0.22),
        elevation: 3,
        height: 80,
        indicatorColor: ColorTokens.blueprintOrange.withValues(alpha: 0.32),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: ColorTokens.textPrimary,
            );
          }
          return GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: ColorTokens.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: ColorTokens.brandRed,
              size: 24,
            );
          }
          return const IconThemeData(
            color: ColorTokens.textMuted,
            size: 24,
          );
        }),
      ),

      // FilledButton — M3 primary action (high emphasis)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.primaryAccent,
          foregroundColor: ColorTokens.onAccent,
          disabledBackgroundColor: ColorTokens.surfaceElevated,
          disabledForegroundColor: ColorTokens.textMuted,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ElevatedButton — M3 tonal-surface action (medium emphasis)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.surfaceElevated,
          foregroundColor: ColorTokens.primaryAccent,
          elevation: 1,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // OutlinedButton — medium-low emphasis
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.textPrimary,
          side: const BorderSide(color: ColorTokens.borderSubtle),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // TextButton — low emphasis
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.primaryAccent,
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.primaryAccent,
        foregroundColor: ColorTokens.onAccent,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input / TextField
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
        enabledBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(
            color: ColorTokens.borderSubtle,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(
            color: ColorTokens.primaryAccent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(color: ColorTokens.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(color: ColorTokens.danger, width: 2),
        ),
        labelStyle: const TextStyle(color: ColorTokens.textSecondary),
        hintStyle: const TextStyle(color: ColorTokens.textMuted),
        prefixIconColor: ColorTokens.textSecondary,
        suffixIconColor: ColorTokens.textSecondary,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: ColorTokens.surface,
        selectedColor: ColorTokens.darkPrimaryContainer,
        disabledColor: ColorTokens.darkSurfaceContainerLow,
        labelStyle: const TextStyle(
          color: ColorTokens.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        secondaryLabelStyle: const TextStyle(
          color: ColorTokens.darkOnPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: ColorTokens.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        elevation: 0,
        pressElevation: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: ColorTokens.surfaceElevated,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.radiusLg),
        titleTextStyle: GoogleFonts.lato(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ColorTokens.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: ColorTokens.textSecondary,
          height: 1.5,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorTokens.surfaceElevated,
        contentTextStyle: const TextStyle(color: ColorTokens.textPrimary),
        actionTextColor: ColorTokens.primaryAccent,
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.radiusMd),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: ColorTokens.textPrimary,
        iconColor: ColorTokens.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return ColorTokens.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorTokens.primaryAccent;
          }
          return ColorTokens.surfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return ColorTokens.borderSubtle;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorTokens.primaryAccent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: ColorTokens.borderSubtle, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorTokens.primaryAccent;
          }
          return ColorTokens.textMuted;
        }),
      ),

      // Badge
      badgeTheme: const BadgeThemeData(
        backgroundColor: ColorTokens.primaryAccent,
        textColor: Colors.white,
        smallSize: 8,
        largeSize: 16,
        textStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColorTokens.surfaceElevated,
          borderRadius: RadiusTokens.radiusSm,
          border: Border.all(color: ColorTokens.borderSubtle),
        ),
        textStyle: const TextStyle(
          color: ColorTokens.textPrimary,
          fontSize: 12,
        ),
      ),

      useMaterial3: true,
      extensions: const [AppColorTokens.dark],
    );
  }

  // ── Light ─────────────────────────────────────────────────────────────────

  static ThemeData light() {
    final textTheme = _buildTextTheme(
      primary: ColorTokens.lightTextPrimary,
      secondary: ColorTokens.lightTextSecondary,
    );

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: ColorTokens.lightBackgroundPrimary,

      // ── Full M3 ColorScheme ────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: ColorTokens.lightPrimaryAccent,
        onPrimary: ColorTokens.onAccent,
        primaryContainer: ColorTokens.lightPrimaryContainer,
        onPrimaryContainer: ColorTokens.lightOnPrimaryContainer,
        secondary: ColorTokens.optionalAccent,
        onSecondary: ColorTokens.lightTextPrimary,
        secondaryContainer: ColorTokens.lightSecondaryContainer,
        onSecondaryContainer: ColorTokens.lightOnSecondaryContainer,
        tertiary: ColorTokens.lightTertiary,
        onTertiary: ColorTokens.lightOnTertiary,
        tertiaryContainer: ColorTokens.lightTertiaryContainer,
        onTertiaryContainer: ColorTokens.lightOnTertiaryContainer,
        error: ColorTokens.danger,
        onError: Colors.white,
        errorContainer: ColorTokens.lightErrorContainer,
        onErrorContainer: ColorTokens.lightOnErrorContainer,
        surface: ColorTokens.lightSurface,
        onSurface: ColorTokens.lightTextPrimary,
        onSurfaceVariant: ColorTokens.lightTextSecondary,
        outline: ColorTokens.lightOutline,
        outlineVariant: ColorTokens.lightBorderSubtle,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: ColorTokens.lightInverseSurface,
        onInverseSurface: ColorTokens.lightOnInverseSurface,
        inversePrimary: ColorTokens.lightInversePrimary,
        surfaceContainerLowest: ColorTokens.lightSurface,
        surfaceContainerLow: ColorTokens.lightSurfaceContainerLow,
        surfaceContainer: ColorTokens.lightSurfaceContainer,
        surfaceContainerHigh: ColorTokens.lightSurfaceContainerHigh,
        surfaceContainerHighest: ColorTokens.lightSurfaceContainerHighest,
      ),

      // ── Full M3 TextTheme ──────────────────────────────────────────────
      textTheme: textTheme,

      // ── Component themes ──────────────────────────────────────────────

      cardTheme: CardThemeData(
        color: ColorTokens.lightSurface,
        elevation: 1,
        surfaceTintColor: ColorTokens.blueprintOrange.withValues(alpha: 0.10),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.radiusMd,
          side: BorderSide(
            color: ColorTokens.lightBorderSubtle.withValues(alpha: 0.8),
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: ColorTokens.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: ColorTokens.lightBackgroundPrimary,
        foregroundColor: ColorTokens.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ColorTokens.lightTextPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: ColorTokens.lightTextPrimary),
      ),

      iconTheme: const IconThemeData(
        color: ColorTokens.lightTextPrimary,
        size: 24,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorTokens.lightSurface,
        surfaceTintColor: ColorTokens.blueprintOrange.withValues(alpha: 0.18),
        elevation: 3,
        height: 80,
        indicatorColor: ColorTokens.blueprintOrange.withValues(alpha: 0.28),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: ColorTokens.lightTextPrimary,
            );
          }
          return GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: ColorTokens.lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: ColorTokens.lightPrimaryAccent,
              size: 24,
            );
          }
          return const IconThemeData(
            color: ColorTokens.lightTextMuted,
            size: 24,
          );
        }),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.lightPrimaryAccent,
          foregroundColor: ColorTokens.onAccent,
          disabledBackgroundColor: ColorTokens.lightSurfaceElevated,
          disabledForegroundColor: ColorTokens.lightTextMuted,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.lightSurfaceElevated,
          foregroundColor: ColorTokens.lightPrimaryAccent,
          elevation: 1,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.lightTextPrimary,
          side: const BorderSide(color: ColorTokens.lightBorderSubtle),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusLg,
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.lightPrimaryAccent,
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.lightPrimaryAccent,
        foregroundColor: ColorTokens.onAccent,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.md,
        ),
        border: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(
            color: ColorTokens.lightBorderSubtle,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(
            color: ColorTokens.lightPrimaryAccent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(color: ColorTokens.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(color: ColorTokens.danger, width: 2),
        ),
        labelStyle: const TextStyle(color: ColorTokens.lightTextSecondary),
        hintStyle: const TextStyle(color: ColorTokens.lightTextMuted),
        prefixIconColor: ColorTokens.lightTextSecondary,
        suffixIconColor: ColorTokens.lightTextSecondary,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: ColorTokens.lightSurface,
        selectedColor: ColorTokens.lightPrimaryContainer,
        disabledColor: ColorTokens.lightSurfaceElevated,
        labelStyle: const TextStyle(
          color: ColorTokens.lightTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        secondaryLabelStyle: const TextStyle(
          color: ColorTokens.lightOnPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: ColorTokens.lightBorderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        elevation: 0,
        pressElevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: ColorTokens.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.radiusLg),
        titleTextStyle: GoogleFonts.lato(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ColorTokens.lightTextPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: ColorTokens.lightTextSecondary,
          height: 1.5,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorTokens.lightSurfaceElevated,
        contentTextStyle:
            const TextStyle(color: ColorTokens.lightTextPrimary),
        actionTextColor: ColorTokens.lightPrimaryAccent,
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.radiusMd),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: ColorTokens.lightTextPrimary,
        iconColor: ColorTokens.lightTextSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return ColorTokens.lightTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorTokens.lightPrimaryAccent;
          }
          return ColorTokens.lightSurfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return ColorTokens.lightBorderSubtle;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorTokens.lightPrimaryAccent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: ColorTokens.lightBorderSubtle, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorTokens.lightPrimaryAccent;
          }
          return ColorTokens.lightTextMuted;
        }),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: ColorTokens.lightPrimaryAccent,
        textColor: Colors.white,
        smallSize: 8,
        largeSize: 16,
        textStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColorTokens.lightSurfaceElevated,
          borderRadius: RadiusTokens.radiusSm,
          border: Border.all(color: ColorTokens.lightBorderSubtle),
        ),
        textStyle: const TextStyle(
          color: ColorTokens.lightTextPrimary,
          fontSize: 12,
        ),
      ),

      useMaterial3: true,
      extensions: const [AppColorTokens.light],
    );
  }

  // ── Shared TextTheme builder ───────────────────────────────────────────────
  //
  // Sizes follow M3 spec with minor adjustments for the app's compact mobile
  // viewport (displayLarge capped at 40 instead of M3's 57).
  //
  // Lato (via GoogleFonts): blueprint typography for all M3 text roles.

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
  }) {
    final latoBase = GoogleFonts.latoTextTheme(
      TextTheme(
        // Display roles
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: 0,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: 0,
        ),
        // Headline roles
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: 0.4,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        // Title roles — Lato
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: primary,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primary,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primary,
          letterSpacing: 0.1,
        ),
        // Body roles — Lato
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: secondary,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondary,
          letterSpacing: 0.4,
        ),
        // Label roles — Lato
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondary,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondary,
          letterSpacing: 0.5,
        ),
      ),
    ).apply(
      bodyColor: primary,
      displayColor: primary,
      decoration: TextDecoration.none,
    );

    return latoBase;
  }
}
