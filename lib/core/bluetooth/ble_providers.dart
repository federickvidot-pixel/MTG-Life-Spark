import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';
import '../game/lobby_state.dart';
import '../network/ws_client_service.dart';
import '../network/ws_host_service.dart';
import '../persistence/providers.dart';
import 'ble_service.dart';

/// Which role this device is playing in the current session.
enum BleRole { none, host, client }

final bleRoleProvider = StateProvider<BleRole>((ref) => BleRole.none);

/// The active network service for the current session (host or client).
/// Null when no game session is active.
final bleServiceProvider = StateProvider<BleService?>((ref) => null);

/// Convenience: the active host service (null if client or no session).
final bleHostServiceProvider = Provider<WsHostService?>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service is WsHostService ? service : null;
});

/// Convenience: the active client service (null if host or no session).
final bleClientServiceProvider = Provider<WsClientService?>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service is WsClientService ? service : null;
});

/// Creates and starts a host WebSocket server session.
Future<void> startHostSession(WidgetRef ref) async {
  final profile = ref.read(profileRepositoryProvider).getProfile();
  if (profile == null) return;

  final existing = ref.read(bleServiceProvider);
  if (existing != null) {
    await existing.dispose();
    ref.read(bleServiceProvider.notifier).state = null;
    ref.read(bleRoleProvider.notifier).state = BleRole.none;
  }

  final host = WsHostService(
    hostPlayerId: profile.username,
    hostUsername: profile.username,
  );
  await host.initialize();

  ref.read(bleServiceProvider.notifier).state = host;
  ref.read(bleRoleProvider.notifier).state = BleRole.host;
}

/// Creates a WebSocket client session ready to connect.
/// Call [WsClientService.connectToHost] with the URI from the QR code.
Future<void> startClientSession(WidgetRef ref) async {
  // Reuse existing client service if already created.
  if (ref.read(bleServiceProvider) is WsClientService) return;

  final profile = ref.read(profileRepositoryProvider).getProfile();
  if (profile == null) return;

  final client = WsClientService(
    localPlayerId: profile.username,
    localUsername: profile.username,
  );
  await client.initialize();

  ref.read(bleServiceProvider.notifier).state = client;
  ref.read(bleRoleProvider.notifier).state = BleRole.client;
}

/// Tears down the current session completely.
Future<void> endSession(WidgetRef ref) async {
  final service = ref.read(bleServiceProvider);
  await service?.dispose();
  ref.read(bleServiceProvider.notifier).state = null;
  ref.read(bleRoleProvider.notifier).state = BleRole.none;
}

/// Ends the network session and clears in-memory game/lobby state.
Future<void> quitActiveGame(WidgetRef ref) async {
  await endSession(ref);
  ref.read(gameProvider.notifier).reset();
  ref.read(lobbyProvider.notifier).reset();
}
