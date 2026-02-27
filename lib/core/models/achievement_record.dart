import 'package:hive/hive.dart';

part 'achievement_record.g.dart';

@HiveType(typeId: 3)
class AchievementRecord extends HiveObject {
  @HiveField(0)
  String achievementId;

  @HiveField(1)
  DateTime unlockedAt;

  AchievementRecord({
    required this.achievementId,
    required this.unlockedAt,
  });
}
