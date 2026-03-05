import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';

/// Cast Commander button; can be used inline or in the top-right corner.
class CastCommanderButton extends StatelessWidget {
  final PlayerGameState player;
  final VoidCallback onCastCommander;

  const CastCommanderButton({
    super.key,
    required this.player,
    required this.onCastCommander,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: player.isEliminated ? null : onCastCommander,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: player.isEliminated
                ? AppTheme.textSecondary.withValues(alpha: 0.3)
                : AppTheme.accent.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              size: 16,
              color: player.isEliminated
                  ? AppTheme.textSecondary
                  : AppTheme.accent,
            ),
            Text(
              'Cast',
              style: TextStyle(
                fontSize: 9,
                color: player.isEliminated
                    ? AppTheme.textSecondary
                    : AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top bar of the personal view: commander avatar, name, tax badge, and
/// optionally a "Cast Commander" button (can be placed inline or separately).
class CommanderInfoBar extends StatelessWidget {
  final PlayerGameState player;
  final VoidCallback onCastCommander;
  /// When false, the cast button is not shown (use CastCommanderButton separately).
  final bool includeCastButton;
  /// Optional round number to show under tax (extra info).
  final int? roundNumber;

  const CommanderInfoBar({
    super.key,
    required this.player,
    required this.onCastCommander,
    this.includeCastButton = true,
    this.roundNumber,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isCompact = w < 360;
    final isVeryNarrow = w < 320;
    final avatarSize = isVeryNarrow ? 36.0 : (isCompact ? 40.0 : 48.0);
    final partnerSize = isVeryNarrow ? 28.0 : 38.0;
    final gap = isVeryNarrow ? 4.0 : (isCompact ? 6.0 : 14.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVeryNarrow ? 8 : (isCompact ? 12 : 16),
        vertical: isVeryNarrow ? 6 : (isCompact ? 10 : 14),
      ),
      child: Row(
        children: [
          // Commander avatar (primary)
          _CommanderAvatar(
            imageUrl: player.commanderImageUrl,
            name: player.commanderName,
            playerColor: player.playerColor,
            size: avatarSize,
          ),

          // Partner avatar (if applicable)
          if (player.hasPartner && player.partnerCommanderName != null) ...[
            SizedBox(width: gap),
            _CommanderAvatar(
              imageUrl: player.partnerCommanderImageUrl,
              name: player.partnerCommanderName,
              playerColor: player.playerColor,
              size: partnerSize,
            ),
          ],

          SizedBox(width: gap),

          // Name + tax info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.commanderName ?? 'No Commander',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isVeryNarrow ? 12 : 14,
                  ),
                ),
                if (player.hasPartner && player.partnerCommanderName != null)
                  Text(
                    '+ ${player.partnerCommanderName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                const SizedBox(height: 4),
                _CommanderTaxBadge(
                  castCount: player.commanderCastCount,
                  tax: player.commanderTax,
                ),
                if (roundNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Round $roundNumber',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (includeCastButton)
            CastCommanderButton(
              player: player,
              onCastCommander: onCastCommander,
            ),

          // Alliance indicator
          if (player.allyPlayerId != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Allied with ${player.allyPlayerId}',
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.6)),
                ),
                child: const Icon(Icons.handshake,
                    size: 16, color: AppTheme.accentGold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommanderAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final Color playerColor;
  final double size;

  const _CommanderAvatar({
    required this.imageUrl,
    required this.name,
    required this.playerColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: playerColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: playerColor.withValues(alpha: 0.5)),
        ),
        child: Icon(Icons.style, color: playerColor, size: size * 0.5),
      );
}

class _CommanderTaxBadge extends StatelessWidget {
  final int castCount;
  final int tax;

  const _CommanderTaxBadge({required this.castCount, required this.tax});

  @override
  Widget build(BuildContext context) {
    if (castCount == 0) {
      return const Text(
        'No tax yet',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.6)),
          ),
          child: Text(
            'Tax +$tax',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(cast $castCount×)',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
