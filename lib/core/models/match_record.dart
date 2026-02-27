import 'package:hive/hive.dart';

part 'match_record.g.dart';

@HiveType(typeId: 1)
class MatchRecord extends HiveObject {
  @HiveField(0)
  String matchId;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String commanderName;

  @HiveField(3)
  String? partnerCommanderName;

  @HiveField(4)
  List<String> opponentNames;

  @HiveField(5)
  String result; // 'win' | 'loss' | 'concede'

  @HiveField(6)
  String eliminationReason; // 'life' | 'poison' | 'commanderDamage' | 'deckEmpty' | 'concede' | 'survived'

  @HiveField(7)
  String format; // 'Commander' | 'Standard'

  @HiveField(8)
  int durationMinutes;

  @HiveField(9)
  int startingLifeTotal;

  @HiveField(10)
  int playerCount;

  MatchRecord({
    required this.matchId,
    required this.date,
    required this.commanderName,
    this.partnerCommanderName,
    required this.opponentNames,
    required this.result,
    required this.eliminationReason,
    required this.format,
    required this.durationMinutes,
    required this.startingLifeTotal,
    required this.playerCount,
  });
}
