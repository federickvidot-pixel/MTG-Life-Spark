import 'package:flutter/material.dart';

import 'app_color_palettes.dart';

/// MTG Life Spark color system — **dark-first**, scheme-aware palette.
///
/// The active palette comes from [AppColorPalettes] and is switched in Settings.
/// [applyPalette] is called when building [ThemeData]; legacy [AppTheme] getters
/// read through this class so game + shell stay in sync.
class ColorTokens {
  ColorTokens._();

  static AppColorPalette _palette = AppColorPalettes.violet;

  static AppColorPalette get palette => _palette;

  static void applyPalette(AppColorPalette palette) {
    _palette = palette;
  }

  static void applyScheme(AppColorSchemeId id) {
    _palette = AppColorPalettes.byId(id);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Brand
  // ══════════════════════════════════════════════════════════════════════════

  static Color get brandBlack => _palette.brandBlack;
  static Color get brandAccent => _palette.brandAccent;
  static const Color onAccent = Color(0xFFFFFFFF);

  static Color get brandAccentSoft => _palette.brandAccentSoft;
  static Color get brandAccentMuted => _palette.brandAccentMuted;

  // Backward-compatible aliases
  static Color get brandPurple => brandAccent;
  static Color get brandPurpleSoft => brandAccentSoft;
  static Color get brandPurpleMuted => brandAccentMuted;
  static Color get brandRed => brandAccent;

  // ══════════════════════════════════════════════════════════════════════════
  // Dark neutrals
  // ══════════════════════════════════════════════════════════════════════════

  static Color get backgroundPrimary => _palette.backgroundPrimary;
  static Color get backgroundSecondary => _palette.backgroundSecondary;
  static Color get surface => _palette.surface;
  static Color get surfaceElevated => _palette.surfaceElevated;
  static Color get borderSubtle => _palette.borderSubtle;

  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textMuted => _palette.textMuted;

  // ══════════════════════════════════════════════════════════════════════════
  // Semantic (shared across schemes)
  // ══════════════════════════════════════════════════════════════════════════

  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  static Color get emphasis => _palette.emphasis;

  static Color get primaryAccent => brandAccent;
  static const Color optionalAccent = success;
  static Color get blueprintOrange => emphasis;
  static Color get accentGold => emphasis;
  static const Color dangerAmber = warning;

  // ══════════════════════════════════════════════════════════════════════════
  // Player identification (multiplayer only)
  // ══════════════════════════════════════════════════════════════════════════

  static const List<Color> playerPalette = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  static Color playerColor(int index) =>
      playerPalette[index % playerPalette.length];

  // ══════════════════════════════════════════════════════════════════════════
  // Light theme neutrals
  // ══════════════════════════════════════════════════════════════════════════

  static Color get lightBackgroundPrimary => _palette.lightBackgroundPrimary;
  static Color get lightBackgroundSecondary => _palette.lightBackgroundSecondary;
  static Color get lightSurface => _palette.lightSurface;
  static Color get lightSurfaceElevated => _palette.lightSurfaceElevated;
  static Color get lightBorderSubtle => _palette.lightBorderSubtle;
  static Color get lightTextPrimary => _palette.lightTextPrimary;
  static Color get lightTextSecondary => _palette.lightTextSecondary;
  static Color get lightTextMuted => _palette.lightTextMuted;
  static Color get lightPrimaryAccent => _palette.lightPrimaryAccent;

  // ══════════════════════════════════════════════════════════════════════════
  // M3 ColorScheme roles — dark
  // ══════════════════════════════════════════════════════════════════════════

  static Color get darkPrimaryContainer => _palette.darkPrimaryContainer;
  static Color get darkOnPrimaryContainer => _palette.darkOnPrimaryContainer;
  static const Color darkSecondary = Color(0xFF9CA3AF);
  static Color get darkOnSecondary => brandBlack;
  static Color get darkSecondaryContainer => _palette.darkSecondaryContainer;
  static const Color darkOnSecondaryContainer = Color(0xFFE5E7EB);
  static const Color darkTertiary = Color(0xFF8B8B9E);
  static Color get darkOnTertiary => brandBlack;
  static const Color darkTertiaryContainer = Color(0xFF232330);
  static const Color darkOnTertiaryContainer = Color(0xFFD1D5DB);
  static Color get darkOutlineVariant => borderSubtle;
  static const Color darkErrorContainer = Color(0xFF3D1A24);
  static const Color darkOnErrorContainer = Color(0xFFFFD6DE);
  static const Color darkInverseSurface = Color(0xFFE8E8ED);
  static Color get darkOnInverseSurface => brandBlack;
  static Color get darkInversePrimary => _palette.darkInversePrimary;
  static Color get darkSurfaceContainerLowest => _palette.darkSurfaceContainerLowest;
  static Color get darkSurfaceContainerLow => _palette.darkSurfaceContainerLow;
  static Color get darkSurfaceContainerHighest => surfaceElevated;

  // ══════════════════════════════════════════════════════════════════════════
  // M3 ColorScheme roles — light
  // ══════════════════════════════════════════════════════════════════════════

  static Color get lightPrimaryContainer => _palette.lightPrimaryContainer;
  static Color get lightOnPrimaryContainer => _palette.lightOnPrimaryContainer;
  static const Color lightSecondary = Color(0xFF52525E);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static Color get lightSecondaryContainer => _palette.lightSecondaryContainer;
  static Color get lightOnSecondaryContainer => _palette.lightOnSecondaryContainer;
  static const Color lightTertiary = Color(0xFF737380);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFE0E0EA);
  static const Color lightOnTertiaryContainer = Color(0xFF262630);
  static const Color lightOutline = Color(0xFF9A9AAA);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF410002);
  static Color get lightInverseSurface => _palette.surface;
  static Color get lightOnInverseSurface => lightBackgroundPrimary;
  static Color get lightInversePrimary => _palette.lightInversePrimary;
  static Color get lightSurfaceContainerLow => _palette.lightSurfaceContainerLow;
  static Color get lightSurfaceContainer => _palette.lightSurfaceContainer;
  static Color get lightSurfaceContainerHigh => _palette.lightSurfaceContainerHigh;
  static Color get lightSurfaceContainerHighest =>
      _palette.lightSurfaceContainerHighest;
}
