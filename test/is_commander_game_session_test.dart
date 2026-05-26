import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgt_life_spark/core/game/game_format.dart';
import 'package:mgt_life_spark/core/game/player_game_state.dart';
import 'package:mgt_life_spark/features/game/widgets/commander_damage_panel.dart';

PlayerGameState _player({
  String id = 'p1',
  String? commanderName,
  int life = 40,
}) {
  return PlayerGameState(
    playerId: id,
    username: id,
    playerColor: Colors.blue,
    life: life,
    commanderName: commanderName,
  );
}

void main() {
  test('solo commander pod stays visible after gaining life', () {
    final local = _player(life: 41);

    expect(
      isCommanderGameSession(
        local: local,
        allPlayers: [local],
        gameFormat: GameFormat.commander,
        startingLife: 40,
      ),
      isTrue,
    );
  });

  test('solo standard pod without commander stays hidden', () {
    final local = _player(life: 20);

    expect(
      isCommanderGameSession(
        local: local,
        allPlayers: [local],
        gameFormat: GameFormat.standard,
        startingLife: 20,
      ),
      isFalse,
    );
  });

  test('commander name always enables commander damage UI', () {
    final local = _player(commanderName: 'Atraxa', life: 50);

    expect(
      isCommanderGameSession(
        local: local,
        allPlayers: [local],
        gameFormat: GameFormat.standard,
        startingLife: 20,
      ),
      isTrue,
    );
  });
}
