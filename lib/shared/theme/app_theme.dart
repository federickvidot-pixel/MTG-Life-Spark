import 'package:flutter/material.dart';

import '../../ui/theme/app_theme.dart' as ui_theme;
import '../../ui/tokens/color_tokens.dart';

/// Re-exports theme from ui layer.
/// Legacy color constants for game code compatibility.
abstract class AppTheme {
  static ThemeData dark() => ui_theme.AppTheme.dark();
  static ThemeData light() => ui_theme.AppTheme.light();

  // Legacy compatibility (game screens, widgets)
  static const Color primary = ColorTokens.backgroundPrimary;
  static const Color surface = ColorTokens.backgroundSecondary;
  static const Color card = ColorTokens.surface;
  static const Color accent = ColorTokens.primaryAccent;
  static const Color accentGold = ColorTokens.accentGold;
  static const Color textPrimary = ColorTokens.textPrimary;
  static const Color textSecondary = ColorTokens.textSecondary;
  static const Color danger = ColorTokens.danger;
  static const Color dangerAmber = ColorTokens.dangerAmber;
  static const Color success = ColorTokens.success;
  static const List<Color> playerPalette = ColorTokens.playerPalette;

  static Color playerColor(int index) => ColorTokens.playerColor(index);
}
