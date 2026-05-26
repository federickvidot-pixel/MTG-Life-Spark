import 'alliance.dart';
import 'game_log_entry.dart';
import 'game_phase.dart';
import 'player_game_state.dart';
import 'stack_item.dart';

enum DayNightState { none, day, night }

class GameState {
  final List<PlayerGameState> players;
  final List<String> turnOrder; // player IDs in turn order
  final int activePlayerIndex;
  final GamePhase currentPhase;
  final int roundNumber;

  // Priority
  final bool priorityHeld;
  final String? priorityHolderId;

  // Timeout
  final bool timeoutActive;
  final DateTime? timeoutStartTime;
  final int? timeoutDurationSeconds; // 120 or 300; null = no auto-end timer

  // Global markers
  final String? monarchPlayerId;
  final String? initiativePlayerId;
  final DayNightState dayNight;

  // Political
  final List<Alliance> alliances;
  final List<AllianceProposal> pendingProposals;
  final List<AllianceProposal> scheduledProposals;
  final bool alliancesEnabled;

  // Game result
  final bool gameOver;
  final String? winnerPlayerId;

  // Session metadata
  final bool isHost;
  final String localPlayerId;

  // Teams: playerId → teamIndex (1–4; 0 = no team)
  final Map<String, int> teamAssignments;

  // When the game was started (set by host on initFromLobby)
  final DateTime? gameStartTime;

  // First player roll phase (each player rolls d6, highest goes first)
  final bool awaitingFirstPlayerRoll;
  final Map<String, int> firstPlayerRolls; // playerId -> roll value

  // From lobby config
  final bool autoKoFromLife;
  final bool autoKoFromPoison;
  final bool autoKoFromCommanderDamage;
  final bool commanderDamageReducesLife;
  final int? turnTimeLimitSeconds;
  final bool trackTurnDuration;
  final DateTime? turnStartTime; // when current turn started

  // Variant modes (Planechase, Archenemy, Bounty) – decks fetched from Scryfall
  final bool planechaseEnabled;
  final bool archenemyEnabled;
  final bool bountyEnabled;
  final int currentPlanarIndex; // index into planar deck
  final int currentSchemeIndex;
  final int currentBountyIndex;

  /// Monotonic counter for History tab grouping (increments on each turn pass).
  final int sessionTurnCounter;

  /// Session action log (life, counters, commander damage, …).
  final List<GameLogEntry> sessionActionLog;

  /// Stack tracker entries (shared across players via BLE / snapshot).
  final List<StackItem> stackItems;

  const GameState({
    this.players = const [],
    this.turnOrder = const [],
    this.activePlayerIndex = 0,
    this.currentPhase = GamePhase.untap,
    this.roundNumber = 1,
    this.priorityHeld = false,
    this.priorityHolderId,
    this.timeoutActive = false,
    this.timeoutStartTime,
    this.timeoutDurationSeconds,
    this.monarchPlayerId,
    this.initiativePlayerId,
    this.dayNight = DayNightState.none,
    this.alliances = const [],
    this.pendingProposals = const [],
    this.scheduledProposals = const [],
    this.alliancesEnabled = true,
    this.gameOver = false,
    this.winnerPlayerId,
    this.isHost = false,
    this.localPlayerId = '',
    this.teamAssignments = const {},
    this.gameStartTime,
    this.awaitingFirstPlayerRoll = false,
    this.firstPlayerRolls = const {},
    this.autoKoFromLife = true,
    this.autoKoFromPoison = true,
    this.autoKoFromCommanderDamage = true,
    this.commanderDamageReducesLife = true,
    this.turnTimeLimitSeconds,
    this.trackTurnDuration = false,
    this.turnStartTime,
    this.planechaseEnabled = false,
    this.archenemyEnabled = false,
    this.bountyEnabled = false,
    this.currentPlanarIndex = 0,
    this.currentSchemeIndex = 0,
    this.currentBountyIndex = 0,
    this.sessionTurnCounter = 1,
    this.sessionActionLog = const [],
    this.stackItems = const [],
  });

  factory GameState.empty() => const GameState();

  static const _sentinel = Object();

  GameState copyWith({
    List<PlayerGameState>? players,
    List<String>? turnOrder,
    int? activePlayerIndex,
    GamePhase? currentPhase,
    int? roundNumber,
    bool? priorityHeld,
    Object? priorityHolderId = _sentinel,
    bool? timeoutActive,
    Object? timeoutStartTime = _sentinel,
    Object? timeoutDurationSeconds = _sentinel,
    Object? monarchPlayerId = _sentinel,
    Object? initiativePlayerId = _sentinel,
    DayNightState? dayNight,
    List<Alliance>? alliances,
    List<AllianceProposal>? pendingProposals,
    List<AllianceProposal>? scheduledProposals,
    bool? alliancesEnabled,
    bool? gameOver,
    Object? winnerPlayerId = _sentinel,
    bool? isHost,
    String? localPlayerId,
    Map<String, int>? teamAssignments,
    Object? gameStartTime = _sentinel,
    bool? awaitingFirstPlayerRoll,
    Map<String, int>? firstPlayerRolls,
    bool? autoKoFromLife,
    bool? autoKoFromPoison,
    bool? autoKoFromCommanderDamage,
    bool? commanderDamageReducesLife,
    Object? turnTimeLimitSeconds = _sentinel,
    bool? trackTurnDuration,
    Object? turnStartTime = _sentinel,
    bool? planechaseEnabled,
    bool? archenemyEnabled,
    bool? bountyEnabled,
    int? currentPlanarIndex,
    int? currentSchemeIndex,
    int? currentBountyIndex,
    int? sessionTurnCounter,
    List<GameLogEntry>? sessionActionLog,
    List<StackItem>? stackItems,
  }) {
    return GameState(
      players: players ?? this.players,
      turnOrder: turnOrder ?? this.turnOrder,
      activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
      currentPhase: currentPhase ?? this.currentPhase,
      roundNumber: roundNumber ?? this.roundNumber,
      priorityHeld: priorityHeld ?? this.priorityHeld,
      priorityHolderId: identical(priorityHolderId, _sentinel)
          ? this.priorityHolderId
          : priorityHolderId as String?,
      timeoutActive: timeoutActive ?? this.timeoutActive,
      timeoutStartTime: identical(timeoutStartTime, _sentinel)
          ? this.timeoutStartTime
          : timeoutStartTime as DateTime?,
      timeoutDurationSeconds: identical(timeoutDurationSeconds, _sentinel)
          ? this.timeoutDurationSeconds
          : timeoutDurationSeconds as int?,
      monarchPlayerId: identical(monarchPlayerId, _sentinel)
          ? this.monarchPlayerId
          : monarchPlayerId as String?,
      initiativePlayerId: identical(initiativePlayerId, _sentinel)
          ? this.initiativePlayerId
          : initiativePlayerId as String?,
      dayNight: dayNight ?? this.dayNight,
      alliances: alliances ?? this.alliances,
      pendingProposals: pendingProposals ?? this.pendingProposals,
      scheduledProposals: scheduledProposals ?? this.scheduledProposals,
      alliancesEnabled: alliancesEnabled ?? this.alliancesEnabled,
      gameOver: gameOver ?? this.gameOver,
      winnerPlayerId: identical(winnerPlayerId, _sentinel)
          ? this.winnerPlayerId
          : winnerPlayerId as String?,
      isHost: isHost ?? this.isHost,
      localPlayerId: localPlayerId ?? this.localPlayerId,
      teamAssignments: teamAssignments ?? this.teamAssignments,
      gameStartTime: identical(gameStartTime, _sentinel)
          ? this.gameStartTime
          : gameStartTime as DateTime?,
      awaitingFirstPlayerRoll:
          awaitingFirstPlayerRoll ?? this.awaitingFirstPlayerRoll,
      firstPlayerRolls: firstPlayerRolls ?? this.firstPlayerRolls,
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
      turnStartTime: identical(turnStartTime, _sentinel)
          ? this.turnStartTime
          : turnStartTime as DateTime?,
      planechaseEnabled: planechaseEnabled ?? this.planechaseEnabled,
      archenemyEnabled: archenemyEnabled ?? this.archenemyEnabled,
      bountyEnabled: bountyEnabled ?? this.bountyEnabled,
      currentPlanarIndex: currentPlanarIndex ?? this.currentPlanarIndex,
      currentSchemeIndex: currentSchemeIndex ?? this.currentSchemeIndex,
      currentBountyIndex: currentBountyIndex ?? this.currentBountyIndex,
      sessionTurnCounter: sessionTurnCounter ?? this.sessionTurnCounter,
      sessionActionLog: sessionActionLog ?? this.sessionActionLog,
      stackItems: stackItems ?? this.stackItems,
    );
  }

  // ── Convenience getters ─────────────────────────────────────────────────

  String get activePlayerId {
    if (turnOrder.isEmpty) return '';
    return turnOrder[activePlayerIndex % turnOrder.length];
  }

  bool get isLocalPlayersTurn => activePlayerId == localPlayerId;

  PlayerGameState? get localPlayer {
    try {
      return players.firstWhere((p) => p.playerId == localPlayerId);
    } catch (_) {
      return null;
    }
  }

  PlayerGameState? playerById(String id) {
    try {
      return players.firstWhere((p) => p.playerId == id);
    } catch (_) {
      return null;
    }
  }

  Alliance? allianceFor(String playerId) {
    try {
      return alliances.firstWhere((a) => a.involves(playerId));
    } catch (_) {
      return null;
    }
  }

  AllianceProposal? pendingProposalFor(String targetId) {
    try {
      return pendingProposals.firstWhere(
        (p) => p.toId == targetId && p.delivered,
      );
    } catch (_) {
      return null;
    }
  }

  List<AllianceProposal> scheduledProposalsFrom(String fromId) =>
      scheduledProposals.where((p) => p.fromId == fromId).toList();

  List<AllianceProposal> scheduledProposalsTo(String toId) =>
      scheduledProposals.where((p) => p.toId == toId).toList();

  List<Alliance> get revealedAlliances =>
      alliances.where((a) => a.isRevealed).toList();

  /// Secret alliance visible to [viewerId], or any revealed alliance.
  Alliance? visibleAllianceFor(String viewerId, String subjectId) {
    try {
      final alliance = alliances.firstWhere((a) => a.involves(subjectId));
      if (alliance.isRevealed || alliance.involves(viewerId)) return alliance;
    } catch (_) {}
    return null;
  }

  bool isMonarch(String playerId) => monarchPlayerId == playerId;

  bool hasInitiative(String playerId) => initiativePlayerId == playerId;

  List<PlayerGameState> get activePlayers =>
      players.where((p) => !p.isEliminated).toList();

  // ── Snapshot serialisation ──────────────────────────────────────────────

  Map<String, dynamic> toSnapshotJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'turnOrder': turnOrder,
        'activePlayerIndex': activePlayerIndex,
        'currentPhase': currentPhase.name,
        'roundNumber': roundNumber,
        'priorityHeld': priorityHeld,
        'priorityHolderId': priorityHolderId,
        'monarchPlayerId': monarchPlayerId,
        'initiativePlayerId': initiativePlayerId,
        'dayNight': dayNight.name,
        'alliances': alliances.map((a) => a.toJson()).toList(),
        'pendingProposals':
            pendingProposals.map((p) => p.toJson()).toList(),
        'scheduledProposals':
            scheduledProposals.map((p) => p.toJson()).toList(),
        'alliancesEnabled': alliancesEnabled,
        'gameOver': gameOver,
        'winnerPlayerId': winnerPlayerId,
        'teamAssignments': teamAssignments.map((k, v) => MapEntry(k, v)),
        'gameStartTime': gameStartTime?.toIso8601String(),
        'awaitingFirstPlayerRoll': awaitingFirstPlayerRoll,
        'firstPlayerRolls': firstPlayerRolls,
        'autoKoFromLife': autoKoFromLife,
        'autoKoFromPoison': autoKoFromPoison,
        'autoKoFromCommanderDamage': autoKoFromCommanderDamage,
        'commanderDamageReducesLife': commanderDamageReducesLife,
        'turnTimeLimitSeconds': turnTimeLimitSeconds,
        'trackTurnDuration': trackTurnDuration,
        'turnStartTime': turnStartTime?.toIso8601String(),
        'planechaseEnabled': planechaseEnabled,
        'archenemyEnabled': archenemyEnabled,
        'bountyEnabled': bountyEnabled,
        'currentPlanarIndex': currentPlanarIndex,
        'currentSchemeIndex': currentSchemeIndex,
        'currentBountyIndex': currentBountyIndex,
        'sessionTurnCounter': sessionTurnCounter,
        'sessionActionLog':
            sessionActionLog.map((e) => e.toJson()).toList(),
        'stackItems': stackItems.map((e) => e.toJson()).toList(),
      };

  factory GameState.fromSnapshotJson(
    Map<String, dynamic> json, {
    required bool isHost,
    required String localPlayerId,
  }) {
    return GameState(
      players: (json['players'] as List<dynamic>)
          .map((e) => PlayerGameState.fromJson(e as Map<String, dynamic>))
          .toList(),
      turnOrder: List<String>.from(json['turnOrder'] as List),
      activePlayerIndex: (json['activePlayerIndex'] as num).toInt(),
      currentPhase: GamePhase.values.firstWhere(
        (p) => p.name == json['currentPhase'],
        orElse: () => GamePhase.untap,
      ),
      roundNumber: (json['roundNumber'] as num).toInt(),
      priorityHeld: json['priorityHeld'] as bool? ?? false,
      priorityHolderId: json['priorityHolderId'] as String?,
      monarchPlayerId: json['monarchPlayerId'] as String?,
      initiativePlayerId: json['initiativePlayerId'] as String?,
      dayNight: DayNightState.values.firstWhere(
        (d) => d.name == json['dayNight'],
        orElse: () => DayNightState.none,
      ),
      alliances: (json['alliances'] as List<dynamic>?)
              ?.map((e) => Alliance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingProposals: (json['pendingProposals'] as List<dynamic>?)
              ?.map((e) => AllianceProposal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scheduledProposals: (json['scheduledProposals'] as List<dynamic>?)
              ?.map((e) => AllianceProposal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alliancesEnabled: json['alliancesEnabled'] as bool? ?? true,
      gameOver: json['gameOver'] as bool? ?? false,
      winnerPlayerId: json['winnerPlayerId'] as String?,
      isHost: isHost,
      localPlayerId: localPlayerId,
      teamAssignments: (json['teamAssignments'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      gameStartTime: json['gameStartTime'] != null
          ? DateTime.tryParse(json['gameStartTime'] as String)
          : null,
      awaitingFirstPlayerRoll:
          json['awaitingFirstPlayerRoll'] as bool? ?? false,
      firstPlayerRolls: (json['firstPlayerRolls'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      autoKoFromLife: json['autoKoFromLife'] as bool? ?? true,
      autoKoFromPoison: json['autoKoFromPoison'] as bool? ?? true,
      autoKoFromCommanderDamage:
          json['autoKoFromCommanderDamage'] as bool? ?? true,
      commanderDamageReducesLife:
          json['commanderDamageReducesLife'] as bool? ?? true,
      turnTimeLimitSeconds:
          (json['turnTimeLimitSeconds'] as num?)?.toInt(),
      trackTurnDuration: json['trackTurnDuration'] as bool? ?? false,
      turnStartTime: json['turnStartTime'] != null
          ? DateTime.tryParse(json['turnStartTime'] as String)
          : null,
      planechaseEnabled: json['planechaseEnabled'] as bool? ?? false,
      archenemyEnabled: json['archenemyEnabled'] as bool? ?? false,
      bountyEnabled: json['bountyEnabled'] as bool? ?? false,
      currentPlanarIndex: (json['currentPlanarIndex'] as num?)?.toInt() ?? 0,
      currentSchemeIndex: (json['currentSchemeIndex'] as num?)?.toInt() ?? 0,
      currentBountyIndex: (json['currentBountyIndex'] as num?)?.toInt() ?? 0,
      sessionTurnCounter: (json['sessionTurnCounter'] as num?)?.toInt() ?? 1,
      sessionActionLog: (json['sessionActionLog'] as List<dynamic>?)
              ?.map((e) => GameLogEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stackItems: (json['stackItems'] as List<dynamic>?)
              ?.map((e) => StackItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
