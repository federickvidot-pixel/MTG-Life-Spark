/// Layout and proportion constants.
/// Use golden-ratio spacing for harmonious, evenly distributed layouts.
class LayoutTokens {
  LayoutTokens._();

  /// Golden ratio φ ≈ 1.618.
  /// Use for harmonious proportions (e.g. width:height = φ:1 for golden rectangle).
  static const double goldenRatio = 1.618;

  /// Inverse golden ratio 1/φ ≈ 0.618.
  /// For portrait golden: aspectRatio = 1/goldenRatio gives height = width * φ.
  static const double goldenRatioInverse = 0.618;

  /// Golden-ratio spacing scale: base × φ^n for n = 0,1,2,3,4,5,6.
  /// Use for consistent, harmonious spacing across all screens.
  static const double gr0 = 4;   // base
  static const double gr1 = 6;   // base × φ
  static const double gr2 = 10;  // base × φ²
  static const double gr3 = 16;  // base × φ³
  static const double gr4 = 26;  // base × φ⁴
  static const double gr5 = 42; // base × φ⁵
  static const double gr6 = 68; // base × φ⁶
}
