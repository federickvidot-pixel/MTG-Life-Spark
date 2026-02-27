import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/match_record.dart';
import '../../core/persistence/providers.dart';
import '../../ui/bento/bento_tile.dart';
import '../../ui/components/ui_app_bar.dart';
import '../../ui/components/ui_surface.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/tokens/spacing_tokens.dart';

class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchRepo = ref.watch(matchRepositoryProvider);
    final recent = matchRepo.getRecentMatches();
    final all = matchRepo.getAllMatches();
    final profile = ref.watch(profileRepositoryProvider).getProfile();

    return Scaffold(
      appBar: const UiAppBar(title: 'Match History'),
      backgroundColor: ColorTokens.backgroundPrimary,
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        children: [
          if (profile != null) ...[
            BentoTile(
              title: 'Lifetime Record',
              accentStrip: true,
              columnSpan: 1,
              child: _LifetimeSummary(
                wins: profile.totalWins,
                losses: profile.totalLosses,
                games: profile.totalGamesPlayed,
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
          ],
          Text(
            'Last 30 Days',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          if (recent.isEmpty)
            _EmptyState(message: 'No matches in the last 30 days.')
          else
            ...recent.map((m) => _MatchCard(match: m)),
          if (all.length > recent.length) ...[
            const SizedBox(height: SpacingTokens.xs),
            UiSurface(
              padding: const EdgeInsets.all(SpacingTokens.md),
              borderRadius: RadiusTokens.radiusMd,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: ColorTokens.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'Older matches have been rolled into your lifetime stats.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: SpacingTokens.xl),
        ],
      ),
    );
  }
}

class _LifetimeSummary extends StatelessWidget {
  final int wins;
  final int losses;
  final int games;

  const _LifetimeSummary({
    required this.wins,
    required this.losses,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    final rate = games == 0 ? 0.0 : wins / games * 100;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SummaryItem(label: 'Games', value: '$games'),
        _SummaryItem(label: 'Wins', value: '$wins', color: ColorTokens.success),
        _SummaryItem(label: 'Losses', value: '$losses', color: ColorTokens.primaryAccent),
        _SummaryItem(
          label: 'Win %',
          value: '${rate.toStringAsFixed(0)}%',
          color: ColorTokens.primaryAccent,
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color ?? ColorTokens.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchRecord match;
  const _MatchCard({required this.match});

  Color get _resultColor {
    if (match.result == 'win') return ColorTokens.success;
    return ColorTokens.primaryAccent;
  }

  String get _resultLabel {
    if (match.result == 'win') return 'WIN';
    if (match.result == 'concede') return 'CONCEDE';
    return 'LOSS';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y');
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: UiSurface(
        padding: const EdgeInsets.all(SpacingTokens.md),
        borderRadius: RadiusTokens.radiusMd,
        borderColor: _resultColor.withValues(alpha: 0.5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.commanderName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.format} · ${match.playerCount} players · ${match.durationMinutes}m',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(match.date),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xxs,
              ),
              decoration: BoxDecoration(
                color: _resultColor.withValues(alpha: 0.15),
                borderRadius: RadiusTokens.radiusSm,
              ),
              child: Text(
                _resultLabel,
                style: TextStyle(
                  color: _resultColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xl),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
