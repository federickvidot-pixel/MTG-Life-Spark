import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/game/game_phase.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';

/// Row of player boxes with commander images in turn order.
/// Active player is highlighted and shows the current phase.
/// Round counter is displayed alongside.
class TurnOrderWidget extends StatelessWidget {
  final GameState game;

  const TurnOrderWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.turnOrder.isEmpty) return const SizedBox.shrink();

    final playersInOrder = game.turnOrder
        .map((id) => game.playerById(id))
        .whereType<PlayerGameState>()
        .toList();

    if (playersInOrder.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: Colors.transparent,
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
                isLocalPlayer: player.playerId == game.localPlayerId,
                activeColor: game.playerById(game.activePlayerId)
                        ?.playerColor ??
                    AppTheme.accent,
              ),
          ],
        ),
      ),
    );
  }
}

class _TurnOrderPlayerBox extends StatefulWidget {
  final PlayerGameState player;
  final bool isActive;
  final GamePhase currentPhase;
  final bool isLocalPlayer;
  final Color activeColor;

  const _TurnOrderPlayerBox({
    required this.player,
    required this.isActive,
    required this.currentPhase,
    required this.isLocalPlayer,
    required this.activeColor,
  });

  @override
  State<_TurnOrderPlayerBox> createState() => _TurnOrderPlayerBoxState();
}

class _TurnOrderPlayerBoxState extends State<_TurnOrderPlayerBox> {
  bool _showLife = false;
  bool _lifeOverlayMounted = false;
  Timer? _lifeHideTimer;

  @override
  void dispose() {
    _lifeHideTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    _lifeHideTimer?.cancel();
    setState(() {
      _showLife = true;
      _lifeOverlayMounted = true;
    });
    _lifeHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showLife = false);
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) setState(() => _lifeOverlayMounted = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w < 360 ? 72.0 : 88.0; // Smaller on narrow screens
    final player = widget.player;
    final isActive = widget.isActive;
    final activeColor = widget.activeColor;
    final currentPhase = widget.currentPhase;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeColor : AppTheme.textSecondary.withValues(alpha: 0.2),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Commander image (dimmed background)
                _buildAvatar(widget.player, size),
                // Dark overlay for text readability
                Container(
                  color: (isActive ? activeColor : Colors.black).withValues(alpha: 0.5),
                ),
                // Name at top, status centered at bottom
                Padding(
                  padding: EdgeInsets.all(size < 80 ? 6 : 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name at top
                      Text(
                        player.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size < 80 ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      // Status centered at bottom
                      Center(
                        child: _buildStatus(player, isActive, currentPhase, activeColor),
                      ),
                    ],
                  ),
                ),
                // Life overlay (center, fades in on tap, fades out after 3 sec)
                if (_lifeOverlayMounted)
                  IgnorePointer(
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _showLife ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${player.life}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('❤', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(PlayerGameState player, bool isActive, GamePhase currentPhase, Color activeColor) {
    if (player.isEliminated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.textSecondary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'OUT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          currentPhase.shortName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAvatar(PlayerGameState player, double size) {
    if (player.commanderImageUrl != null && player.commanderImageUrl!.isNotEmpty) {
      return Opacity(
        opacity: 0.4,
        child: CachedNetworkImage(
          imageUrl: player.commanderImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(player, size),
        ),
      );
    }
    return _placeholder(player, size);
  }

  Widget _placeholder(PlayerGameState player, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: player.playerColor.withValues(alpha: 0.25),
          border: Border.all(color: player.playerColor.withValues(alpha: 0.5)),
        ),
        child: Icon(Icons.style, color: player.playerColor, size: size * 0.5),
      );
}
