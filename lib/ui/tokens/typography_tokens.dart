import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_tokens.dart';

/// Duolingo-like bold typography. Nunito for friendly gamer SaaS.
class TypographyTokens {
  TypographyTokens._();

  static TextStyle headline(BuildContext context) =>
      GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: ColorTokens.textPrimary,
      );

  static TextStyle title(BuildContext context) =>
      GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
      );

  static TextStyle body(BuildContext context) =>
      GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textPrimary,
      );

  static TextStyle bodySecondary(BuildContext context) =>
      GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textSecondary,
      );

  static TextStyle label(BuildContext context) =>
      GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
      );

  static TextStyle caption(BuildContext context) =>
      GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textMuted,
      );

  static TextStyle button(BuildContext context) =>
      GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
      );
}
