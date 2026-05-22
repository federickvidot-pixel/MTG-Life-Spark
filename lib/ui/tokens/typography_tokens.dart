import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_tokens.dart';
import 'font_tokens.dart';

/// Bold typography helpers. **Lato** — matches [AppTheme] / Material [TextTheme].
class TypographyTokens {
  TypographyTokens._();

  static TextStyle headline(BuildContext context) =>
      GoogleFonts.lato(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: ColorTokens.textPrimary,
      );

  static TextStyle title(BuildContext context) =>
      GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
      );

  /// Module headers — profile sections, lobby blocks, decks screen (20dp w800).
  static TextStyle sectionTitle(Color primary) => GoogleFonts.lato(
        fontSize: FontTokens.headline,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        height: 1.2,
        color: primary,
      );

  /// In-card titles — bento carousel tiles (16dp w800).
  static TextStyle cardTitle(Color primary) => GoogleFonts.lato(
        fontSize: FontTokens.title,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.15,
        height: 1.2,
        color: primary,
      );

  static TextStyle body(BuildContext context) =>
      GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textPrimary,
      );

  static TextStyle bodySecondary(BuildContext context) =>
      GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textSecondary,
      );

  static TextStyle label(BuildContext context) =>
      GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
      );

  static TextStyle caption(BuildContext context) =>
      GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textMuted,
      );

  static TextStyle button(BuildContext context) =>
      GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
      );
}
