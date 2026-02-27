import 'package:hive/hive.dart';

part 'player_profile.g.dart';

@HiveType(typeId: 0)
class PlayerProfile extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  int level;

  @HiveField(2)
  int xp;

  @HiveField(3)
  String tier; // 'Bronze' | 'Silver' | 'Gold' | 'Platinum' | 'Diamond'

  @HiveField(4)
  int totalWins;

  @HiveField(5)
  int totalLosses;

  @HiveField(6)
  String? selectedCommanderName;

  @HiveField(7)
  String? selectedCommanderImageUrl;

  @HiveField(8)
  String? selectedPartnerCommanderName;

  @HiveField(9)
  String? selectedPartnerCommanderImageUrl;

  @HiveField(10)
  List<String> unlockedThemes;

  @HiveField(11)
  List<String> unlockedBadges;

  @HiveField(12)
  int lifetimePoisonDealt;

  @HiveField(13)
  int lifetimeCommanderKills;

  @HiveField(14)
  int currentWinStreak;

  @HiveField(15)
  int totalGamesPlayed;

  @HiveField(16)
  String? profileAvatarImageUrl;

  PlayerProfile({
    required this.username,
    this.level = 1,
    this.xp = 0,
    this.tier = 'Bronze',
    this.totalWins = 0,
    this.totalLosses = 0,
    this.selectedCommanderName,
    this.selectedCommanderImageUrl,
    this.selectedPartnerCommanderName,
    this.selectedPartnerCommanderImageUrl,
    this.unlockedThemes = const ['default'],
    this.unlockedBadges = const [],
    this.lifetimePoisonDealt = 0,
    this.lifetimeCommanderKills = 0,
    this.currentWinStreak = 0,
    this.totalGamesPlayed = 0,
    this.profileAvatarImageUrl,
  });
}
