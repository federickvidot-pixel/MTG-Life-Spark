import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/providers.dart';

/// Thin wrapper around Flutter's built-in HapticFeedback.
/// Respects the user's haptic preference from AppSettings.
class HapticService {
  bool _enabled = true;

  void setEnabled(bool enabled) => _enabled = enabled;

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
  final settings = ref.read(settingsRepositoryProvider).settings;
  final service = HapticService();
  service.setEnabled(settings.hapticEnabled);
  return service;
});
