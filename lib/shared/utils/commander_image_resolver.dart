import '../../core/models/player_deck.dart';
import '../../core/models/player_profile.dart';

/// Immediate commander art URL for a saved deck (no network).
String? resolveDeckCommanderImageUrl({
  required PlayerDeck deck,
  PlayerProfile? profile,
}) {
  final stored = deck.commanderImageUrl?.trim();
  if (stored != null && stored.isNotEmpty) return stored;

  if (profile != null) {
    final deckCmd = deck.commanderName.trim();
    final selName = profile.selectedCommanderName?.trim();
    if (selName != null &&
        selName.isNotEmpty &&
        selName.toLowerCase() == deckCmd.toLowerCase()) {
      final url = profile.selectedCommanderImageUrl?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
  }
  return null;
}

/// Immediate partner art URL for a saved deck (no network).
String? resolveDeckPartnerImageUrl({
  required PlayerDeck deck,
  PlayerProfile? profile,
}) {
  final stored = deck.partnerCommanderImageUrl?.trim();
  if (stored != null && stored.isNotEmpty) return stored;

  if (profile != null && deck.hasPartner) {
    final partner = deck.partnerCommanderName!.trim();
    final selPartner = profile.selectedPartnerCommanderName?.trim();
    if (selPartner != null &&
        selPartner.isNotEmpty &&
        selPartner.toLowerCase() == partner.toLowerCase()) {
      final url = profile.selectedPartnerCommanderImageUrl?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
  }
  return null;
}

bool isPreviewPlaceholderDeck(PlayerDeck deck) =>
    deck.id.startsWith('__preview_placeholder_deck');
