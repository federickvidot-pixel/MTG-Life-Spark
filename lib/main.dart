import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/models/player_profile.dart';
import 'core/models/match_record.dart';
import 'core/models/commander_stats.dart';
import 'core/models/achievement_record.dart';
import 'core/models/app_settings.dart';
import 'core/persistence/match_repository.dart';
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

    try {
      await _initHive();
      runApp(const ProviderScope(child: MgtLifeSparkApp()));
    } catch (e, st) {
      debugPrint('Init error: $e');
      debugPrint('Stack: $st');
      runApp(_ErrorApp(message: e.toString(), stack: st.toString()));
    }
  }, (error, stack) {
    debugPrint('Zone error: $error');
    debugPrint('Stack: $stack');
  });
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

  // Open all boxes up front
  await Hive.openBox<PlayerProfile>('playerProfile');
  await Hive.openBox<MatchRecord>('matchHistory');
  await Hive.openBox<CommanderStats>('commanderStats');
  await Hive.openBox<AchievementRecord>('achievements');
  await Hive.openBox<AppSettings>('appSettings');
  await Hive.openBox<String>('matchFeedback');

  // Ensure default settings exist
  final settingsBox = Hive.box<AppSettings>('appSettings');
  if (!settingsBox.containsKey('settings')) {
    await settingsBox.put('settings', AppSettings());
  }

  // Purge match history entries older than 30 days on every startup
  await MatchRepository().purgeOldMatches();
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
