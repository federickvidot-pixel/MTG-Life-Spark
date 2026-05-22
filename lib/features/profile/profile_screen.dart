import 'dart:convert';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../core/models/commander_stats.dart';
import '../../core/models/match_record.dart';
import '../../core/models/player_deck.dart';
import '../../core/models/player_profile.dart';
import '../../core/persistence/providers.dart';
import '../../shared/utils/app_router.dart';
import '../../shared/utils/commander_image_resolver.dart';
import '../../shared/widgets/deck_tile_visual.dart';
import '../../shared/widgets/mana_cost_pips.dart';
import '../../shared/widgets/tier_badge.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/font_tokens.dart';
import '../../ui/tokens/layout_tokens.dart';
import '../../ui/tokens/motion_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/tokens/typography_tokens.dart';

/// Internal padding of every profile carousel card ([LayoutTokens.gr2]).
/// Inner element radius = RadiusTokens.bento − padding (nested radius rule).
const double _kBentoCardPaddingPx = LayoutTokens.gr2;

/// Outline strength shared by all profile carousel [Card]s.
const double _kBentoCardBorderAlpha = 0.55;

/// When true, profile sections show rich sample data for layout review.
/// Set to false once you want only real Hive data.
const bool _kProfileForcePlaceholderPreview = true;

/// Bundled MTG art when no custom banner is set (from project mana assets).
const String _kDefaultBannerPlaceholderAsset = 'assets/mana/MYB/fullManaCost.png';

BorderRadius get _kBentoRadius => RadiusTokens.radiusBento;

/// Typical phones (≥360 logical width) use tighter horizontal page padding.
const double _kProfileStatsRowBreakpoint = 360;

/// Clamped text scale (1.0 = default) for layout reserves and hero sizing.
double _profileLayoutTextScale(BuildContext context) {
  final t = MediaQuery.textScalerOf(context).scale(1.0);
  if (!t.isFinite || t <= 0) return 1.0;
  return t.clamp(1.0, 1.45);
}

/// Hero banner height from viewport and orientation; stays within [260, 380].
double _profileHeroCardHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final availH = math.max(200.0, size.height - padding.vertical);
  final portrait = size.height >= size.width;
  final ts = _profileLayoutTextScale(context);
  final frac = portrait ? 0.36 : 0.30;
  return (availH * frac * (0.88 + 0.12 * (ts - 1.0))).clamp(260.0, 380.0);
}

int _xpNeededForLevel(int level) {
  const thresholds = [
    (10, 500),
    (25, 1000),
    (50, 2000),
    (75, 3500),
    (100, 5000),
  ];
  for (final (max, xp) in thresholds) {
    if (level <= max) return xp;
  }
  return 5000;
}

Widget _defaultBannerFill(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return ColoredBox(
    color: scheme.surfaceContainer,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerLow,
            scheme.surfaceContainer,
            Color.lerp(scheme.surfaceContainer, scheme.primary, 0.06)!,
          ],
        ),
      ),
    ),
  );
}

Widget _recentMatchCommanderArt(BuildContext context, String? imageUrl) {
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => _defaultBannerFill(context),
      errorWidget: (_, __, ___) => _defaultBannerFill(context),
    );
  }
  return _defaultBannerFill(context);
}

/// Bottom-weighted vignette for text over commander art on recent match cards.
Widget _recentMatchCardVignette({required bool expanded}) {
  if (expanded) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.52),
                Colors.black.withValues(alpha: 0.68),
                Colors.black.withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.15,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.42),
              ],
              stops: const [0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
  // Bottom-only scrim with a long, soft feather into the art.
  return Align(
    alignment: Alignment.bottomCenter,
    child: FractionallySizedBox(
      heightFactor: 0.68,
      widthFactor: 1,
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.04),
              Colors.black.withValues(alpha: 0.14),
              Colors.black.withValues(alpha: 0.32),
              Colors.black.withValues(alpha: 0.58),
              Colors.black.withValues(alpha: 0.82),
            ],
            stops: const [0.0, 0.18, 0.38, 0.58, 0.78, 1.0],
          ),
        ),
      ),
    ),
  );
}

/// Shared [Card] chrome for profile carousel tiles.
RoundedRectangleBorder _profileCarouselCardShape(ColorScheme scheme) {
  return RoundedRectangleBorder(
    borderRadius: _kBentoRadius,
    side: BorderSide(
      color: scheme.outlineVariant.withValues(alpha: _kBentoCardBorderAlpha),
      width: 1,
    ),
  );
}

/// Shared shell for profile carousel tiles (player stats, deck perf, recent games).
class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerHigh,
      elevation: 1,
      surfaceTintColor: scheme.surfaceTint,
      shape: _profileCarouselCardShape(scheme),
      child: Padding(
        padding: EdgeInsets.all(_kBentoCardPaddingPx),
        child: child,
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileWatch = ref.watch(profileProvider);
    final profile = profileWatch.profile;
    final matchRepo = ref.watch(matchRepositoryProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final storedMatches = matchRepo.getAllMatches().toList();
    final hasStoredMatches = storedMatches.isNotEmpty;
    final hasStoredDecks =
        ref.read(deckRepositoryProvider).getAll().isNotEmpty;
    final usePreview = _kProfileForcePlaceholderPreview;
    final displayProfile =
        usePreview ? _previewPlaceholderProfile(profile) : profile;
    final allMatches = (usePreview || !hasStoredMatches)
        ? _previewPlaceholderMatches()
        : storedMatches;
    final isExampleProfile = usePreview;

    final colors = AppColorTokens.of(context);
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = MediaQuery.sizeOf(context).width;
            final screenH = MediaQuery.sizeOf(context).height;
            final raw = constraints.maxWidth;
            final bodyW =
                raw.isFinite && raw > 0 ? raw : screenW.clamp(320.0, 2000.0);
            final isNarrow = bodyW < _kProfileStatsRowBreakpoint;
            final hPad = isNarrow ? LayoutTokens.gr2 : LayoutTokens.gr3;

            final maxH = constraints.maxHeight;
            final layoutTs = _profileLayoutTextScale(context);
            final sectionCardListMaxHeight =
                (MediaQuery.sizeOf(context).height *
                        0.42 *
                        (0.94 + 0.06 * (layoutTs - 1.0)))
                    .clamp(280.0, 560.0);

            final scroll = CustomScrollView(
              key: ValueKey(profileWatch.revision),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    // Match horizontal inset so the banner isn’t flush under SafeArea.
                    padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
                    child: _ProfileHeroCard(
                      profile: displayProfile,
                      colors: colors,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: LayoutTokens.gr4)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, hPad),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PlayerStatsSection(
                        profile: displayProfile,
                        colors: colors,
                        listMaxHeight: sectionCardListMaxHeight,
                        isExampleData: isExampleProfile,
                        previewTopCommander: usePreview
                            ? _previewPlaceholderTopCommander()
                            : null,
                        previewWorstDeck: usePreview
                            ? _previewPlaceholderWorstDeck()
                            : null,
                      ),
                      SizedBox(height: LayoutTokens.gr4),
                      _DeckPerformanceSection(
                        colors: colors,
                        listMaxHeight: sectionCardListMaxHeight,
                        usePlaceholderDecks: usePreview || !hasStoredDecks,
                      ),
                      SizedBox(height: LayoutTokens.gr4),
                      _RecentGamesModule(
                        matches: allMatches,
                        isExampleData: isExampleProfile || !hasStoredMatches,
                        colors: colors,
                        listMaxHeight: sectionCardListMaxHeight,
                      ),
                      SizedBox(height: LayoutTokens.gr4),
                    ]),
                  ),
                ),
              ],
            );

            if (maxH.isFinite && maxH > 0) {
              return scroll;
            }
            return SizedBox(
              height: screenH,
              width: double.infinity,
              child: scroll,
            );
          },
        ),
      ),
    );
  }
}

String _formatProfileStat(int n) => NumberFormat.decimalPattern().format(n);

/// Rounded hero card: banner art, banner action, floating stats pill.
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.profile,
    required this.colors,
  });

  final PlayerProfile profile;
  final AppColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final cardHeight = _profileHeroCardHeight(context);
    void onBanner() => context.push(AppRoutes.profileBanner);

    Widget background() {
      final url = profile.profileBannerImageUrl;
      if (url != null && url.isNotEmpty) {
        return CachedNetworkImage(
          key: ValueKey(url),
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: cardHeight,
          placeholder: (ctx, _) => _defaultBannerFill(ctx),
          errorWidget: (ctx, _, __) => _defaultBannerFill(ctx),
        );
      }
      return Image.asset(
        _kDefaultBannerPlaceholderAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: cardHeight,
        errorBuilder: (ctx, _, __) => _defaultBannerFill(ctx),
      );
    }

    return ClipRRect(
      borderRadius: RadiusTokens.radiusBento,
      child: SizedBox(
        height: cardHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: background()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: (cardHeight * 0.52).clamp(96.0, 200.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Semantics(
                button: true,
                label: 'Change profile banner',
                child: Material(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onBanner,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wallpaper_outlined,
                            color: ColorTokens.onAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Banner',
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: ColorTokens.onAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _ProfileHeroIdentityAndStats(
                profile: profile,
                colors: colors,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name + tier badge above the stats pill (inside hero gradient). Rank is shown under Level progress.
class _ProfileHeroIdentityAndStats extends StatelessWidget {
  const _ProfileHeroIdentityAndStats({
    required this.profile,
    required this.colors,
  });

  final PlayerProfile profile;
  final AppColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          profile.username,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ColorTokens.onAccent,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 12,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(height: LayoutTokens.gr0),
        Center(child: TierBadge(tier: profile.tier, level: profile.level)),
        SizedBox(height: LayoutTokens.gr2),
        _ProfileFloatingStatsPill(profile: profile),
      ],
    );
  }
}

/// Dark pill: value + label per stat, no dividers.
class _ProfileFloatingStatsPill extends StatelessWidget {
  const _ProfileFloatingStatsPill({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      (_formatProfileStat(profile.totalWins), 'Wins'),
      (_formatProfileStat(profile.honorsMvpReceived), 'MVP'),
      (_formatProfileStat(profile.honorsTeamPlayerReceived), 'Team'),
      (_formatProfileStat(profile.honorsUnderdogReceived), 'Underdog'),
    ];

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final item in items)
              Expanded(child: _StatColumn(value: item.$1, shortLabel: item.$2)),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.shortLabel});

  final String value;
  final String shortLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: ColorTokens.onAccent,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shortLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Counts XP-in-level numerals so the label matches the progress bar animation.
class _AnimatedXpInLevelLabel extends StatefulWidget {
  const _AnimatedXpInLevelLabel({
    required this.targetXpInLevel,
    required this.xpNeeded,
    required this.level,
    required this.style,
  });

  final int targetXpInLevel;
  final int xpNeeded;
  final int level;
  final TextStyle? style;

  @override
  State<_AnimatedXpInLevelLabel> createState() =>
      _AnimatedXpInLevelLabelState();
}

class _AnimatedXpInLevelLabelState extends State<_AnimatedXpInLevelLabel>
    with SingleTickerProviderStateMixin {
  static const _duration = MotionTokens.emphasis;

  late final AnimationController _controller;
  Animation<double> _value = const AlwaysStoppedAnimation<double>(0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _value = Tween<double>(
      begin: 0,
      end: widget.targetXpInLevel.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedXpInLevelLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bandChanged =
        oldWidget.level != widget.level ||
        oldWidget.xpNeeded != widget.xpNeeded;
    if (bandChanged) {
      _value = Tween<double>(
        begin: 0,
        end: widget.targetXpInLevel.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
      return;
    }
    if (oldWidget.targetXpInLevel != widget.targetXpInLevel) {
      final from = _value.value.clamp(0.0, 1e9);
      _value = Tween<double>(
        begin: from,
        end: widget.targetXpInLevel.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shown = _value.value.round().clamp(0, widget.xpNeeded);
        return Text(
          '$shown / ${widget.xpNeeded} XP',
          style: widget.style,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

/// Highest-volume commander from hive stats with deck art when possible.
/// Fixed-size bento tile for the player stats horizontal carousel.
class _PlayerStatsBentoTile extends StatelessWidget {
  const _PlayerStatsBentoTile({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _BentoCard(child: child),
    );
  }
}

/// Rich sample profile for layout preview ([_kProfileForcePlaceholderPreview]).
PlayerProfile _previewPlaceholderProfile(PlayerProfile real) {
  return PlayerProfile(
    username: real.username.trim().isNotEmpty ? real.username : 'Planeswalker',
    level: 24,
    xp: 1650,
    tier: 'Gold',
    totalWins: 47,
    totalLosses: 31,
    totalGamesPlayed: 78,
    likesReceived: 42,
    dislikesReceived: 9,
    honorsMvpReceived: 6,
    honorsTeamPlayerReceived: 4,
    honorsUnderdogReceived: 3,
    lifetimePoisonDealt: 18,
    lifetimeCommanderKills: 11,
    currentWinStreak: 3,
    profileBannerImageUrl: _kMostPlayedPlaceholderImageUrl,
    selectedCommanderName: _kMostPlayedPlaceholderCommander,
    selectedCommanderImageUrl: _kMostPlayedPlaceholderImageUrl,
  );
}

CommanderStats _previewPlaceholderTopCommander() => CommanderStats(
      commanderName: _kMostPlayedPlaceholderCommander,
      wins: 12,
      losses: 7,
      gamesPlayed: 19,
    );

/// Deck with the lowest win rate among decks with at least one recorded game.
PlayerDeck? _pickWorstDeck(Iterable<PlayerDeck> decks) {
  final played = decks.where((d) => d.gamesPlayed > 0).toList();
  if (played.isEmpty) return null;
  played.sort((a, b) {
    final wr = a.winRate.compareTo(b.winRate);
    if (wr != 0) return wr;
    final lossCmp = b.losses.compareTo(a.losses);
    if (lossCmp != 0) return lossCmp;
    return a.wins.compareTo(b.wins);
  });
  return played.first;
}

class _PlayerStatsSection extends ConsumerWidget {
  const _PlayerStatsSection({
    required this.profile,
    required this.colors,
    required this.listMaxHeight,
    this.isExampleData = false,
    this.previewTopCommander,
    this.previewWorstDeck,
  });

  final PlayerProfile profile;
  final AppColorTokens colors;
  final double listMaxHeight;
  final bool isExampleData;
  final CommanderStats? previewTopCommander;
  final PlayerDeck? previewWorstDeck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(deckListRevisionProvider);
    final repoDecks = ref.watch(deckRepositoryProvider).getAll();
    final xpNeeded = _xpNeededForLevel(profile.level);
    final xpInLevel = profile.xp % xpNeeded;
    final xpProgress =
        (xpNeeded > 0) ? (xpInLevel / xpNeeded).clamp(0.0, 1.0) : 0.0;

    final stats =
        List<CommanderStats>.from(
          ref.watch(profileRepositoryProvider).getAllCommanderStats(),
        )..sort((a, b) {
          final g = b.gamesPlayed.compareTo(a.gamesPlayed);
          if (g != 0) return g;
          return b.wins.compareTo(a.wins);
        });
    CommanderStats? top = previewTopCommander;
    if (top == null &&
        stats.isNotEmpty &&
        stats.first.gamesPlayed > 0) {
      top = stats.first;
    }

    PlayerDeck? worst = previewWorstDeck;
    if (worst == null) {
      worst = _pickWorstDeck(repoDecks);
    }

    final titleStyle = TypographyTokens.sectionTitle(colors.textPrimary);

    return LayoutBuilder(
      builder: (context, _) {
        final cardHeight =
            _profilePlayerStatsCardHeight(context, listMaxHeight);
        final cardWidth = _kDeckPerfCardWidth;

        final tiles = <Widget>[
          _PlayerStatsBentoTile(
            width: cardWidth,
            height: cardHeight,
            child: _LevelDonutCard(
              profile: profile,
              colors: colors,
              xpNeeded: xpNeeded,
              xpInLevel: xpInLevel,
              xpProgress: xpProgress,
              fillHeight: true,
            ),
          ),
          _PlayerStatsBentoTile(
            width: cardWidth,
            height: cardHeight,
            child: _BehaviourBarCard(
              profile: profile,
              colors: colors,
              fillHeight: true,
            ),
          ),
          _PlayerStatsBentoTile(
            width: cardWidth,
            height: cardHeight,
            child: _MostPlayedBentoCard(
              profile: profile,
              colors: colors,
              top: top,
            ),
          ),
          _PlayerStatsBentoTile(
            width: cardWidth,
            height: cardHeight,
            child: _WorstDeckBentoCard(
              profile: profile,
              colors: colors,
              deck: worst,
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Player stats', style: titleStyle),
            if (isExampleData) ...[
              SizedBox(height: LayoutTokens.gr0),
              Text(
                'Example stats — play games to track your real progress.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            SizedBox(height: LayoutTokens.gr2),
            SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemCount: tiles.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: LayoutTokens.gr2),
                itemBuilder: (_, i) => tiles[i],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Preview art/stats for Most played when no commander history exists yet.
const String _kMostPlayedPlaceholderImageUrl =
    'https://cards.scryfall.io/art_crop/front/1/0/10d42b35-844f-4a64-9981-c6118d45e826.jpg?1689999317';
const String _kMostPlayedPlaceholderCommander = 'The Ur-Dragon';
const String _kMostPlayedPlaceholderStatsLine = '12W · 7L · 19 games';

/// Preview art/stats for Worst deck when no deck record qualifies yet.
const String _kWorstDeckPlaceholderImageUrl =
    'https://cards.scryfall.io/art_crop/front/f/e/fe9be3e0-076c-4703-9750-2a6b0a178bc9.jpg?1761053654';
const String _kWorstDeckPlaceholderLabel = 'Yuriko turns';
const String _kWorstDeckPlaceholderStatsLine = '6W · 5L · 11 games';

/// Shared layout for Most played / Worst deck player-stats tiles.
class _PlayerStatsHighlightBentoCard extends StatelessWidget {
  const _PlayerStatsHighlightBentoCard({
    required this.title,
    required this.infoMessage,
    required this.colors,
    required this.primaryLabel,
    required this.statsLine,
    required this.imageUrl,
  });

  final String title;
  final String infoMessage;
  final AppColorTokens colors;
  final String primaryLabel;
  final String statsLine;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final innerRadius = RadiusTokens.bento - _kBentoCardPaddingPx;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BentoSectionHeader(
          title: title,
          colors: colors,
          infoMessage: infoMessage,
        ),
        SizedBox(height: LayoutTokens.gr2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(innerRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null && imageUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _defaultBannerFill(context),
                          errorWidget: (_, __, ___) =>
                              _defaultBannerFill(context),
                        )
                      else
                        _defaultBannerFill(context),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: LayoutTokens.gr1),
              Text(
                primaryLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.15,
                ),
              ),
              SizedBox(height: LayoutTokens.gr0),
              Text(
                statsLine,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MostPlayedBentoCard extends ConsumerWidget {
  const _MostPlayedBentoCard({
    required this.profile,
    required this.colors,
    required this.top,
  });

  final PlayerProfile profile;
  final AppColorTokens colors;
  final CommanderStats? top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaceholder = top == null;
    final commander = top;

    String? imageUrl;
    if (isPlaceholder) {
      imageUrl = _kMostPlayedPlaceholderImageUrl;
    } else {
      final decks = ref.watch(deckRepositoryProvider).getAll();
      for (final d in decks) {
        if (d.commanderName.toLowerCase() ==
            commander!.commanderName.toLowerCase()) {
          imageUrl = resolveDeckCommanderImageUrl(deck: d, profile: profile);
          break;
        }
      }
      imageUrl ??= profile.selectedCommanderImageUrl;
    }

    final commanderName =
        commander?.commanderName ?? _kMostPlayedPlaceholderCommander;
    final statsLine = commander != null
        ? '${commander.wins}W · ${commander.losses}L · ${commander.gamesPlayed} games'
        : _kMostPlayedPlaceholderStatsLine;

    return _PlayerStatsHighlightBentoCard(
      title: 'Most played',
      infoMessage:
          'Commander you have played the most games with across recorded matches.',
      colors: colors,
      primaryLabel: commanderName,
      statsLine: statsLine,
      imageUrl: imageUrl,
    );
  }
}

class _WorstDeckBentoCard extends ConsumerWidget {
  const _WorstDeckBentoCard({
    required this.profile,
    required this.colors,
    required this.deck,
  });

  final PlayerProfile profile;
  final AppColorTokens colors;
  final PlayerDeck? deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = deck;
    final isPlaceholder = d == null;
    final String? imageUrl = isPlaceholder
        ? _kWorstDeckPlaceholderImageUrl
        : resolveDeckCommanderImageUrl(deck: d!, profile: profile);
    final primaryLabel = d?.displayName ?? _kWorstDeckPlaceholderLabel;
    final statsLine = d != null
        ? '${d.wins}W · ${d.losses}L · ${d.gamesPlayed} games'
        : _kWorstDeckPlaceholderStatsLine;

    return _PlayerStatsHighlightBentoCard(
      title: 'Tough record',
      infoMessage:
          'Saved deck with the lowest win rate among decks with at least one recorded game.',
      colors: colors,
      primaryLabel: primaryLabel,
      statsLine: statsLine,
      imageUrl: imageUrl,
    );
  }
}

/// 0 = Good, 1 = Salty (from dislike ratio among reactions).
double _saltFraction(PlayerProfile profile) {
  final total = profile.likesReceived + profile.dislikesReceived;
  if (total == 0) return 0.5;
  return (profile.dislikesReceived / total).clamp(0.0, 1.0);
}

IconData _behaviourSmileyIcon(double salt) {
  if (salt < 0.28) return Icons.sentiment_very_satisfied_rounded;
  if (salt < 0.42) return Icons.sentiment_satisfied_alt_rounded;
  if (salt < 0.58) return Icons.sentiment_neutral_rounded;
  if (salt < 0.72) return Icons.sentiment_dissatisfied_rounded;
  return Icons.sentiment_very_dissatisfied_rounded;
}

Color _behaviourSmileyColor(double salt, AppColorTokens colors) {
  return Color.lerp(
        colors.textMuted,
        colors.primaryAccent,
        salt,
      ) ??
      colors.textPrimary;
}

/// Sentiment icon for the behaviour card (centered separately from the track).
Widget _behaviourSmileyMark({
  required PlayerProfile profile,
  required AppColorTokens colors,
}) {
  final salt = _saltFraction(profile);
  const double dp = 44.0;
  return Icon(
    _behaviourSmileyIcon(salt),
    size: dp,
    color: _behaviourSmileyColor(salt, colors),
    shadows: [
      Shadow(
        color: colors.backgroundPrimary.withValues(alpha: 0.9),
        blurRadius: 2,
      ),
    ],
  );
}

/// Gradient spectrum track + thumb only; [width] must be finite and positive.
Widget _behaviourSpectrumTrack({
  required PlayerProfile profile,
  required AppColorTokens colors,
  required double width,
}) {
  final salt = _saltFraction(profile);
  final w =
      width.isFinite && width > 0 ? width : 280.0;
  const double sideInset = 16.0;
  final double trackUsableW = math.max(0.0, w - 2 * sideInset);
  const double barHeight = 14.0;
  const double thumbSize = 18.0;
  final double knobCenterX = sideInset + trackUsableW * salt;
  final double knobLeft = (knobCenterX - thumbSize / 2).clamp(
    0.0,
    math.max(0.0, w - thumbSize),
  );
  final double h = thumbSize;
  final double barTop = (thumbSize - barHeight) / 2;

  return SizedBox(
    width: w,
    height: h,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        Positioned(
          left: 0,
          top: barTop,
          child: Container(
            width: w,
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colors.borderSubtle.withValues(alpha: 0.55),
                width: 1,
              ),
              gradient: LinearGradient(
                colors: [
                  colors.textMuted,
                  colors.textSecondary,
                  colors.primaryAccent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: knobLeft,
          top: 0,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              color: colors.textPrimary,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.backgroundPrimary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

void _showBentoSectionInfo(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showAdaptiveDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog.adaptive(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Title + info icon row shared by Level and Behaviour bento cards so headers
/// line up when the two cards sit side-by-side (same min height, top alignment).
class _BentoSectionHeader extends StatelessWidget {
  const _BentoSectionHeader({
    required this.title,
    required this.infoMessage,
    required this.colors,
    this.titleMaxLines = 1,
  });

  final String title;
  final String infoMessage;
  final AppColorTokens colors;
  final int titleMaxLines;

  static const double _minRowHeight = 36;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minRowHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: titleMaxLines,
              overflow: TextOverflow.ellipsis,
              style: TypographyTokens.cardTitle(colors.textPrimary),
            ),
          ),
          IconButton(
            onPressed: () => _showBentoSectionInfo(
              context,
              title: title,
              message: infoMessage,
            ),
            icon: Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: colors.textSecondary,
            ),
            tooltip: infoMessage,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.all(LayoutTokens.gr1),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _LevelDonutCard extends StatelessWidget {
  const _LevelDonutCard({
    required this.profile,
    required this.colors,
    required this.xpNeeded,
    required this.xpInLevel,
    required this.xpProgress,
    this.fillHeight = false,
  });

  final PlayerProfile profile;
  final AppColorTokens colors;
  final int xpNeeded;
  final int xpInLevel;
  final double xpProgress;
  /// When true (wide side-by-side row), middle content expands to match sibling card height.
  final bool fillHeight;

  /// Reserve for the `… / … XP` line at the bottom of the card (fill-height layout).
  static const double _kBottomXpLabelReserveH = 24.0;

  static const double _kDonutSizeMin = 56.0;
  static const double _kDonutSizeMax = 164.0;
  static const double _kDonutStrokeReferenceSize = 140.0;

  /// Donut + center (% + level) only; stroke scales with [size].
  Widget _donutGaugeOnly(BuildContext context, double size) {
    final stroke =
        (size / _kDonutStrokeReferenceSize * 12).clamp(8.0, 14.0);
    return Center(
      child: _AnimatedDonutGauge(
        targetProgress: xpProgress,
        size: size,
        strokeWidth: stroke,
        trackColor: colors.backgroundSecondary.withValues(alpha: 0.95),
        progressColor: colors.primaryAccent,
        centerBuilder: (ctx, t) {
          final pct = (t * 100).round().clamp(0, 100);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: size < 100 ? 17 : 20,
                ),
              ),
              Text(
                'Lv ${profile.level}',
                style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _xpNumeralsLine(BuildContext context) {
    return Center(
      child: _AnimatedXpInLevelLabel(
        targetXpInLevel: xpInLevel,
        xpNeeded: xpNeeded,
        level: profile.level,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BentoSectionHeader(
          title: 'Level progress',
          colors: colors,
          infoMessage:
              'XP in your current level fills the ring. Reach 100% for the next level band.',
        ),
        SizedBox(height: LayoutTokens.gr2),
        if (fillHeight)
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final layoutTs = _profileLayoutTextScale(context);
                final bottomReserve = _kBottomXpLabelReserveH * layoutTs;
                final widthLimit = c.maxWidth.isFinite && c.maxWidth > 0
                    ? c.maxWidth
                    : _kDonutSizeMax;
                final heightLimit =
                    math.max(0.0, c.maxHeight - bottomReserve);
                final donutSize = math
                    .min(widthLimit, heightLimit)
                    .clamp(_kDonutSizeMin, _kDonutSizeMax);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _donutGaugeOnly(context, donutSize),
                        ),
                      ),
                    ),
                    _xpNumeralsLine(context),
                  ],
                );
              },
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _donutGaugeOnly(context, _kDonutSizeMax),
              SizedBox(height: LayoutTokens.gr2),
              _xpNumeralsLine(context),
            ],
          ),
      ],
    );
  }
}

class _BehaviourBarCard extends StatelessWidget {
  const _BehaviourBarCard({
    required this.profile,
    required this.colors,
    this.fillHeight = false,
  });

  final PlayerProfile profile;
  final AppColorTokens colors;
  /// When true (wide row), spectrum block expands so the bento matches level progress height.
  final bool fillHeight;

  /// Smiley (44) + spectrum track (20) + axis row + reaction line — remainder split evenly.
  static const double _kFillBehaviourCoreH = 100.0;
  static const int _kFillBehaviourBandGaps = 4;

  static double _fillBehaviourBandGap(double maxHeight, double layoutTextScale) {
    final core = _kFillBehaviourCoreH * layoutTextScale;
    final slack = maxHeight - core;
    final raw = slack / _kFillBehaviourBandGaps;
    if (!raw.isFinite) return LayoutTokens.gr1;
    return math.max(0.0, raw);
  }

  @override
  Widget build(BuildContext context) {
    Widget axisRow() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Good',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FontTokens.sm,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Neutral',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FontTokens.sm,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Salty',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FontTokens.sm,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    Widget reactionsLine() {
      return Text(
        '${profile.likesReceived} likes · ${profile.dislikesReceived} dislikes',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
          fontSize: FontTokens.caption,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BentoSectionHeader(
          title: 'Player behaviour',
          colors: colors,
          infoMessage:
              'Position on the spectrum reflects reactions from others—more dislikes shifts toward Salty.',
        ),
        SizedBox(height: LayoutTokens.gr2),
        if (fillHeight)
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final w =
                    c.maxWidth.isFinite && c.maxWidth > 0 ? c.maxWidth : 280.0;
                final bandGap = _fillBehaviourBandGap(
                  c.maxHeight,
                  _profileLayoutTextScale(context),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: bandGap),
                    Center(
                      child: _behaviourSmileyMark(
                        profile: profile,
                        colors: colors,
                      ),
                    ),
                    SizedBox(height: bandGap),
                    _behaviourSpectrumTrack(
                      profile: profile,
                      colors: colors,
                      width: w,
                    ),
                    SizedBox(height: bandGap),
                    axisRow(),
                    SizedBox(height: bandGap),
                    reactionsLine(),
                  ],
                );
              },
            ),
          )
        else ...[
          Center(
            child: _behaviourSmileyMark(
              profile: profile,
              colors: colors,
            ),
          ),
          SizedBox(height: LayoutTokens.gr1),
          LayoutBuilder(
            builder: (context, c) {
              final w =
                  c.maxWidth.isFinite && c.maxWidth > 0 ? c.maxWidth : 280.0;
              return _behaviourSpectrumTrack(
                profile: profile,
                colors: colors,
                width: w,
              );
            },
          ),
          SizedBox(height: LayoutTokens.gr1),
          axisRow(),
          SizedBox(height: LayoutTokens.gr1),
          reactionsLine(),
        ],
      ],
    );
  }
}

class _DonutRingPainter extends CustomPainter {
  _DonutRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 11,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    final track =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    final arc =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * p, false, arc);
  }

  @override
  bool shouldRepaint(covariant _DonutRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Animated donut; [targetProgress] in 0–1.
class _AnimatedDonutGauge extends StatefulWidget {
  const _AnimatedDonutGauge({
    required this.targetProgress,
    required this.trackColor,
    required this.progressColor,
    required this.centerBuilder,
    this.size = 120,
    this.strokeWidth = 11,
  });

  final double targetProgress;
  final Color trackColor;
  final Color progressColor;
  final Widget Function(BuildContext context, double animatedT) centerBuilder;
  final double size;
  final double strokeWidth;

  @override
  State<_AnimatedDonutGauge> createState() => _AnimatedDonutGaugeState();
}

class _AnimatedDonutGaugeState extends State<_AnimatedDonutGauge>
    with SingleTickerProviderStateMixin {
  static const _duration = MotionTokens.emphasis;

  late final AnimationController _controller;
  Animation<double> _fill = const AlwaysStoppedAnimation<double>(0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _fill = Tween<double>(
      begin: 0,
      end: widget.targetProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedDonutGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetProgress != widget.targetProgress) {
      final from = _fill.value.clamp(0.0, 1.0);
      _fill = Tween<double>(begin: from, end: widget.targetProgress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = _fill.value.clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _DonutRingPainter(
                  progress: v,
                  trackColor: widget.trackColor,
                  progressColor: widget.progressColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              widget.centerBuilder(context, v),
            ],
          );
        },
      ),
    );
  }
}

/// Time window for Recent Games list filtering.
enum _RecentGamesTimeFilter {
  all,
  recent,
  thisWeek,
  thisMonth,
}

extension _RecentGamesTimeFilterLabel on _RecentGamesTimeFilter {
  String get menuLabel => switch (this) {
    _RecentGamesTimeFilter.all => 'All games',
    _RecentGamesTimeFilter.recent => 'Recent (14 days)',
    _RecentGamesTimeFilter.thisWeek => 'This week',
    _RecentGamesTimeFilter.thisMonth => 'This month',
  };
}

DateTime _startOfLocalWeekMonday(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.weekday - DateTime.monday;
  return day.subtract(Duration(days: diff));
}

List<MatchRecord> _filterMatchesForRecentGames(
  List<MatchRecord> matches,
  _RecentGamesTimeFilter filter,
) {
  final sorted = List<MatchRecord>.from(matches)
    ..sort((a, b) => b.date.compareTo(a.date));
  final now = DateTime.now();
  switch (filter) {
    case _RecentGamesTimeFilter.all:
      return sorted;
    case _RecentGamesTimeFilter.recent:
      final startOfToday = DateTime(now.year, now.month, now.day);
      final cutoff = startOfToday.subtract(const Duration(days: 14));
      return sorted.where((m) => !m.date.isBefore(cutoff)).toList();
    case _RecentGamesTimeFilter.thisWeek:
      final start = _startOfLocalWeekMonday(now);
      return sorted.where((m) => !m.date.isBefore(start)).toList();
    case _RecentGamesTimeFilter.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      return sorted.where((m) => !m.date.isBefore(start)).toList();
  }
}

Color _recentMatchResultColor(MatchRecord m, AppColorTokens colors) {
  if (m.result == 'win') return ColorTokens.success;
  return colors.primaryAccent;
}

String _recentMatchResultLabel(MatchRecord m) {
  if (m.result == 'win') return 'Win';
  if (m.result == 'concede') return 'Concede';
  return 'Loss';
}

String _recentMatchPlayerInitials(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  final parts = t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return t.length >= 2 ? t.substring(0, 2).toUpperCase() : t.toUpperCase();
}

Widget _recentMatchDetailRow(
  BuildContext context,
  AppColorTokens colors,
  String label,
  String value, {
  bool compact = false,
}) {
  final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
    color: colors.textSecondary,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    fontSize: compact ? FontTokens.caption : null,
  );
  final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: colors.textPrimary,
    fontWeight: FontWeight.w600,
    fontSize: compact ? FontTokens.sm : null,
    height: compact ? 1.25 : null,
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      SizedBox(height: compact ? LayoutTokens.gr0 : LayoutTokens.gr1),
      Text(
        value,
        style: valueStyle,
        maxLines: compact ? 2 : 3,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

class _RecentGamesModule extends StatefulWidget {
  final List<MatchRecord> matches;
  final bool isExampleData;
  final AppColorTokens colors;
  final double listMaxHeight;

  const _RecentGamesModule({
    required this.matches,
    this.isExampleData = false,
    required this.colors,
    required this.listMaxHeight,
  });

  @override
  State<_RecentGamesModule> createState() => _RecentGamesModuleState();
}

class _RecentGamesModuleState extends State<_RecentGamesModule> {
  _RecentGamesTimeFilter _filter = _RecentGamesTimeFilter.all;
  late final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RecentGamesModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.matches.isEmpty && _filter != _RecentGamesTimeFilter.all) {
      setState(() => _filter = _RecentGamesTimeFilter.all);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final lh = widget.listMaxHeight;
    final filtered = _filterMatchesForRecentGames(widget.matches, _filter);
    final showFilterMenu = widget.matches.isNotEmpty;

    final titleStyle = TypographyTokens.sectionTitle(c.textPrimary);

    Widget titleRow() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Recent games',
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showFilterMenu && !widget.isExampleData)
                PopupMenuButton<_RecentGamesTimeFilter>(
                  tooltip: 'Filter: ${_filter.menuLabel}',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: kMinInteractiveDimension,
                    minHeight: kMinInteractiveDimension,
                  ),
                  onSelected: (v) => setState(() => _filter = v),
                  icon: Icon(
                    Icons.filter_list_rounded,
                    size: 22,
                    color: c.primaryAccent,
                  ),
                  itemBuilder: (context) => [
                    for (final f in _RecentGamesTimeFilter.values)
                      CheckedPopupMenuItem<_RecentGamesTimeFilter>(
                        value: f,
                        checked: f == _filter,
                        child: Text(f.menuLabel),
                      ),
                  ],
                ),
            ],
          ),
          if (widget.isExampleData)
            Padding(
              padding: const EdgeInsets.only(top: LayoutTokens.gr0),
              child: Text(
                'Example matches — play a game to see your real history.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
        ],
      );
    }

    Widget emptyBody(String message) {
      return SizedBox(
        height: 148,
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: c.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (widget.matches.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleRow(),
          SizedBox(height: LayoutTokens.gr2),
          emptyBody('No recent matches.'),
        ],
      );
    }

    if (filtered.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleRow(),
          SizedBox(height: LayoutTokens.gr2),
          emptyBody('No matches for this filter.'),
        ],
      );
    }

    final cardHeight = _profileSectionHorizontalCardHeight(context, lh);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleRow(),
        SizedBox(height: LayoutTokens.gr2),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(width: LayoutTokens.gr2),
            itemBuilder: (context, i) {
              return _RecentMatchCard(
                key: ValueKey<String>(filtered[i].matchId),
                match: filtered[i],
                colors: c,
                width: _kDeckPerfCardWidth,
                height: cardHeight,
              );
            },
          ),
        ),
      ],
    );
  }
}

String _formatDurationSeconds(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Readable match structure for Recent Games (uses [MatchRecord.matchTypeLabel]).
String _recentMatchStructureLine(MatchRecord m) {
  final raw = m.matchTypeLabel;
  final label = raw
      .replaceAll('1vs1', '1 vs 1')
      .replaceAll('2vs2', '2 vs 2');
  final n =
      m.participantSnapshots.isNotEmpty
          ? m.participantSnapshots.length
          : m.playerCount;
  if (n >= 2) return '$label · $n players';
  return label;
}

int _recentMatchPlayerCount(MatchRecord m) {
  if (m.participantSnapshots.isNotEmpty) {
    return m.participantSnapshots.length;
  }
  return m.playerCount;
}

/// Best-effort winner row for profile recent-game tiles ([MatchRecord.result]
/// is from the local player's perspective).
MatchParticipantSnapshot? _winnerParticipantForRecentCard(
  MatchRecord m,
  PlayerProfile? profile,
) {
  final snaps = m.participantSnapshots;
  if (snaps.isEmpty) return null;

  MatchParticipantSnapshot? localSnap;
  final un = profile?.username.trim().toLowerCase();
  for (final p in snaps) {
    final pn = p.username.trim().toLowerCase();
    if (un != null && un.isNotEmpty && pn == un) {
      localSnap = p;
      break;
    }
    if (p.playerId == 'local') {
      localSnap = p;
      break;
    }
  }
  localSnap ??= snaps.first;

  if (m.result == 'win') {
    return localSnap;
  }
  for (final p in snaps) {
    if (p.playerId != localSnap.playerId) return p;
  }
  return snaps.length > 1 ? snaps[1] : localSnap;
}

bool _participantSnapshotIsLocal(
  MatchParticipantSnapshot p,
  PlayerProfile? profile,
) {
  if (profile != null &&
      p.username.trim().toLowerCase() ==
          profile.username.trim().toLowerCase()) {
    return true;
  }
  return p.playerId == 'local';
}

/// Commander art for recent-game tiles: snapshot URL, then saved deck lookup.
String? _resolveCommanderImageForRecentCard(
  WidgetRef ref,
  MatchParticipantSnapshot? participant,
  MatchRecord match,
  PlayerProfile? profile,
) {
  if (participant == null) return null;

  final stored = participant.commanderImageUrl?.trim();
  if (stored != null && stored.isNotEmpty) return stored;

  final commander = participant.commanderName?.trim();
  if (commander != null && commander.isNotEmpty) {
    final decks = ref.read(deckRepositoryProvider).getAll();
    for (final d in decks) {
      if (d.commanderName.toLowerCase() == commander.toLowerCase()) {
        final url = d.commanderImageUrl?.trim();
        if (url != null && url.isNotEmpty) return url;
      }
    }
  }

  if (_participantSnapshotIsLocal(participant, profile)) {
    final deckId = match.localDeckIdSnapshot?.trim();
    if (deckId != null && deckId.isNotEmpty) {
      final deck = ref.read(deckRepositoryProvider).getById(deckId);
      final url = deck?.commanderImageUrl?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
    final selected = profile?.selectedCommanderImageUrl?.trim();
    if (selected != null && selected.isNotEmpty) return selected;
  }

  return null;
}

Widget _winnerProfileCircle({
  required BuildContext context,
  required MatchParticipantSnapshot? winner,
  required ColorScheme scheme,
  required AppColorTokens colors,
  required double diameter,
  String? imageUrl,
}) {
  final initials = winner == null
      ? '?'
      : _recentMatchPlayerInitials(
          (winner.commanderName != null &&
                  winner.commanderName!.trim().isNotEmpty)
              ? winner.commanderName!
              : winner.username,
        );
  final trimmed = imageUrl?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: trimmed,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        placeholder: (_, __) => _winnerInitialsDisk(
          scheme: scheme,
          colors: colors,
          diameter: diameter,
          initials: initials,
        ),
        errorWidget: (_, __, ___) => _winnerInitialsDisk(
          scheme: scheme,
          colors: colors,
          diameter: diameter,
          initials: initials,
        ),
      ),
    );
  }
  return _winnerInitialsDisk(
    scheme: scheme,
    colors: colors,
    diameter: diameter,
    initials: initials,
  );
}

Widget _winnerInitialsDisk({
  required ColorScheme scheme,
  required AppColorTokens colors,
  required double diameter,
  required String initials,
}) {
  final fs = (diameter * 0.32).clamp(18.0, 30.0);
  return Container(
    width: diameter,
    height: diameter,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: scheme.secondaryContainer.withValues(alpha: 0.65),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.55),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.textPrimary.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: TextStyle(
        fontSize: fs,
        fontWeight: FontWeight.w800,
        color: scheme.onSecondaryContainer,
        letterSpacing: -0.5,
      ),
    ),
  );
}

/// One match: collapsed summary; tap expands to full details (horizontal list).
class _RecentMatchCard extends ConsumerStatefulWidget {
  const _RecentMatchCard({
    super.key,
    required this.match,
    required this.colors,
    required this.width,
    required this.height,
  });

  final MatchRecord match;
  final AppColorTokens colors;
  final double width;
  final double height;

  @override
  ConsumerState<_RecentMatchCard> createState() => _RecentMatchCardState();
}

class _RecentMatchCardState extends ConsumerState<_RecentMatchCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = widget.match;
    final colors = widget.colors;
    final fmt = DateFormat('MMM d, y');
    final timeFmt = DateFormat('HH:mm');
    final dateStr = fmt.format(m.date);
    final timeStr = timeFmt.format(m.date);
    final secs = m.durationSecondsEffective;
    final participants = m.participantSnapshots;
    final resultColor = _recentMatchResultColor(m, colors);
    final resultLabel = _recentMatchResultLabel(m);
    final n = _recentMatchPlayerCount(m);
    final playerLine = '$n ${n == 1 ? 'player' : 'players'}';

    final structureStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.35,
    );
    final formatStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.15,
      height: 1.25,
      color: colors.textPrimary,
    );
    final metaStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    final dateStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.textPrimary,
      height: 1.2,
    );
    final timeStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    final resultPill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr2,
        vertical: LayoutTokens.gr1,
      ),
      decoration: BoxDecoration(
        color: resultColor.withValues(alpha: 0.15),
        borderRadius: RadiusTokens.radiusSm,
      ),
      child: Text(
        resultLabel,
        style: TextStyle(
          color: resultColor,
          fontWeight: FontWeight.w700,
          fontSize: FontTokens.caption,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );

    final structureLine = _recentMatchStructureLine(m);

    final innerPad = _kBentoCardPaddingPx;
    final expandedInnerH = math.max(0.0, widget.height - 2 * innerPad);
    final profile = ref.watch(profileProvider).profile;
    final winner = _winnerParticipantForRecentCard(m, profile);
    final commanderImageUrl = _resolveCommanderImageForRecentCard(
      ref,
      winner,
      m,
      profile,
    );

    Widget summaryView() {
      const overlayShadow = [
        Shadow(
          color: Color(0xCC000000),
          blurRadius: 8,
          offset: Offset(0, 1),
        ),
      ];
      final overlayFormatStyle = formatStyle!.copyWith(
        color: ColorTokens.onAccent,
        shadows: overlayShadow,
      );
      final overlayMetaStyle = metaStyle!.copyWith(
        color: ColorTokens.onAccent.withValues(alpha: 0.92),
        shadows: overlayShadow,
      );
      final overlayDateStyle = dateStyle!.copyWith(
        color: ColorTokens.onAccent,
        shadows: overlayShadow,
      );
      final overlayTimeStyle = timeStyle!.copyWith(
        color: ColorTokens.onAccent.withValues(alpha: 0.88),
        shadows: overlayShadow,
      );

      return Stack(
        fit: StackFit.expand,
        children: [
          _recentMatchCommanderArt(context, commanderImageUrl),
          _recentMatchCardVignette(expanded: false),
          Padding(
            padding: EdgeInsets.all(LayoutTokens.gr2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [resultPill],
                ),
                const Spacer(),
                Text(
                  m.format,
                  style: overlayFormatStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: LayoutTokens.gr0),
                Text(
                  playerLine,
                  style: overlayMetaStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: LayoutTokens.gr0),
                Text(
                  dateStr,
                  style: overlayDateStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeStr,
                  style: overlayTimeStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: LayoutTokens.gr2),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      if (!_expanded) setState(() => _expanded = true);
                    },
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.standard,
                      padding: EdgeInsets.symmetric(
                        horizontal: LayoutTokens.gr3,
                        vertical: LayoutTokens.gr2,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: colors.primaryAccent.withValues(alpha: 0.55),
                        width: 1.25,
                      ),
                      foregroundColor: colors.primaryAccent,
                      backgroundColor:
                          colors.primaryAccent.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      'Show more',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.15,
                        color: colors.primaryAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget detailsColumn(double maxHeight) {
      final metaBlocks = <Widget>[
        _recentMatchDetailRow(
          context,
          colors,
          'Duration',
          _formatDurationSeconds(secs),
          compact: true,
        ),
        if (m.podNameSnapshot != null && m.podNameSnapshot!.isNotEmpty)
          _recentMatchDetailRow(
            context,
            colors,
            'Pod',
            m.podNameSnapshot!,
            compact: true,
          ),
        if (m.localDeckIdSnapshot != null &&
            m.localDeckIdSnapshot!.isNotEmpty)
          _recentMatchDetailRow(
            context,
            colors,
            'Deck',
            ref
                    .read(deckRepositoryProvider)
                    .getById(m.localDeckIdSnapshot!)
                    ?.displayName ??
                m.localDeckIdSnapshot!,
            compact: true,
          ),
      ];

      Widget? playersBlock;
      if (participants.isNotEmpty) {
        playersBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Players',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                fontSize: FontTokens.caption,
              ),
            ),
            SizedBox(height: LayoutTokens.gr0),
            Wrap(
              spacing: LayoutTokens.gr1,
              runSpacing: LayoutTokens.gr1,
              children: participants.map((p) {
                final chipImageUrl = _resolveCommanderImageForRecentCard(
                  ref,
                  p,
                  m,
                  profile,
                );
                final chipInitials = _recentMatchPlayerInitials(
                  (p.commanderName != null &&
                          p.commanderName!.trim().isNotEmpty)
                      ? p.commanderName!
                      : p.username,
                );
                return Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  labelPadding: const EdgeInsets.only(left: 2, right: 4),
                  avatar: CircleAvatar(
                    radius: 10,
                    backgroundColor: colors.primaryAccent.withValues(
                      alpha: 0.28,
                    ),
                    backgroundImage:
                        chipImageUrl != null && chipImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(chipImageUrl)
                            : null,
                    child: chipImageUrl == null || chipImageUrl.isEmpty
                        ? Text(
                            chipInitials,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          )
                        : null,
                  ),
                  label: Text(
                    p.commanderName ?? p.username,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: scheme.surfaceContainerLow,
                  side: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }

      final bodyChildren = <Widget>[];
      for (var i = 0; i < metaBlocks.length; i++) {
        if (i > 0) bodyChildren.add(SizedBox(height: LayoutTokens.gr2));
        bodyChildren.add(metaBlocks[i]);
      }
      if (playersBlock != null) {
        if (bodyChildren.isNotEmpty) {
          bodyChildren.add(SizedBox(height: LayoutTokens.gr2));
        }
        bodyChildren.add(playersBlock);
      }

      return SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: colors.backgroundSecondary.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  onPressed: () => setState(() => _expanded = false),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
            SizedBox(height: LayoutTokens.gr0),
            Text(
              structureLine,
              style: structureStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: LayoutTokens.gr1),
            Divider(
              height: 1,
              thickness: 1,
              color: colors.textSecondary.withValues(alpha: 0.18),
            ),
            SizedBox(height: LayoutTokens.gr2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...bodyChildren,
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final card = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerHigh,
        elevation: 1,
        surfaceTintColor: scheme.surfaceTint,
        shape: _profileCarouselCardShape(scheme),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _expanded
                ? null
                : () => setState(() => _expanded = true),
            borderRadius: _kBentoRadius,
            child: AnimatedCrossFade(
              firstChild: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: summaryView(),
              ),
              secondChild: Stack(
                fit: StackFit.expand,
                children: [
                  _recentMatchCommanderArt(context, commanderImageUrl),
                  _recentMatchCardVignette(expanded: true),
                  Padding(
                    padding: EdgeInsets.all(innerPad),
                    child: SizedBox(
                      height: expandedInnerH,
                      width: double.infinity,
                      child: ClipRect(
                        child: detailsColumn(expandedInnerH),
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: MotionTokens.standard,
              sizeCurve: Curves.easeInOut,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );

    return MergeSemantics(
      child: Semantics(
        container: true,
        expanded: _expanded,
        label: 'Recent match, $resultLabel, ${m.format}',
        value: '$playerLine. $dateStr $timeStr.',
        hint: _expanded
            ? 'Close button returns to summary'
            : 'Show more for full match details, or tap the card',
        child: card,
      ),
    );
  }
}

/// Sample rows for Recent Games when there is no local history yet.
List<MatchRecord> _previewPlaceholderMatches() {
  final now = DateTime.now();

  final duel = [
    MatchParticipantSnapshot(
      playerId: 'local',
      username: 'You',
      commanderName: 'The Ur-Dragon',
      commanderImageUrl: _kMostPlayedPlaceholderImageUrl,
      teamIndex: 0,
    ),
    const MatchParticipantSnapshot(
      playerId: 'opp1',
      username: 'Alex',
      commanderName: 'Niv-Mizzet, Parun',
      teamIndex: 0,
    ),
  ];

  final fourPlayer = [
    MatchParticipantSnapshot(
      playerId: 'local',
      username: 'You',
      commanderName: 'Atraxa, Praetors\' Voice',
      commanderImageUrl:
          'https://cards.scryfall.io/art_crop/front/d/0/d0d33d52-3d28-4635-b985-51e126289259.jpg?1599707796',
      teamIndex: 0,
    ),
    MatchParticipantSnapshot(
      playerId: 'p2',
      username: 'Sam',
      commanderName: 'Yuriko, the Tiger\'s Shadow',
      commanderImageUrl:
          'https://cards.scryfall.io/art_crop/front/f/e/fe9be3e0-076c-4703-9750-2a6b0a178bc9.jpg?1761053654',
      teamIndex: 0,
    ),
    const MatchParticipantSnapshot(
      playerId: 'p3',
      username: 'Jordan',
      commanderName: 'Kinnan, Bonder Prodigy',
      teamIndex: 0,
    ),
    const MatchParticipantSnapshot(
      playerId: 'p4',
      username: 'Taylor',
      commanderName: 'Winota, Joiner of Forces',
      teamIndex: 0,
    ),
  ];

  final podOfThree = [
    const MatchParticipantSnapshot(
      playerId: 'local',
      username: 'You',
      commanderName: 'Wilhelt, the Rotcleaver',
      teamIndex: 0,
    ),
    const MatchParticipantSnapshot(
      playerId: 'a',
      username: 'Morgan',
      commanderName: 'Lathril, Blade of Elves',
      teamIndex: 0,
    ),
    const MatchParticipantSnapshot(
      playerId: 'b',
      username: 'Riley',
      commanderName: 'Meren of Clan Nel Toth',
      teamIndex: 0,
    ),
  ];

  final olderDuel = [
    const MatchParticipantSnapshot(
      playerId: 'local',
      username: 'You',
      commanderName: 'Kinnan, Bonder Prodigy',
      teamIndex: 0,
    ),
    const MatchParticipantSnapshot(
      playerId: 'opp_casey',
      username: 'Casey',
      commanderName: 'Krark, the Thumbless',
      teamIndex: 0,
    ),
  ];

  return [
    MatchRecord(
      matchId: '__preview_placeholder_1__',
      date: now.subtract(const Duration(days: 1, hours: 2)),
      commanderName: 'The Ur-Dragon',
      partnerCommanderName: null,
      opponentNames: const ['Alex'],
      result: 'win',
      eliminationReason: 'survived',
      format: 'Commander',
      durationMinutes: 90,
      startingLifeTotal: 40,
      playerCount: 2,
      durationSeconds: 90 * 60 + 30,
      participantsJson: jsonEncode(duel.map((e) => e.toJson()).toList()),
      podNameSnapshot: 'Friday Night',
      locationSnapshot: 'Game shop',
      localDeckIdSnapshot: null,
    ),
    MatchRecord(
      matchId: '__preview_placeholder_2__',
      date: now.subtract(const Duration(days: 5, hours: 4)),
      commanderName: 'Atraxa, Praetors\' Voice',
      partnerCommanderName: null,
      opponentNames: const ['Sam', 'Jordan', 'Taylor'],
      result: 'loss',
      eliminationReason: 'life',
      format: 'Commander',
      durationMinutes: 127,
      startingLifeTotal: 40,
      playerCount: 4,
      durationSeconds: 127 * 60 + 12,
      participantsJson: jsonEncode(
        fourPlayer.map((e) => e.toJson()).toList(),
      ),
      podNameSnapshot: 'Game Store League',
      locationSnapshot: null,
      localDeckIdSnapshot: null,
    ),
    MatchRecord(
      matchId: '__preview_placeholder_3__',
      date: now.subtract(const Duration(days: 14, hours: 1)),
      commanderName: 'Wilhelt, the Rotcleaver',
      partnerCommanderName: null,
      opponentNames: const ['Morgan', 'Riley'],
      result: 'concede',
      eliminationReason: 'concede',
      format: 'Commander',
      durationMinutes: 52,
      startingLifeTotal: 40,
      playerCount: 3,
      durationSeconds: 52 * 60 + 45,
      participantsJson: jsonEncode(
        podOfThree.map((e) => e.toJson()).toList(),
      ),
      podNameSnapshot: 'Kitchen table',
      locationSnapshot: 'Home',
      localDeckIdSnapshot: null,
    ),
    MatchRecord(
      matchId: '__preview_placeholder_4__',
      date: now.subtract(const Duration(days: 21, hours: 3)),
      commanderName: 'Kinnan, Bonder Prodigy',
      partnerCommanderName: null,
      opponentNames: const ['Casey'],
      result: 'loss',
      eliminationReason: 'commanderDamage',
      format: 'Commander',
      durationMinutes: 74,
      startingLifeTotal: 40,
      playerCount: 2,
      durationSeconds: 74 * 60 + 6,
      participantsJson: jsonEncode(
        olderDuel.map((e) => e.toJson()).toList(),
      ),
      podNameSnapshot: 'Commander night',
      locationSnapshot: null,
      localDeckIdSnapshot: null,
    ),
  ];
}

bool _deckHasManaForProfile(PlayerDeck d) {
  final c = d.commanderManaCost?.trim();
  final p = d.partnerManaCost?.trim();
  return (c != null && c.isNotEmpty) ||
      (d.hasPartner && p != null && p.isNotEmpty);
}

/// Lower bound for deck perf card height: tall commander portrait + partner
/// line + dual mana rows + [DeckStatChips] wrapping at [_kDeckPerfCardWidth].
double _deckPerfCardMinHeightPx(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(12) / 12.0;
  const double atUnitScale = 388;
  return (atUnitScale * scale.clamp(1.0, 1.45)).clamp(318.0, 480.0);
}

/// Sample rows for Deck performance when there are no saved decks yet.
/// Mana strings use bundled `assets/mana/` symbols (WUBRG, hybrids, numbers).
List<PlayerDeck> _previewPlaceholderDecks() {
  return [
    PlayerDeck(
      id: '__preview_placeholder_deck__',
      displayName: "Ur-Dragon's Horde",
      commanderName: 'The Ur-Dragon',
      commanderManaCost: '{2}{W}{U}{B}{R}{G}',
      commanderImageUrl:
          'https://cards.scryfall.io/art_crop/front/1/0/10d42b35-844f-4a64-9981-c6118d45e826.jpg?1689999317',
      partnerCommanderName: null,
      partnerCommanderImageUrl: null,
      partnerManaCost: null,
      wins: 12,
      losses: 7,
      gamesPlayed: 19,
    ),
    PlayerDeck(
      id: '__preview_placeholder_deck_2__',
      displayName: 'Rograkh / Silas artifacts',
      commanderName: 'Rograkh, Son of Rohgahh',
      commanderManaCost: '{R}',
      commanderImageUrl:
          'https://cards.scryfall.io/art_crop/front/a/4/a4fab67f-00c2-4125-9262-d21a29411797.jpg?1769437009',
      partnerCommanderName: 'Silas Renn, Seeker Adept',
      partnerCommanderImageUrl:
          'https://cards.scryfall.io/art_crop/front/4/e/4e3fe912-1374-47c7-b73f-89ef55c479c1.jpg?1562399367',
      partnerManaCost: '{U}{B}',
      wins: 8,
      losses: 4,
      gamesPlayed: 12,
    ),
    PlayerDeck(
      id: '__preview_placeholder_deck_3__',
      displayName: 'Feather storm',
      commanderName: 'Feather, the Redeemed',
      commanderManaCost: '{3}{R/W}{R}',
      commanderImageUrl:
          'https://cards.scryfall.io/art_crop/front/e/4/e4a2d2c6-8eaa-4760-b620-921b807baa2e.jpg?1557577142',
      partnerCommanderName: null,
      partnerCommanderImageUrl: null,
      partnerManaCost: null,
      wins: 15,
      losses: 6,
      gamesPlayed: 21,
    ),
    PlayerDeck(
      id: '__preview_placeholder_deck_4__',
      displayName: 'Yuriko turns',
      commanderName: 'Yuriko, the Tiger\'s Shadow',
      commanderManaCost: '{1}{U}{B}',
      commanderImageUrl:
          'https://cards.scryfall.io/art_crop/front/f/e/fe9be3e0-076c-4703-9750-2a6b0a178bc9.jpg?1761053654',
      partnerCommanderName: null,
      partnerCommanderImageUrl: null,
      partnerManaCost: null,
      wins: 6,
      losses: 5,
      gamesPlayed: 11,
    ),
  ];
}

PlayerDeck? _previewPlaceholderWorstDeck() =>
    _pickWorstDeck(_previewPlaceholderDecks());

class _DeckPerformanceSection extends ConsumerStatefulWidget {
  final AppColorTokens colors;
  /// When null, list uses remaining flex height (one-screen layout).
  final double? listMaxHeight;
  final bool usePlaceholderDecks;

  const _DeckPerformanceSection({
    required this.colors,
    this.listMaxHeight,
    this.usePlaceholderDecks = false,
  });

  @override
  ConsumerState<_DeckPerformanceSection> createState() =>
      _DeckPerformanceSectionState();
}

/// Horizontal card width — sized so 1.5 cards peek on a 360px-wide viewport
/// (signals "more to scroll") and 2+ cards show on wider devices.
const double _kDeckPerfCardWidth = LayoutTokens.profileCarouselCardWidth;

/// Title row height (text + spacing) reserved above the horizontal deck list.
const double _kDeckPerfTitleHeight = 44;

/// Commander portrait in deck perf: scales inside [Expanded]; these clamp size.
/// Height is the long edge; width follows 63×88 mm card ratio in [DeckCommanderAvatarCluster].
const double _kDeckPerfCommanderPortraitMin = 108;
const double _kDeckPerfCommanderPortraitMax = 168;

/// Horizontal deck tiles only need ~this much vertical space (avatar, text,
/// mana, WR bar, chips). Parent passes a large [listMaxHeight] for other
/// modules; without a cap each card stretches and shows empty deck surface.
const double _kDeckPerfCardIdealHeight = 400;

/// Pixel height for profile horizontal tiles (deck performance + recent games).
double _profileSectionHorizontalCardHeight(
  BuildContext context,
  double? listMaxHeight,
) {
  final double listBudget =
      (listMaxHeight != null && listMaxHeight.isFinite && listMaxHeight > 0)
          ? listMaxHeight - _kDeckPerfTitleHeight
          : 240.0;
  final double budget = math.max(180.0, listBudget);
  final double need = _deckPerfCardMinHeightPx(context);
  final double softCap = math.max(_kDeckPerfCardIdealHeight, need);
  return math.max(need, math.min(budget, softCap));
}

/// Tighter dynamic height for the Player stats carousel only (level, behaviour,
/// most played). Still scales with viewport; capped lower than deck tiles.
double _profilePlayerStatsCardHeight(
  BuildContext context,
  double? listMaxHeight,
) {
  final full = _profileSectionHorizontalCardHeight(context, listMaxHeight);
  const scale = 0.86;
  const softCap = 320.0;
  const floor = 252.0;
  return (full * scale).clamp(floor, softCap);
}

class _DeckPerformanceSectionState
    extends ConsumerState<_DeckPerformanceSection> {
  late final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(deckListRevisionProvider);
    final repoDecks = List<PlayerDeck>.from(
      ref.read(deckRepositoryProvider).getAll(),
    )..sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));

    final isExampleDecks = widget.usePlaceholderDecks || repoDecks.isEmpty;
    final decks = isExampleDecks ? _previewPlaceholderDecks() : repoDecks;
    final colors = widget.colors;
    final lh = widget.listMaxHeight;

    final deckTitleStyle = TypographyTokens.sectionTitle(colors.textPrimary);

    Widget horizontalList(double cardHeight) {
      return SizedBox(
        height: cardHeight,
        child: ListView.separated(
          controller: _scrollCtrl,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemCount: decks.length,
          separatorBuilder: (_, __) => SizedBox(width: LayoutTokens.gr2),
          itemBuilder: (context, i) {
            return _DeckPerfCard(
              deck: decks[i],
              colors: colors,
              width: _kDeckPerfCardWidth,
              height: cardHeight,
            );
          },
        ),
      );
    }

    Widget titleRow() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Deck performance', style: deckTitleStyle),
              ),
              IconButton(
                icon: Icon(
                  Icons.layers_outlined,
                  size: 22,
                  color: colors.primaryAccent,
                ),
                tooltip: 'Manage decks',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: kMinInteractiveDimension,
                  minHeight: kMinInteractiveDimension,
                ),
                onPressed: () => context.go(AppRoutes.decks),
              ),
            ],
          ),
          if (isExampleDecks)
            Padding(
              padding: const EdgeInsets.only(top: LayoutTokens.gr0),
              child: Text(
                'Example decks — create a deck to track real performance.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final double cardHeight =
            _profileSectionHorizontalCardHeight(context, lh);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            titleRow(),
            SizedBox(height: LayoutTokens.gr2),
            horizontalList(cardHeight),
          ],
        );
      },
    );
  }
}

/// Vertical card showing one deck's commander art, names, mana, WR bar, and chips.
class _DeckPerfCard extends StatelessWidget {
  const _DeckPerfCard({
    required this.deck,
    required this.colors,
    required this.width,
    required this.height,
  });

  final PlayerDeck deck;
  final AppColorTokens colors;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Primary card height `size`; cluster width scales with partner overlap.
                  final wRatio = deck.hasPartner
                      ? (63 / 88) * (1 + 0.35 * 0.58)
                      : (63 / 88);
                  final maxByWidth = c.maxWidth / wRatio;
                  final sz = math
                      .min(c.maxHeight, maxByWidth)
                      .clamp(
                        _kDeckPerfCommanderPortraitMin,
                        _kDeckPerfCommanderPortraitMax,
                      );
                  return Center(
                    child: ResolvedDeckCommanderAvatarCluster(
                      deck: deck,
                      colors: colors,
                      size: sz,
                      portraitStyle: CommanderPortraitStyle.card,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: LayoutTokens.gr0),
            Text(
              deck.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              deck.hasPartner
                  ? '${deck.commanderName} // ${deck.partnerCommanderName}'
                  : deck.commanderName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_deckHasManaForProfile(deck)) ...[
              SizedBox(height: LayoutTokens.gr1),
              DeckManaCostRows(
                commanderManaCost: deck.commanderManaCost,
                partnerManaCost: deck.partnerManaCost,
                hasPartner: deck.hasPartner,
                compact: true,
              ),
            ],
            SizedBox(height: LayoutTokens.gr2),
            DeckWinLossRatioBar(deck: deck, colors: colors, height: 6),
            SizedBox(height: LayoutTokens.gr1),
            DeckStatChips(deck: deck, colors: colors, compact: true),
          ],
        ),
      ),
    );
  }
}
