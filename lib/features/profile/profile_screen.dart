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
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/font_tokens.dart';
import '../../ui/tokens/layout_tokens.dart';
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

    final allMatches = matchRepo.getAllMatches().toList();

    final colors = AppColorTokens.of(context);
    return Scaffold(
      appBar: const UiAppBar(),
      backgroundColor: colors.backgroundPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = MediaQuery.sizeOf(context).width < 360;
          return ListView(
        padding: EdgeInsets.all(isNarrow ? LayoutTokens.gr3 : LayoutTokens.gr4),
        children: [
          _ProfileHeader(profile: profile, colors: colors),
          SizedBox(height: LayoutTokens.gr4),
          _XpProgressModule(profile: profile, colors: colors),
          SizedBox(height: LayoutTokens.gr4),
          BentoGrid(
            padding: EdgeInsets.zero,
            crossAxisCount: isNarrow ? 1 : 2,
            tileAspectRatio: isNarrow ? 3.2 : 2.8,
            mainAxisSpacing: LayoutTokens.gr2,
            crossAxisSpacing: LayoutTokens.gr2,
            children: _buildStatsGrid(context, profile, feedbackRepo),
          ),
          SizedBox(height: LayoutTokens.gr4),
          _RecentGamesModule(matches: allMatches, colors: colors),
          SizedBox(height: LayoutTokens.gr5),
        ],
      );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final PlayerProfile profile;
  final AppColorTokens colors;
  const _ProfileHeader({required this.profile, required this.colors});

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
    final size = MediaQuery.sizeOf(context);
    final avatarRadius = (size.width < 360 ? 56.0 : 72.0).clamp(48.0, 72.0);

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
                    color: colors.primaryAccent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: colors.surface,
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
                            color: colors.textPrimary,
                          ),
                    ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(LayoutTokens.gr1),
                  decoration: BoxDecoration(
                    color: colors.primaryAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.backgroundPrimary,
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
        SizedBox(height: LayoutTokens.gr3),
        Text(
          profile.username,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                fontSize: MediaQuery.sizeOf(context).width < 360 ? 20 : null,
              ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SizedBox(height: LayoutTokens.gr1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TierBadge(tier: profile.tier),
            SizedBox(width: LayoutTokens.gr1),
            Text(
              'Level ${profile.level}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
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
  final AppColorTokens colors;
  const _XpProgressModule({required this.profile, required this.colors});

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
      padding: EdgeInsets.all(LayoutTokens.gr3),
      borderRadius: RadiusTokens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XP Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
          ),
          SizedBox(height: LayoutTokens.gr2),
          ClipRRect(
            borderRadius: RadiusTokens.radiusSm,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colors.backgroundSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
            ),
          ),
          SizedBox(height: LayoutTokens.gr1),
          Text(
            '$xpInLevel / $xpNeeded XP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontSize: MediaQuery.sizeOf(context).width < 360 ? 12 : null,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

List<BentoTile> _buildStatsGrid(
    BuildContext context,
    PlayerProfile profile,
    FeedbackRepository feedbackRepo) {
  final colors = AppColorTokens.of(context);
  return [
    BentoTile(
      title: '${profile.totalWins}',
      subtitle: 'Wins',
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '${profile.totalLosses}',
      subtitle: 'Losses',
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '${feedbackRepo.totalMvpVotesGiven}',
      subtitle: 'MVP Votes',
      columnSpan: 1,
      compact: true,
    ),
    BentoTile(
      title: '${feedbackRepo.totalTeamPlayerVotesGiven}',
      subtitle: 'Team Player',
      columnSpan: 1,
      compact: true,
    ),
  ];
}

class _RecentGamesModule extends StatefulWidget {
  final List<MatchRecord> matches;
  final AppColorTokens colors;
  const _RecentGamesModule({required this.matches, required this.colors});

  @override
  State<_RecentGamesModule> createState() => _RecentGamesModuleState();
}

class _RecentGamesModuleState extends State<_RecentGamesModule> {
  bool _expanded = false;

  static const int _initialCount = 5;

  @override
  Widget build(BuildContext context) {
    final matches = widget.matches;
    final hasMore = matches.length > _initialCount;
    final displayed = _expanded
        ? matches
        : matches.take(_initialCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Games',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.colors.textPrimary,
              ),
        ),
        SizedBox(height: LayoutTokens.gr2),
        if (matches.isEmpty)
          UiSurface(
            padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? LayoutTokens.gr3 : LayoutTokens.gr4),
            borderRadius: RadiusTokens.radiusMd,
            child: Center(
              child: Text(
                'No recent matches.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.colors.textSecondary,
                    ),
              ),
            ),
          )
        else ...[
          ...displayed.map((m) => _RecentMatchRow(match: m, colors: widget.colors)),
          if (hasMore)
            Padding(
              padding: EdgeInsets.only(top: LayoutTokens.gr2),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = true),
                  child: Text(
                    _expanded ? 'See less' : 'See more',
                    style: TextStyle(
                      color: widget.colors.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _RecentMatchRow extends StatelessWidget {
  final MatchRecord match;
  final AppColorTokens colors;
  const _RecentMatchRow({required this.match, required this.colors});

  Color get _resultColor {
    if (match.result == 'win') return ColorTokens.success;
    return colors.primaryAccent;
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
      padding: EdgeInsets.only(bottom: LayoutTokens.gr2),
      child: UiSurface(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 360 ? LayoutTokens.gr2 : LayoutTokens.gr3,
          vertical: LayoutTokens.gr2,
        ),
        borderRadius: RadiusTokens.radiusMd,
        borderColor: _resultColor.withValues(alpha: 0.5),
        child: Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Text(
                    _opponentLabel,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.sizeOf(context).width < 360 ? 14 : null,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  SizedBox(height: LayoutTokens.gr0),
                  Text(
                    fmt.format(match.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: FontTokens.sm,
                        ),
                  ),
                ],
                ),
              ),
            ),
            SizedBox(width: LayoutTokens.gr2),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: LayoutTokens.gr2,
                vertical: LayoutTokens.gr1,
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
                  fontSize: MediaQuery.sizeOf(context).width < 360 ? FontTokens.sm : FontTokens.caption,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
