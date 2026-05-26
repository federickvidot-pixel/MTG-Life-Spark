import 'package:flutter/material.dart';

import '../tokens/app_color_palettes.dart';
import '../tokens/color_tokens.dart';

/// Theme-aware color tokens. Use [AppColorTokens.of] in widgets instead of raw hex.
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primaryAccent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.emphasis,
  });

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primaryAccent;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color error;
  final Color emphasis;

  static AppColorTokens of(BuildContext context) {
    return Theme.of(context).extension<AppColorTokens>()!;
  }

  static AppColorTokens fromPalette(AppColorPalette palette) {
    return AppColorTokens(
      backgroundPrimary: palette.backgroundPrimary,
      backgroundSecondary: palette.backgroundSecondary,
      surface: palette.surface,
      surfaceElevated: palette.surfaceElevated,
      borderSubtle: palette.borderSubtle,
      textPrimary: palette.textPrimary,
      textSecondary: palette.textSecondary,
      textMuted: palette.textMuted,
      primaryAccent: palette.brandAccent,
      onAccent: ColorTokens.onAccent,
      success: ColorTokens.success,
      warning: ColorTokens.warning,
      error: ColorTokens.danger,
      emphasis: palette.emphasis,
    );
  }

  @override
  AppColorTokens copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? surface,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primaryAccent,
    Color? onAccent,
    Color? success,
    Color? warning,
    Color? error,
    Color? emphasis,
  }) {
    return AppColorTokens(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      emphasis: emphasis ?? this.emphasis,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      backgroundPrimary:
          Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary:
          Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      emphasis: Color.lerp(emphasis, other.emphasis, t)!,
    );
  }
}
