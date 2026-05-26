import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_providers.dart';
import '../../../core/game/game_format.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/motion_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import 'game_modal_chrome.dart';

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

/// Total commander damage the local player has dealt across all opponents.
int totalCommanderDamageDealt(
  PlayerGameState local,
  List<PlayerGameState> opponents,
) {
  var total = 0;
  for (final opp in opponents) {
    total += opp.commanderDamageFrom(local.playerId, partnerIndex: 0);
    if (local.hasPartner) {
      total += opp.commanderDamageFrom(local.playerId, partnerIndex: 1);
    }
  }
  return total;
}

/// Highest single track of commander damage the local player has dealt.
int maxCommanderDamageDealtTrack(
  PlayerGameState local,
  List<PlayerGameState> opponents,
) {
  var max = 0;
  for (final opp in opponents) {
    max = math.max(
      max,
      opp.commanderDamageFrom(local.playerId, partnerIndex: 0),
    );
    if (local.hasPartner) {
      max = math.max(
        max,
        opp.commanderDamageFrom(local.playerId, partnerIndex: 1),
      );
    }
  }
  return max;
}

enum CommanderDamageDirection { received, dealt }

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
  GameFormat? gameFormat,
  int? startingLife,
}) {
  if (local.commanderName != null || local.hasPartner) return true;
  if (allPlayers.any((p) => p.commanderName != null || p.hasPartner)) {
    return true;
  }
  // Solo Commander pod — use lobby format / starting life, not current life.
  if (allPlayers.length <= 1) {
    if (gameFormat?.isCommanderStyle == true) return true;
    if (startingLife == GameFormat.commander.defaultStartingLife) return true;
  }
  return false;
}

/// Opens commander damage tracking in a bottom sheet (does not shift Play UI).
Future<void> showCommanderDamageSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showGameBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Consumer(
        builder: (context, ref, _) {
          final game = ref.watch(gameProvider);
          final local = game.localPlayer;
          if (local == null) return const SizedBox.shrink();

          final opponents =
              game.players.where((p) => p.playerId != local.playerId).toList();
          final notifier = ref.read(gameProvider.notifier);

          return SingleChildScrollView(
            controller: scrollController,
            padding: GameModalChrome.sheetPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GameSheetHandle(),
                SizedBox(height: LayoutTokens.gr2),
                const GameSheetHeader(
                  title: 'Commander damage',
                  subtitle:
                      'Track damage to you, or log damage you dealt to others.',
                  showHandle: false,
                ),
                SizedBox(height: LayoutTokens.gr2),
                CommanderDamagePanel(
                  localPlayer: local,
                  opponents: opponents,
                  onDamageChange: ({
                    required String fromPlayerId,
                    required int partnerIndex,
                    required String toPlayerId,
                    required int delta,
                  }) =>
                      notifier.applyCommanderDamage(
                    fromPlayerId: fromPlayerId,
                    partnerIndex: partnerIndex,
                    toPlayerId: toPlayerId,
                    delta: delta,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// Compact status control for the commander bar (right side).
class CommanderDamageBarButton extends StatelessWidget {
  final int totalDamage;
  final int maxTrackDamage;
  final bool enabled;
  final VoidCallback onTap;

  const CommanderDamageBarButton({
    super.key,
    required this.totalDamage,
    required this.maxTrackDamage,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = maxTrackDamage >= 18;
    final lethal = maxTrackDamage >= 21;
    final accent = commanderDamageColor(maxTrackDamage);
    final displayTotal = totalDamage;

    return Semantics(
      button: true,
      enabled: enabled,
      label:
          'Commander damage taken, $displayTotal total, highest single track $maxTrackDamage',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: RadiusTokens.radiusControlSm,
        child: AnimatedContainer(
          duration: MotionTokens.standard,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(
            minHeight: LayoutTokens.minTapTarget,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: LayoutTokens.gr2,
            vertical: LayoutTokens.gr1,
          ),
            decoration: BoxDecoration(
              color: urgent
                  ? accent.withValues(alpha: 0.12)
                  : AppTheme.surface.withValues(alpha: 0.65),
              borderRadius: RadiusTokens.radiusControlSm,
              border: Border.all(
                color: urgent
                    ? accent.withValues(alpha: lethal ? 0.95 : 0.65)
                    : AppTheme.textSecondary.withValues(alpha: 0.28),
                width: lethal ? 2 : 1,
              ),
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
                  displayTotal > 0 ? '$displayTotal' : '—',
                  style: TextStyle(
                    color: enabled ? accent : AppTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1,
                  ),
                ),
                Text(
                  'IN',
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
      ),
    );
  }
}

/// Commander damage listing for the commander-damage bottom sheet.
class CommanderDamagePanel extends StatefulWidget {
  final PlayerGameState localPlayer;
  final List<PlayerGameState> opponents;
  final void Function({
    required String fromPlayerId,
    required int partnerIndex,
    required String toPlayerId,
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
  CommanderDamageDirection _direction = CommanderDamageDirection.received;
  String? _selectedOpponentId;

  List<PlayerGameState> get _trackableOpponents {
    return widget.opponents.where((o) {
      if (!o.isEliminated) return true;
      return _maxTrackForOpponent(o) > 0;
    }).toList();
  }

  int _maxTrackForOpponent(PlayerGameState opponent) {
    if (_direction == CommanderDamageDirection.received) {
      final primary = widget.localPlayer.commanderDamageFrom(
        opponent.playerId,
        partnerIndex: 0,
      );
      if (!opponent.hasPartner) return primary;
      return math.max(
        primary,
        widget.localPlayer.commanderDamageFrom(
          opponent.playerId,
          partnerIndex: 1,
        ),
      );
    }

    final primary = opponent.commanderDamageFrom(
      widget.localPlayer.playerId,
      partnerIndex: 0,
    );
    if (!widget.localPlayer.hasPartner) return primary;
    return math.max(
      primary,
      opponent.commanderDamageFrom(
        widget.localPlayer.playerId,
        partnerIndex: 1,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(covariant CommanderDamagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  void _syncSelection() {
    final opponents = _trackableOpponents;
    if (opponents.isEmpty) {
      _selectedOpponentId = null;
      return;
    }
    if (_selectedOpponentId != null &&
        opponents.any((o) => o.playerId == _selectedOpponentId)) {
      return;
    }
    _selectedOpponentId = opponents.first.playerId;
  }

  PlayerGameState? get _selectedOpponent {
    final id = _selectedOpponentId;
    if (id == null) return null;
    for (final opp in _trackableOpponents) {
      if (opp.playerId == id) return opp;
    }
    return null;
  }

  int _damageForOpponent(PlayerGameState opponent) {
    if (_direction == CommanderDamageDirection.received) {
      var total = widget.localPlayer.commanderDamageFrom(
        opponent.playerId,
        partnerIndex: 0,
      );
      if (opponent.hasPartner) {
        total += widget.localPlayer.commanderDamageFrom(
          opponent.playerId,
          partnerIndex: 1,
        );
      }
      return total;
    }

    var total = opponent.commanderDamageFrom(
      widget.localPlayer.playerId,
      partnerIndex: 0,
    );
    if (widget.localPlayer.hasPartner) {
      total += opponent.commanderDamageFrom(
        widget.localPlayer.playerId,
        partnerIndex: 1,
      );
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final opponents = _trackableOpponents;
    final received = _direction == CommanderDamageDirection.received;
    final selected = _selectedOpponent;
    final selectedDamage =
        selected != null ? _damageForOpponent(selected) : 0;
    final pickerPrompt = received ? 'Who hit you?' : 'Who did you hit?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommanderDamageModeToggle(
          direction: _direction,
          onChanged: (direction) => setState(() {
            _direction = direction;
            _syncSelection();
          }),
        ),
        SizedBox(height: LayoutTokens.gr2),
        _CommanderDamageSummary(
          direction: _direction,
          damage: selectedDamage,
          opponentName: selected?.username,
          commanderImageUrl: selected?.commanderImageUrl,
          playerColor:
              selected?.playerColor ?? widget.localPlayer.playerColor,
        ),
        SizedBox(height: LayoutTokens.gr2),
        if (opponents.isEmpty)
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
        else ...[
          Text(
            pickerPrompt,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          SizedBox(height: LayoutTokens.gr1),
          _OpponentPickerStrip(
            direction: _direction,
            opponents: opponents,
            localPlayer: widget.localPlayer,
            selectedOpponentId: _selectedOpponentId,
            onSelected: (id) => setState(() => _selectedOpponentId = id),
          ),
          if (selected != null) ...[
            SizedBox(height: LayoutTokens.gr2),
            _SelectedOpponentDamageCard(
              direction: _direction,
              opponent: selected,
              localPlayer: widget.localPlayer,
              onDamageChange: widget.onDamageChange,
            ),
          ],
        ],
      ],
    );
  }
}

class _CommanderDamageModeToggle extends StatelessWidget {
  final CommanderDamageDirection direction;
  final ValueChanged<CommanderDamageDirection> onChanged;

  const _CommanderDamageModeToggle({
    required this.direction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.55),
        borderRadius: RadiusTokens.radiusMd,
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeToggleChip(
              label: 'To you',
              selected: direction == CommanderDamageDirection.received,
              onTap: () => onChanged(CommanderDamageDirection.received),
            ),
          ),
          Expanded(
            child: _ModeToggleChip(
              label: 'You dealt',
              selected: direction == CommanderDamageDirection.dealt,
              onTap: () => onChanged(CommanderDamageDirection.dealt),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: RadiusTokens.radiusMd,
          child: AnimatedContainer(
            duration: MotionTokens.standard,
            padding: EdgeInsets.symmetric(vertical: LayoutTokens.gr2),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.accent.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: RadiusTokens.radiusMd,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommanderDamageSummary extends StatelessWidget {
  final CommanderDamageDirection direction;
  final int damage;
  final String? opponentName;
  final String? commanderImageUrl;
  final Color playerColor;

  const _CommanderDamageSummary({
    required this.direction,
    required this.damage,
    required this.opponentName,
    required this.commanderImageUrl,
    required this.playerColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = commanderDamageColor(damage);
    final received = direction == CommanderDamageDirection.received;
    final label = received ? 'Damage Taken' : 'Damage Dealt';
    final hasArt =
        commanderImageUrl != null && commanderImageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: RadiusTokens.radiusMd,
      child: SizedBox(
        height: 112,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasArt)
              CachedNetworkImage(
                key: ValueKey(commanderImageUrl),
                imageUrl: commanderImageUrl!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorWidget: (_, __, ___) => _summaryFallbackArt(playerColor),
              )
            else
              _summaryFallbackArt(playerColor),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.42),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    accent.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(LayoutTokens.gr2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (opponentName != null) ...[
                          SizedBox(height: LayoutTokens.gr0),
                          Text(
                            opponentName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '$damage',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: accent.withValues(alpha: 0.85),
                          blurRadius: 16,
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: RadiusTokens.radiusMd,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryFallbackArt(Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.35),
            AppTheme.primary.withValues(alpha: 0.92),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.style,
          size: 48,
          color: color.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _OpponentPickerStrip extends StatelessWidget {
  final CommanderDamageDirection direction;
  final List<PlayerGameState> opponents;
  final PlayerGameState localPlayer;
  final String? selectedOpponentId;
  final ValueChanged<String> onSelected;

  const _OpponentPickerStrip({
    required this.direction,
    required this.opponents,
    required this.localPlayer,
    required this.selectedOpponentId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opponents.length,
        separatorBuilder: (_, __) => SizedBox(width: LayoutTokens.gr1),
        itemBuilder: (context, index) {
          final opp = opponents[index];
          final selected = opp.playerId == selectedOpponentId;

          return Semantics(
            button: true,
            selected: selected,
            label: '${opp.username}${selected ? ', selected' : ''}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(opp.playerId),
                borderRadius: RadiusTokens.radiusMd,
                child: AnimatedContainer(
                  duration: MotionTokens.standard,
                  width: 84,
                  padding: EdgeInsets.symmetric(
                    horizontal: LayoutTokens.gr1,
                    vertical: LayoutTokens.gr1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.accent.withValues(alpha: 0.12)
                        : AppTheme.surface.withValues(alpha: 0.55),
                    borderRadius: RadiusTokens.radiusMd,
                    border: Border.all(
                      color: selected
                          ? AppTheme.accent.withValues(alpha: 0.85)
                          : AppTheme.textSecondary.withValues(alpha: 0.18),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OpponentAvatar(opponent: opp, size: 40),
                      SizedBox(height: LayoutTokens.gr0),
                      Text(
                        opp.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedOpponentDamageCard extends StatelessWidget {
  final CommanderDamageDirection direction;
  final PlayerGameState opponent;
  final PlayerGameState localPlayer;
  final void Function({
    required String fromPlayerId,
    required int partnerIndex,
    required String toPlayerId,
    required int delta,
  }) onDamageChange;

  const _SelectedOpponentDamageCard({
    required this.direction,
    required this.opponent,
    required this.localPlayer,
    required this.onDamageChange,
  });

  @override
  Widget build(BuildContext context) {
    final received = direction == CommanderDamageDirection.received;
    final targetPlayer = received ? localPlayer : opponent;
    final sourcePlayer = received ? opponent : localPlayer;
    final canEdit = received
        ? !localPlayer.isEliminated
        : !opponent.isEliminated;

    final primaryDmg = targetPlayer.commanderDamageFrom(
      sourcePlayer.playerId,
      partnerIndex: 0,
    );
    final partnerDmg = sourcePlayer.hasPartner
        ? targetPlayer.commanderDamageFrom(
            sourcePlayer.playerId,
            partnerIndex: 1,
          )
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DamageTrack(
          label: sourcePlayer.commanderName ?? 'Commander',
          damage: primaryDmg,
          onAdd: canEdit
              ? () => onDamageChange(
                    fromPlayerId: sourcePlayer.playerId,
                    partnerIndex: 0,
                    toPlayerId: targetPlayer.playerId,
                    delta: 1,
                  )
              : null,
          onRemove: primaryDmg > 0 && canEdit
              ? () => onDamageChange(
                    fromPlayerId: sourcePlayer.playerId,
                    partnerIndex: 0,
                    toPlayerId: targetPlayer.playerId,
                    delta: -1,
                  )
              : null,
        ),
          if (sourcePlayer.hasPartner) ...[
            SizedBox(height: LayoutTokens.gr2),
            _DamageTrack(
              label: sourcePlayer.partnerCommanderName ?? 'Partner commander',
              damage: partnerDmg,
              onAdd: canEdit
                  ? () => onDamageChange(
                        fromPlayerId: sourcePlayer.playerId,
                        partnerIndex: 1,
                        toPlayerId: targetPlayer.playerId,
                        delta: 1,
                      )
                  : null,
              onRemove: partnerDmg > 0 && canEdit
                  ? () => onDamageChange(
                        fromPlayerId: sourcePlayer.playerId,
                        partnerIndex: 1,
                        toPlayerId: targetPlayer.playerId,
                        delta: -1,
                      )
                  : null,
            ),
          ],
        ],
    );
  }
}

class _OpponentAvatar extends StatelessWidget {
  final PlayerGameState opponent;
  final double size;

  const _OpponentAvatar({required this.opponent, this.size = 44});

  @override
  Widget build(BuildContext context) {
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

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
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
            width: LayoutTokens.minTapTarget,
            height: LayoutTokens.minTapTarget,
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
      ),
    );
  }
}
