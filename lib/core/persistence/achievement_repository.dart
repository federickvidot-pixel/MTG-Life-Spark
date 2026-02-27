import 'package:hive_flutter/hive_flutter.dart';
import '../models/achievement_record.dart';

class AchievementRepository {
  static const _boxName = 'achievements';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<AchievementRecord>(_boxName);
    }
  }

  Box<AchievementRecord> get _box => Hive.box<AchievementRecord>(_boxName);

  bool isUnlocked(String achievementId) => _box.containsKey(achievementId);

  Future<void> unlock(String achievementId) async {
    if (isUnlocked(achievementId)) return;
    await _box.put(
      achievementId,
      AchievementRecord(achievementId: achievementId, unlockedAt: DateTime.now()),
    );
  }

  List<AchievementRecord> getAll() => _box.values.toList();

  Set<String> getUnlockedIds() => _box.keys.cast<String>().toSet();
}
