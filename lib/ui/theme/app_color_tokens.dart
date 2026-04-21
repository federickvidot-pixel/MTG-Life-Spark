import 'package:flutter/material.dart';

/// Theme-aware color tokens. Use [AppColorTokens.of] to resolve for current theme.
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

  static AppColorTokens of(BuildContext context) {
    return Theme.of(context).extension<AppColorTokens>()!;
  }

  static const AppColorTokens dark = AppColorTokens(
    backgroundPrimary: Color(0xFF080C18),
    backgroundSecondary: Color(0xFF10192E),
    surface: Color(0xFF162038),
    surfaceElevated: Color(0xFF1E2A48),
    borderSubtle: Color(0xFF3D4F78),
    textPrimary: Color(0xFFF1F4FF),
    textSecondary: Color(0xFFA8B8D8),
    textMuted: Color(0xFF6B7FA3),
    primaryAccent: Color(0xFF8B9CFF),
  );

  static const AppColorTokens light = AppColorTokens(
    backgroundPrimary: Color(0xFFF5F7FF),
    backgroundSecondary: Color(0xFFE8ECFA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF0F2FC),
    borderSubtle: Color(0xFFD4DBF0),
    textPrimary: Color(0xFF0D1224),
    textSecondary: Color(0xFF3D4A6B),
    textMuted: Color(0xFF6B7280),
    primaryAccent: Color(0xFF6366F1),
  );

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
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary: Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
    );
  }
}
