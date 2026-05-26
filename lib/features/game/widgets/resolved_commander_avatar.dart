import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_providers.dart';
import '../../../core/game/scryfall_service.dart';
import '../../../core/persistence/providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/commander_image_resolver.dart';
import '../../../ui/tokens/radius_tokens.dart';

/// Commander avatar that resolves stored URLs from deck/profile and fetches
/// Scryfall art when missing (same strategy as deck tiles).
class ResolvedCommanderAvatar extends ConsumerStatefulWidget {
  const ResolvedCommanderAvatar({
    super.key,
    required this.playerId,
    required this.commanderName,
    required this.imageUrl,
    required this.playerColor,
    required this.size,
    this.isPartner = false,
    this.selectedDeckId,
  });

  final String playerId;
  final String? commanderName;
  final String? imageUrl;
  final Color playerColor;
  final double size;
  final bool isPartner;
  final String? selectedDeckId;

  @override
  ConsumerState<ResolvedCommanderAvatar> createState() =>
      _ResolvedCommanderAvatarState();
}

class _ResolvedCommanderAvatarState extends ConsumerState<ResolvedCommanderAvatar> {
  String? _resolvedUrl;
  bool _fetchStarted = false;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _syncResolve();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFromScryfall());
  }

  @override
  void didUpdateWidget(ResolvedCommanderAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commanderName != widget.commanderName ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.selectedDeckId != widget.selectedDeckId ||
        oldWidget.isPartner != widget.isPartner) {
      _fetchStarted = false;
      _resolvedUrl = _syncResolve();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFromScryfall());
    }
  }

  String? _syncResolve() {
    final profile = ref.read(profileRepositoryProvider).getProfile();
    final deckRepo = ref.read(deckRepositoryProvider);
    if (widget.isPartner) {
      return resolvePlayerPartnerImageUrl(
        partnerCommanderName: widget.commanderName,
        partnerCommanderImageUrl: widget.imageUrl,
        selectedDeckId: widget.selectedDeckId,
        profile: profile,
        deckRepo: deckRepo,
      );
    }
    return resolvePlayerCommanderImageUrl(
      commanderName: widget.commanderName,
      commanderImageUrl: widget.imageUrl,
      selectedDeckId: widget.selectedDeckId,
      profile: profile,
      deckRepo: deckRepo,
    );
  }

  Future<void> _fetchFromScryfall() async {
    if (_fetchStarted) return;
    if (_resolvedUrl != null && _resolvedUrl!.isNotEmpty) return;
    final name = widget.commanderName?.trim();
    if (name == null || name.isEmpty) return;

    _fetchStarted = true;
    final card = await ref.read(scryfallServiceProvider).fetchCardByName(name);
    final url = card?.imageUrl?.trim();
    if (!mounted || url == null || url.isEmpty) return;

    setState(() => _resolvedUrl = url);
    final notifier = ref.read(gameProvider.notifier);
    if (widget.isPartner) {
      notifier.patchCommanderArt(
        widget.playerId,
        partnerCommanderImageUrl: url,
      );
    } else {
      notifier.patchCommanderArt(
        widget.playerId,
        commanderImageUrl: url,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommanderAvatarImage(
      imageUrl: _resolvedUrl,
      name: widget.commanderName,
      playerColor: widget.playerColor,
      size: widget.size,
    );
  }
}

/// Shared commander art tile with network load + placeholder.
class CommanderAvatarImage extends StatelessWidget {
  const CommanderAvatarImage({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.playerColor,
    required this.size,
  });

  final String? imageUrl;
  final String? name;
  final Color playerColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: RadiusTokens.radiusControlMd,
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(showProgress: true),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool showProgress = false}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: playerColor.withValues(alpha: 0.15),
          borderRadius: RadiusTokens.radiusControlMd,
          border: Border.all(color: playerColor.withValues(alpha: 0.5)),
        ),
        child: showProgress
            ? Center(
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accent,
                  ),
                ),
              )
            : Icon(Icons.style, color: playerColor, size: size * 0.5),
      );
}
