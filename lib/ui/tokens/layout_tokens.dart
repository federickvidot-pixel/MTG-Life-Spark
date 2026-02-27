/// Layout and proportion constants.
class LayoutTokens {
  LayoutTokens._();

  /// Golden ratio φ ≈ 1.618.
  /// Use for harmonious proportions (e.g. width:height = φ:1 for golden rectangle).
  static const double goldenRatio = 1.618;

  /// Inverse golden ratio 1/φ ≈ 0.618.
  /// For portrait golden: aspectRatio = 1/goldenRatio gives height = width * φ.
  static const double goldenRatioInverse = 0.618;
}
