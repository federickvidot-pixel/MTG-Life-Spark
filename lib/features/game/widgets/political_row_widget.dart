import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/theme_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/color_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/spacing_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';

class PoliticalRowWidget extends ConsumerWidget {
  final GameState game;
  final bool overviewStyle;

  const PoliticalRowWidget({
    super.key,
    required this.game,
    this.overviewStyle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);

    final row = Row(
      children: [
        Expanded(
          child: _PoliticalBadge(
            icon: '👑',
            label: 'Monarch',
            holderId: game.monarchPlayerId,
            players: game.players,
            canAssign: game.isHost,
            overviewStyle: overviewStyle,
            onTap:
                game.isHost
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
            icon: '⚔️',
            label: 'Initiative',
            holderId: game.initiativePlayerId,
            players: game.players,
            canAssign: game.isHost,
            overviewStyle: overviewStyle,
            onTap:
                game.isHost
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
            overviewStyle: overviewStyle,
            onTap:
                game.isHost
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
    );

    if (!overviewStyle) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: RadiusTokens.radiusPill,
        ),
        child: row,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Game markers',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: FontTokens.label,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: LayoutTokens.gr1),
        row,
      ],
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
        borderRadius: RadiusTokens.radiusSheetTop,
      ),
      builder:
          (_) => _PlayerPickerSheet(
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
    final holder =
        holderId != null
            ? players.where((p) => p.playerId == holderId).firstOrNull
            : null;
    final hasHolder = holder != null;

    if (overviewStyle) {
      return _OverviewFilledMarkerButton(
        enabled: canAssign,
        onPressed: canAssign ? onTap : null,
        filled: hasHolder,
        fillColor:
            hasHolder
                ? AppTheme.accentGold.withValues(alpha: 0.85)
                : AppTheme.surface,
        foregroundColor:
            hasHolder ? AppTheme.primary : AppTheme.textSecondary,
        label: label,
        value: holder?.username ?? 'None',
      );
    }

    final borderColor =
        hasHolder
            ? AppTheme.accentGold.withValues(alpha: OpacityTokens.half)
            : AppTheme.surface;
    final holderColor =
        hasHolder ? AppTheme.accentGold : AppTheme.textSecondary;

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
          color: AppTheme.card,
          borderRadius: RadiusTokens.radiusPill,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: LayoutTokens.gr1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: FontTokens.xs,
                    ),
                  ),
                  Text(
                    holder?.username ?? 'None',
                    style: TextStyle(
                      color: holderColor,
                      fontSize: FontTokens.hudXs,
                      fontWeight:
                          hasHolder ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (canAssign)
              Icon(
                Icons.edit,
                size: 12,
                color: AppTheme.textSecondary.withValues(alpha: OpacityTokens.half),
              ),
          ],
        ),
      ),
    );
    return IgnorePointer(ignoring: !canAssign, child: child);
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
    final (label, color) = switch (dayNight) {
      DayNightState.none => ('Day/Night', AppTheme.textSecondary),
      DayNightState.day => ('Day', AppTheme.accentGold),
      DayNightState.night => ('Night', AppTheme.accent),
    };
    final isActive = dayNight != DayNightState.none;

    if (overviewStyle) {
      return _OverviewFilledMarkerButton(
        enabled: isHost,
        onPressed: isHost ? onTap : null,
        filled: isActive,
        fillColor:
            isActive ? color.withValues(alpha: 0.85) : AppTheme.surface,
        foregroundColor: isActive ? AppTheme.primary : AppTheme.textSecondary,
        label: 'Day / Night',
        value: label,
      );
    }

    final borderColor =
        isActive ? color.withValues(alpha: OpacityTokens.half) : AppTheme.surface;
    final icon = switch (dayNight) {
      DayNightState.none => '🌓',
      DayNightState.day => '☀️',
      DayNightState.night => '🌙',
    };

    final child = GestureDetector(
      onTap: isHost ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr2,
          vertical: LayoutTokens.gr1,
        ),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: RadiusTokens.radiusPill,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            Text(label, style: TextStyle(color: color, fontSize: FontTokens.xs)),
          ],
        ),
      ),
    );
    return IgnorePointer(ignoring: !isHost, child: child);
  }
}

/// Overview row: text-only [FilledButton] for monarch, initiative, day/night.
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
        minimumSize: const Size(0, LayoutTokens.minTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr1,
          vertical: LayoutTokens.gr1,
        ),
        backgroundColor: fillColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: AppTheme.surface.withValues(alpha: 0.6),
        disabledForegroundColor: AppTheme.textSecondary.withValues(alpha: OpacityTokens.half),
        elevation: filled ? 0 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.radiusControlMd,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: FontTokens.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: LayoutTokens.gr0),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: FontTokens.sm,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
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
          ListTile(
            tileColor:
                currentHolderId == null
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
          const SizedBox(height: LayoutTokens.gr1),
          ...players.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: LayoutTokens.gr1),
              child: ListTile(
                tileColor:
                    p.playerId == currentHolderId
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
                trailing:
                    p.playerId == currentHolderId
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
