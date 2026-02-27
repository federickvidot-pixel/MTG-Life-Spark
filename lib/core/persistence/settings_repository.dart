import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  static const _boxName = 'appSettings';
  static const _settingsKey = 'settings';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<AppSettings>(_boxName);
    }
    // Ensure a default settings object exists
    if (!_box.containsKey(_settingsKey)) {
      await _box.put(_settingsKey, AppSettings());
    }
  }

  Box<AppSettings> get _box => Hive.box<AppSettings>(_boxName);

  AppSettings get settings => _box.get(_settingsKey)!;

  Future<void> update(AppSettings updated) async {
    await _box.put(_settingsKey, updated);
  }

  Future<void> markOnboardingCompleted() async {
    final s = settings;
    s.onboardingCompleted = true;
    await s.save();
  }
}
