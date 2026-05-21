import 'package:flutter/material.dart';

/// Very rounded corners — Duolingo-friendly.
///
/// Scale: sm(12) → md(16) → lg(20) → xl(24) → bento(28) → pill(999).
/// Extended slots [controlSm] and [chip] cover compact UI elements; [bento]
/// covers large profile/stats cards which use the nested-radius pattern.
class RadiusTokens {
  RadiusTokens._();

  // ── Standard UI scale ─────────────────────────────────────────────────────
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  // ── Compact UI / controls ─────────────────────────────────────────────────

  /// Small control corner (6). QR frame, code chips, compact badges.
  static const double controlXs = 6;

  /// Small control corner (10). Pill-adjacent buttons, HUD chips.
  static const double controlSm = 10;

  /// Card / deck chip (14). Lobby slot cards, end-game tiles.
  static const double chip = 14;

  // ── Hero cards ────────────────────────────────────────────────────────────

  /// Bento card (28). Profile stats, deck-performance carousel cards.
  static const double bento = 28;

  // ── BorderRadius constants ────────────────────────────────────────────────
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(controlXs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusBento = BorderRadius.all(Radius.circular(bento));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius radiusControlSm = BorderRadius.all(Radius.circular(controlSm));
  static const BorderRadius radiusChip = BorderRadius.all(Radius.circular(chip));
}
