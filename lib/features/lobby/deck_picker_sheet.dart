import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/game/lobby_state.dart';
import '../../core/persistence/providers.dart';
import '../../shared/utils/app_router.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/layout_tokens.dart';

/// Pick a registered deck for match tracking, or clear deck selection.
Future<void> showDeckPickerSheet(
  BuildContext context,
  WidgetRef ref,
  String playerId,
) async {
  final decks = ref.read(deckRepositoryProvider).getAll();
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    showDragHandle: true,
    builder: (ctx) {
      final colors = AppColorTokens.of(ctx);
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  LayoutTokens.gr3,
                  LayoutTokens.gr1,
                  LayoutTokens.gr3,
                  LayoutTokens.gr2,
                ),
                child: Text(
                  'Deck for this match',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person_outline, color: colors.textSecondary),
                title: Text(
                  'Manual commander only',
                  style: TextStyle(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Keep commanders as-is; do not attribute to a saved deck',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  ref.read(lobbyProvider.notifier).clearSelectedDeck(playerId);
                  Navigator.pop(ctx);
                },
              ),
              Divider(color: colors.borderSubtle, height: 1),
              if (decks.isEmpty)
                Padding(
                  padding: EdgeInsets.all(LayoutTokens.gr3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No saved decks yet. Create one from the Decks tab and assign a commander.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                      SizedBox(height: LayoutTokens.gr2),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ctx.go(AppRoutes.decks);
                        },
                        child: Text('Open Decks'),
                      ),
                    ],
                  ),
                )
              else
                ...decks.map(
                  (d) => ListTile(
                    leading: Icon(Icons.style, color: colors.primaryAccent),
                    title: Text(
                      d.displayName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      d.hasPartner
                          ? '${d.commanderName} // ${d.partnerCommanderName}'
                          : d.commanderName,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      d.gamesPlayed > 0
                          ? '${(d.winRate * 100).round()}% WR'
                          : '—',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      ref
                          .read(lobbyProvider.notifier)
                          .applyDeck(playerId: playerId, deck: d);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              SizedBox(height: LayoutTokens.gr2),
            ],
          ),
        ),
      );
    },
  );
}
