import 'package:flutter/material.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_phase.dart';
import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../shared/theme/app_theme.dart';

class TurnControlsWidget extends ConsumerWidget {
  final GameState game;

  const TurnControlsWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final active = game.playerById(game.activePlayerId);
    final isMyTurn = game.isLocalPlayersTurn;
    final canEndTurn = game.isHost &&
        isMyTurn &&
        !game.timeoutActive;

    final activeColor = active?.playerColor ?? AppTheme.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: AppTheme.card,
      child: Row(
        children: [
          // Active player indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMyTurn ? 'Your Turn' : "${active?.username ?? '?'}'s Turn",
                  style: TextStyle(
                    color: isMyTurn ? activeColor : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: FontTokens.hudSm,
                  ),
                ),
                Text(
                  'Round ${game.roundNumber}  •  ${game.currentPhase.streamlinedDisplayName}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // End Turn
          _ControlBtn(
            label: 'End Turn',
            icon: Icons.skip_next,
            color: AppTheme.accent,
            enabled: canEndTurn,
            onTap: () => notifier.endTurn(),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ControlBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : color.withValues(alpha: OpacityTokens.moderate);
    final child = GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: OpacityTokens.subtle),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: c, fontSize: 11)),
          ],
        ),
      ),
    );
    return IgnorePointer(
      ignoring: !enabled,
      child: child,
    );
  }
}
