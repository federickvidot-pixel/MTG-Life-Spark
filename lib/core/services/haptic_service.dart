import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/providers.dart';

/// Thin wrapper around Flutter's built-in HapticFeedback.
/// Respects the user's haptic preference from AppSettings.
class HapticService {
  HapticService(this._ref);

  final Ref _ref;

  bool get _enabled =>
      _ref.read(settingsRepositoryProvider).settings.hapticEnabled;

  /// Light tap — use for counter increments, life +1.
  Future<void> light() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact — use for turn end, phase advance, undo.
  Future<void> medium() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — use for elimination, level up, concede.
  Future<void> heavy() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click — use for toggling options.
  Future<void> selection() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }
}

final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService(ref);
});
