import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/providers.dart';
import '../../features/game_lobby/game_lobby_screen.dart';
import '../../features/profile/profile_setup_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/profile_avatar_picker_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/feedback/feedback_screen.dart';
import '../../features/lobby/lobby_screen.dart';
import '../../features/lobby/join_scan_screen.dart';
import '../../features/commander/commander_select_screen.dart';
import '../../features/game/screens/game_screen.dart';
import '../../features/end_game/end_game_screen.dart';
import '../widgets/main_shell.dart';

class AppRoutes {
  static const splash = '/';
  static const profileSetup = '/profile-setup';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const lobby = '/lobby';
  static const lobbyHost = '/lobby/host';
  static const lobbyJoin = '/lobby/join';
  static const settings = '/settings';
  static const profileAvatar = '/home/avatar';
  static const feedback = '/settings/feedback';
  static const commanderSelect = '/commander-select';
  static const game = '/game';
  static const endGame = '/end-game';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'avatar',
                    builder: (context, state) =>
                        const ProfileAvatarPickerScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.lobby,
                builder: (context, state) => const GameLobbyScreen(),
                routes: [
                  GoRoute(
                    path: 'host',
                    builder: (context, state) => const LobbyScreen(),
                    routes: [
                      GoRoute(
                        path: 'commander',
                        builder: (context, state) {
                          final extra = state.extra;
                          final String playerId;
                          if (extra is Map) {
                            playerId = extra['playerId'] as String? ?? '';
                          } else {
                            playerId = extra as String? ?? '';
                          }
                          return CommanderSelectScreen(playerId: playerId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'join',
                    builder: (context, state) => const JoinScanScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'feedback',
                    builder: (context, state) => const FeedbackScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.commanderSelect,
        builder: (context, state) {
          final extra = state.extra;
          final String playerId;
          if (extra is Map) {
            playerId = extra['playerId'] as String? ?? '';
          } else {
            playerId = extra as String? ?? '';
          }
          return CommanderSelectScreen(playerId: playerId);
        },
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: AppRoutes.endGame,
        builder: (context, state) => const EndGameScreen(),
      ),
    ],
    redirect: (context, state) {
      final hasProfile = ref.read(profileRepositoryProvider).hasProfile;
      final settings = ref.read(settingsRepositoryProvider).settings;
      final path = state.uri.path;

      if (!hasProfile && path != AppRoutes.profileSetup) {
        return AppRoutes.profileSetup;
      }
      if (hasProfile &&
          !settings.onboardingCompleted &&
          path != AppRoutes.onboarding &&
          path != AppRoutes.profileSetup) {
        return AppRoutes.onboarding;
      }
      if (path == AppRoutes.splash && hasProfile && settings.onboardingCompleted) {
        return AppRoutes.home;
      }
      return null;
    },
  );
});
