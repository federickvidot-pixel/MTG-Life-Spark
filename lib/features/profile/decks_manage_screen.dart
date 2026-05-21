import 'package:flutter/material.dart';
import '../../ui/tokens/font_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/player_deck.dart';
import '../../core/persistence/deck_repository.dart';
import '../../core/persistence/providers.dart';
import '../../shared/utils/app_router.dart';
import '../../shared/widgets/deck_tile_visual.dart';
import '../../shared/widgets/mana_cost_pips.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/layout_tokens.dart';

class DecksManageScreen extends ConsumerStatefulWidget {
  const DecksManageScreen({super.key});

  @override
  ConsumerState<DecksManageScreen> createState() => _DecksManageScreenState();
}

bool _deckHasMana(PlayerDeck d) {
  final c = d.commanderManaCost?.trim();
  final p = d.partnerManaCost?.trim();
  return (c != null && c.isNotEmpty) ||
      (d.hasPartner && p != null && p.isNotEmpty);
}

class _DecksManageScreenState extends ConsumerState<DecksManageScreen> {
  List<PlayerDeck> _decks = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _decks = ref.read(deckRepositoryProvider).getAll();
    });
  }

  Future<void> _promptNewDeckName() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = AppColorTokens.of(ctx);
        return AlertDialog(
          title: Text('Deck name', style: TextStyle(color: colors.textPrimary)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Raffine Tempo',
              hintStyle: TextStyle(color: colors.textSecondary),
            ),
            style: TextStyle(color: colors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(ctx, t);
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
    if (name == null || !mounted) return;
    final profile = ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;
    await context.push(
      AppRoutes.commanderSelect,
      extra: {
        'playerId': profile.username,
        'newDeckDisplayName': name,
      },
    );
    bumpDeckListRevision(ref);
    _reload();
  }

  Future<void> _editCommanders(PlayerDeck deck) async {
    final profile = ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;
    await context.push(
      AppRoutes.commanderSelect,
      extra: {
        'playerId': profile.username,
        'editDeckId': deck.id,
      },
    );
    bumpDeckListRevision(ref);
    _reload();
  }

  Future<void> _renameDeck(DeckRepository repo, PlayerDeck deck) async {
    final controller = TextEditingController(text: deck.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = AppColorTokens.of(ctx);
        return AlertDialog(
          title: Text('Rename deck', style: TextStyle(color: colors.textPrimary)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(ctx, t);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (name == null || !mounted) return;
    deck.displayName = name;
    await repo.save(deck);
    bumpDeckListRevision(ref);
    _reload();
  }

  Future<void> _confirmDelete(DeckRepository repo, PlayerDeck deck) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete deck?'),
        content: Text(
          'Remove “${deck.displayName}”? Stats for this deck will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.delete(deck.id);
      bumpDeckListRevision(ref);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final repo = ref.read(deckRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My decks'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(LayoutTokens.gr3),
        itemCount: _decks.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: LayoutTokens.gr2),
              child: Text(
                'Register a deck with a name and commander. In the lobby, tap '
                '“Deck” to play under that deck — wins and losses update your '
                'per-deck record.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            );
          }
          final deck = _decks[i - 1];
          return Card(
            margin: EdgeInsets.only(bottom: LayoutTokens.gr2),
            child: Padding(
              padding: EdgeInsets.all(LayoutTokens.gr2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DeckCommanderAvatarCluster(
                        deck: deck,
                        colors: colors,
                        size: 56,
                      ),
                      SizedBox(width: LayoutTokens.gr2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deck.displayName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: LayoutTokens.gr0),
                            Text(
                              deck.hasPartner
                                  ? '${deck.commanderName} // ${deck.partnerCommanderName}'
                                  : deck.commanderName,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: FontTokens.hudSm,
                              ),
                            ),
                            if (_deckHasMana(deck)) ...[
                              SizedBox(height: LayoutTokens.gr1),
                              DeckManaCostRows(
                                commanderManaCost: deck.commanderManaCost,
                                partnerManaCost: deck.partnerManaCost,
                                hasPartner: deck.hasPartner,
                              ),
                            ],
                            SizedBox(height: LayoutTokens.gr2),
                            DeckWinLossRatioBar(
                              deck: deck,
                              colors: colors,
                              height: 8,
                            ),
                            SizedBox(height: LayoutTokens.gr2),
                            DeckStatChips(
                              deck: deck,
                              colors: colors,
                              compact: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: LayoutTokens.gr2),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _editCommanders(deck),
                        child: const Text('Commanders'),
                      ),
                      TextButton(
                        onPressed: () => _renameDeck(repo, deck),
                        child: const Text('Rename'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(repo, deck),
                        icon: Icon(Icons.delete_outline, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _promptNewDeckName,
        icon: const Icon(Icons.add),
        label: const Text('Add deck'),
      ),
    );
  }
}
