import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/alliance.dart';
import '../../../core/game/alliance_ui_events.dart';
import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import 'game_modal_chrome.dart';
import 'game_ui_tokens.dart';

/// Shows alliance-related dialogs when [allianceUiEventProvider] updates.
void handleAllianceUiEvent(
  BuildContext context,
  WidgetRef ref,
  AllianceUiEvent? event,
) {
  if (event == null || !context.mounted) return;

  switch (event.kind) {
    case AllianceUiEventKind.inviteReceived:
      showAllianceInviteDialog(
        context: context,
        ref: ref,
        fromUsername: event.otherUsername ?? 'A player',
        durationLabel: event.durationLabel ?? allianceDurationLabel(
          AllianceDuration.manual,
        ),
      );
    case AllianceUiEventKind.allianceFormed:
      showAllianceFormedDialog(
        context: context,
        allyUsername: event.allyUsername ?? 'your ally',
        durationLabel: event.durationLabel,
      );
    case AllianceUiEventKind.allianceDeclined:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secret alliance offer declined')),
      );
    case AllianceUiEventKind.allianceRevealed:
      showAllianceRevealedDialog(
        context: context,
        playerA: event.otherUsername ?? '?',
        playerB: event.allyUsername ?? '?',
      );
    case AllianceUiEventKind.allianceBroken:
      if (event.betrayal) {
        showAllianceBetrayalDialog(
          context: context,
          playerA: event.otherUsername ?? '?',
          playerB: event.allyUsername ?? '?',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret alliance ended')),
        );
      }
  }

  ref.read(gameProvider.notifier).clearAllianceUiEvent();
}

Future<void> showProposeAllianceSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PlayerGameState target,
}) {
  AllianceDuration duration = AllianceDuration.endOfRound;
  AllianceDeliveryTiming timing = AllianceDeliveryTiming.now;
  var delaySeconds = 30;

  return showGameBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        void sendWhisper() {
          final local = ref.read(gameProvider).localPlayer;
          if (local == null) return;
          ref.read(gameProvider.notifier).proposeAlliance(
                local.playerId,
                target.playerId,
                duration,
                timing: timing,
                delaySeconds: delaySeconds,
              );
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                timing == AllianceDeliveryTiming.now
                    ? 'Whisper sent to ${target.username}'
                    : 'Whisper scheduled for ${target.username}',
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: GameSheetBody(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GameSheetHeader(
                            title: 'Secret alliance',
                            subtitle:
                                'Invite ${target.username} — only they will know.',
                          ),
                          SizedBox(height: LayoutTokens.gr2),
                          Text(
                            'Duration',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: FontTokens.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: LayoutTokens.gr1),
                          ...AllianceDuration.values.map((d) {
                            final selected = duration == d;
                            return Padding(
                              padding: EdgeInsets.only(bottom: LayoutTokens.gr1),
                              child: ListTile(
                                tileColor: selected
                                    ? AppTheme.accentGold.withValues(alpha: 0.12)
                                    : AppTheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: RadiusTokens.radiusControlSm,
                                ),
                                title: Text(allianceDurationLabel(d)),
                                trailing: selected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: AppTheme.accentGold,
                                      )
                                    : null,
                                onTap: () => setState(() => duration = d),
                              ),
                            );
                          }),
                          SizedBox(height: LayoutTokens.gr2),
                          Text(
                            'When to deliver',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: FontTokens.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: LayoutTokens.gr1),
                          Wrap(
                            spacing: LayoutTokens.gr1,
                            runSpacing: LayoutTokens.gr1,
                            children: AllianceDeliveryTiming.values.map((t) {
                              final selected = timing == t;
                              return ChoiceChip(
                                label: Text(
                                  allianceDeliveryLabel(
                                    t,
                                    seconds: delaySeconds,
                                  ),
                                ),
                                selected: selected,
                                onSelected: (_) => setState(() => timing = t),
                              );
                            }).toList(),
                          ),
                          if (timing == AllianceDeliveryTiming.delaySeconds) ...[
                            SizedBox(height: LayoutTokens.gr2),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: delaySeconds.toDouble(),
                                    min: 10,
                                    max: 120,
                                    divisions: 11,
                                    label: '${delaySeconds}s',
                                    onChanged: (v) =>
                                        setState(() => delaySeconds = v.round()),
                                  ),
                                ),
                                Text('${delaySeconds}s'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: LayoutTokens.gr2),
                  FilledButton(
                    style: GameUiTokens.sheetPrimaryButton(AppTheme.accentGold),
                    onPressed: sendWhisper,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> showAllianceInviteDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String fromUsername,
  required String durationLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.radiusMd),
      title: Row(
        children: [
          Icon(Icons.handshake, color: AppTheme.accentGold),
          SizedBox(width: LayoutTokens.gr1),
          const Expanded(child: Text('Secret offer')),
        ],
      ),
      content: Text(
        '$fromUsername proposes a secret alliance.\n\nDuration: $durationLabel\n\nOnly you can see this.',
        style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final localId = ref.read(gameProvider).localPlayerId;
            ref.read(gameProvider.notifier).respondToAlliance(localId, false);
            Navigator.pop(dialogContext);
          },
          child: const Text('Decline'),
        ),
        FilledButton(
          style: GameUiTokens.sheetPrimaryButton(AppTheme.accentGold),
          onPressed: () {
            final localId = ref.read(gameProvider).localPlayerId;
            ref.read(gameProvider.notifier).respondToAlliance(localId, true);
            Navigator.pop(dialogContext);
          },
          child: const Text('Accept'),
        ),
      ],
    ),
  );
}

Future<void> showAllianceFormedDialog({
  required BuildContext context,
  required String allyUsername,
  String? durationLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.radiusMd),
      title: Row(
        children: [
          Icon(Icons.handshake, color: AppTheme.accentGold, size: 28),
          SizedBox(width: LayoutTokens.gr1),
          const Expanded(child: Text('Alliance formed')),
        ],
      ),
      content: Text(
        'You and $allyUsername are now secretly allied'
        '${durationLabel != null ? ' ($durationLabel)' : ''}.\n\n'
        'The table does not know — unless you reveal or betray.',
        style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Understood'),
        ),
      ],
    ),
  );
}

Future<void> showAllianceRevealedDialog({
  required BuildContext context,
  required String playerA,
  required String playerB,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.card,
      title: const Text('Alliance revealed'),
      content: Text(
        '$playerA and $playerB have revealed their secret alliance to the table.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showAllianceBetrayalDialog({
  required BuildContext context,
  required String playerA,
  required String playerB,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.card,
      title: Text('Betrayal!', style: TextStyle(color: AppTheme.danger)),
      content: Text(
        'The secret alliance between $playerA and $playerB has been broken by betrayal.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class OverviewPlayerMarkerBadges extends StatelessWidget {
  const OverviewPlayerMarkerBadges({
    super.key,
    required this.game,
    required this.playerId,
  });

  final GameState game;
  final String playerId;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];
    final localId = game.localPlayerId;
    final alliance = game.allianceFor(playerId);
    if (alliance != null && alliance.isRevealed) {
      badges.add(_chip('Allied'));
    } else if (alliance != null && alliance.involves(localId)) {
      badges.add(_chip('Secret ally'));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: LayoutTokens.gr0,
      runSpacing: LayoutTokens.gr0,
      children: badges,
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr0 + 2,
        vertical: LayoutTokens.gr0 - 1,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: OpacityTokens.subtle),
        borderRadius: RadiusTokens.radiusControlSm,
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: OpacityTokens.soft),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.accentGold,
          fontSize: FontTokens.hudXs,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

String? pendingAllianceLabel(GameState game, String playerId) {
  if (playerId != game.localPlayerId) return null;
  final scheduled =
      game.scheduledProposalsFrom(playerId).where((p) => !p.delivered);
  if (scheduled.isNotEmpty) {
    final target = game.playerById(scheduled.first.toId)?.username ?? '?';
    return 'Whisper pending → $target';
  }
  final outgoing = game.pendingProposals.where((p) => p.fromId == playerId);
  if (outgoing.isNotEmpty) {
    final target = game.playerById(outgoing.first.toId)?.username ?? '?';
    return 'Awaiting $target';
  }
  return null;
}
