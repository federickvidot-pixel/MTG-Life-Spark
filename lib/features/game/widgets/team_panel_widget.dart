import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../shared/theme/app_theme.dart';

const _teamColors = <int, Color>{
  1: Color(0xFF4FC3F7), // Sky blue
  2: Color(0xFFF48FB1), // Pink
  3: Color(0xFFA5D6A7), // Green
  4: Color(0xFFFFCC80), // Amber
};

const _teamLabels = <int, String>{
  1: 'Team 1',
  2: 'Team 2',
  3: 'Team 3',
  4: 'Team 4',
};

Color teamColor(int teamIndex) => _teamColors[teamIndex] ?? Colors.transparent;

class TeamPanelWidget extends ConsumerWidget {
  final GameState game;

  const TeamPanelWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!game.isHost) return const SizedBox.shrink();
    final notifier = ref.read(gameProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              'Team Assignments',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...game.players.where((p) => !p.isEliminated).map((player) {
            final currentTeam = game.teamAssignments[player.playerId] ?? 0;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: player.playerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.username,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 12),
                    ),
                  ),
                  // Team selector chips
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TeamChip(
                        label: 'None',
                        color: AppTheme.textSecondary,
                        isActive: currentTeam == 0,
                        onTap: () =>
                            notifier.assignTeam(player.playerId, 0),
                      ),
                      ...List.generate(4, (i) {
                        final idx = i + 1;
                        return _TeamChip(
                          label: 'T$idx',
                          color: _teamColors[idx]!,
                          isActive: currentTeam == idx,
                          onTap: () =>
                              notifier.assignTeam(player.playerId, idx),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _TeamChip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : color.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Small team badge for use in the overview player cards.
class TeamBadge extends StatelessWidget {
  final int teamIndex;

  const TeamBadge({super.key, required this.teamIndex});

  @override
  Widget build(BuildContext context) {
    if (teamIndex == 0) return const SizedBox.shrink();
    final color = _teamColors[teamIndex] ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _teamLabels[teamIndex] ?? 'T$teamIndex',
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
