import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_profile.dart';
import '../models/pod_preset.dart';
import 'profile_repository.dart';
import 'match_repository.dart';
import 'achievement_repository.dart';
import 'feedback_repository.dart';
import 'pod_repository.dart';
import 'deck_repository.dart';
import 'settings_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Bumped when [PlayerProfile] is mutated in place so [profileProvider] rebuilds.
/// (Same Hive object reference would otherwise satisfy `==` and skip Riverpod notify.)
final profileRevisionProvider = StateProvider<int>((ref) => 0);

/// Profile + revision. The revision field is required so Riverpod does not treat
/// consecutive reads as "unchanged" when [getProfile] returns the same Hive instance
/// after in-place mutation.
typedef ProfileWatch = ({PlayerProfile? profile, int revision});

final profileProvider = Provider<ProfileWatch>((ref) {
  final revision = ref.watch(profileRevisionProvider);
  final profile = ref.watch(profileRepositoryProvider).getProfile();
  return (profile: profile, revision: revision);
});

/// Call after any in-place [PlayerProfile] mutation (Hive save) so UI updates.
void bumpProfileRevision(WidgetRef ref) {
  ref.read(profileRevisionProvider.notifier).state++;
}

/// Same as [bumpProfileRevision] for `Ref` (e.g. [StateNotifier] / async providers).
void bumpProfileRevisionRef(Ref ref) {
  ref.read(profileRevisionProvider.notifier).state++;
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

final podRepositoryProvider = Provider<PodRepository>((ref) {
  return PodRepository();
});

/// Bumped when pod presets in Hive change so UI (e.g. lobby dropdown) rebuilds.
final podPresetsRevisionProvider = StateProvider<int>((ref) => 0);

/// Sorted pod list; watches [podPresetsRevisionProvider] so saves invalidate the cache.
final podPresetsListProvider = Provider<List<PodPreset>>((ref) {
  ref.watch(podPresetsRevisionProvider);
  return ref.watch(podRepositoryProvider).getAll();
});

void bumpPodPresetsRevision(WidgetRef ref) {
  ref.read(podPresetsRevisionProvider.notifier).state++;
}

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository();
});

/// Bumped when deck list or deck Hive rows change so profile deck performance refreshes.
final deckListRevisionProvider = StateProvider<int>((ref) => 0);

void bumpDeckListRevision(WidgetRef ref) {
  ref.read(deckListRevisionProvider.notifier).state++;
}

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// Bumped when app settings change so router redirect and UI refresh.
final settingsRevisionProvider = StateProvider<int>((ref) => 0);

void bumpSettingsRevision(WidgetRef ref) {
  ref.read(settingsRevisionProvider.notifier).state++;
}

void bumpSettingsRevisionRef(Ref ref) {
  ref.read(settingsRevisionProvider.notifier).state++;
}
