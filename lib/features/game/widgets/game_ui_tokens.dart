import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/color_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';

/// Shared control chrome for [GameScreen] and related HUD widgets.
abstract final class GameUiTokens {
  static ButtonStyle get sheetSecondaryButton => TextButton.styleFrom(
        minimumSize: const Size(0, LayoutTokens.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: LayoutTokens.gr3),
        foregroundColor: AppTheme.textSecondary,
      );

  static ButtonStyle sheetPrimaryButton(Color accent) => FilledButton.styleFrom(
        minimumSize: const Size(0, LayoutTokens.minTapTarget),
        backgroundColor: accent,
        foregroundColor: ColorTokens.onAccent,
      );

  static ButtonStyle get sheetCancelButton => OutlinedButton.styleFrom(
        minimumSize: const Size(0, LayoutTokens.minTapTarget),
        foregroundColor: AppTheme.textSecondary,
        side: BorderSide(
          color: AppTheme.textSecondary.withValues(alpha: 0.4),
        ),
      );

  static ButtonStyle destructiveFilledButton() => FilledButton.styleFrom(
        minimumSize: const Size(0, LayoutTokens.minTapTarget),
        backgroundColor: AppTheme.danger,
        foregroundColor: AppTheme.textPrimary,
      );
}
