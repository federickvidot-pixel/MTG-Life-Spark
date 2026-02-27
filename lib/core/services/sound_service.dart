import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/providers.dart';

/// Wraps audioplayers to play sound effects from assets/sounds/.
/// Fails silently if a file is missing or audio is disabled.
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  void setEnabled(bool enabled) => _enabled = enabled;

  Future<void> _play(String fileName) async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (_) {
      // File not found or playback error — silently ignore.
    }
  }

  Future<void> lifeGain() => _play('life_gain.mp3');
  Future<void> lifeLoss() => _play('life_loss.mp3');
  Future<void> levelUp() => _play('level_up.mp3');
  Future<void> elimination() => _play('elimination.mp3');
  Future<void> counterChange() => _play('counter_change.mp3');
  Future<void> allianceFormed() => _play('alliance.mp3');
  Future<void> timeout() => _play('timeout.mp3');

  void dispose() => _player.dispose();
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final settings = ref.read(settingsRepositoryProvider).settings;
  final service = SoundService();
  service.setEnabled(settings.soundEnabled);
  ref.onDispose(service.dispose);
  return service;
});
