import 'package:flutter_test/flutter_test.dart';
import 'package:mgt_life_spark/core/game/stack_example_data.dart';

void main() {
  test('demo pod players include commander art for damage UI', () {
    final players = mergeExamplePodPlayers(
      current: const [],
      localPlayerId: 'you',
      startingLife: 40,
    );

    final jordan = players.firstWhere((p) => p.username == 'Jordan');
    final sam = players.firstWhere((p) => p.username == 'Sam');
    final riley = players.firstWhere((p) => p.username == 'Riley');

    expect(jordan.commanderImageUrl, contains('scryfall.io'));
    expect(sam.commanderImageUrl, contains('scryfall.io'));
    expect(riley.commanderImageUrl, contains('scryfall.io'));
    expect(riley.partnerCommanderImageUrl, contains('scryfall.io'));
  });
}
