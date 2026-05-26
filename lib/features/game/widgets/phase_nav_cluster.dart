import 'package:flutter/material.dart';

import '../../../core/game/game_phase.dart';
import '../../../core/game/game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import 'phase_picker_sheet.dart';

/// Unified Back · Phase · Next bar for the Play tab.
class PhaseNavCluster extends StatelessWidget {
  const PhaseNavCluster({
    super.key,
    required this.game,
    required this.accentColor,
    this.onBack,
    this.onNext,
    this.onPickPhase,
  });

  final GameState game;
  final Color accentColor;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final void Function(GamePhase phase)? onPickPhase;

  @override
  Widget build(BuildContext context) {
    final borderColor = accentColor.withValues(alpha: 0.45);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.94),
        borderRadius: RadiusTokens.radiusControlSm,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: RadiusTokens.radiusControlSm,
        child: PhaseNavClusterStrip(
          game: game,
          accentColor: accentColor,
          onBack: onBack,
          onNext: onNext,
          onPickPhase: onPickPhase,
        ),
      ),
    );
  }
}

class PhaseNavClusterStrip extends StatelessWidget {
  const PhaseNavClusterStrip({
    super.key,
    required this.game,
    required this.accentColor,
    this.onBack,
    this.onNext,
    this.onPickPhase,
  });

  final GameState game;
  final Color accentColor;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final void Function(GamePhase phase)? onPickPhase;

  static const double _sideMinWidth = 88;

  @override
  Widget build(BuildContext context) {
    final dividerColor = AppTheme.textSecondary.withValues(alpha: 0.14);

    return SizedBox(
      height: LayoutTokens.minTapTarget,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onBack != null) ...[
            SizedBox(
              width: _sideMinWidth,
              child: _PhaseNavSideButton(
                label: 'Back',
                icon: Icons.chevron_left_rounded,
                iconFirst: true,
                enabled: !game.timeoutActive,
                onPressed: onBack,
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: dividerColor),
          ],
          Expanded(
            child: _PhaseNavCenter(
              game: game,
              accentColor: accentColor,
              onPickPhase: onPickPhase,
            ),
          ),
          if (onNext != null) ...[
            VerticalDivider(width: 1, thickness: 1, color: dividerColor),
            SizedBox(
              width: _sideMinWidth,
              child: _PhaseNavSideButton(
                label: 'Next',
                icon: Icons.chevron_right_rounded,
                iconFirst: false,
                enabled: !game.timeoutActive,
                onPressed: onNext,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhaseNavSideButton extends StatelessWidget {
  const _PhaseNavSideButton({
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.enabled,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool iconFirst;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fg =
        enabled
            ? AppTheme.textPrimary
            : AppTheme.textSecondary.withValues(alpha: 0.45);
    final iconWidget = Icon(icon, size: 20, color: fg);
    final labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: FontTokens.hudSm,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: fg,
        height: 1.1,
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  iconFirst
                      ? [iconWidget, SizedBox(width: LayoutTokens.gr0), labelWidget]
                      : [labelWidget, SizedBox(width: LayoutTokens.gr0), iconWidget],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseNavCenter extends StatelessWidget {
  const _PhaseNavCenter({
    required this.game,
    required this.accentColor,
    this.onPickPhase,
  });

  final GameState game;
  final Color accentColor;
  final void Function(GamePhase phase)? onPickPhase;

  bool get _canPick => onPickPhase != null;

  @override
  Widget build(BuildContext context) {
    final phaseColor =
        game.isLocalPlayersTurn ? AppTheme.accent : AppTheme.textSecondary;

    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            game.currentPhase.displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: FontTokens.title,
              letterSpacing: 0.2,
              color: phaseColor,
            ),
          ),
          if (_canPick) ...[
            const SizedBox(width: LayoutTokens.gr0),
            Icon(
              Icons.unfold_more_rounded,
              size: 18,
              color: phaseColor.withValues(alpha: OpacityTokens.nearOpaque),
            ),
          ],
        ],
      ),
    );

    if (!_canPick) {
      return Semantics(
        header: true,
        label: 'Current phase, ${game.currentPhase.displayName}',
        child: Center(child: label),
      );
    }

    return Semantics(
      button: true,
      label: 'Choose phase, ${game.currentPhase.displayName}',
      child: Material(
        color: AppTheme.primary.withValues(alpha: 0.08),
        child: InkWell(
          onTap:
              () => showPhasePickerSheet(
                context,
                currentPhase: game.currentPhase,
                accentColor: accentColor,
                onSelected: onPickPhase!,
              ),
          child: Center(
            child: Tooltip(message: 'Choose phase', child: label),
          ),
        ),
      ),
    );
  }
}
