import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ScryfallCard {
  final String name;
  final String? imageUrl; // null = offline / not found
  final String? oracleText;
  final bool isPartner;

  const ScryfallCard({
    required this.name,
    this.imageUrl,
    this.oracleText,
    this.isPartner = false,
  });

  /// Local placeholder path when the network is unavailable.
  static const offlineImageAsset = 'assets/placeholders/card_placeholder.png';
}

class ScryfallService {
  static const _base = 'https://api.scryfall.com';

  /// Scryfall requires User-Agent and Accept headers; requests without them
  /// may be blocked or return 400/403.
  static final _headers = {
    'User-Agent': 'MGT-Life-Spark/1.0 (Commander life tracker)',
    'Accept': 'application/json',
  };

  final http.Client _client;

  ScryfallService({http.Client? client}) : _client = client ?? http.Client();

  // ── Search ────────────────────────────────────────────────────────────────

  /// Returns any MTG cards matching [query] (for avatar selection, etc.).
  /// Throws on network/parse errors; returns empty list only when no results.
  Future<List<ScryfallCard>> searchCards(String query) async {
    if (query.trim().isEmpty) return [];
    final encoded = Uri.encodeComponent('name:${query.trim()} game:paper');
    final uri = Uri.parse(
      '$_base/cards/search?q=$encoded&order=name&unique=cards',
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception('Scryfall API error: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];
    return data.map((card) => _parseCard(card as Map<String, dynamic>)).toList();
  }

  /// Returns commanders matching [query].
  /// Filters to legendary creatures that can be your commander.
  /// Throws on network/parse errors; returns empty list only when no results.
  Future<List<ScryfallCard>> searchCommanders(String query) async {
    if (query.trim().isEmpty) return [];
    final encoded = Uri.encodeComponent(
      'is:commander name:${query.trim()} game:paper',
    );
    final uri = Uri.parse(
      '$_base/cards/search?q=$encoded&order=name&unique=cards',
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return []; // No results
    if (response.statusCode != 200) {
      throw Exception('Scryfall API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];

    return data.map((card) => _parseCard(card as Map<String, dynamic>)).toList();
  }

  // ── Variant decks (Planechase, Archenemy, Bounty) ─────────────────────────

  /// Fetches all planar and phenomenon cards for Planechase.
  /// Requires internet. Returns empty list on error.
  Future<List<ScryfallCard>> fetchPlanarDeck() async {
    return _fetchVariantDeck(
      '(type:plane OR type:phenomenon) game:paper',
      includeExtras: true,
    );
  }

  /// Fetches all scheme cards for Archenemy.
  Future<List<ScryfallCard>> fetchSchemeDeck() async {
    return _fetchVariantDeck('type:scheme game:paper');
  }

  /// Fetches all bounty cards for Bounty minigame.
  Future<List<ScryfallCard>> fetchBountyDeck() async {
    return _fetchVariantDeck('is:bounty game:paper');
  }

  Future<List<ScryfallCard>> _fetchVariantDeck(
    String query, {
    bool includeExtras = false,
  }) async {
    final cards = <ScryfallCard>[];
    String? nextPage =
        '$_base/cards/search?q=${Uri.encodeComponent(query)}&order=name&unique=cards${includeExtras ? '&include_extras=true' : ''}';

    while (nextPage != null) {
      final uri = Uri.parse(nextPage);
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return cards;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      for (final c in data) {
        cards.add(_parseCard(c as Map<String, dynamic>));
      }
      nextPage = json['next_page'] as String?;
    }
    return cards;
  }

  // ── Fetch by exact name ───────────────────────────────────────────────────

  /// Fetches a single card by exact name (for loading saved commanders).
  Future<ScryfallCard?> fetchCardByName(String name) async {
    try {
      final encoded = Uri.encodeComponent(name);
      final uri = Uri.parse('$_base/cards/named?exact=$encoded');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseCard(json);
    } catch (_) {
      return null;
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  ScryfallCard _parseCard(Map<String, dynamic> card) {
    final name = card['name'] as String? ?? '';

    // Double-faced cards store images in card_faces[].
    String? imageUrl;
    final imageUris = card['image_uris'] as Map<String, dynamic>?;
    if (imageUris != null) {
      imageUrl = (imageUris['art_crop'] ?? imageUris['normal']) as String?;
    } else {
      final faces = card['card_faces'] as List<dynamic>?;
      if (faces != null && faces.isNotEmpty) {
        final faceUris = (faces[0] as Map<String, dynamic>)['image_uris']
            as Map<String, dynamic>?;
        imageUrl = faceUris?['art_crop'] as String? ?? faceUris?['normal'] as String?;
      }
    }

    final oracleText = card['oracle_text'] as String? ??
        ((card['card_faces'] as List?)?.isNotEmpty == true
            ? ((card['card_faces'] as List)[0]
                    as Map<String, dynamic>)['oracle_text'] as String?
            : null);

    final keywords = List<String>.from(card['keywords'] as List? ?? []);
    final isPartner =
        keywords.contains('Partner') || keywords.contains('Friends forever');

    return ScryfallCard(
      name: name,
      imageUrl: imageUrl,
      oracleText: oracleText,
      isPartner: isPartner,
    );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final scryfallServiceProvider = Provider<ScryfallService>((ref) {
  return ScryfallService();
});
