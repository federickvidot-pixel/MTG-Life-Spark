import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';

/// Shared control chrome for [GameScreen] and related HUD widgets.
abstract final class GameUiTokens {
  /// Host **Back** / **Next** phase controls: outline, readable label, 44dp min.
  static ButtonStyle hostPhaseNavButton(Color accent) =>
      OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr3,
          vertical: LayoutTokens.gr1,
        ),
        minimumSize: const Size(0, LayoutTokens.minTapTarget),
        foregroundColor: AppTheme.textPrimary,
        side: BorderSide(color: accent.withValues(alpha: 0.75)),
      );
}
