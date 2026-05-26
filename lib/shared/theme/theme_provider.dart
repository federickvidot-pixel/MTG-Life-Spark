import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/providers.dart';
import '../../core/persistence/settings_repository.dart';
import '../../ui/tokens/app_color_palettes.dart';
import '../../ui/tokens/color_tokens.dart';
import 'app_theme.dart';

/// User's color scheme preference (persisted). Violet, Crimson, or Slate.
final colorSchemePreferenceProvider =
    StateNotifierProvider<ColorSchemePreferenceNotifier, AppColorSchemeId>(
        (ref) {
  final repo = ref.read(settingsRepositoryProvider);
  final initial = AppColorPalettes.parse(repo.settings.colorSchemeId);
  ColorTokens.applyScheme(initial);
  return ColorSchemePreferenceNotifier(initial, repo);
});

class ColorSchemePreferenceNotifier extends StateNotifier<AppColorSchemeId> {
  ColorSchemePreferenceNotifier(super.initial, this._repo);

  final SettingsRepository _repo;

  Future<void> setColorScheme(AppColorSchemeId id) async {
    if (state == id) return;
    state = id;
    ColorTokens.applyScheme(id);
    _invalidateThemeCache();
    final s = _repo.settings;
    s.colorSchemeId = AppColorPalettes.storageKey(id);
    await _repo.update(s);
  }
}

ThemeData? _cachedDarkTheme;
AppColorSchemeId? _cachedSchemeId;

void _invalidateThemeCache() {
  _cachedDarkTheme = null;
  _cachedSchemeId = null;
}

ThemeData _darkTheme(AppColorSchemeId schemeId) {
  if (_cachedDarkTheme != null && _cachedSchemeId == schemeId) {
    return _cachedDarkTheme!;
  }
  ColorTokens.applyScheme(schemeId);
  _cachedSchemeId = schemeId;
  return _cachedDarkTheme = AppTheme.dark();
}

/// Effective theme — always dark, tinted by the selected color scheme.
final effectiveThemeProvider = Provider<ThemeData>((ref) {
  final schemeId = ref.watch(colorSchemePreferenceProvider);
  return _darkTheme(schemeId);
});
