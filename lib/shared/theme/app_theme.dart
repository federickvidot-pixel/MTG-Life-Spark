import 'package:flutter/material.dart';

import '../../ui/theme/app_theme.dart' as ui_theme;
import '../../ui/tokens/color_tokens.dart';

/// Re-exports theme from ui layer.
/// Legacy color constants for game code — prefer [AppColorTokens.of] in new UI.
abstract class AppTheme {
  static ThemeData dark() => ui_theme.AppTheme.dark();
  static ThemeData light() => ui_theme.AppTheme.light();

  static Color get primary => ColorTokens.backgroundPrimary;
  static Color get surface => ColorTokens.backgroundSecondary;
  static Color get card => ColorTokens.surface;
  static Color get accent => ColorTokens.primaryAccent;
  static Color get accentGold => ColorTokens.emphasis;
  static Color get textPrimary => ColorTokens.textPrimary;
  static Color get textSecondary => ColorTokens.textSecondary;
  static Color get danger => ColorTokens.danger;
  static Color get dangerAmber => ColorTokens.warning;
  static Color get success => ColorTokens.success;
  static List<Color> get playerPalette => ColorTokens.playerPalette;

  static Color playerColor(int index) => ColorTokens.playerColor(index);
}
