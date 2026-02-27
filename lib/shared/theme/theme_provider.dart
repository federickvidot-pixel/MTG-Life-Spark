import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game/game_providers.dart';
import '../../core/game/game_state.dart';
import '../../core/persistence/providers.dart';
import '../../core/persistence/settings_repository.dart';
import 'app_theme.dart';

/// User's theme preference (persisted). Updated by Settings and Day/Night.
final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, bool>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return ThemePreferenceNotifier(repo.settings.useDarkTheme, repo);
});

class ThemePreferenceNotifier extends StateNotifier<bool> {
  ThemePreferenceNotifier(super.initial, this._repo);

  final SettingsRepository _repo;

  Future<void> setUseDarkTheme(bool value) async {
    state = value;
    final s = _repo.settings;
    s.useDarkTheme = value;
    await _repo.update(s);
  }
}

/// Effective theme: when in game, Day/Night overrides settings.
/// Day → light, Night → dark, None → use settings.
final effectiveThemeProvider = Provider<ThemeData>((ref) {
  final game = ref.watch(gameProvider);
  final useDarkTheme = ref.watch(themePreferenceProvider);

  final inGame = game.players.isNotEmpty;

  if (inGame) {
    switch (game.dayNight) {
      case DayNightState.day:
        return AppTheme.light();
      case DayNightState.night:
        return AppTheme.dark();
      case DayNightState.none:
        return useDarkTheme ? AppTheme.dark() : AppTheme.light();
    }
  }

  return useDarkTheme ? AppTheme.dark() : AppTheme.light();
});
