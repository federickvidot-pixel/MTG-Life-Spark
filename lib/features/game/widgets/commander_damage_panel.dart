import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';

/// Collapsible panel showing commander damage received from each opponent.
/// Partner-aware: shows two damage tracks per opponent when applicable.
/// Highlights amber at 18+, red at 21 (lethal).
class CommanderDamagePanel extends StatefulWidget {
  final PlayerGameState localPlayer;
  final List<PlayerGameState> opponents;
  final void Function({
    required String fromPlayerId,
    required int partnerIndex,
    required int delta,
  }) onDamageChange;

  const CommanderDamagePanel({
    super.key,
    required this.localPlayer,
    required this.opponents,
    required this.onDamageChange,
  });

  @override
  State<CommanderDamagePanel> createState() => _CommanderDamagePanelState();
}

class _CommanderDamagePanelState extends State<CommanderDamagePanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final opponentsWithCommanders = widget.opponents
        .where((o) => !o.isEliminated || o.commanderName != null)
        .toList();

    if (opponentsWithCommanders.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapse toggle
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Commander Damage',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),

        if (_expanded)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: opponentsWithCommanders
                  .map((opp) => _OpponentDamageRow(
                        opponent: opp,
                        localPlayer: widget.localPlayer,
                        onDamageChange: widget.onDamageChange,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _OpponentDamageRow extends StatelessWidget {
  final PlayerGameState opponent;
  final PlayerGameState localPlayer;
  final void Function({
    required String fromPlayerId,
    required int partnerIndex,
    required int delta,
  }) onDamageChange;

  const _OpponentDamageRow({
    required this.opponent,
    required this.localPlayer,
    required this.onDamageChange,
  });

  Color _damageColor(int damage) => AppTheme.textSecondary;

  @override
  Widget build(BuildContext context) {
    final primaryDmg =
        localPlayer.commanderDamageFrom(opponent.playerId, partnerIndex: 0);
    final partnerDmg = opponent.hasPartner
        ? localPlayer.commanderDamageFrom(opponent.playerId, partnerIndex: 1)
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Opponent avatar
          _OpponentAvatar(opponent: opponent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent.username,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 6),
                // Primary commander damage
                _DamageTrack(
                  label: opponent.commanderName ?? 'Commander',
                  damage: primaryDmg,
                  damageColor: _damageColor(primaryDmg),
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
                // Partner commander damage (if applicable)
                if (opponent.hasPartner && opponent.partnerCommanderName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _DamageTrack(
                      label: opponent.partnerCommanderName!,
                      damage: partnerDmg,
                      damageColor: _damageColor(partnerDmg),
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
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentAvatar extends StatelessWidget {
  final PlayerGameState opponent;
  const _OpponentAvatar({required this.opponent});

  @override
  Widget build(BuildContext context) {
    if (opponent.commanderImageUrl != null &&
        opponent.commanderImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: opponent.commanderImageUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _colorDot(),
        ),
      );
    }
    return _colorDot();
  }

  Widget _colorDot() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: opponent.playerColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: opponent.playerColor),
        ),
        child: Icon(Icons.person, color: opponent.playerColor, size: 18),
      );
}

class _DamageTrack extends StatelessWidget {
  final String label;
  final int damage;
  final Color damageColor;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const _DamageTrack({
    required this.label,
    required this.damage,
    required this.damageColor,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ),
        const SizedBox(width: 8),
        _DmgBtn(icon: Icons.remove, onTap: onRemove),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: damageColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            child: Text('$damage'),
          ),
        ),
        _DmgBtn(icon: Icons.add, onTap: onAdd),
        if (damage >= 21)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Tooltip(
              message: 'Lethal commander damage!',
              child: Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppTheme.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _DmgBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _DmgBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.card
              : AppTheme.card.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
