import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/scryfall_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/spacing_tokens.dart';

/// Shows current Planechase plane, Archenemy scheme, or Bounty card with
/// advance controls. Requires internet for deck data.
class VariantCardPanel extends ConsumerWidget {
  const VariantCardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final decksAsync = ref.watch(variantDecksProvider);

    if (!game.planechaseEnabled &&
        !game.archenemyEnabled &&
        !game.bountyEnabled) {
      return const SizedBox.shrink();
    }

    return decksAsync.when(
      data: (decks) => _VariantContent(
        game: game,
        decks: decks,
        notifier: ref.read(gameProvider.notifier),
      ),
      loading: () => Padding(
        padding: SpacingTokens.horizontalMd.add(SpacingTokens.verticalXs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: LayoutTokens.gr5 - LayoutTokens.gr0,
              height: LayoutTokens.gr5 - LayoutTokens.gr0,
              child: CircularProgressIndicator(
                strokeWidth: LayoutTokens.gr0 / 2,
              ),
            ),
            SizedBox(width: LayoutTokens.gr2),
            Text(
              'Loading variant decks…',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: LayoutTokens.gr3,
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => Padding(
        padding: SpacingTokens.horizontalMd.add(SpacingTokens.verticalXs),
        child: Text(
          'Could not load decks (internet required)',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: LayoutTokens.gr2,
          ),
        ),
      ),
    );
  }
}

class _VariantContent extends StatelessWidget {
  final GameState game;
  final Map<String, List<ScryfallCard>> decks;
  final dynamic notifier;

  const _VariantContent({
    required this.game,
    required this.decks,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (game.planechaseEnabled) {
      final planar = decks['planar'] ?? [];
      if (planar.isNotEmpty) {
        children.add(
          _VariantTile(
            title: 'Planechase',
            icon: Icons.public,
            iconWidget: null,
            card: planar[game.currentPlanarIndex % planar.length],
            deckSize: planar.length,
            onAdvance: () => notifier.advancePlanar(planar.length),
          ),
        );
      }
    }

    if (game.archenemyEnabled) {
      final scheme = decks['scheme'] ?? [];
      if (scheme.isNotEmpty) {
        children.add(
          _VariantTile(
            title: 'Archenemy',
            icon: Icons.shield,
            iconWidget: null,
            card: scheme[game.currentSchemeIndex % scheme.length],
            deckSize: scheme.length,
            onAdvance: () => notifier.advanceScheme(scheme.length),
          ),
        );
      }
    }

    if (game.bountyEnabled) {
      final bounty = decks['bounty'] ?? [];
      if (bounty.isNotEmpty) {
        children.add(
          _VariantTile(
            title: 'Bounty',
            iconWidget: GameIcon.bounty(size: 20, color: AppTheme.accent),
            card: bounty[game.currentBountyIndex % bounty.length],
            deckSize: bounty.length,
            onAdvance: () => notifier.advanceBounty(bounty.length),
          ),
        );
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr3,
        vertical: LayoutTokens.gr2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _VariantTile extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? iconWidget;
  final ScryfallCard card;
  final int deckSize;
  final VoidCallback onAdvance;

  const _VariantTile({
    required this.title,
    this.icon,
    this.iconWidget,
    required this.card,
    required this.deckSize,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final pad = LayoutTokens.gr3;
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final thumbW = narrow ? 56.0 : 72.0;
    final thumbH = narrow ? 80.0 : 100.0;
    return Container(
      margin: EdgeInsets.only(bottom: pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(pad),
        border: Border.all(color: AppTheme.surface, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCardDetail(context),
          borderRadius: BorderRadius.circular(pad),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Row(
              children: [
                // Card thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: thumbW,
                    height: thumbH,
                    child: card.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: card.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppTheme.surface,
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: AppTheme.textSecondary,
                                  size: 24,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.surface,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.surface,
                            child: const Icon(
                              Icons.help_outline,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name + oracle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (iconWidget != null)
                            iconWidget!
                          else if (icon != null)
                            Icon(icon, size: 20, color: AppTheme.accent),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (card.oracleText != null &&
                          card.oracleText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          card.oracleText!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Advance button
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: onAdvance,
                  tooltip: 'Next card',
                  color: AppTheme.accent,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCardDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (card.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: card.imageUrl!,
                      width: (MediaQuery.sizeOf(context).width - 40).clamp(200.0, 280.0),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                card.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (card.oracleText != null && card.oracleText!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  card.oracleText!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
