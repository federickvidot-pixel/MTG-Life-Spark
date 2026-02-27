import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_profile.dart';
import 'profile_repository.dart';
import 'match_repository.dart';
import 'achievement_repository.dart';
import 'feedback_repository.dart';
import 'settings_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Profile data provider. Invalidate this after saving to refresh the UI.
final profileProvider = Provider<PlayerProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});
