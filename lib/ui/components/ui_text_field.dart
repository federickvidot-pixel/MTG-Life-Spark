import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';

/// Rounded (16) gamer-dark fill, blurple focus ring.
class UiTextField extends StatelessWidget {
  const UiTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: ColorTokens.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: ColorTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.md,
        ),
        border: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: const BorderSide(
            color: ColorTokens.primaryAccent,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.radiusMd,
          borderSide: BorderSide(
            color: ColorTokens.borderSubtle.withValues(alpha: 0.5),
          ),
        ),
        labelStyle: const TextStyle(color: ColorTokens.textSecondary),
        hintStyle: const TextStyle(color: ColorTokens.textMuted),
      ),
    );
  }
}
