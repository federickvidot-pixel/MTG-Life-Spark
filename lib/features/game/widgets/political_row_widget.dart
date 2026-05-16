import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/theme_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/spacing_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';

class PoliticalRowWidget extends ConsumerWidget {
  final GameState game;
  final bool overviewStyle;

  const PoliticalRowWidget({super.key, required this.game, this.overviewStyle = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: overviewStyle ? Colors.transparent : AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          // Monarch
          Expanded(
            child: _PoliticalBadge(
              icon: '👑',
              label: 'Monarch',
              holderId: game.monarchPlayerId,
              players: game.players,
              canAssign: game.isHost,
              overviewStyle: overviewStyle,
              onTap: game.isHost
                  ? () => _showAssignPicker(
                        context,
                        ref,
                        'Assign Monarch',
                        game.monarchPlayerId,
                        (pid) => notifier.setMonarch(pid),
                      )
                  : null,
            ),
          ),

          const SizedBox(width: LayoutTokens.gr1),

          // Initiative
          Expanded(
            child: _PoliticalBadge(
              icon: '⚔️',
              label: 'Initiative',
              holderId: game.initiativePlayerId,
              players: game.players,
              canAssign: game.isHost,
              overviewStyle: overviewStyle,
              onTap: game.isHost
                  ? () => _showAssignPicker(
                        context,
                        ref,
                        'Assign Initiative',
                        game.initiativePlayerId,
                        (pid) => notifier.setInitiative(pid),
                      )
                  : null,
            ),
          ),

          const SizedBox(width: LayoutTokens.gr1),

          // Day / Night (host only) — also syncs app theme
          _DayNightToggle(
            dayNight: game.dayNight,
            isHost: game.isHost,
            overviewStyle: overviewStyle,
            onTap: game.isHost
                ? () {
                    final next = _nextDayNight(game.dayNight);
                    notifier.setDayNight(next);
                    // Sync theme with Day/Night
                    if (next == DayNightState.day || next == DayNightState.night) {
                      ref.read(themePreferenceProvider.notifier).setUseDarkTheme(
                            next == DayNightState.night,
                          );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  DayNightState _nextDayNight(DayNightState current) {
    switch (current) {
      case DayNightState.none:
        return DayNightState.day;
      case DayNightState.day:
        return DayNightState.night;
      case DayNightState.night:
        return DayNightState.none;
    }
  }

  void _showAssignPicker(
    BuildContext context,
    WidgetRef ref,
    String title,
    String? currentHolderId,
    void Function(String? pid) onAssign,
  ) {
    final game = ref.read(gameProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RadiusTokens.xl),
        ),
      ),
      builder: (_) => _PlayerPickerSheet(
        title: title,
        players: game.players.where((p) => !p.isEliminated).toList(),
        currentHolderId: currentHolderId,
        onSelected: (pid) {
          Navigator.pop(context);
          onAssign(pid);
        },
      ),
    );
  }
}

class _PoliticalBadge extends StatelessWidget {
  final String icon;
  final String label;
  final String? holderId;
  final List<PlayerGameState> players;
  final bool canAssign;
  final bool overviewStyle;
  final VoidCallback? onTap;

  const _PoliticalBadge({
    required this.icon,
    required this.label,
    required this.holderId,
    required this.players,
    required this.canAssign,
    this.overviewStyle = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final holder = holderId != null
        ? players.where((p) => p.playerId == holderId).firstOrNull
        : null;

    final borderColor = overviewStyle
        ? AppTheme.textPrimary
        : (holder != null
            ? AppTheme.accentGold.withValues(alpha: 0.5)
            : AppTheme.surface);
    final textColor = overviewStyle ? AppTheme.textPrimary : AppTheme.textSecondary;
    final holderColor = overviewStyle
        ? AppTheme.textPrimary
        : (holder != null ? AppTheme.accentGold : AppTheme.textSecondary);

    final child = GestureDetector(
      onTap: canAssign ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: LayoutTokens.minTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr1,
          vertical: LayoutTokens.gr1,
        ),
        decoration: BoxDecoration(
          color: overviewStyle ? Colors.transparent : AppTheme.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: overviewStyle ? 12 : 14)),
            const SizedBox(width: LayoutTokens.gr1),
            Expanded(
              child: overviewStyle
                  ? Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          holder?.username ?? 'None',
                          style: TextStyle(
                            color: holderColor,
                            fontSize: 11,
                            fontWeight: holder != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
            if (canAssign && !overviewStyle)
              Icon(
                Icons.edit,
                size: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
    return IgnorePointer(
      ignoring: !canAssign,
      child: child,
    );
  }
}

class _DayNightToggle extends StatelessWidget {
  final DayNightState dayNight;
  final bool isHost;
  final bool overviewStyle;
  final VoidCallback? onTap;

  const _DayNightToggle({
    required this.dayNight,
    required this.isHost,
    this.overviewStyle = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (dayNight) {
      DayNightState.none => ('🌓', 'Day/Night', AppTheme.textSecondary),
      DayNightState.day => ('☀️', 'Day', AppTheme.accentGold),
      DayNightState.night => ('🌙', 'Night', AppTheme.accent),
    };

    final borderColor = overviewStyle
        ? AppTheme.textPrimary
        : (dayNight != DayNightState.none
            ? color.withValues(alpha: 0.5)
            : AppTheme.surface);
    final textColor = overviewStyle ? AppTheme.textPrimary : color;

    final child = GestureDetector(
      onTap: isHost ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr2,
          vertical: LayoutTokens.gr1,
        ),
        decoration: BoxDecoration(
          color: overviewStyle ? Colors.transparent : AppTheme.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: overviewStyle
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: LayoutTokens.gr0),
                  Text(
                    label,
                    style: TextStyle(color: textColor, fontSize: 11),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  Text(
                    label,
                    style: TextStyle(color: color, fontSize: 9),
                  ),
                ],
              ),
      ),
    );
    return IgnorePointer(
      ignoring: !isHost,
      child: child,
    );
  }
}

class _PlayerPickerSheet extends StatelessWidget {
  final String title;
  final List<PlayerGameState> players;
  final String? currentHolderId;
  final void Function(String? pid) onSelected;

  const _PlayerPickerSheet({
    required this.title,
    required this.players,
    required this.currentHolderId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        SpacingTokens.md,
        SpacingTokens.lg,
        SpacingTokens.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: LayoutTokens.gr3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: LayoutTokens.gr2),
          // None option
          ListTile(
            tileColor: currentHolderId == null
                ? AppTheme.accent.withValues(alpha: 0.1)
                : AppTheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RadiusTokens.sm)),
            title: const Text('None',
                style: TextStyle(color: AppTheme.textSecondary)),
            onTap: () => onSelected(null),
          ),
          const SizedBox(height: LayoutTokens.gr1),
          ...players.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: LayoutTokens.gr1),
                child: ListTile(
                  tileColor: p.playerId == currentHolderId
                      ? p.playerColor.withValues(alpha: 0.15)
                      : AppTheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.sm)),
                  leading: CircleAvatar(
                    backgroundColor: p.playerColor,
                    radius: 14,
                    child: Text(
                      p.username.isNotEmpty
                          ? p.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(p.username,
                      style: const TextStyle(color: AppTheme.textPrimary)),
                  trailing: p.playerId == currentHolderId
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.success, size: 18)
                      : null,
                  onTap: () => onSelected(p.playerId),
                ),
              )),
        ],
      ),
    );
  }
}
