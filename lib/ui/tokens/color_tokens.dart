import 'package:flutter/material.dart';

/// Discord-inspired dark gamer color palette.
/// Duolingo-bold + Discord-gamer theme.
class ColorTokens {
  ColorTokens._();

  // Background
  static const Color backgroundPrimary = Color(0xFF0F1117);
  static const Color backgroundSecondary = Color(0xFF161A23);

  // Surface
  static const Color surface = Color(0xFF1E232D);
  static const Color surfaceElevated = Color(0xFF262B36);

  // Border
  static const Color borderSubtle = Color(0xFF2E3442);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB5BAC1);
  static const Color textMuted = Color(0xFF7C818C);

  // Accent
  static const Color primaryAccent = Color(0xFF5865F2); // Discord blurple
  static const Color optionalAccent = Color(0xFF57F287); // Neon green
  static const Color accentGold = Color(0xFFFBBF24); // Warm gold (Monarch, tiers)

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
