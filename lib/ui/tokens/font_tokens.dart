/// Consistent font sizes — **multiples of 4** for alignment with the 4dp layout grid.
/// Pair with [FontWeight] on [TextStyle] for hierarchy when two slots share a size.
///
/// HUD slots ([hudXs], [hudSm]) are 11/13 — intentionally off the 4dp grid to
/// match standard game-HUD readability convention in compact viewports.
class FontTokens {
  FontTokens._();

  /// Tiny emphasis (8)
  static const double xs = 8;

  /// Small / compact (12)
  static const double sm = 12;

  /// Captions, secondary (12)
  static const double caption = 12;

  /// Labels (12) — use [FontWeight.w700] vs body when both are 12.
  static const double label = 12;

  // ── HUD / game compact slots ──────────────────────────────────────────────

  /// Compact HUD micro-label (11). Smallest legible in-game text.
  static const double hudXs = 11;

  /// Compact HUD secondary label (13). Between caption and body.
  static const double hudSm = 13;

  // ── Body / UI ─────────────────────────────────────────────────────────────

  /// Body (16)
  static const double body = 16;

  /// Tile / section titles (16) — use weight/letterSpacing vs [body].
  static const double title = 16;

  /// Primary body / buttons (16)
  static const double bodyLg = 16;

  /// Screen titles (20)
  static const double headline = 20;

  // ── Hero display — game screens ───────────────────────────────────────────

  /// Commander name hero display (36).
  static const double displayCommander = 36;

  /// Life total hero display (56).
  static const double displayLife = 56;
}
