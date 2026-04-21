import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'player_deck.g.dart';

@HiveType(typeId: 6)
class PlayerDeck extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String displayName;

  @HiveField(2)
  String commanderName;

  @HiveField(3)
  String? commanderImageUrl;

  @HiveField(4)
  String? partnerCommanderName;

  @HiveField(5)
  String? partnerCommanderImageUrl;

  @HiveField(6)
  int wins;

  @HiveField(7)
  int losses;

  @HiveField(8)
  int gamesPlayed;

  /// Scryfall-style mana cost, e.g. `{3}{W}{U}`.
  @HiveField(9)
  String? commanderManaCost;

  @HiveField(10)
  String? partnerManaCost;

  PlayerDeck({
    required this.id,
    required this.displayName,
    required this.commanderName,
    this.commanderImageUrl,
    this.partnerCommanderName,
    this.partnerCommanderImageUrl,
    this.wins = 0,
    this.losses = 0,
    this.gamesPlayed = 0,
    this.commanderManaCost,
    this.partnerManaCost,
  });

  bool get hasPartner =>
      partnerCommanderName != null && partnerCommanderName!.isNotEmpty;

  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  factory PlayerDeck.create({
    required String displayName,
    required String commanderName,
    String? commanderImageUrl,
    String? partnerCommanderName,
    String? partnerCommanderImageUrl,
    String? commanderManaCost,
    String? partnerManaCost,
  }) =>
      PlayerDeck(
        id: const Uuid().v4(),
        displayName: displayName,
        commanderName: commanderName,
        commanderImageUrl: commanderImageUrl,
        partnerCommanderName: partnerCommanderName,
        partnerCommanderImageUrl: partnerCommanderImageUrl,
        commanderManaCost: commanderManaCost,
        partnerManaCost: partnerManaCost,
      );
}
