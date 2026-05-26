import 'package:flutter/material.dart';

/// User-selectable app color schemes (Settings → Appearance).
enum AppColorSchemeId {
  violet,
  crimson,
  slate,
  forest,
}

/// Full dark/light palette for one color scheme.
class AppColorPalette {
  const AppColorPalette({
    required this.id,
    required this.label,
    required this.description,
    required this.previewAccent,
    required this.previewBackground,
    required this.brandBlack,
    required this.brandAccent,
    required this.brandAccentSoft,
    required this.brandAccentMuted,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.emphasis,
    required this.darkPrimaryContainer,
    required this.darkOnPrimaryContainer,
    required this.darkSecondaryContainer,
    required this.darkInversePrimary,
    required this.darkSurfaceContainerLowest,
    required this.darkSurfaceContainerLow,
    required this.lightBackgroundPrimary,
    required this.lightBackgroundSecondary,
    required this.lightSurface,
    required this.lightSurfaceElevated,
    required this.lightBorderSubtle,
    required this.lightTextPrimary,
    required this.lightTextSecondary,
    required this.lightTextMuted,
    required this.lightPrimaryAccent,
    required this.lightPrimaryContainer,
    required this.lightOnPrimaryContainer,
    required this.lightSecondaryContainer,
    required this.lightOnSecondaryContainer,
    required this.lightInversePrimary,
    required this.lightSurfaceContainerLow,
    required this.lightSurfaceContainer,
    required this.lightSurfaceContainerHigh,
    required this.lightSurfaceContainerHighest,
  });

  final AppColorSchemeId id;
  final String label;
  final String description;
  final Color previewAccent;
  final Color previewBackground;

  final Color brandBlack;
  final Color brandAccent;
  final Color brandAccentSoft;
  final Color brandAccentMuted;

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color borderSubtle;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color emphasis;

  final Color darkPrimaryContainer;
  final Color darkOnPrimaryContainer;
  final Color darkSecondaryContainer;
  final Color darkInversePrimary;
  final Color darkSurfaceContainerLowest;
  final Color darkSurfaceContainerLow;

  final Color lightBackgroundPrimary;
  final Color lightBackgroundSecondary;
  final Color lightSurface;
  final Color lightSurfaceElevated;
  final Color lightBorderSubtle;
  final Color lightTextPrimary;
  final Color lightTextSecondary;
  final Color lightTextMuted;
  final Color lightPrimaryAccent;
  final Color lightPrimaryContainer;
  final Color lightOnPrimaryContainer;
  final Color lightSecondaryContainer;
  final Color lightOnSecondaryContainer;
  final Color lightInversePrimary;
  final Color lightSurfaceContainerLow;
  final Color lightSurfaceContainer;
  final Color lightSurfaceContainerHigh;
  final Color lightSurfaceContainerHighest;
}

abstract final class AppColorPalettes {
  static const List<AppColorPalette> all = [violet, crimson, slate, forest];

  static const AppColorPalette violet = AppColorPalette(
    id: AppColorSchemeId.violet,
    label: 'Violet',
    description: 'Deep charcoal with vibrant purple accents',
    previewAccent: Color(0xFF9B6DFF),
    previewBackground: Color(0xFF12121A),
    brandBlack: Color(0xFF12121A),
    brandAccent: Color(0xFF9B6DFF),
    brandAccentSoft: Color(0xFFC4A8FF),
    brandAccentMuted: Color(0xFF2D2D3A),
    backgroundPrimary: Color(0xFF12121A),
    backgroundSecondary: Color(0xFF161622),
    surface: Color(0xFF1E1E2A),
    surfaceElevated: Color(0xFF2D2D3A),
    borderSubtle: Color(0xFF3D3D4C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    emphasis: Color(0xFFC4A8FF),
    darkPrimaryContainer: Color(0xFF2A1F45),
    darkOnPrimaryContainer: Color(0xFFE9DEFF),
    darkSecondaryContainer: Color(0xFF2D2D3A),
    darkInversePrimary: Color(0xFF7C52E8),
    darkSurfaceContainerLowest: Color(0xFF0C0C12),
    darkSurfaceContainerLow: Color(0xFF14141C),
    lightBackgroundPrimary: Color(0xFFF4F4F8),
    lightBackgroundSecondary: Color(0xFFEBEBF2),
    lightSurface: Color(0xFFFFFFFF),
    lightSurfaceElevated: Color(0xFFF0F0F6),
    lightBorderSubtle: Color(0xFFD4D4E0),
    lightTextPrimary: Color(0xFF12121A),
    lightTextSecondary: Color(0xFF52525E),
    lightTextMuted: Color(0xFF737380),
    lightPrimaryAccent: Color(0xFF7C3AED),
    lightPrimaryContainer: Color(0xFFEDE9FE),
    lightOnPrimaryContainer: Color(0xFF2E1065),
    lightSecondaryContainer: Color(0xFFE5E5EE),
    lightOnSecondaryContainer: Color(0xFF1A1A24),
    lightInversePrimary: Color(0xFFC4A8FF),
    lightSurfaceContainerLow: Color(0xFFF4F4F8),
    lightSurfaceContainer: Color(0xFFEBEBF2),
    lightSurfaceContainerHigh: Color(0xFFE5E5EE),
    lightSurfaceContainerHighest: Color(0xFFDCDCE6),
  );

  static const AppColorPalette crimson = AppColorPalette(
    id: AppColorSchemeId.crimson,
    label: 'Crimson',
    description: 'Classic dark UI with bold red brand accents',
    previewAccent: Color(0xFFD41414),
    previewBackground: Color(0xFF0E0E0E),
    brandBlack: Color(0xFF0E0E0E),
    brandAccent: Color(0xFFD41414),
    brandAccentSoft: Color(0xFFF59E0B),
    brandAccentMuted: Color(0xFF2E2E2E),
    backgroundPrimary: Color(0xFF0E0E0E),
    backgroundSecondary: Color(0xFF121212),
    surface: Color(0xFF1A1A1A),
    surfaceElevated: Color(0xFF242424),
    borderSubtle: Color(0xFF2E2E2E),
    textPrimary: Color(0xFFEDEDED),
    textSecondary: Color(0xFFA3A3A3),
    textMuted: Color(0xFF6B6B6B),
    emphasis: Color(0xFFF59E0B),
    darkPrimaryContainer: Color(0xFF3A1515),
    darkOnPrimaryContainer: Color(0xFFFFD6D6),
    darkSecondaryContainer: Color(0xFF252525),
    darkInversePrimary: Color(0xFFFF8A80),
    darkSurfaceContainerLowest: Color(0xFF080808),
    darkSurfaceContainerLow: Color(0xFF101010),
    lightBackgroundPrimary: Color(0xFFF5F5F5),
    lightBackgroundSecondary: Color(0xFFEEEEEE),
    lightSurface: Color(0xFFFFFFFF),
    lightSurfaceElevated: Color(0xFFF0F0F0),
    lightBorderSubtle: Color(0xFFD4D4D4),
    lightTextPrimary: Color(0xFF0E0E0E),
    lightTextSecondary: Color(0xFF525252),
    lightTextMuted: Color(0xFF737373),
    lightPrimaryAccent: Color(0xFFD41414),
    lightPrimaryContainer: Color(0xFFFFDAD6),
    lightOnPrimaryContainer: Color(0xFF410008),
    lightSecondaryContainer: Color(0xFFE5E5E5),
    lightOnSecondaryContainer: Color(0xFF1A1A1A),
    lightInversePrimary: Color(0xFFFF5449),
    lightSurfaceContainerLow: Color(0xFFF5F5F5),
    lightSurfaceContainer: Color(0xFFEEEEEE),
    lightSurfaceContainerHigh: Color(0xFFE8E8E8),
    lightSurfaceContainerHighest: Color(0xFFE0E0E0),
  );

  static const AppColorPalette slate = AppColorPalette(
    id: AppColorSchemeId.slate,
    label: 'Slate',
    description: 'Cool neutral dark with soft blue highlights',
    previewAccent: Color(0xFF60A5FA),
    previewBackground: Color(0xFF0F1419),
    brandBlack: Color(0xFF0F1419),
    brandAccent: Color(0xFF60A5FA),
    brandAccentSoft: Color(0xFF93C5FD),
    brandAccentMuted: Color(0xFF2A3140),
    backgroundPrimary: Color(0xFF0F1419),
    backgroundSecondary: Color(0xFF151A21),
    surface: Color(0xFF1C222B),
    surfaceElevated: Color(0xFF2A3140),
    borderSubtle: Color(0xFF3A424E),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    emphasis: Color(0xFF93C5FD),
    darkPrimaryContainer: Color(0xFF1E3A5F),
    darkOnPrimaryContainer: Color(0xFFDBEAFE),
    darkSecondaryContainer: Color(0xFF2A3140),
    darkInversePrimary: Color(0xFF3B82F6),
    darkSurfaceContainerLowest: Color(0xFF0A0E12),
    darkSurfaceContainerLow: Color(0xFF121820),
    lightBackgroundPrimary: Color(0xFFF1F5F9),
    lightBackgroundSecondary: Color(0xFFE2E8F0),
    lightSurface: Color(0xFFFFFFFF),
    lightSurfaceElevated: Color(0xFFF8FAFC),
    lightBorderSubtle: Color(0xFFCBD5E1),
    lightTextPrimary: Color(0xFF0F172A),
    lightTextSecondary: Color(0xFF475569),
    lightTextMuted: Color(0xFF64748B),
    lightPrimaryAccent: Color(0xFF2563EB),
    lightPrimaryContainer: Color(0xFFDBEAFE),
    lightOnPrimaryContainer: Color(0xFF1E3A8A),
    lightSecondaryContainer: Color(0xFFE2E8F0),
    lightOnSecondaryContainer: Color(0xFF1E293B),
    lightInversePrimary: Color(0xFF93C5FD),
    lightSurfaceContainerLow: Color(0xFFF1F5F9),
    lightSurfaceContainer: Color(0xFFE2E8F0),
    lightSurfaceContainerHigh: Color(0xFFCBD5E1),
    lightSurfaceContainerHighest: Color(0xFF94A3B8),
  );

  static const AppColorPalette forest = AppColorPalette(
    id: AppColorSchemeId.forest,
    label: 'Forest',
    description: 'Deep forest dark with emerald green accents',
    previewAccent: Color(0xFF34D399),
    previewBackground: Color(0xFF0B1210),
    brandBlack: Color(0xFF0B1210),
    brandAccent: Color(0xFF34D399),
    brandAccentSoft: Color(0xFF6EE7B7),
    brandAccentMuted: Color(0xFF1E2B24),
    backgroundPrimary: Color(0xFF0B1210),
    backgroundSecondary: Color(0xFF101915),
    surface: Color(0xFF152019),
    surfaceElevated: Color(0xFF1E2B24),
    borderSubtle: Color(0xFF2A3D34),
    textPrimary: Color(0xFFF0FDF4),
    textSecondary: Color(0xFFA7BDB0),
    textMuted: Color(0xFF647A6E),
    emphasis: Color(0xFF6EE7B7),
    darkPrimaryContainer: Color(0xFF14352A),
    darkOnPrimaryContainer: Color(0xFFD1FAE5),
    darkSecondaryContainer: Color(0xFF1E2B24),
    darkInversePrimary: Color(0xFF10B981),
    darkSurfaceContainerLowest: Color(0xFF070C0A),
    darkSurfaceContainerLow: Color(0xFF0E1612),
    lightBackgroundPrimary: Color(0xFFF0FDF4),
    lightBackgroundSecondary: Color(0xFFDCFCE7),
    lightSurface: Color(0xFFFFFFFF),
    lightSurfaceElevated: Color(0xFFECFDF5),
    lightBorderSubtle: Color(0xFFBBF7D0),
    lightTextPrimary: Color(0xFF052E16),
    lightTextSecondary: Color(0xFF166534),
    lightTextMuted: Color(0xFF4B7C5E),
    lightPrimaryAccent: Color(0xFF059669),
    lightPrimaryContainer: Color(0xFFD1FAE5),
    lightOnPrimaryContainer: Color(0xFF064E3B),
    lightSecondaryContainer: Color(0xFFDCFCE7),
    lightOnSecondaryContainer: Color(0xFF14532D),
    lightInversePrimary: Color(0xFF6EE7B7),
    lightSurfaceContainerLow: Color(0xFFF0FDF4),
    lightSurfaceContainer: Color(0xFFDCFCE7),
    lightSurfaceContainerHigh: Color(0xFFBBF7D0),
    lightSurfaceContainerHighest: Color(0xFF86EFAC),
  );

  static AppColorPalette byId(AppColorSchemeId id) => switch (id) {
        AppColorSchemeId.violet => violet,
        AppColorSchemeId.crimson => crimson,
        AppColorSchemeId.slate => slate,
        AppColorSchemeId.forest => forest,
      };

  static AppColorSchemeId parse(String? raw) {
    return switch (raw) {
      'crimson' => AppColorSchemeId.crimson,
      'slate' => AppColorSchemeId.slate,
      'forest' => AppColorSchemeId.forest,
      _ => AppColorSchemeId.violet,
    };
  }

  static String storageKey(AppColorSchemeId id) => id.name;
}
