import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgt_life_spark/core/game/alliance.dart';
import 'package:mgt_life_spark/core/game/game_state.dart';
import 'package:mgt_life_spark/core/game/player_game_state.dart';
import 'package:mgt_life_spark/features/game/widgets/alliance_overview_ui.dart';

PlayerGameState _player(String id) => PlayerGameState(
      playerId: id,
      username: id,
      playerColor: Colors.blue,
      life: 40,
    );

GameState _game({
  required String localId,
  List<Alliance> alliances = const [],
  List<AllianceProposal> scheduled = const [],
  List<AllianceProposal> pending = const [],
}) {
  return GameState(
    localPlayerId: localId,
    players: [_player('a'), _player('b'), _player('c')],
    turnOrder: const ['a', 'b', 'c'],
    alliances: alliances,
    scheduledProposals: scheduled,
    pendingProposals: pending,
    monarchPlayerId: 'b',
    initiativePlayerId: 'c',
  );
}

void main() {
  test('visibleAllianceFor hides secret alliances from outsiders', () {
    const secret = Alliance(
      id: 'x',
      proposerId: 'a',
      targetId: 'b',
      duration: AllianceDuration.manual,
      formedAtRound: 1,
      formedAtTurnIndex: 0,
    );
    final game = _game(localId: 'c', alliances: [secret]);

    expect(game.visibleAllianceFor('a', 'b'), secret);
    expect(game.visibleAllianceFor('c', 'b'), isNull);
  });

  test('visibleAllianceFor shows revealed alliances to everyone', () {
    const revealed = Alliance(
      id: 'x',
      proposerId: 'a',
      targetId: 'b',
      duration: AllianceDuration.manual,
      formedAtRound: 1,
      formedAtTurnIndex: 0,
      isRevealed: true,
    );
    final game = _game(localId: 'c', alliances: [revealed]);

    expect(game.visibleAllianceFor('c', 'b'), revealed);
  });

  test('pendingAllianceLabel is only visible to the local proposer', () {
    final scheduled = [
      AllianceProposal(
        id: 'p1',
        fromId: 'a',
        toId: 'b',
        duration: AllianceDuration.manual,
        deliveryTiming: AllianceDeliveryTiming.delaySeconds,
        delivered: false,
      ),
    ];
    final gameAsProposer = _game(localId: 'a', scheduled: scheduled);
    final gameAsOutsider = _game(localId: 'c', scheduled: scheduled);

    expect(pendingAllianceLabel(gameAsProposer, 'a'), contains('Whisper pending'));
    expect(pendingAllianceLabel(gameAsOutsider, 'a'), isNull);
  });

  test('alliance proposal round-trips through json', () {
    final proposal = AllianceProposal(
      id: 'p1',
      fromId: 'a',
      toId: 'b',
      duration: AllianceDuration.endOfRound,
      deliveryTiming: AllianceDeliveryTiming.endOfProposerTurn,
      createdAtRound: 2,
      createdAtTurnIndex: 1,
      delivered: false,
    );

    final restored = AllianceProposal.fromJson(proposal.toJson());
    expect(restored.id, proposal.id);
    expect(restored.deliveryTiming, AllianceDeliveryTiming.endOfProposerTurn);
    expect(restored.delivered, isFalse);
  });
}
