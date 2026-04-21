import 'package:flutter/material.dart';

/// Cool dark fantasy palette — bluish / violet-tinted surfaces (no warm paper).
class ColorTokens {
  ColorTokens._();

  // Background
  static const Color backgroundPrimary = Color(0xFF080C18);
  static const Color backgroundSecondary = Color(0xFF10192E);

  // Surface
  static const Color surface = Color(0xFF162038);
  static const Color surfaceElevated = Color(0xFF1E2A48);

  // Border
  static const Color borderSubtle = Color(0xFF3D4F78);

  // Text (cool grays, not warm)
  static const Color textPrimary = Color(0xFFF1F4FF);
  static const Color textSecondary = Color(0xFFA8B8D8);
  static const Color textMuted = Color(0xFF6B7FA3);

  // Accent
  static const Color primaryAccent = Color(0xFF8B9CFF); // Periwinkle / arcane
  static const Color optionalAccent = Color(0xFF57F287); // Neon green
  /// Prestige / monarch / dice highlights — cool highlight (replaces warm gold).
  static const Color accentGold = Color(0xFFA5B4FC);

  // Semantic
  static const Color success = Color(0xFF57F287);
  static const Color danger = Color(0xFFED4245);
  static const Color dangerAmber = Color(0xFFF97316);
  static const Color warning = Color(0xFFFEE75C);

  // Player palette (for game)
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
}
