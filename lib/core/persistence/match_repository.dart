import 'package:hive_flutter/hive_flutter.dart';
import '../models/match_record.dart';

class MatchRepository {
  static const _boxName = 'matchHistory';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<MatchRecord>(_boxName);
    }
  }

  Box<MatchRecord> get _box => Hive.box<MatchRecord>(_boxName);

  Future<void> saveMatch(MatchRecord record) async {
    await _box.put(record.matchId, record);
  }

  List<MatchRecord> getRecentMatches() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _box.values
        .where((m) => m.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<MatchRecord> getAllMatches() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Call on app startup — removes detailed entries older than 30 days.
  /// Stats should already be rolled into PlayerProfile lifetime totals.
  Future<void> purgeOldMatches() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final oldKeys = _box.keys.where((k) {
      final record = _box.get(k);
      return record != null && record.date.isBefore(cutoff);
    }).toList();

    await _box.deleteAll(oldKeys);
  }

  Future<void> deleteMatch(String matchId) async {
    await _box.delete(matchId);
  }
}
