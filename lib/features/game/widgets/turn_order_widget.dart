import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../ui/tokens/color_tokens.dart';
import '../../../ui/tokens/motion_tokens.dart';
import '../../../ui/tokens/font_tokens.dart';

import '../../../core/game/game_phase.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';

/// Row of square player tiles in turn order: name, centered life, phase for active player.
class TurnOrderWidget extends StatelessWidget {
  final GameState game;

  const TurnOrderWidget({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    if (game.turnOrder.isEmpty) return const SizedBox.shrink();

    final playersInOrder = game.turnOrder
        .map((id) => game.playerById(id))
        .whereType<PlayerGameState>()
        .toList();

    if (playersInOrder.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr2,
        vertical: LayoutTokens.gr1,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final player in playersInOrder)
              _TurnOrderPlayerBox(
                player: player,
                isActive: player.playerId == game.activePlayerId,
                currentPhase: game.currentPhase,
                activeColor:
                    game.playerById(game.activePlayerId)?.playerColor ??
                    AppTheme.accent,
              ),
          ],
        ),
      ),
    );
  }
}

class _TurnOrderPlayerBox extends StatelessWidget {
  final PlayerGameState player;
  final bool isActive;
  final GamePhase currentPhase;
  final Color activeColor;

  const _TurnOrderPlayerBox({
    required this.player,
    required this.isActive,
    required this.currentPhase,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final compact = shortest < 360;
    // Slightly smaller squares on 4dp grid (overview / turn strip).
    final side = compact ? 92.0 : 100.0;
    final radius = LayoutTokens.gr2;

    return Padding(
      padding: const EdgeInsets.only(right: LayoutTokens.gr2),
      child: AnimatedContainer(
        duration: MotionTokens.standard,
        width: side,
        height: side,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color:
                isActive
                    ? activeColor
                    : AppTheme.textSecondary.withValues(alpha: 0.25),
            width: isActive ? 2 : 1,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.28),
                      blurRadius: LayoutTokens.gr2,
                      spreadRadius: 0,
                    ),
                  ]
                  : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildAvatar(player, side, side),
              Container(
                color: (isActive ? activeColor : Colors.black).withValues(
                  alpha: 0.48,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(LayoutTokens.gr1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: LayoutTokens.gr5,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          player.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColorTokens.onAccent,
                            fontSize: FontTokens.hudSm,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.85),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            player.isEliminated ? '—' : '${player.life}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              color: ColorTokens.onAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: LayoutTokens.gr6,
                      child: Center(
                        child: _buildStatusChip(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    if (player.isEliminated) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LayoutTokens.gr1,
            vertical: LayoutTokens.gr0,
          ),
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(LayoutTokens.gr0),
          ),
          child: const Text(
            'OUT',
            style: TextStyle(
              color: ColorTokens.onAccent,
              fontSize: FontTokens.hudXs,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    if (!isActive) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 96),
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr1,
          vertical: LayoutTokens.gr0,
        ),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(LayoutTokens.gr0),
        ),
        child: Text(
          currentPhase.streamlinedShortLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ColorTokens.onAccent,
            fontSize: FontTokens.hudXs,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(PlayerGameState player, double w, double h) {
    if (player.commanderImageUrl != null &&
        player.commanderImageUrl!.isNotEmpty) {
      return Opacity(
        opacity: 0.42,
        child: CachedNetworkImage(
          imageUrl: player.commanderImageUrl!,
          width: w,
          height: h,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _placeholder(player, w, h),
        ),
      );
    }
    return _placeholder(player, w, h);
  }

  Widget _placeholder(PlayerGameState player, double w, double h) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: player.playerColor.withValues(alpha: 0.28),
          border: Border.all(color: player.playerColor.withValues(alpha: 0.55)),
        ),
        child: Icon(Icons.style, color: player.playerColor, size: w * 0.44),
      );
}
