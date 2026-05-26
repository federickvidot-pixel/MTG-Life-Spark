import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../tokens/color_tokens.dart';
import '../tokens/font_tokens.dart';
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
    final colors = AppColorTokens.of(context);
    final effectiveOnPressed = enabled && !loading ? onPressed : null;

    if (variant == UiButtonVariant.primary) {
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: effectiveOnPressed,
          icon: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorTokens.onAccent,
                  ),
                )
              : (icon ?? const SizedBox.shrink()),
          label: loading ? const SizedBox.shrink() : Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
          style: FilledButton.styleFrom(
            backgroundColor: colors.primaryAccent,
            foregroundColor: ColorTokens.onAccent,
            disabledBackgroundColor: colors.surface,
            disabledForegroundColor: colors.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: RadiusTokens.radiusLg,
            ),
            textStyle: TextStyle(
              fontSize: FontTokens.bodyLg,
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
          label: loading ? const SizedBox.shrink() : Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.borderSubtle),
            shape: RoundedRectangleBorder(
              borderRadius: RadiusTokens.radiusLg,
            ),
            textStyle: TextStyle(
              fontSize: FontTokens.bodyLg,
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
        label: loading ? const SizedBox.shrink() : Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        style: TextButton.styleFrom(
          foregroundColor: colors.textPrimary,
          textStyle: TextStyle(
            fontSize: FontTokens.bodyLg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
