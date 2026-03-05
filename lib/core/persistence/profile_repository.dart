import 'package:hive_flutter/hive_flutter.dart';
import '../models/player_profile.dart';
import '../models/commander_stats.dart';

class ProfileRepository {
  static const _profileBox = 'playerProfile';
  static const _commanderStatsBox = 'commanderStats';
  static const _profileKey = 'myProfile';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_profileBox)) {
      await Hive.openBox<PlayerProfile>(_profileBox);
    }
    if (!Hive.isBoxOpen(_commanderStatsBox)) {
      await Hive.openBox<CommanderStats>(_commanderStatsBox);
    }
  }

  Box<PlayerProfile> get _box => Hive.box<PlayerProfile>(_profileBox);
  Box<CommanderStats> get _statsBox =>
      Hive.box<CommanderStats>(_commanderStatsBox);

  PlayerProfile? getProfile() => _box.get(_profileKey);

  Future<void> saveProfile(PlayerProfile profile) async {
    await _box.put(_profileKey, profile);
  }

  bool get hasProfile => _box.containsKey(_profileKey);

  Future<void> recordMatchResult({
    required String commanderName,
    required bool won,
    required int xpGained,
  }) async {
    final profile = getProfile();
    if (profile == null) return;

    profile.xp += xpGained;
    profile.totalGamesPlayed += 1;

    if (won) {
      profile.totalWins += 1;
    } else {
      profile.totalLosses += 1;
    }

    profile.level = _calculateLevel(profile.xp);
    profile.tier = _calculateTier(profile.level);

    await profile.save();

    await _updateCommanderStats(commanderName, won);
  }

  Future<void> incrementCommanderKills() async {
    final profile = getProfile();
    if (profile == null) return;
    profile.lifetimeCommanderKills += 1;
    await profile.save();
  }

  Future<void> addPoisonDealt(int amount) async {
    final profile = getProfile();
    if (profile == null) return;
    profile.lifetimePoisonDealt += amount;
    await profile.save();
  }

  /// Add XP without affecting match stats (e.g. for giving likes).
  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    final profile = getProfile();
    if (profile == null) return;
    profile.xp += amount;
    profile.level = _calculateLevel(profile.xp);
    profile.tier = _calculateTier(profile.level);
    await profile.save();
  }

  Future<void> _updateCommanderStats(String commanderName, bool won) async {
    CommanderStats stats =
        _statsBox.get(commanderName) ??
        CommanderStats(commanderName: commanderName);
    stats.gamesPlayed += 1;
    if (won) {
      stats.wins += 1;
    } else {
      stats.losses += 1;
    }
    await _statsBox.put(commanderName, stats);
  }

  List<CommanderStats> getAllCommanderStats() => _statsBox.values.toList();

  CommanderStats? getCommanderStats(String name) => _statsBox.get(name);

  int _calculateLevel(int xp) {
    // Bronze 1-10: 500 XP each = 5000 total
    // Silver 11-25: 1000 XP each = 15000 total
    // Gold 26-50: 2000 XP each = 50000 total
    // Platinum 51-75: 3500 XP each = 87500 total
    // Diamond 76-100: 5000 XP each = 125000 total
    const thresholds = [
      (10, 500),
      (25, 1000),
      (50, 2000),
      (75, 3500),
      (100, 5000),
    ];

    int level = 1;
    int remaining = xp;

    for (final (maxLevel, xpPerLevel) in thresholds) {
      while (level < maxLevel && remaining >= xpPerLevel) {
        remaining -= xpPerLevel;
        level++;
      }
      if (remaining < xpPerLevel && level <= maxLevel) break;
    }

    return level.clamp(1, 100);
  }

  String _calculateTier(int level) {
    if (level <= 10) return 'Bronze';
    if (level <= 25) return 'Silver';
    if (level <= 50) return 'Gold';
    if (level <= 75) return 'Platinum';
    return 'Diamond';
  }
}
