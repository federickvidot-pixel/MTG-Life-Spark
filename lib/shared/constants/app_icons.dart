/// Central reference for game-related icon assets.
/// Icons are stored in assets/icons/ (SVG format).
class AppIcons {
  AppIcons._();

  // ── Game counters ────────────────────────────────────────────────────────
  /// Poison counter (replaces ☠ emoji)
  static const String poison = 'assets/icons/Poison.svg';
  /// Energy counter (replaces ⚡ emoji)
  static const String energy = 'assets/icons/Energy.svg';
  /// Radiation counter (replaces ☢ emoji)
  static const String radiation = 'assets/icons/Radiation.svg';
  /// Experience counter (replaces ★ emoji)
  static const String experience = 'assets/icons/Experience.svg';

  // ── Variant modes ────────────────────────────────────────────────────────
  /// Bounty variant mode
  static const String bounty = 'assets/icons/Bounty.svg';

  // ── Mana symbols (WUBRG) ────────────────────────────────────────────────
  static const String manaW = 'assets/icons/W.svg';
  static const String manaU = 'assets/icons/U.svg';
  static const String manaB = 'assets/icons/B.svg';
  static const String manaR = 'assets/icons/R.svg';
  static const String manaG = 'assets/icons/G.svg';

  /// Returns mana icon path for a single character (W, U, B, R, G).
  static String? manaFor(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'W':
        return manaW;
      case 'U':
        return manaU;
      case 'B':
        return manaB;
      case 'R':
        return manaR;
      case 'G':
        return manaG;
      default:
        return null;
    }
  }
}
