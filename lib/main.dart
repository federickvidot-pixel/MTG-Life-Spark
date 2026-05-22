import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models/player_profile.dart';
import 'core/models/match_record.dart';
import 'core/models/commander_stats.dart';
import 'core/models/achievement_record.dart';
import 'core/models/app_settings.dart';
import 'core/models/pod_preset.dart';
import 'core/models/player_deck.dart';
import 'core/persistence/match_repository.dart';
import 'core/persistence/feedback_repository.dart';
import 'core/persistence/profile_repository.dart';
import 'shared/theme/theme_provider.dart';
import 'shared/utils/app_router.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    runApp(const ProviderScope(child: _AppBootstrap()));
  }, (error, stack) {
    debugPrint('Zone error: $error');
    debugPrint('Stack: $stack');
  });
}

/// Paints immediately so the HTML splash can dismiss, then finishes Hive init.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final Future<void> _initFuture = _initHive();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorApp(
            message: snapshot.error.toString(),
            stack: snapshot.stackTrace.toString(),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF0e0e0e),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.red.shade700),
                    const SizedBox(height: 16),
                    Text(
                      'Loading MGT Life Spark…',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const MgtLifeSparkApp();
      },
    );
  }
}

class _ErrorApp extends StatelessWidget {
  final String message;
  final String stack;

  const _ErrorApp({required this.message, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Startup Error', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[300])),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 24),
                Text('Stack trace:', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: 8),
                SelectableText(stack, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initHive() async {
  await Hive.initFlutter();

  // Register all adapters
  Hive.registerAdapter(PlayerProfileAdapter());
  Hive.registerAdapter(MatchRecordAdapter());
  Hive.registerAdapter(CommanderStatsAdapter());
  Hive.registerAdapter(AchievementRecordAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(PodPresetAdapter());
  Hive.registerAdapter(PlayerDeckAdapter());

  // Open all boxes up front
  await Hive.openBox<PlayerProfile>('playerProfile');
  await Hive.openBox<MatchRecord>('matchHistory');
  await Hive.openBox<CommanderStats>('commanderStats');
  await Hive.openBox<AchievementRecord>('achievements');
  await Hive.openBox<AppSettings>('appSettings');
  await Hive.openBox<String>('matchFeedback');
  await Hive.openBox<PodPreset>('podPresets');
  await Hive.openBox<PlayerDeck>('playerDecks');

  // Ensure default settings exist
  final settingsBox = Hive.box<AppSettings>('appSettings');
  if (!settingsBox.containsKey('settings')) {
    await settingsBox.put('settings', AppSettings());
  }

  // Purge match history entries older than 30 days on every startup
  await MatchRepository().purgeOldMatches();
  await FeedbackRepository().init();

  // Non-blocking maintenance — keeps first paint fast on web/mobile.
  unawaited(_deferredProfileMaintenance());
}

Future<void> _deferredProfileMaintenance() async {
  try {
    final profileRepo = ProfileRepository();
    final feedbackRepo = FeedbackRepository();
    final prof = profileRepo.getProfile();
    if (prof == null) return;
    await profileRepo.recomputeSocialStatsFromFeedback(
      feedbackRepo,
      prof.username,
    );
    await _maybeSeedPreviewXpRing(profileRepo);
  } catch (e, st) {
    debugPrint('Deferred profile maintenance failed: $e');
    debugPrint('Stack: $st');
  }
}

/// One-time: add XP so the profile ring shows a clear arc (does not repeat after the flag is set).
Future<void> _maybeSeedPreviewXpRing(ProfileRepository profileRepo) async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'profile_preview_xp_ring_v2';
  if (prefs.getBool(key) == true) return;

  final p = profileRepo.getProfile();
  if (p == null) return;

  int xpPerLevel(int level) {
    const thresholds = [(10, 500), (25, 1000), (50, 2000), (75, 3500), (100, 5000)];
    for (final (max, xp) in thresholds) {
      if (level <= max) return xp;
    }
    return 5000;
  }

  final needed = xpPerLevel(p.level);
  if (needed <= 0) return;
  final inLevel = p.xp % needed;
  final target = (needed * 0.78).round().clamp(1, needed);
  if (inLevel >= target) {
    await prefs.setBool(key, true);
    return;
  }
  await profileRepo.addXp(target - inLevel);
  await prefs.setBool(key, true);
}

class MgtLifeSparkApp extends ConsumerWidget {
  const MgtLifeSparkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final theme = ref.watch(effectiveThemeProvider);

    return MaterialApp.router(
      title: 'MGT Life Spark',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
