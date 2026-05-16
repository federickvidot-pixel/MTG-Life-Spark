/// Layout and proportion constants.
///
/// **Spacing** uses a strict **4dp grid** (`gr0` … `gr6`) so padding, gaps, and
/// insets stay visually consistent. Use [SpacingTokens] for the same grid with
/// semantic names (`xs`, `sm`, …).
///
/// **Golden ratio** helpers remain for non-spacing proportions (e.g. aspect
/// ratios), not for padding or font sizes.
class LayoutTokens {
  LayoutTokens._();

  /// Golden ratio φ ≈ 1.618 (aspect ratios only — not the spacing scale).
  static const double goldenRatio = 1.618;

  /// Inverse golden ratio 1/φ ≈ 0.618.
  static const double goldenRatioInverse = 0.618;

  /// 4dp spacing scale: `4 × n` for n = 1 … 12 on the main rungs.
  static const double gr0 = 4;
  static const double gr1 = 8;
  static const double gr2 = 12;
  static const double gr3 = 16;
  static const double gr4 = 24;
  static const double gr5 = 32;
  static const double gr6 = 48;

  /// Minimum **44×44 dp** tap target (WCAG / Material); `11 × 4dp` on the grid.
  static const double minTapTarget = 44;
}

/// Width / height hints for **in-game** layouts (personal view, HUD rows).
abstract final class GameLayoutBreakpoints {
  static const double narrow = 320;
  static const double compact = 360;
  static const double comfortable = 400;
  static const double shortViewport = 720;
}
