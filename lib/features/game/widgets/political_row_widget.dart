import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/theme_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/color_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';
import 'game_modal_chrome.dart';
import '../../../ui/tokens/radius_tokens.dart';

/// Truncates long player names for compact overview chips.
String overviewShortPlayerName(String name, {int maxChars = 9}) {
  final trimmed = name.trim();
  if (trimmed.length <= maxChars) return trimmed;
  return '${trimmed.substring(0, maxChars - 1)}…';
}

/// Monarch, Initiative, and Day/Night controls for the overview board.
class PoliticalRowWidget extends ConsumerWidget {
  final GameState game;

  const PoliticalRowWidget({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final dayNightLabel = switch (game.dayNight) {
      DayNightState.day => 'Day',
      DayNightState.night => 'Night',
      DayNightState.none => '—',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.14),
            AppTheme.card,
          ],
        ),
        borderRadius: RadiusTokens.radiusMd,
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(LayoutTokens.gr2 + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: AppTheme.accentGold, size: 18),
                SizedBox(width: LayoutTokens.gr1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table politics',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: FontTokens.hudSm,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: LayoutTokens.gr0 - 1),
                      Text(
                        'Monarch · Initiative · $dayNightLabel',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: FontTokens.hudXs,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: LayoutTokens.gr2),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PoliticalBadge(
                      label: 'Monarch',
                      icon: '👑',
                      holderId: game.monarchPlayerId,
                      players: game.players,
                      canAssign: game.isHost,
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
                  SizedBox(width: LayoutTokens.gr1),
                  Expanded(
                    child: _PoliticalBadge(
                      label: 'Initiative',
                      icon: '⚔️',
                      holderId: game.initiativePlayerId,
                      players: game.players,
                      canAssign: game.isHost,
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
                  SizedBox(width: LayoutTokens.gr1),
                  Expanded(
                    child: _DayNightToggle(
                      dayNight: game.dayNight,
                      isHost: game.isHost,
                      onTap: game.isHost
                          ? () {
                              final next = _nextDayNight(game.dayNight);
                              notifier.setDayNight(next);
                              if (next == DayNightState.day ||
                                  next == DayNightState.night) {
                                ref
                                    .read(themePreferenceProvider.notifier)
                                    .setUseDarkTheme(next == DayNightState.night);
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    showGameBottomSheet<void>(
      context: context,
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
  final String label;
  final String icon;
  final String? holderId;
  final List<PlayerGameState> players;
  final bool canAssign;
  final VoidCallback? onTap;

  const _PoliticalBadge({
    required this.label,
    required this.icon,
    required this.holderId,
    required this.players,
    required this.canAssign,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final holder = holderId != null
        ? players.where((p) => p.playerId == holderId).firstOrNull
        : null;
    final hasHolder = holder != null;

    return _OverviewFilledMarkerButton(
      enabled: canAssign,
      onPressed: canAssign ? onTap : null,
      filled: hasHolder,
      fillColor: hasHolder
          ? AppTheme.accentGold.withValues(alpha: 0.88)
          : AppTheme.surface.withValues(alpha: 0.9),
      foregroundColor: hasHolder ? AppTheme.primary : AppTheme.textSecondary,
      label: '$icon $label',
      value: holder != null
          ? overviewShortPlayerName(holder.username)
          : 'None',
    );
  }
}

class _DayNightToggle extends StatelessWidget {
  final DayNightState dayNight;
  final bool isHost;
  final VoidCallback? onTap;

  const _DayNightToggle({
    required this.dayNight,
    required this.isHost,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (dayNight) {
      DayNightState.none => ('Day/Night', '🌓', AppTheme.textSecondary),
      DayNightState.day => ('Day', '☀️', AppTheme.accentGold),
      DayNightState.night => ('Night', '🌙', AppTheme.accent),
    };
    final isActive = dayNight != DayNightState.none;

    return _OverviewFilledMarkerButton(
      enabled: isHost,
      onPressed: isHost ? onTap : null,
      filled: isActive,
      fillColor:
          isActive ? color.withValues(alpha: 0.88) : AppTheme.surface.withValues(alpha: 0.9),
      foregroundColor: isActive ? AppTheme.primary : AppTheme.textSecondary,
      label: '$icon Day/Night',
      value: label,
    );
  }
}

class _OverviewFilledMarkerButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;
  final bool filled;
  final Color fillColor;
  final Color foregroundColor;
  final String label;
  final String value;

  const _OverviewFilledMarkerButton({
    required this.enabled,
    required this.onPressed,
    required this.filled,
    required this.fillColor,
    required this.foregroundColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, LayoutTokens.minTapTarget - 4),
        padding: EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr0 + 2,
          vertical: LayoutTokens.gr1,
        ),
        backgroundColor: fillColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: AppTheme.surface.withValues(alpha: 0.6),
        disabledForegroundColor:
            AppTheme.textSecondary.withValues(alpha: 0.5),
        elevation: filled ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.radiusControlMd,
          side: BorderSide(
            color: filled
                ? AppTheme.accentGold.withValues(alpha: 0.35)
                : AppTheme.textSecondary.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: FontTokens.hudXs,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          SizedBox(height: LayoutTokens.gr0 - 1),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: FontTokens.hudXs,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
              height: 1.15,
            ),
          ),
        ],
      ),
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
    return GameSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameSheetHeader(title: title),
          ListTile(
            tileColor: currentHolderId == null
                ? AppTheme.accent.withValues(alpha: 0.1)
                : AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
            title: const Text(
              'None',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            onTap: () => onSelected(null),
          ),
          SizedBox(height: LayoutTokens.gr1),
          ...players.map(
            (p) => Padding(
              padding: EdgeInsets.only(bottom: LayoutTokens.gr1),
              child: ListTile(
                tileColor: p.playerId == currentHolderId
                    ? p.playerColor.withValues(alpha: 0.15)
                    : AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
                leading: CircleAvatar(
                  backgroundColor: p.playerColor,
                  radius: 14,
                  child: Text(
                    p.username.isNotEmpty
                        ? p.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: ColorTokens.onAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  p.username,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                trailing: p.playerId == currentHolderId
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 18,
                      )
                    : null,
                onTap: () => onSelected(p.playerId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
