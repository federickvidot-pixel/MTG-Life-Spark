import 'package:hive/hive.dart';

part 'commander_stats.g.dart';

@HiveType(typeId: 2)
class CommanderStats extends HiveObject {
  @HiveField(0)
  String commanderName;

  @HiveField(1)
  int wins;

  @HiveField(2)
  int losses;

  @HiveField(3)
  int gamesPlayed;

  CommanderStats({
    required this.commanderName,
    this.wins = 0,
    this.losses = 0,
    this.gamesPlayed = 0,
  });

  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;
}
