import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/match_record.dart';
import '../../core/models/player_profile.dart';
import '../../core/persistence/feedback_repository.dart';
import '../../core/persistence/providers.dart';
import '../../shared/utils/app_router.dart';
import '../../shared/widgets/tier_badge.dart';
import '../../ui/bento/bento_grid.dart';
import '../../ui/bento/bento_tile.dart';
import '../../ui/components/ui_app_bar.dart';
import '../../ui/components/ui_surface.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/tokens/spacing_tokens.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final matchRepo = ref.watch(matchRepositoryProvider);
    final feedbackRepo = ref.watch(feedbackRepositoryProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final recentMatches = matchRepo.getAllMatches().take(5).toList();

    return Scaffold(
      appBar: UiAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            iconSize: 28,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(12),
              minimumSize: const Size(48, 48),
            ),
            tooltip: 'Achievements',
            onPressed: () => context.push(AppRoutes.achievements),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            iconSize: 28,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(12),
              minimumSize: const Size(48, 48),
            ),
            tooltip: 'Match History',
            onPressed: () => context.push(AppRoutes.history),
          ),
        ],
      ),
      backgroundColor: ColorTokens.backgroundPrimary,
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        children: [
          _ProfileHeader(profile: profile),
          const SizedBox(height: SpacingTokens.md),
          _XpProgressModule(profile: profile),
          const SizedBox(height: SpacingTokens.md),
          BentoGrid(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            tileAspectRatio: 2.8,
            mainAxisSpacing: SpacingTokens.xs,
            crossAxisSpacing: SpacingTokens.xs,
            children: _buildStatsGrid(profile, feedbackRepo),
          ),
          const SizedBox(height: SpacingTokens.md),
          _RecentGamesModule(matches: recentMatches),
          const SizedBox(height: SpacingTokens.xl),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final PlayerProfile profile;
  const _ProfileHeader({required this.profile});

  void _onAvatarTap(BuildContext context) {
    context.push(AppRoutes.profileAvatar);
  }

  String get _initials {
    final parts = profile.username.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    final first = parts.first;
    final last = parts.last;
    if (first.isEmpty || last.isEmpty) return '?';
    return '${first[0]}${last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _onAvatarTap(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorTokens.primaryAccent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
              radius: 72,
              backgroundColor: ColorTokens.surface,
              backgroundImage: profile.profileAvatarImageUrl != null &&
                      profile.profileAvatarImageUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(profile.profileAvatarImageUrl!)
                  : null,
              child: profile.profileAvatarImageUrl != null &&
                      profile.profileAvatarImageUrl!.isNotEmpty
                  ? null
                  : Text(
                      _initials,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ColorTokens.textPrimary,
                          ),
                    ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorTokens.primaryAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorTokens.backgroundPrimary,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Text(
          profile.username,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: ColorTokens.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: SpacingTokens.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TierBadge(tier: profile.tier),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              'Level ${profile.level}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _XpProgressModule extends StatelessWidget {
  final PlayerProfile profile;
  const _XpProgressModule({required this.profile});

  int _xpForCurrentLevel(int level) {
    const thresholds = [(10, 500), (25, 1000), (50, 2000), (75, 3500), (100, 5000)];
    for (final (max, xp) in thresholds) {
      if (level <= max) return xp;
    }
    return 5000;
  }

  @override
  Widget build(BuildContext context) {
    final xpNeeded = _xpForCurrentLevel(profile.level);
    final xpInLevel = profile.xp % xpNeeded;
    final progress = (xpNeeded > 0) ? (xpInLevel / xpNeeded).clamp(0.0, 1.0) : 0.0;

    return UiSurface(
      padding: const EdgeInsets.all(SpacingTokens.md),
      borderRadius: RadiusTokens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XP Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColorTokens.textPrimary,
                ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          ClipRRect(
            borderRadius: RadiusTokens.radiusSm,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: ColorTokens.backgroundSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(ColorTokens.primaryAccent),
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            '$xpInLevel / $xpNeeded XP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorTokens.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

List<BentoTile> _buildStatsGrid(
    PlayerProfile profile, FeedbackRepository feedbackRepo) {
  final totalTies = (profile.totalGamesPlayed - profile.totalWins - profile.totalLosses)
      .clamp(0, 1 << 31);

  return [
    BentoTile(
      title: '${profile.totalWins}',
      subtitle: 'Wins',
      icon: Icon(Icons.emoji_events, size: 14, color: ColorTokens.success.withValues(alpha: 0.8)),
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '${profile.totalLosses}',
      subtitle: 'Losses',
      icon: Icon(Icons.close, size: 14, color: ColorTokens.primaryAccent.withValues(alpha: 0.8)),
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '$totalTies',
      subtitle: 'Ties',
      icon: Icon(Icons.remove, size: 14, color: ColorTokens.textSecondary),
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '${profile.currentWinStreak}',
      subtitle: 'Win Streak',
      icon: Icon(Icons.local_fire_department, size: 14, color: ColorTokens.primaryAccent.withValues(alpha: 0.8)),
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '${feedbackRepo.totalLikesGiven}',
      subtitle: 'Likes Given',
      icon: Icon(Icons.thumb_up, size: 14, color: ColorTokens.success.withValues(alpha: 0.8)),
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '${feedbackRepo.totalMvpVotesGiven}',
      subtitle: 'MVP Votes',
      icon: Icon(Icons.star, size: 14, color: ColorTokens.primaryAccent.withValues(alpha: 0.8)),
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '${feedbackRepo.totalTeamPlayerVotesGiven}',
      subtitle: 'Team Player',
      icon: Icon(Icons.groups, size: 14, color: ColorTokens.primaryAccent.withValues(alpha: 0.8)),
      columnSpan: 1,
      compact: true,
    ),
  ];
}

class _RecentGamesModule extends StatelessWidget {
  final List<MatchRecord> matches;
  const _RecentGamesModule({required this.matches});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Games',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ColorTokens.textPrimary,
              ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        if (matches.isEmpty)
          UiSurface(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            borderRadius: RadiusTokens.radiusMd,
            child: Center(
              child: Text(
                'No recent matches.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorTokens.textSecondary,
                    ),
              ),
            ),
          )
        else
          ...matches.map((m) => _RecentMatchRow(match: m)),
      ],
    );
  }
}

class _RecentMatchRow extends StatelessWidget {
  final MatchRecord match;
  const _RecentMatchRow({required this.match});

  Color get _resultColor {
    if (match.result == 'win') return ColorTokens.success;
    return ColorTokens.primaryAccent;
  }

  String get _resultLabel {
    if (match.result == 'win') return 'Win';
    if (match.result == 'concede') return 'Concede';
    return 'Loss';
  }

  String get _opponentLabel {
    if (match.opponentNames.isNotEmpty) {
      return match.opponentNames.join(', ');
    }
    return 'vs ${match.playerCount} players';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: UiSurface(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        borderRadius: RadiusTokens.radiusMd,
        borderColor: _resultColor.withValues(alpha: 0.5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _opponentLabel,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(match.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorTokens.textSecondary,
                          fontSize: 12,
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
