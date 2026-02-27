import 'package:flutter/material.dart';
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
        !game.priorityHeld &&
        !game.timeoutActive;

    final activeColor = active?.playerColor ?? AppTheme.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Round ${game.roundNumber}  •  ${game.currentPhase.displayName}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Priority hold/release
          if (isMyTurn && !game.timeoutActive) ...[
            _ControlBtn(
              label: game.priorityHeld ? 'Release' : 'Hold',
              icon: game.priorityHeld ? Icons.lock_open : Icons.lock,
              color: game.priorityHeld ? AppTheme.accentGold : AppTheme.textSecondary,
              onTap: () {
                if (game.priorityHeld) {
                    notifier.releasePriority(game.localPlayerId);
                  } else {
                  notifier.holdPriority(game.localPlayerId);
                }
              },
            ),
            const SizedBox(width: 8),
          ] else if (game.priorityHeld && !isMyTurn) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 12, color: AppTheme.accentGold),
                  const SizedBox(width: 4),
                  Text(
                    'Priority held',
                    style: const TextStyle(
                        color: AppTheme.accentGold, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

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
    final c = enabled ? color : color.withValues(alpha: 0.3);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
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
  }
}
