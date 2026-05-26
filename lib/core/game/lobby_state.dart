import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bluetooth/ble_message.dart';
import '../bluetooth/ble_protocol.dart';
import '../bluetooth/ble_providers.dart';
import '../bluetooth/ble_service.dart';
import '../models/player_slot.dart';
import '../models/player_deck.dart';
import '../models/pod_preset.dart';
import '../persistence/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/commander_image_resolver.dart';
import 'game_format.dart';

// ── Config ─────────────────────────────────────────────────────────────────

class LobbyConfig {
  final GameFormat format;
  final int startingLife;
  final bool alliancesEnabled;
  final int maxPlayers;

  // Gameplay variants (placeholders for future implementation)
  final bool planechaseEnabled;
  final bool archenemyEnabled;
  final bool bountyEnabled;

  // Auto-KO: which loss conditions eliminate a player
  final bool autoKoFromLife;
  final bool autoKoFromPoison;
  final bool autoKoFromCommanderDamage;

  // Commander damage also reduces life total (when true)
  final bool commanderDamageReducesLife;

  // Turn timing
  final int? turnTimeLimitSeconds; // null = no limit
  final bool trackTurnDuration;

  const LobbyConfig({
    this.format = GameFormat.commander,
    this.startingLife = 40,
    this.alliancesEnabled = true,
    this.maxPlayers = 6,
    this.planechaseEnabled = false,
    this.archenemyEnabled = false,
    this.bountyEnabled = false,
    this.autoKoFromLife = true,
    this.autoKoFromPoison = true,
    this.autoKoFromCommanderDamage = true,
    this.commanderDamageReducesLife = true,
    this.turnTimeLimitSeconds,
    this.trackTurnDuration = false,
  });

  static const _sentinel = Object();

  LobbyConfig copyWith({
    GameFormat? format,
    int? startingLife,
    bool? alliancesEnabled,
    int? maxPlayers,
    bool? planechaseEnabled,
    bool? archenemyEnabled,
    bool? bountyEnabled,
    bool? autoKoFromLife,
    bool? autoKoFromPoison,
    bool? autoKoFromCommanderDamage,
    bool? commanderDamageReducesLife,
    Object? turnTimeLimitSeconds = _sentinel,
    bool? trackTurnDuration,
  }) =>
      LobbyConfig(
        format: format ?? this.format,
        startingLife: startingLife ?? this.startingLife,
        alliancesEnabled: alliancesEnabled ?? this.alliancesEnabled,
        maxPlayers: maxPlayers ?? this.maxPlayers,
        planechaseEnabled: planechaseEnabled ?? this.planechaseEnabled,
        archenemyEnabled: archenemyEnabled ?? this.archenemyEnabled,
        bountyEnabled: bountyEnabled ?? this.bountyEnabled,
        autoKoFromLife: autoKoFromLife ?? this.autoKoFromLife,
        autoKoFromPoison: autoKoFromPoison ?? this.autoKoFromPoison,
        autoKoFromCommanderDamage:
            autoKoFromCommanderDamage ?? this.autoKoFromCommanderDamage,
        commanderDamageReducesLife:
            commanderDamageReducesLife ?? this.commanderDamageReducesLife,
        turnTimeLimitSeconds: identical(turnTimeLimitSeconds, _sentinel)
            ? this.turnTimeLimitSeconds
            : turnTimeLimitSeconds as int?,
        trackTurnDuration: trackTurnDuration ?? this.trackTurnDuration,
      );

  Map<String, dynamic> toJson() => {
        'format': format.name,
        'startingLife': startingLife,
        'alliancesEnabled': alliancesEnabled,
        'maxPlayers': maxPlayers,
        'planechaseEnabled': planechaseEnabled,
        'archenemyEnabled': archenemyEnabled,
        'bountyEnabled': bountyEnabled,
        'autoKoFromLife': autoKoFromLife,
        'autoKoFromPoison': autoKoFromPoison,
        'autoKoFromCommanderDamage': autoKoFromCommanderDamage,
        'commanderDamageReducesLife': commanderDamageReducesLife,
        'turnTimeLimitSeconds': turnTimeLimitSeconds,
        'trackTurnDuration': trackTurnDuration,
      };

  factory LobbyConfig.fromJson(Map<String, dynamic> json) => LobbyConfig(
        format:
            GameFormatDetails.fromName(json['format'] as String?) ??
            GameFormat.commander,
        startingLife: (json['startingLife'] as num?)?.toInt() ?? 40,
        alliancesEnabled: json['alliancesEnabled'] as bool? ?? true,
        maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 6,
        planechaseEnabled: json['planechaseEnabled'] as bool? ?? false,
        archenemyEnabled: json['archenemyEnabled'] as bool? ?? false,
        bountyEnabled: json['bountyEnabled'] as bool? ?? false,
        autoKoFromLife: json['autoKoFromLife'] as bool? ?? true,
        autoKoFromPoison: json['autoKoFromPoison'] as bool? ?? true,
        autoKoFromCommanderDamage:
            json['autoKoFromCommanderDamage'] as bool? ?? true,
        commanderDamageReducesLife:
            json['commanderDamageReducesLife'] as bool? ?? true,
        turnTimeLimitSeconds:
            (json['turnTimeLimitSeconds'] as num?)?.toInt(),
        trackTurnDuration: json['trackTurnDuration'] as bool? ?? false,
      );
}

// ── State ──────────────────────────────────────────────────────────────────

class LobbyState {
  final List<PlayerSlot> players;
  final LobbyConfig config;
  final bool isHost;
  final bool isGameStarted; // set true when host broadcasts gameStart

  /// Selected pod preset id (host), optional.
  final String? selectedPodPresetId;

  /// Snapshotted labels for match history (set when host picks a preset or edits).
  final String? podNameSnapshot;
  final String? locationLabelSnapshot;

  const LobbyState({
    this.players = const [],
    this.config = const LobbyConfig(),
    this.isHost = false,
    this.isGameStarted = false,
    this.selectedPodPresetId,
    this.podNameSnapshot,
    this.locationLabelSnapshot,
  });

  LobbyState copyWith({
    List<PlayerSlot>? players,
    LobbyConfig? config,
    bool? isHost,
    bool? isGameStarted,
    Object? selectedPodPresetId = _sentinelPod,
    Object? podNameSnapshot = _sentinelPod,
    Object? locationLabelSnapshot = _sentinelPod,
  }) =>
      LobbyState(
        players: players ?? this.players,
        config: config ?? this.config,
        isHost: isHost ?? this.isHost,
        isGameStarted: isGameStarted ?? this.isGameStarted,
        selectedPodPresetId: identical(selectedPodPresetId, _sentinelPod)
            ? this.selectedPodPresetId
            : selectedPodPresetId as String?,
        podNameSnapshot: identical(podNameSnapshot, _sentinelPod)
            ? this.podNameSnapshot
            : podNameSnapshot as String?,
        locationLabelSnapshot: identical(locationLabelSnapshot, _sentinelPod)
            ? this.locationLabelSnapshot
            : locationLabelSnapshot as String?,
      );

  static const Object _sentinelPod = Object();

  /// Host can start when at least 1 player is present and everyone (including
  /// host) has clicked ready.
  bool get canStart =>
      players.isNotEmpty && players.every((p) => p.isReady);
}

// ── Notifier ───────────────────────────────────────────────────────────────

class LobbyNotifier extends StateNotifier<LobbyState> {
  final Ref _ref;
  StreamSubscription<BleMessage>? _messageSub;
  StreamSubscription<BleConnectionEvent>? _connectionSub;
  int _seqNum = 0;

  LobbyNotifier(this._ref) : super(const LobbyState());

  // ── Initialisation ───────────────────────────────────────────────────────

  /// Call when the host creates a new session.
  void initAsHost() {
    final profile = _ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;

    final hostSlot = PlayerSlot(
      playerId: profile.username,
      username: profile.username,
      playerColor: AppTheme.playerColor(0),
      isHost: true,
      isReady: false,
    );

    state = LobbyState(
      isHost: true,
      players: [hostSlot],
      config: state.config,
    );

    _listenToBle();
  }

  /// Call when a client joins an existing session.
  void initAsClient() {
    state = state.copyWith(
      isHost: false,
      isGameStarted: false,
    );
    _listenToBle();
  }

  /// Clears lobby state when leaving a game or session.
  void reset() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _messageSub = null;
    _connectionSub = null;
    _seqNum = 0;
    state = const LobbyState();
  }

  void _listenToBle() {
    final service = _ref.read(bleServiceProvider);
    if (service == null) return;

    _messageSub = service.messageStream.listen(_onBleMessage);
    _connectionSub = service.connectionStream.listen(_onConnectionEvent);
  }

  // ── Host-only actions ────────────────────────────────────────────────────

  void updateConfig(LobbyConfig config) {
    if (!state.isHost) return;
    state = state.copyWith(config: config);
    _broadcastLobbyUpdate();
  }

  /// Host selects a saved pod preset for match history labels (optional).
  void setMatchPodFromPreset(PodPreset? preset) {
    if (!state.isHost) return;
    if (preset == null) {
      state = state.copyWith(
        selectedPodPresetId: null,
        podNameSnapshot: null,
        locationLabelSnapshot: null,
      );
    } else {
      state = state.copyWith(
        selectedPodPresetId: preset.id,
        podNameSnapshot: preset.name,
        locationLabelSnapshot: null,
      );
    }
    _broadcastLobbyUpdate();
  }

  void setCommander({
    required String playerId,
    required String commanderName,
    required String commanderImageUrl,
    String? partnerCommanderName,
    String? partnerCommanderImageUrl,
    List<String> commanderColorIdentity = const [],
  }) {
    final players = state.players.map((p) {
      if (p.playerId != playerId) return p;
      return p.copyWith(
        commanderName: commanderName,
        commanderImageUrl: commanderImageUrl,
        partnerCommanderName: partnerCommanderName,
        partnerCommanderImageUrl: partnerCommanderImageUrl,
        selectedDeckId: null,
        commanderColorIdentity: List<String>.from(commanderColorIdentity),
      );
    }).toList();
    state = state.copyWith(players: players);
    _broadcastLobbyUpdate();
  }

  /// Apply a saved deck: fills commanders and tags the slot for win/loss tracking.
  void applyDeck({required String playerId, required PlayerDeck deck}) {
    final profile = _ref.read(profileRepositoryProvider).getProfile();
    final commanderImageUrl = resolveDeckCommanderImageUrl(
          deck: deck,
          profile: profile,
        ) ??
        deck.commanderImageUrl;
    final partnerCommanderImageUrl = resolveDeckPartnerImageUrl(
          deck: deck,
          profile: profile,
        ) ??
        deck.partnerCommanderImageUrl;

    final players = state.players.map((p) {
      if (p.playerId != playerId) return p;
      return p.copyWith(
        commanderName: deck.commanderName,
        commanderImageUrl: commanderImageUrl,
        partnerCommanderName: deck.partnerCommanderName,
        partnerCommanderImageUrl: partnerCommanderImageUrl,
        hasPartner: deck.hasPartner,
        selectedDeckId: deck.id,
        commanderColorIdentity: List<String>.from(deck.commanderColorIdentity),
      );
    }).toList();
    state = state.copyWith(players: players);
    _broadcastLobbyUpdate();
  }

  /// Stop attributing results to a registered deck (keeps current commanders).
  void clearSelectedDeck(String playerId) {
    final players = state.players.map((p) {
      if (p.playerId != playerId) return p;
      return p.copyWith(selectedDeckId: null);
    }).toList();
    state = state.copyWith(players: players);
    _broadcastLobbyUpdate();
  }

  void togglePartner(String playerId) {
    final players = state.players.map((p) {
      if (p.playerId != playerId) return p;
      return p.copyWith(
        hasPartner: !p.hasPartner,
        partnerCommanderName: null,
        partnerCommanderImageUrl: null,
        selectedDeckId: null,
      );
    }).toList();
    state = state.copyWith(players: players);
    _broadcastLobbyUpdate();
  }

  void setReady(String playerId, {required bool ready}) {
    final players = state.players.map((p) {
      if (p.playerId != playerId) return p;
      return p.copyWith(isReady: ready);
    }).toList();
    state = state.copyWith(players: players);
    _broadcastLobbyUpdate();
  }

  Future<void> broadcastGameStart() async {
    _send(BleMessage(
      type: BleMessageType.gameStart,
      payload: {
        'config': state.config.toJson(),
        'players': state.players.map((p) => p.toJson()).toList(),
        'selectedPodPresetId': state.selectedPodPresetId,
        'podNameSnapshot': state.podNameSnapshot,
        'locationLabelSnapshot': state.locationLabelSnapshot,
      },
      seqNum: _nextSeq(),
    ));
  }

  // ── Client-only actions ──────────────────────────────────────────────────

  /// Client sends its READY state and commander selection to the host.
  void sendReadyToHost({required bool ready}) {
    final profile = _ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;

    // Optimistically update local state
    final players = state.players.map((p) {
      if (p.playerId != profile.username) return p;
      return p.copyWith(isReady: ready);
    }).toList();
    state = state.copyWith(players: players);

    _send(BleMessage(
      type: BleMessageType.lobbyPlayerReady,
      payload: {
        'pid': profile.username,
        'ready': ready,
        'slot': players
            .firstWhere((p) => p.playerId == profile.username,
                orElse: () => players.first)
            .toJson(),
      },
      seqNum: _nextSeq(),
    ));
  }

  /// Client announces itself after a successful BLE connection.
  void sendJoinAnnouncement() {
    final profile = _ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;
    _send(BleMessage(
      type: BleMessageType.lobbyPlayerJoined,
      payload: {
        'pid': profile.username,
        'username': profile.username,
      },
      seqNum: _nextSeq(),
    ));
  }

  // ── BLE inbound handling ─────────────────────────────────────────────────

  void _onBleMessage(BleMessage message) {
    switch (message.type) {
      case BleMessageType.lobbyPlayerJoined:
        if (state.isHost) _hostHandlePlayerJoined(message.payload);
        break;

      case BleMessageType.lobbyPlayerReady:
        if (state.isHost) _hostHandlePlayerReady(message.payload);
        break;

      // Host broadcasts stateSnapshot whenever the lobby changes.
      // Clients apply the full snapshot so their waiting room stays in sync
      // (shows all joined players, config changes, roll result, etc.).
      case BleMessageType.stateSnapshot:
        if (!state.isHost) _clientApplySnapshot(message.payload);
        break;

      case BleMessageType.gameStart:
        _handleGameStart(message.payload);
        break;

      default:
        break;
    }
  }

  void _clientApplySnapshot(Map<String, dynamic> payload) {
    final configJson = payload['config'] as Map<String, dynamic>?;
    final playersJson = payload['players'] as List<dynamic>?;

    state = state.copyWith(
      config: configJson != null
          ? LobbyConfig.fromJson(configJson)
          : state.config,
      players: playersJson != null
          ? playersJson
              .map((e) => PlayerSlot.fromJson(e as Map<String, dynamic>))
              .toList()
          : state.players,
      selectedPodPresetId: payload['selectedPodPresetId'] as String?,
      podNameSnapshot: payload['podNameSnapshot'] as String?,
      locationLabelSnapshot: payload['locationLabelSnapshot'] as String?,
    );
  }

  void _hostHandlePlayerJoined(Map<String, dynamic> payload) {
    final playerId = payload['pid'] as String? ?? '';
    final username = payload['username'] as String? ?? playerId;
    if (state.players.any((p) => p.playerId == playerId)) return;
    if (state.players.length >= state.config.maxPlayers) return;

    final colorIndex = state.players.length;
    final newSlot = PlayerSlot(
      playerId: playerId,
      username: username,
      playerColor: AppTheme.playerColor(colorIndex),
      isHost: false,
      isReady: false,
    );

    state = state.copyWith(players: [...state.players, newSlot]);
    _broadcastLobbyUpdate();
  }

  void _hostHandlePlayerReady(Map<String, dynamic> payload) {
    final pid = payload['pid'] as String? ?? '';
    final ready = payload['ready'] as bool? ?? false;
    final slotJson = payload['slot'] as Map<String, dynamic>?;

    final players = state.players.map((p) {
      if (p.playerId != pid) return p;
      if (slotJson != null) {
        final updated = PlayerSlot.fromJson(slotJson);
        return updated.copyWith(isReady: ready);
      }
      return p.copyWith(isReady: ready);
    }).toList();

    state = state.copyWith(players: players);
    _broadcastLobbyUpdate();
  }

  void _handleGameStart(Map<String, dynamic> payload) {
    final configJson = payload['config'] as Map<String, dynamic>?;
    final playersJson = payload['players'] as List<dynamic>?;

    LobbyConfig? config;
    List<PlayerSlot>? players;

    if (configJson != null) config = LobbyConfig.fromJson(configJson);
    if (playersJson != null) {
      players = playersJson
          .map((e) => PlayerSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    state = state.copyWith(
      config: config ?? state.config,
      players: players ?? state.players,
      isGameStarted: true,
      selectedPodPresetId: payload['selectedPodPresetId'] as String?,
      podNameSnapshot: payload['podNameSnapshot'] as String?,
      locationLabelSnapshot: payload['locationLabelSnapshot'] as String?,
    );
  }

  void _onConnectionEvent(BleConnectionEvent event) {
    if (event.status == BleConnectionStatus.disconnected && state.isHost) {
      final players =
          state.players.where((p) => p.playerId != event.playerId).toList();
      state = state.copyWith(players: players);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _broadcastLobbyUpdate() {
    if (!state.isHost) return;
    _send(BleMessage(
      type: BleMessageType.stateSnapshot,
      payload: {
        'config': state.config.toJson(),
        'players': state.players.map((p) => p.toJson()).toList(),
        'selectedPodPresetId': state.selectedPodPresetId,
        'podNameSnapshot': state.podNameSnapshot,
        'locationLabelSnapshot': state.locationLabelSnapshot,
      },
      seqNum: _nextSeq(),
    ));
  }

  void _send(BleMessage message) {
    final service = _ref.read(bleServiceProvider);
    service?.send(message);
  }

  int _nextSeq() => _seqNum++;

  @override
  void dispose() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final lobbyProvider =
    StateNotifierProvider<LobbyNotifier, LobbyState>((ref) {
  return LobbyNotifier(ref);
});
