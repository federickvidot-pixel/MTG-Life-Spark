import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../ui/tokens/color_tokens.dart';

import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';

/// Top bar of the personal view: commander avatar (tap to cast), tax, round.
class CommanderInfoBar extends StatelessWidget {
  final PlayerGameState player;
  final VoidCallback onCastCommander;
  /// When true, use tighter padding for embedding inside a parent card.
  final bool embeddedInCard;
  /// Optional round number to show under tax (extra info).
  final int? roundNumber;
  /// Optional trailing control (e.g. commander damage status).
  final Widget? statusTrailing;
  /// Resolved ally display name when [player.allyPlayerId] is set.
  final String? allyUsername;

  const CommanderInfoBar({
    super.key,
    required this.player,
    required this.onCastCommander,
    this.embeddedInCard = false,
    this.roundNumber,
    this.statusTrailing,
    this.allyUsername,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isCompact = w < GameLayoutBreakpoints.compact;
    final isVeryNarrow = w < GameLayoutBreakpoints.narrow;
    final avatarSize = isVeryNarrow ? 36.0 : (isCompact ? 40.0 : LayoutTokens.gr6);
    final partnerSize = isVeryNarrow ? 28.0 : 40.0;
    final gap = isVeryNarrow
        ? LayoutTokens.gr0
        : (isCompact ? LayoutTokens.gr1 : LayoutTokens.gr3);

    return Container(
      padding:
          embeddedInCard
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(
                horizontal:
                    isVeryNarrow ? LayoutTokens.gr1 : (isCompact ? LayoutTokens.gr2 : LayoutTokens.gr3),
                vertical:
                    isVeryNarrow ? LayoutTokens.gr1 : (isCompact ? LayoutTokens.gr2 : LayoutTokens.gr3),
              ),
      child: Row(
        children: [
          _CastableCommanderAvatar(
            imageUrl: player.commanderImageUrl,
            name: player.commanderName,
            playerColor: player.playerColor,
            size: avatarSize,
            enabled: !player.isEliminated,
            onCast: onCastCommander,
          ),

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
                    fontSize: isVeryNarrow
                        ? LayoutTokens.gr2
                        : (isCompact ? 14.0 : LayoutTokens.gr3),
                  ),
                ),
                if (player.hasPartner && player.partnerCommanderName != null)
                  Text(
                    '+ ${player.partnerCommanderName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: LayoutTokens.gr2,
                    ),
                  ),
                SizedBox(height: isVeryNarrow ? 3 : 4),
                _CommanderTaxBadge(
                  castCount: player.commanderCastCount,
                  tax: player.commanderTax,
                  compact: isVeryNarrow || isCompact,
                ),
                if (roundNumber != null) ...[
                  SizedBox(height: LayoutTokens.gr0),
                  Text(
                    'Round $roundNumber',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: LayoutTokens.gr2,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (statusTrailing != null) ...[
            SizedBox(width: isVeryNarrow ? LayoutTokens.gr0 : LayoutTokens.gr1),
            statusTrailing!,
          ],

          if (player.allyPlayerId != null) ...[
            const SizedBox(width: LayoutTokens.gr1),
            Tooltip(
              message:
                  'Allied with ${allyUsername ?? player.allyPlayerId}',
              child: Container(
                padding: const EdgeInsets.all(LayoutTokens.gr1),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.12),
                  borderRadius: RadiusTokens.radiusControlMd,
                  border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.6)),
                ),
                child: Icon(Icons.handshake,
                    size: LayoutTokens.gr3, color: AppTheme.accentGold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Primary commander art: tap to cast (replaces separate Cast control).
class _CastableCommanderAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final Color playerColor;
  final double size;
  final bool enabled;
  final VoidCallback onCast;

  const _CastableCommanderAvatar({
    required this.imageUrl,
    required this.name,
    required this.playerColor,
    required this.size,
    required this.enabled,
    required this.onCast,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? 'Cast commander' : 'Eliminated',
      child: Tooltip(
        message: enabled ? 'Cast commander' : 'Eliminated',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onCast : null,
            borderRadius: RadiusTokens.radiusControlMd,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: _CommanderAvatar(
                      imageUrl: imageUrl,
                      name: name,
                      playerColor: playerColor,
                      size: size,
                    ),
                  ),
                  if (enabled)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(LayoutTokens.gr0),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.card,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: LayoutTokens.gr0,
                                offset: Offset(0, LayoutTokens.gr0),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.bolt_rounded,
                            size: size >= LayoutTokens.minTapTarget
                                ? LayoutTokens.gr2
                                : LayoutTokens.gr0 * 2,
                            color: ColorTokens.onAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
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
        borderRadius: RadiusTokens.radiusControlMd,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _placeholder(),
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
          borderRadius: RadiusTokens.radiusControlMd,
          border: Border.all(color: playerColor.withValues(alpha: 0.5)),
        ),
        child: Icon(Icons.style, color: playerColor, size: size * 0.5),
      );
}

class _CommanderTaxBadge extends StatelessWidget {
  final int castCount;
  final int tax;
  final bool compact;

  const _CommanderTaxBadge({
    required this.castCount,
    required this.tax,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fs = compact ? 11.0 : 12.0;
    if (castCount == 0) {
      return Text(
        'No tax yet',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: fs),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.15),
            borderRadius: RadiusTokens.radiusControlMd,
            border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.6)),
          ),
          child: Text(
            'Tax +$tax',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: fs,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: compact ? 3 : 4),
        Flexible(
          child: Text(
            '(cast $castCount×)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: fs),
          ),
        ),
      ],
    );
  }
}
