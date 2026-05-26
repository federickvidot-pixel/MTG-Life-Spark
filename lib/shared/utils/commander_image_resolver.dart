import '../../core/models/player_deck.dart';
import '../../core/models/player_profile.dart';
import '../../core/persistence/deck_repository.dart';

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

/// Commander art for an in-game player row (slot/deck/profile, no network).
String? resolvePlayerCommanderImageUrl({
  required String? commanderName,
  required String? commanderImageUrl,
  String? selectedDeckId,
  PlayerProfile? profile,
  DeckRepository? deckRepo,
}) {
  final stored = commanderImageUrl?.trim();
  if (stored != null && stored.isNotEmpty) return stored;

  if (selectedDeckId != null && deckRepo != null) {
    final deck = deckRepo.getById(selectedDeckId);
    if (deck != null) {
      final fromDeck = resolveDeckCommanderImageUrl(deck: deck, profile: profile);
      if (fromDeck != null && fromDeck.isNotEmpty) return fromDeck;
    }
  }

  if (profile != null && commanderName != null) {
    final name = commanderName.trim();
    if (name.isNotEmpty) {
      final selName = profile.selectedCommanderName?.trim();
      if (selName != null &&
          selName.isNotEmpty &&
          selName.toLowerCase() == name.toLowerCase()) {
        final url = profile.selectedCommanderImageUrl?.trim();
        if (url != null && url.isNotEmpty) return url;
      }
    }
  }
  return null;
}

/// Partner art for an in-game player row (slot/deck/profile, no network).
String? resolvePlayerPartnerImageUrl({
  required String? partnerCommanderName,
  required String? partnerCommanderImageUrl,
  String? selectedDeckId,
  PlayerProfile? profile,
  DeckRepository? deckRepo,
}) {
  final stored = partnerCommanderImageUrl?.trim();
  if (stored != null && stored.isNotEmpty) return stored;

  if (selectedDeckId != null && deckRepo != null) {
    final deck = deckRepo.getById(selectedDeckId);
    if (deck != null && deck.hasPartner) {
      final fromDeck =
          resolveDeckPartnerImageUrl(deck: deck, profile: profile);
      if (fromDeck != null && fromDeck.isNotEmpty) return fromDeck;
    }
  }

  if (profile != null && partnerCommanderName != null) {
    final name = partnerCommanderName.trim();
    if (name.isNotEmpty) {
      final selPartner = profile.selectedPartnerCommanderName?.trim();
      if (selPartner != null &&
          selPartner.isNotEmpty &&
          selPartner.toLowerCase() == name.toLowerCase()) {
        final url = profile.selectedPartnerCommanderImageUrl?.trim();
        if (url != null && url.isNotEmpty) return url;
      }
    }
  }
  return null;
}

bool isPreviewPlaceholderDeck(PlayerDeck deck) =>
    deck.id.startsWith('__preview_placeholder_deck');
