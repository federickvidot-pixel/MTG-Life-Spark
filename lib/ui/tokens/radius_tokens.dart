import 'package:flutter/material.dart';

/// Very rounded corners — Duolingo-friendly.
class RadiusTokens {
  RadiusTokens._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));
}
