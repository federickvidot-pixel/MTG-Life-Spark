import 'package:flutter/material.dart';

/// Animation durations and curves.
///
/// Standard durations follow Material motion guidance (100–300 ms for micro
/// interactions, 500 ms+ for emphasis / celebrations).
class MotionTokens {
  MotionTokens._();

  // ── Durations ─────────────────────────────────────────────────────────────

  /// Hover / ink ripple response (150 ms).
  static const Duration fast = Duration(milliseconds: 150);

  /// Default element transition (200 ms).
  static const Duration standard = Duration(milliseconds: 200);

  /// Container / page transition (300 ms).
  static const Duration slow = Duration(milliseconds: 300);

  /// Celebration / hero animation (500 ms).
  static const Duration hero = Duration(milliseconds: 500);

  /// XP / progress bar emphasis (1100 ms).
  static const Duration emphasis = Duration(milliseconds: 1100);

  // ── Curves ────────────────────────────────────────────────────────────────

  /// Standard ease-out — most UI transitions.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Enter emphasis — elements sliding/scaling in.
  static const Curve enter = Curves.easeOut;

  /// Exit — elements fading/scaling out.
  static const Curve exit = Curves.easeIn;
}
