import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/tokens/opacity_tokens.dart';

import '../../core/game/scryfall_service.dart';
import '../../core/models/player_deck.dart';
import '../../core/persistence/providers.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/color_tokens.dart';
import '../utils/commander_image_resolver.dart';

/// How commander art is framed in a list row.
enum CommanderPortraitStyle {
  /// Circular crop (compact lists).
  circle,

  /// MTG card proportions (63×88 mm), portrait with rounded corners.
  card,
}

/// Commander card art + optional partner overlap.
class DeckCommanderAvatarCluster extends StatelessWidget {
  const DeckCommanderAvatarCluster({
    super.key,
    required this.deck,
    required this.colors,
    this.size = 56,
    this.portraitStyle = CommanderPortraitStyle.circle,
    this.primaryImageUrl,
    this.partnerImageUrl,
  });

  final PlayerDeck deck;
  final AppColorTokens colors;
  final double size;
  final CommanderPortraitStyle portraitStyle;
  /// Resolved art URL; falls back to [PlayerDeck.commanderImageUrl].
  final String? primaryImageUrl;
  /// Resolved partner art URL; falls back to [PlayerDeck.partnerCommanderImageUrl].
  final String? partnerImageUrl;

  /// Standard playing-card aspect (width : height) for Magic cards.
  static const double _cardAspectWidthOverHeight = 63 / 88;

  @override
  Widget build(BuildContext context) {
    final primaryUrl = primaryImageUrl ?? deck.commanderImageUrl;
    final partnerUrl = partnerImageUrl ?? deck.partnerCommanderImageUrl;
    final hasPartner = deck.hasPartner;

    if (portraitStyle == CommanderPortraitStyle.card) {
      if (!hasPartner) {
        return _cardPortraitTile(url: primaryUrl, height: size);
      }
      final small = size * 0.58;
      final bigW = size * _cardAspectWidthOverHeight;
      final smW = small * _cardAspectWidthOverHeight;
      return SizedBox(
        width: bigW + smW * 0.35,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: _cardPortraitTile(url: primaryUrl, height: size),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    _cardCornerRadiusForHeight(small) + 2,
                  ),
                  border: Border.all(color: colors.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: OpacityTokens.soft),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _cardPortraitTile(
                    url: partnerUrl != null && partnerUrl.isNotEmpty
                        ? partnerUrl
                        : null,
                    height: small - 4,
                    showSurround: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget circleImage(String? url, double diameter) {
      return ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: diameter,
                  height: diameter,
                  color: colors.backgroundSecondary,
                  child: Icon(
                    Icons.person,
                    size: diameter * 0.45,
                    color: colors.textMuted,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: diameter,
                  height: diameter,
                  color: colors.backgroundSecondary,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: diameter * 0.35,
                    color: colors.textMuted,
                  ),
                ),
              )
            : Container(
                width: diameter,
                height: diameter,
                color: colors.backgroundSecondary,
                child: Icon(
                  Icons.person,
                  size: diameter * 0.45,
                  color: colors.textMuted,
                ),
              ),
      );
    }

    if (!hasPartner) {
      return circleImage(primaryUrl, size);
    }

    final small = size * 0.58;
    return SizedBox(
      width: size + small * 0.35,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, top: 0, child: circleImage(primaryUrl, size)),
          Positioned(
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
              child: circleImage(
                partnerUrl != null && partnerUrl.isNotEmpty
                    ? partnerUrl
                    : null,
                small,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _cardCornerRadiusForHeight(double height) {
    final w = height * _cardAspectWidthOverHeight;
    return (w * 0.075).clamp(3.0, 7.0);
  }

  /// Card-shaped thumbnail: [height] is the long side (portrait).
  Widget _cardPortraitTile({
    required String? url,
    required double height,
    bool showSurround = true,
  }) {
    final width = height * _cardAspectWidthOverHeight;
    final r = math.max(3.0, _cardCornerRadiusForHeight(height));
    final innerR = BorderRadius.circular(r);

    Widget content() {
      if (url != null && url.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: width,
            height: height,
            color: colors.backgroundSecondary,
            alignment: Alignment.center,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textMuted,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _cardPlaceholder(height: height),
        );
      }
      return _cardPlaceholder(height: height);
    }

    final core = ClipRRect(
      borderRadius: innerR,
      child: content(),
    );

    if (!showSurround) {
      return SizedBox(width: width, height: height, child: core);
    }

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: innerR,
          border: Border.all(
            color: colors.borderSubtle.withValues(alpha: OpacityTokens.strong),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: core,
      ),
    );
  }

  Widget _cardPlaceholder({required double height}) {
    final width = height * _cardAspectWidthOverHeight;
    return Container(
      width: width,
      height: height,
      color: colors.backgroundSecondary,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: height * 0.32,
        color: colors.textMuted,
      ),
    );
  }
}

/// Deck commander portraits with profile fallbacks and one-shot Scryfall lookup.
class ResolvedDeckCommanderAvatarCluster extends ConsumerStatefulWidget {
  const ResolvedDeckCommanderAvatarCluster({
    super.key,
    required this.deck,
    required this.colors,
    this.size = 56,
    this.portraitStyle = CommanderPortraitStyle.circle,
  });

  final PlayerDeck deck;
  final AppColorTokens colors;
  final double size;
  final CommanderPortraitStyle portraitStyle;

  @override
  ConsumerState<ResolvedDeckCommanderAvatarCluster> createState() =>
      _ResolvedDeckCommanderAvatarClusterState();
}

class _ResolvedDeckCommanderAvatarClusterState
    extends ConsumerState<ResolvedDeckCommanderAvatarCluster> {
  String? _primaryUrl;
  String? _partnerUrl;
  bool _fetchStarted = false;

  @override
  void initState() {
    super.initState();
    _applySyncResolve();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMissingFromScryfall());
  }

  @override
  void didUpdateWidget(ResolvedDeckCommanderAvatarCluster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deck.id != widget.deck.id ||
        oldWidget.deck.commanderImageUrl != widget.deck.commanderImageUrl ||
        oldWidget.deck.partnerCommanderImageUrl !=
            widget.deck.partnerCommanderImageUrl) {
      _fetchStarted = false;
      _applySyncResolve();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fetchMissingFromScryfall());
    }
  }

  void _applySyncResolve() {
    final profile = ref.read(profileRepositoryProvider).getProfile();
    _primaryUrl = resolveDeckCommanderImageUrl(
      deck: widget.deck,
      profile: profile,
    );
    _partnerUrl = resolveDeckPartnerImageUrl(
      deck: widget.deck,
      profile: profile,
    );
  }

  Future<void> _fetchMissingFromScryfall() async {
    if (_fetchStarted) return;
    final needPrimary = _primaryUrl == null || _primaryUrl!.isEmpty;
    final needPartner = widget.deck.hasPartner &&
        (_partnerUrl == null || _partnerUrl!.isEmpty);
    if (!needPrimary && !needPartner) return;

    _fetchStarted = true;
    final service = ref.read(scryfallServiceProvider);
    var primary = _primaryUrl;
    var partner = _partnerUrl;

    if (needPrimary) {
      final card =
          await service.fetchCardByName(widget.deck.commanderName);
      primary = card?.imageUrl?.trim();
    }
    if (needPartner && widget.deck.partnerCommanderName != null) {
      final card = await service.fetchCardByName(
        widget.deck.partnerCommanderName!,
      );
      partner = card?.imageUrl?.trim();
    }

    if (!mounted) return;
    if ((primary != null && primary.isNotEmpty) ||
        (partner != null && partner.isNotEmpty)) {
      setState(() {
        if (primary != null && primary.isNotEmpty) _primaryUrl = primary;
        if (partner != null && partner.isNotEmpty) _partnerUrl = partner;
      });
      await _persistFetchedUrls(primary: primary, partner: partner);
    }
  }

  Future<void> _persistFetchedUrls({
    String? primary,
    String? partner,
  }) async {
    if (isPreviewPlaceholderDeck(widget.deck)) return;
    final repo = ref.read(deckRepositoryProvider);
    final deck = repo.getById(widget.deck.id);
    if (deck == null) return;
    var changed = false;
    if (primary != null &&
        primary.isNotEmpty &&
        (deck.commanderImageUrl == null || deck.commanderImageUrl!.isEmpty)) {
      deck.commanderImageUrl = primary;
      changed = true;
    }
    if (partner != null &&
        partner.isNotEmpty &&
        (deck.partnerCommanderImageUrl == null ||
            deck.partnerCommanderImageUrl!.isEmpty)) {
      deck.partnerCommanderImageUrl = partner;
      changed = true;
    }
    if (changed) {
      await repo.save(deck);
      bumpDeckListRevision(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DeckCommanderAvatarCluster(
      deck: widget.deck,
      colors: widget.colors,
      size: widget.size,
      portraitStyle: widget.portraitStyle,
      primaryImageUrl: _primaryUrl,
      partnerImageUrl: _partnerUrl,
    );
  }
}

/// Horizontal bar: wins (green) vs losses (red) by game count.
class DeckWinLossRatioBar extends StatelessWidget {
  const DeckWinLossRatioBar({
    super.key,
    required this.deck,
    required this.colors,
    this.height = 8,
  });

  final PlayerDeck deck;
  final AppColorTokens colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    final gp = deck.gamesPlayed;
    if (gp <= 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
    }
    final w = deck.wins;
    final l = deck.losses;
    if (w <= 0 && l <= 0) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Row(
          children: [
            if (w > 0)
              Expanded(
                flex: w,
                child: Container(color: ColorTokens.success),
              ),
            if (l > 0)
              Expanded(
                flex: l,
                child: Container(
                  color: ColorTokens.danger.withValues(alpha: OpacityTokens.nearOpaque),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// WR / W / L / GP as compact visual chips (icons + values).
class DeckStatChips extends StatelessWidget {
  const DeckStatChips({
    super.key,
    required this.deck,
    required this.colors,
    this.compact = false,
  });

  final PlayerDeck deck;
  final AppColorTokens colors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gp = deck.gamesPlayed;
    final wr = gp == 0 ? null : (deck.winRate * 100).round();

    Widget chip({
      required IconData icon,
      required String label,
      required String value,
      Color? valueColor,
    }) {
      final fs = compact ? 11.0 : 12.0;
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: OpacityTokens.soft),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 14 : 16, color: colors.textSecondary),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: fs - 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? colors.textPrimary,
                fontSize: fs,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: 6,
      children: [
        chip(
          icon: Icons.percent,
          label: 'WR',
          value: wr == null ? '—' : '$wr%',
          valueColor: colors.primaryAccent,
        ),
        chip(
          icon: Icons.emoji_events_outlined,
          label: 'W',
          value: '${deck.wins}',
          valueColor: ColorTokens.success,
        ),
        chip(
          icon: Icons.remove_circle_outline,
          label: 'L',
          value: '${deck.losses}',
          valueColor: ColorTokens.danger.withValues(alpha: 0.95),
        ),
        chip(
          icon: Icons.sports_esports_outlined,
          label: 'GP',
          value: '$gp',
        ),
      ],
    );
  }
}
