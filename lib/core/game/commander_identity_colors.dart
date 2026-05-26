import 'package:flutter/material.dart';

import '../../ui/tokens/color_tokens.dart';

/// Maps Scryfall `color_identity` letters (W,U,B,R,G) to splash colors for gameplay chrome.
abstract final class CommanderIdentityColors {
  static const Map<String, Color> mana = {
    'W': Color(0xFFF8F6D8),
    'U': Color(0xFF0E68AB),
    'B': Color(0xFF494949),
    'R': Color(0xFFD32029),
    'G': Color(0xFF00733E),
  };

  /// Gradient stops for scaffold / life counter chrome — violet shell only.
  static List<Color> gameplayGradient([
    List<String> identity = const [],
  ]) {
    final base = ColorTokens.backgroundPrimary;
    final mid = ColorTokens.backgroundSecondary;
    final end = ColorTokens.surface;
    final brand = ColorTokens.brandAccent;
    final soft = ColorTokens.brandAccentSoft;

    return [
      base,
      Color.lerp(base, soft, 0.08)!,
      Color.lerp(mid, brand, 0.10)!,
      Color.lerp(end, brand, 0.06)!.withValues(alpha: 0.95),
    ];
  }

  /// Accent for phase nav, tabs, and HUD chrome — brand purple, not seat color.
  static Color gameChromeAccent([List<String> identity = const []]) {
    if (identity.isEmpty) return ColorTokens.brandAccent;
    final tint = _identityTint(identity, ColorTokens.brandAccent);
    return Color.lerp(ColorTokens.brandAccent, tint, 0.12)!;
  }

  static Color emphasisBorder([List<String> identity = const []]) {
    return Color.lerp(
      ColorTokens.brandAccentSoft,
      gameChromeAccent(identity),
      0.35,
    )!;
  }

  /// Blended WUBRG tint for a commander (falls back to app accent when unknown).
  static Color identityTint(List<String> identity) {
    return _identityTint(identity, ColorTokens.brandAccent);
  }

  static Color _identityTint(List<String> identity, Color fallback) {
    if (identity.isEmpty) return ColorTokens.brandAccent;
    if (identity.length == 1) {
      return mana[identity.first] ?? fallback;
    }
    final first = mana[identity.first] ?? fallback;
    final second = mana[identity[1]] ?? fallback;
    return Color.lerp(first, second, 0.5)!;
  }
}
