import 'package:flutter/material.dart';

/// Design palette: near-black base (#0E0E0E), brand red accent (#D41414),
/// warm orange (#FF6D00) for secondary emphasis (often with [.withValues] opacity).
class ColorTokens {
  ColorTokens._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color brandBlack = Color(0xFF0E0E0E);
  static const Color brandRed = Color(0xFFD41414);

  /// Warm orange — use full strength or `blueprintOrange.withValues(alpha: x)` for tints.
  static const Color blueprintOrange = Color(0xFFFF6D00);

  /// Text/icons on top of [brandRed] filled surfaces (buttons, FAB, etc.).
  static const Color onAccent = Color(0xFFFFFFFF);

  // ── Dark background ──────────────────────────────────────────────────────
  static const Color backgroundPrimary = brandBlack;
  static const Color backgroundSecondary = Color(0xFF131313);

  // ── Dark surface ─────────────────────────────────────────────────────────
  static const Color surface = Color(0xFF181818);
  static const Color surfaceElevated = Color(0xFF222222);

  // ── Dark border ──────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF383838);

  // ── Dark text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textMuted = Color(0xFF7A7A7A);

  // ── Accent ───────────────────────────────────────────────────────────────
  static const Color primaryAccent = brandRed;
  static const Color optionalAccent = Color(0xFF57F287); // secondary emphasis (success-adjacent)
  /// Legacy name: warm orange highlights (monarch, timers, energy, etc.).
  static const Color accentGold = blueprintOrange;

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF57F287);
  static const Color danger = Color(0xFFED4245);
  static const Color dangerAmber = Color(0xFFF97316);
  static const Color warning = Color(0xFFFEE75C);

  // ── Player palette ───────────────────────────────────────────────────────
  static const List<Color> playerPalette = [
    Color(0xFFE94560),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFFFD54F),
    Color(0xFFCE93D8),
    Color(0xFFFF8A65),
  ];

  static Color playerColor(int index) =>
      playerPalette[index % playerPalette.length];

  // ══════════════════════════════════════════════════════════════════════════
  // Light theme palette
  // ══════════════════════════════════════════════════════════════════════════

  static const Color lightBackgroundPrimary = Color(0xFFF4F4F4);
  static const Color lightBackgroundSecondary = Color(0xFFEBEBEB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F0F0);
  static const Color lightBorderSubtle = Color(0xFFD0D0D0);
  static const Color lightTextPrimary = Color(0xFF0E0E0E);
  static const Color lightTextSecondary = Color(0xFF4A4A4A);
  static const Color lightTextMuted = Color(0xFF6B7280);
  static const Color lightPrimaryAccent = brandRed;

  // ══════════════════════════════════════════════════════════════════════════
  // M3 container / role tokens — dark
  // ══════════════════════════════════════════════════════════════════════════

  static const Color darkPrimaryContainer = Color(0xFF3D1010);
  static const Color darkOnPrimaryContainer = Color(0xFFFFDAD6);
  static const Color darkSecondaryContainer = Color(0xFF1A2E24);
  static const Color darkOnSecondaryContainer = Color(0xFFA6F4C5);
  // tertiary == warm orange for M3 tertiary role
  static const Color darkOnTertiary = Color(0xFF1A0D12);
  static const Color darkTertiaryContainer = Color(0xFF2A2218);
  static const Color darkOnTertiaryContainer = Color(0xFFFFE7CC);
  static const Color darkOutlineVariant = Color(0xFF3A3A3A);
  static const Color darkErrorContainer = Color(0xFF4A0E0E);
  static const Color darkOnErrorContainer = Color(0xFFFFB3B3);
  static const Color darkInverseSurface = Color(0xFFE8E8E8);
  static const Color darkOnInverseSurface = Color(0xFF0E0E0E);
  static const Color darkInversePrimary = Color(0xFFFFB4A8);
  static const Color darkSurfaceContainerLowest = Color(0xFF080808);
  static const Color darkSurfaceContainerLow = Color(0xFF0A0A0A);
  static const Color darkSurfaceContainerHighest = Color(0xFF262626);

  // ══════════════════════════════════════════════════════════════════════════
  // M3 container / role tokens — light
  // ══════════════════════════════════════════════════════════════════════════

  static const Color lightPrimaryContainer = Color(0xFFFFDAD6);
  static const Color lightOnPrimaryContainer = Color(0xFF410008);
  static const Color lightSecondaryContainer = Color(0xFFCCF5E0);
  static const Color lightOnSecondaryContainer = Color(0xFF0A3020);
  static const Color lightTertiary = blueprintOrange;
  static const Color lightOnTertiary = Color(0xFF1A0D12);
  static const Color lightTertiaryContainer = Color(0xFFFFE8D6);
  static const Color lightOnTertiaryContainer = Color(0xFF331800);
  static const Color lightOutline = Color(0xFF9A9A9A);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF410002);
  static const Color lightInverseSurface = Color(0xFF1E1E1E);
  static const Color lightOnInverseSurface = Color(0xFFF5F5F5);
  static const Color lightInversePrimary = Color(0xFFFF5449);
  static const Color lightSurfaceContainerLow = Color(0xFFF5F5F5);
  static const Color lightSurfaceContainer = Color(0xFFEEEEEE);
  static const Color lightSurfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color lightSurfaceContainerHighest = Color(0xFFE0E0E0);
}
