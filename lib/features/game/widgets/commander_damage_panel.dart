import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../ui/tokens/motion_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';

import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';

/// Highest commander damage on any single track (primary or partner).
int maxCommanderDamageTrack(
  PlayerGameState local,
  List<PlayerGameState> opponents,
) {
  var max = 0;
  for (final opp in opponents) {
    max = math.max(
      max,
      local.commanderDamageFrom(opp.playerId, partnerIndex: 0),
    );
    if (opp.hasPartner) {
      max = math.max(
        max,
        local.commanderDamageFrom(opp.playerId, partnerIndex: 1),
      );
    }
  }
  return max;
}

Color commanderDamageColor(int damage) {
  if (damage >= 21) return AppTheme.danger;
  if (damage >= 18) return AppTheme.dangerAmber;
  if (damage >= 10) return AppTheme.accent.withValues(alpha: 0.95);
  return AppTheme.textPrimary;
}

/// True when this session uses Commander rules.
bool isCommanderGameSession({
  required PlayerGameState local,
  required List<PlayerGameState> allPlayers,
}) {
  if (local.commanderName != null || local.hasPartner) return true;
  if (allPlayers.any((p) => p.commanderName != null)) return true;
  if (allPlayers.length > 1) return true;
  // Solo Commander pod (40-life default; still true after life changes).
  return local.life <= 40;
}

/// Compact status control for the commander bar (right side).
class CommanderDamageBarButton extends StatelessWidget {
  final int totalDamage;
  final int maxTrackDamage;
  final bool expanded;
  final bool enabled;
  final VoidCallback onTap;

  const CommanderDamageBarButton({
    super.key,
    required this.totalDamage,
    required this.maxTrackDamage,
    required this.expanded,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = maxTrackDamage >= 18;
    final lethal = maxTrackDamage >= 21;
    final accent = commanderDamageColor(maxTrackDamage);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: RadiusTokens.radiusControlSm,
        child: AnimatedContainer(
          duration: MotionTokens.standard,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: LayoutTokens.gr2,
            vertical: LayoutTokens.gr1,
          ),
          decoration: BoxDecoration(
            color: expanded
                ? accent.withValues(alpha: 0.18)
                : (urgent
                    ? accent.withValues(alpha: 0.12)
                    : AppTheme.surface.withValues(alpha: 0.65)),
            borderRadius: RadiusTokens.radiusControlSm,
            border: Border.all(
              color: expanded || urgent
                  ? accent.withValues(alpha: lethal ? 0.95 : 0.65)
                  : AppTheme.textSecondary.withValues(alpha: 0.28),
              width: expanded || lethal ? 2 : 1,
            ),
            boxShadow: expanded
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: LayoutTokens.gr2,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                lethal ? Icons.warning_amber_rounded : Icons.shield_outlined,
                size: LayoutTokens.gr3,
                color: enabled ? accent : AppTheme.textSecondary,
              ),
              SizedBox(height: LayoutTokens.gr0),
              Text(
                maxTrackDamage > 0 ? '$maxTrackDamage' : '—',
                style: TextStyle(
                  color: enabled ? accent : AppTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1,
                ),
              ),
              Text(
                'CMD',
                style: TextStyle(
                  color: enabled
                      ? AppTheme.textSecondary.withValues(alpha: 0.9)
                      : AppTheme.textSecondary.withValues(alpha: 0.55),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Commander damage listing — shown when expanded from the commander bar.
class CommanderDamagePanel extends StatelessWidget {
  final bool expanded;
  final PlayerGameState localPlayer;
  final List<PlayerGameState> opponents;
  final void Function({
    required String fromPlayerId,
    required int partnerIndex,
    required int delta,
  }) onDamageChange;

  const CommanderDamagePanel({
    super.key,
    required this.expanded,
    required this.localPlayer,
    required this.opponents,
    required this.onDamageChange,
  });

  @override
  Widget build(BuildContext context) {
    final opponentsWithCommanders = opponents
        .where((o) => !o.isEliminated || o.commanderName != null)
        .toList();

    if (!expanded) {
      return const SizedBox.shrink();
    }

    final total = localPlayer.totalCommanderDamageReceived;
    final maxTrack = maxCommanderDamageTrack(
      localPlayer,
      opponentsWithCommanders,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: LayoutTokens.gr2),
          child: Divider(
            height: 1,
            color: AppTheme.textSecondary.withValues(alpha: 0.14),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            LayoutTokens.gr0,
            LayoutTokens.gr2,
            LayoutTokens.gr0,
            LayoutTokens.gr1,
          ),
          child: _YourDamageSummary(
            totalDamage: total,
            maxTrackDamage: maxTrack,
          ),
        ),
        if (opponentsWithCommanders.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: LayoutTokens.gr1),
            child: Text(
              'Opponents will appear here when others join the pod.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          )
        else
          ...opponentsWithCommanders.map(
            (opp) => _OpponentDamageCard(
              opponent: opp,
              localPlayer: localPlayer,
              onDamageChange: onDamageChange,
            ),
          ),
      ],
    );
  }
}

class _YourDamageSummary extends StatelessWidget {
  final int totalDamage;
  final int maxTrackDamage;

  const _YourDamageSummary({
    required this.totalDamage,
    required this.maxTrackDamage,
  });

  @override
  Widget build(BuildContext context) {
    final accent = commanderDamageColor(maxTrackDamage);
    final progress = (maxTrackDamage / 21).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(LayoutTokens.gr2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: RadiusTokens.radiusMd,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin_circle_outlined,
                  size: LayoutTokens.gr3, color: accent),
              SizedBox(width: LayoutTokens.gr1),
              Expanded(
                child: Text(
                  'Your commander damage',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$maxTrackDamage / 21',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: LayoutTokens.gr1),
          ClipRRect(
            borderRadius: BorderRadius.circular(LayoutTokens.gr0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: LayoutTokens.gr1,
              backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.12),
              color: accent,
            ),
          ),
          if (totalDamage != maxTrackDamage) ...[
            SizedBox(height: LayoutTokens.gr0),
            Text(
              '$totalDamage total across all commanders',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OpponentDamageCard extends StatelessWidget {
  final PlayerGameState opponent;
  final PlayerGameState localPlayer;
  final void Function({
    required String fromPlayerId,
    required int partnerIndex,
    required int delta,
  }) onDamageChange;

  const _OpponentDamageCard({
    required this.opponent,
    required this.localPlayer,
    required this.onDamageChange,
  });

  @override
  Widget build(BuildContext context) {
    final primaryDmg =
        localPlayer.commanderDamageFrom(opponent.playerId, partnerIndex: 0);
    final partnerDmg = opponent.hasPartner
        ? localPlayer.commanderDamageFrom(opponent.playerId, partnerIndex: 1)
        : 0;

    return Padding(
      padding: EdgeInsets.only(bottom: LayoutTokens.gr2),
      child: Container(
        padding: EdgeInsets.all(LayoutTokens.gr2),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.55),
          borderRadius: RadiusTokens.radiusMd,
          border: Border.all(
            color: AppTheme.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OpponentAvatar(opponent: opponent),
            SizedBox(width: LayoutTokens.gr2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    opponent.username,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: LayoutTokens.gr1),
                  _DamageTrack(
                    label: opponent.commanderName ?? 'Commander',
                    damage: primaryDmg,
                    onAdd: localPlayer.isEliminated
                        ? null
                        : () => onDamageChange(
                              fromPlayerId: opponent.playerId,
                              partnerIndex: 0,
                              delta: 1,
                            ),
                    onRemove: primaryDmg > 0 && !localPlayer.isEliminated
                        ? () => onDamageChange(
                              fromPlayerId: opponent.playerId,
                              partnerIndex: 0,
                              delta: -1,
                            )
                        : null,
                  ),
                  if (opponent.hasPartner &&
                      opponent.partnerCommanderName != null) ...[
                    SizedBox(height: LayoutTokens.gr1),
                    _DamageTrack(
                      label: opponent.partnerCommanderName!,
                      damage: partnerDmg,
                      onAdd: localPlayer.isEliminated
                          ? null
                          : () => onDamageChange(
                                fromPlayerId: opponent.playerId,
                                partnerIndex: 1,
                                delta: 1,
                              ),
                      onRemove: partnerDmg > 0 && !localPlayer.isEliminated
                          ? () => onDamageChange(
                                fromPlayerId: opponent.playerId,
                                partnerIndex: 1,
                                delta: -1,
                              )
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpponentAvatar extends StatelessWidget {
  final PlayerGameState opponent;
  const _OpponentAvatar({required this.opponent});

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    if (opponent.commanderImageUrl != null &&
        opponent.commanderImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: RadiusTokens.radiusControlMd,
        child: CachedNetworkImage(
          imageUrl: opponent.commanderImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _colorDot(size),
        ),
      );
    }
    return _colorDot(size);
  }

  Widget _colorDot(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: opponent.playerColor.withValues(alpha: OpacityTokens.soft),
          borderRadius: RadiusTokens.radiusControlMd,
          border: Border.all(color: opponent.playerColor),
        ),
        child: Icon(
          Icons.person,
          color: opponent.playerColor,
          size: LayoutTokens.gr3,
        ),
      );
}

class _DamageTrack extends StatelessWidget {
  final String label;
  final int damage;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const _DamageTrack({
    required this.label,
    required this.damage,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = commanderDamageColor(damage);
    final progress = (damage / 21).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (damage >= 21)
              Tooltip(
                message: 'Lethal commander damage!',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: LayoutTokens.gr2,
                  color: AppTheme.danger,
                ),
              ),
          ],
        ),
        SizedBox(height: LayoutTokens.gr0),
        ClipRRect(
          borderRadius: BorderRadius.circular(LayoutTokens.gr0),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.1),
            color: color.withValues(alpha: 0.85),
          ),
        ),
        SizedBox(height: LayoutTokens.gr1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DmgStepButton(
              icon: Icons.remove_rounded,
              label: '−1',
              isAdd: false,
              onTap: onRemove,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: LayoutTokens.gr3),
              child: AnimatedDefaultTextStyle(
                duration: MotionTokens.standard,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  shadows: damage >= 10
                      ? [
                          Shadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Text('$damage'),
              ),
            ),
            _DmgStepButton(
              icon: Icons.add_rounded,
              label: '+1',
              isAdd: true,
              onTap: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}

class _DmgStepButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isAdd;
  final VoidCallback? onTap;

  const _DmgStepButton({
    required this.icon,
    required this.label,
    required this.isAdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fill = isAdd
        ? AppTheme.accent.withValues(alpha: enabled ? 0.22 : 0.08)
        : AppTheme.success.withValues(alpha: enabled ? 0.2 : 0.08);
    final border = isAdd
        ? AppTheme.accent.withValues(alpha: enabled ? 0.75 : 0.25)
        : AppTheme.success.withValues(alpha: enabled ? 0.7 : 0.25);
    final iconColor = enabled
        ? (isAdd ? AppTheme.accent : AppTheme.success)
        : AppTheme.textSecondary.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        borderRadius: RadiusTokens.radiusPill,
        child: AnimatedContainer(
          duration: MotionTokens.standard,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: enabled ? 2 : 1),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: (isAdd ? AppTheme.accent : AppTheme.success)
                          .withValues(alpha: 0.18),
                      blurRadius: LayoutTokens.gr1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: iconColor),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
