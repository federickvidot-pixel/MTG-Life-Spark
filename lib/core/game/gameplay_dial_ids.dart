import 'player_game_state.dart';

/// Preset modular dial keys (blueprint). Values live in [PlayerGameState.extraDials].
abstract final class GameplayDialIds {
  static const blood = 'blood';
  static const clue = 'clue';
  static const map = 'map';
  static const treasure = 'treasure';
  static const devotion = 'devotion';
  static const creatures = 'creatures';
  static const enchantments = 'enchantments';
  static const artifacts = 'artifacts';
  static const graveyardCreatures = 'gy_creatures';
  static const exile = 'exile';

  static const List<String> presets = [
    blood,
    clue,
    map,
    treasure,
    devotion,
    creatures,
    enchantments,
    artifacts,
    graveyardCreatures,
    exile,
  ];

  /// Max counters visible on the gameplay strip (one row + Add tile).
  static const int maxStripDials = 4;

  /// Max user-defined custom counters per player.
  static const int maxCustomDials = 4;
}

/// Shared rules for counter limits on the gameplay strip.
abstract final class GameplayDialLimits {
  static int customDialCount(PlayerGameState player) =>
      player.customDialLabels.length;

  static int stripDialCount(PlayerGameState player) =>
      player.visibleGameplayDials.length;

  static int visibleCustomDialCount(PlayerGameState player) =>
      player.visibleGameplayDials
          .where((id) => player.customDialLabels.containsKey(id))
          .length;

  static bool stripIsFull(PlayerGameState player) =>
      stripDialCount(player) >= GameplayDialIds.maxStripDials;

  static bool canAddDialToStrip(PlayerGameState player) => !stripIsFull(player);

  static bool canAddCustomDial(PlayerGameState player) =>
      customDialCount(player) < GameplayDialIds.maxCustomDials &&
      canAddDialToStrip(player);

  /// Add tile stays in the row until 4 custom counters are showing, and only
  /// while the row still has fewer than 4 pills (prevents a clipped second row).
  static bool showAddCounterTile(
    PlayerGameState player, {
    required bool isEliminated,
  }) =>
      !isEliminated &&
      visibleCustomDialCount(player) < GameplayDialIds.maxCustomDials &&
      stripDialCount(player) < GameplayDialIds.maxStripDials;

  static bool canRegisterCustomDial(
    PlayerGameState player, {
    required bool isNewKey,
    required bool addsToStrip,
  }) {
    if (isNewKey &&
        customDialCount(player) >= GameplayDialIds.maxCustomDials) {
      return false;
    }
    if (addsToStrip && stripIsFull(player)) return false;
    return true;
  }
}
