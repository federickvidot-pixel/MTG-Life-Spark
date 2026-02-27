import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/radius_tokens.dart';

enum UiButtonVariant { primary, secondary, ghost }

/// Rounded (18) bold button. Variants: primary (blurple), secondary, ghost.
class UiButton extends StatelessWidget {
  const UiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = UiButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final UiButtonVariant variant;
  final Widget? icon;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = enabled && !loading ? onPressed : null;

    if (variant == UiButtonVariant.primary) {
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: effectiveOnPressed,
          icon: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : (icon ?? const SizedBox.shrink()),
          label: loading ? const SizedBox.shrink() : Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorTokens.primaryAccent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: ColorTokens.surface,
            disabledForegroundColor: ColorTokens.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: RadiusTokens.radiusLg,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (variant == UiButtonVariant.secondary) {
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: effectiveOnPressed,
          icon: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (icon ?? const SizedBox.shrink()),
          label: loading ? const SizedBox.shrink() : Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorTokens.textPrimary,
            side: const BorderSide(color: ColorTokens.borderSubtle),
            shape: RoundedRectangleBorder(
              borderRadius: RadiusTokens.radiusLg,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    // Ghost
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: TextButton.icon(
        onPressed: effectiveOnPressed,
        icon: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (icon ?? const SizedBox.shrink()),
        label: loading ? const SizedBox.shrink() : Text(label),
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.textPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
