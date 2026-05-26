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
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/components/ui_app_bar.dart';
import '../game/widgets/game_modal_chrome.dart';

ButtonStyle _deckActionButtonStyle(
  AppColorTokens colors, {
  Color? foreground,
  Color? border,
  bool expanded = false,
}) {
  return OutlinedButton.styleFrom(
    foregroundColor: foreground ?? colors.textPrimary,
    backgroundColor: colors.surface.withValues(alpha: 0.35),
    side: BorderSide(
      color: border ?? colors.borderSubtle,
      width: 1.25,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: LayoutTokens.gr2,
      vertical: LayoutTokens.gr2,
    ),
    minimumSize: Size(expanded ? double.infinity : 0, LayoutTokens.minTapTarget),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: RoundedRectangleBorder(
      borderRadius: RadiusTokens.radiusControlMd,
    ),
    textStyle: TextStyle(
      fontSize: FontTokens.caption,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );
}

class _DeckCardActions extends StatelessWidget {
  const _DeckCardActions({
    required this.colors,
    required this.onCommanders,
    required this.onRename,
    required this.onDelete,
  });

  final AppColorTokens colors;
  final VoidCallback onCommanders;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: LayoutTokens.gr3,
          thickness: 1,
          color: colors.borderSubtle.withValues(alpha: 0.65),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCommanders,
                icon: Icon(
                  Icons.style_outlined,
                  size: 18,
                  color: colors.primaryAccent,
                ),
                label: const Text('Commanders'),
                style: _deckActionButtonStyle(
                  colors,
                  foreground: colors.primaryAccent,
                  border: colors.primaryAccent.withValues(alpha: 0.5),
                ),
              ),
            ),
            SizedBox(width: LayoutTokens.gr1),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRename,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: colors.textPrimary,
                ),
                label: const Text('Rename'),
                style: _deckActionButtonStyle(colors),
              ),
            ),
          ],
        ),
        SizedBox(height: LayoutTokens.gr1),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: colors.error,
          ),
          label: const Text('Delete deck'),
          style: _deckActionButtonStyle(
            colors,
            foreground: colors.error,
            border: colors.error.withValues(alpha: 0.45),
            expanded: true,
          ),
        ),
      ],
    );
  }
}

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
          title: GameDialogTitleRow(
            title: 'Deck name',
            onClose: () => Navigator.pop(ctx),
          ),
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
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(ctx, t);
              },
              child: Text('Next'),
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
          title: GameDialogTitleRow(
            title: 'Rename deck',
            onClose: () => Navigator.pop(ctx),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(ctx, t);
              },
              child: Text('Save'),
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
        title: GameDialogTitleRow(
          title: 'Delete deck?',
          onClose: () => Navigator.pop(ctx, false),
        ),
        content: Text(
          'Remove “${deck.displayName}”? Stats for this deck will be deleted.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete'),
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
    ref.listen(deckListRevisionProvider, (_, __) => _reload());
    final colors = AppColorTokens.of(context);
    final repo = ref.read(deckRepositoryProvider);

    return Scaffold(
      appBar: const UiAppBar(title: 'My decks'),
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
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.all(LayoutTokens.gr3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResolvedDeckCommanderAvatarCluster(
                        deck: deck,
                        colors: colors,
                        size: 60,
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
                                fontSize: FontTokens.body,
                                height: 1.25,
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
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                  _DeckCardActions(
                    colors: colors,
                    onCommanders: () => _editCommanders(deck),
                    onRename: () => _renameDeck(repo, deck),
                    onDelete: () => _confirmDelete(repo, deck),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _promptNewDeckName,
        icon: Icon(Icons.add),
        label: Text('Add deck'),
      ),
    );
  }
}
