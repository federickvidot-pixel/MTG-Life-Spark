import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/providers.dart';
import '../../features/game_lobby/game_lobby_screen.dart';
import '../../features/profile/profile_setup_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/profile_banner_picker_screen.dart';
import '../../features/profile/pods_manage_screen.dart';
import '../../features/profile/decks_manage_screen.dart';
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
  /// Primary route for deck library (shell tab). Prefer over legacy [profileDecks].
  static const decks = '/decks';
  static const profileBanner = '/home/banner';
  static const profilePods = '/home/pods';
  /// Legacy path; use [decks]. Kept so old links can redirect if added later.
  static const profileDecks = '/decks';
  static const feedback = '/settings/feedback';
  static const commanderSelect = '/commander-select';
  static const game = '/game';
  static const endGame = '/end-game';
}

Widget _buildCommanderSelect(GoRouterState state) {
  final extra = state.extra;
  final String playerId;
  final String? newDeckDisplayName;
  final String? editDeckId;
  if (extra is Map) {
    playerId = extra['playerId'] as String? ?? '';
    newDeckDisplayName = extra['newDeckDisplayName'] as String?;
    editDeckId = extra['editDeckId'] as String?;
  } else {
    playerId = extra as String? ?? '';
    newDeckDisplayName = null;
    editDeckId = null;
  }
  return CommanderSelectScreen(
    playerId: playerId,
    newDeckDisplayName: newDeckDisplayName,
    editDeckId: editDeckId,
  );
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
                    path: 'banner',
                    builder: (context, state) =>
                        const ProfileBannerPickerScreen(),
                  ),
                  GoRoute(
                    path: 'pods',
                    builder: (context, state) => const PodsManageScreen(),
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
                        builder: (context, state) => _buildCommanderSelect(state),
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
                path: AppRoutes.decks,
                builder: (context, state) => const DecksManageScreen(),
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
        builder: (context, state) => _buildCommanderSelect(state),
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
          path != AppRoutes.profileSetup &&
          path != AppRoutes.game &&
          path != AppRoutes.endGame &&
          !path.startsWith('${AppRoutes.lobby}/')) {
        return AppRoutes.onboarding;
      }
      if (path == AppRoutes.splash && hasProfile && settings.onboardingCompleted) {
        return AppRoutes.home;
      }
      return null;
    },
  );
});
