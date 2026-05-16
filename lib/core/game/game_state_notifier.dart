import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bluetooth/ble_message.dart';
import '../bluetooth/ble_protocol.dart';
import '../bluetooth/ble_providers.dart';
import '../persistence/providers.dart';
import 'alliance.dart';
import 'game_log_entry.dart';
import 'game_phase.dart';
import 'game_state.dart';
import 'gameplay_dial_ids.dart';
import 'lobby_state.dart';
import 'player_game_state.dart';
import 'undo_action.dart';

class GameStateNotifier extends StateNotifier<GameState> {
  final Ref _ref;
  StreamSubscription<BleMessage>? _messageSub;
  Timer? _timeoutTimer;
  Timer? _turnLimitTimer;
  int _seqNum = 0;

  GameStateNotifier(this._ref) : super(GameState.empty());

  static const _kLogCap = 400;

  void _trimAndSetLogs(List<GameLogEntry> logs) {
    final trimmed =
        logs.length > _kLogCap ? logs.sublist(logs.length - _kLogCap) : logs;
    state = state.copyWith(sessionActionLog: trimmed);
  }

  void _appendGameLog(String message, {int? turnNumber}) {
    final t = turnNumber ?? state.sessionTurnCounter;
    final entry =
        GameLogEntry(turnNumber: t, time: DateTime.now(), message: message);
    _trimAndSetLogs([...state.sessionActionLog, entry]);
  }

  String _labelForCounterField(String field) {
    switch (field) {
      case 'poison':
        return 'Poison';
      case 'energy':
        return 'Energy';
      case 'experience':
        return 'Experience';
      case 'rad':
        return 'Rad';
      case GameplayDialIds.blood:
        return 'Blood';
      case GameplayDialIds.clue:
        return 'Clue';
      case GameplayDialIds.map:
        return 'Map';
      case GameplayDialIds.treasure:
        return 'Treasure';
      case GameplayDialIds.devotion:
        return 'Devotion';
      case GameplayDialIds.creatures:
        return 'Creatures';
      case GameplayDialIds.enchantments:
        return 'Enchantments';
      case GameplayDialIds.artifacts:
        return 'Artifacts';
      case GameplayDialIds.graveyardCreatures:
        return 'GY creatures';
      case GameplayDialIds.exile:
        return 'Exile';
      default:
        for (final p in state.players) {
          final lb = p.customDialLabels[field];
          if (lb != null) return lb;
        }
        return field;
    }
  }

  // ── Initialization ───────────────────────────────────────────────────────

  void initFromLobby(LobbyState lobby) {
    final profile = _ref.read(profileRepositoryProvider).getProfile();
    final localPlayerId = profile?.username ?? '';
    final isHost = _ref.read(bleRoleProvider) == BleRole.host;

    final players = lobby.players
        .map((slot) => PlayerGameState.fromSlot(
              slot: slot,
              startingLife: lobby.config.startingLife,
            ))
        .toList();

    final turnOrder = players.map((p) => p.playerId).toList();
    final singlePlayer = players.length == 1;

    state = GameState(
      players: players,
      turnOrder: turnOrder,
      activePlayerIndex: 0,
      currentPhase: GamePhase.untap,
      roundNumber: 1,
      alliancesEnabled: lobby.config.alliancesEnabled,
      isHost: isHost,
      localPlayerId: localPlayerId,
      gameStartTime: DateTime.now(),
      awaitingFirstPlayerRoll: !singlePlayer,
      firstPlayerRolls: const {},
      autoKoFromLife: lobby.config.autoKoFromLife,
      autoKoFromPoison: lobby.config.autoKoFromPoison,
      autoKoFromCommanderDamage: lobby.config.autoKoFromCommanderDamage,
      commanderDamageReducesLife: lobby.config.commanderDamageReducesLife,
      turnTimeLimitSeconds: lobby.config.turnTimeLimitSeconds,
      trackTurnDuration: lobby.config.trackTurnDuration,
      turnStartTime: DateTime.now(),
      planechaseEnabled: lobby.config.planechaseEnabled,
      archenemyEnabled: lobby.config.archenemyEnabled,
      bountyEnabled: lobby.config.bountyEnabled,
    );

    _listenToBle();
  }

  /// Submit local player's roll for first-player determination (d6).
  void submitFirstPlayerRoll(int roll) {
    if (!state.awaitingFirstPlayerRoll) return;

    if (state.isHost) {
      _hostRecordRoll(state.localPlayerId, roll);
    } else {
      _send(BleMessage(
        type: BleMessageType.firstPlayerRollSubmit,
        payload: {'pid': state.localPlayerId, 'roll': roll},
        seqNum: _nextSeq(),
      ));
    }
  }

  void _hostRecordRoll(String playerId, int roll) {
    final rolls = {...state.firstPlayerRolls, playerId: roll};
    state = state.copyWith(firstPlayerRolls: rolls);
    _maybeCompleteFirstPlayerRoll();
  }

  void _maybeCompleteFirstPlayerRoll() {
    if (!state.isHost || !state.awaitingFirstPlayerRoll) return;
    if (state.firstPlayerRolls.length < state.players.length) return;

    // Highest roll goes first; ties broken by first submission order
    final sorted = state.players
        .map((p) => MapEntry(p.playerId, state.firstPlayerRolls[p.playerId] ?? 0))
        .toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return state.turnOrder.indexOf(a.key)
            .compareTo(state.turnOrder.indexOf(b.key));
      });

    final turnOrder = sorted.map((e) => e.key).toList();
    final now = DateTime.now();
    state = state.copyWith(
      turnOrder: turnOrder,
      activePlayerIndex: 0,
      awaitingFirstPlayerRoll: false,
      firstPlayerRolls: const {},
      turnStartTime: now,
    );

    _startTurnLimitTimer();

    _send(BleMessage(
      type: BleMessageType.firstPlayerTurnOrder,
      payload: {'turnOrder': turnOrder},
      seqNum: _nextSeq(),
    ));
  }

  // ── Life ─────────────────────────────────────────────────────────────────

  void adjustLife(String playerId, int delta) {
    if (state.timeoutActive) return;
    final player = _playerById(playerId);
    if (player == null || player.isEliminated) return;

    final newLife = player.life + delta;
    final newLog = List<LifeChange>.from(player.lifeChangeLog)
      ..add(LifeChange(delta: delta, time: DateTime.now()));
    if (newLog.length > 10) newLog.removeAt(0);

    _pushUndo(UndoAction(
      playerId: playerId,
      field: 'life',
      previousValue: player.life,
    ));

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != playerId) return p;
        return p.copyWith(life: newLife, lifeChangeLog: newLog);
      }).toList(),
    );

    _appendGameLog(
      '${player.username}: Life ${delta > 0 ? '+' : ''}$delta',
    );

    _send(BleMessage.stateDelta(
      seqNum: _nextSeq(),
      playerId: playerId,
      field: 'life',
      newValue: newLife,
      delta: delta,
    ));

    _checkLossConditions();
  }

  // ── Counters ─────────────────────────────────────────────────────────────

  void adjustCounter(String playerId, String field, int delta) {
    if (state.timeoutActive) return;
    final player = _playerById(playerId);
    if (player == null || player.isEliminated) return;

    final current = _getCounterValue(player, field);
    final newValue = (current + delta).clamp(0, 9999);

    _pushUndo(UndoAction(
      playerId: playerId,
      field: field,
      previousValue: current,
    ));

    state = state.copyWith(
      players: state.players
          .map((p) =>
              p.playerId == playerId ? _setCounterValue(p, field, newValue) : p)
          .toList(),
    );

    final pl = _playerById(playerId);
    if (pl != null) {
      _appendGameLog(
        '${pl.username}: ${_labelForCounterField(field)} '
        '${delta > 0 ? '+' : ''}$delta (→ $newValue)',
      );
    }

    _send(BleMessage.stateDelta(
      seqNum: _nextSeq(),
      playerId: playerId,
      field: field,
      newValue: newValue,
      delta: delta,
    ));

    _checkLossConditions();
  }

  /// Snap-style dial adjustment without flooding undo (single delta vs prior value).
  void setGameplayDialAbsolute(String playerId, String field, int value) {
    final player = _playerById(playerId);
    if (player == null || player.isEliminated) return;
    final v = value.clamp(0, 9999);
    final cur = _getCounterValue(player, field);
    if (v == cur) return;
    adjustCounter(playerId, field, v - cur);
  }

  /// Session-local custom dial metadata (labels). Values sync via normal state deltas.
  void registerCustomGameplayDial(
      String playerId, String rawKey, String rawLabel) {
    if (state.timeoutActive) return;
    final key = rawKey
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final label = rawLabel.trim();
    if (key.isEmpty || label.isEmpty) return;

    const core = {'life', 'poison', 'energy', 'experience', 'rad'};
    if (core.contains(key) || GameplayDialIds.presets.contains(key)) return;

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != playerId) return p;
        final labels = Map<String, String>.from(p.customDialLabels);
        labels[key] = label;
        final vis = [...p.visibleGameplayDials];
        if (!vis.contains(key)) vis.add(key);
        return p.copyWith(customDialLabels: labels, visibleGameplayDials: vis);
      }).toList(),
    );
  }

  static const _coreDialFields = {'poison', 'energy', 'experience', 'rad'};

  bool _isKnownDialField(PlayerGameState p, String field) =>
      _coreDialFields.contains(field) ||
      GameplayDialIds.presets.contains(field) ||
      p.customDialLabels.containsKey(field);

  /// Show a dial on this player's strip (values stay in counter maps).
  void addGameplayDialToStrip(String playerId, String field) {
    if (state.timeoutActive) return;
    final f = field.trim().toLowerCase();
    if (f.isEmpty) return;
    final player = _playerById(playerId);
    if (player == null || player.isEliminated) return;
    if (!_isKnownDialField(player, f)) return;

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != playerId) return p;
        if (p.visibleGameplayDials.contains(f)) return p;
        return p.copyWith(visibleGameplayDials: [...p.visibleGameplayDials, f]);
      }).toList(),
    );
  }

  /// Hide a dial from the strip without changing its value.
  void removeGameplayDialFromStrip(String playerId, String field) {
    if (state.timeoutActive) return;
    final f = field.trim().toLowerCase();
    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != playerId) return p;
        final next =
            p.visibleGameplayDials.where((id) => id != f).toList(growable: false);
        return p.copyWith(visibleGameplayDials: next);
      }).toList(),
    );
  }

  int _getCounterValue(PlayerGameState p, String field) => switch (field) {
        'poison' => p.poison,
        'energy' => p.energy,
        'experience' => p.experience,
        'rad' => p.rad,
        _ => p.extraDials[field] ?? 0,
      };

  PlayerGameState _setCounterValue(PlayerGameState p, String field, int value) {
    switch (field) {
      case 'poison':
        return p.copyWith(poison: value);
      case 'energy':
        return p.copyWith(energy: value);
      case 'experience':
        return p.copyWith(experience: value);
      case 'rad':
        return p.copyWith(rad: value);
      default:
        final m = Map<String, int>.from(p.extraDials);
        if (value <= 0) {
          m.remove(field);
        } else {
          m[field] = value;
        }
        return p.copyWith(extraDials: m);
    }
  }

  // ── Commander Damage ──────────────────────────────────────────────────────

  /// [partnerIndex] 0 = primary commander, 1 = partner commander.
  void applyCommanderDamage({
    required String fromPlayerId,
    required int partnerIndex,
    required String toPlayerId,
    required int delta,
  }) {
    if (state.timeoutActive) return;
    final victim = _playerById(toPlayerId);
    if (victim == null || victim.isEliminated || delta <= 0) return;

    final currentDamage =
        Map<String, List<int>>.from(victim.commanderDamage.map(
      (k, v) => MapEntry(k, List<int>.from(v)),
    ));
    final fromDamage =
        List<int>.from(currentDamage[fromPlayerId] ?? [0, 0]);
    while (fromDamage.length <= partnerIndex) {
      fromDamage.add(0);
    }

    _pushUndo(UndoAction(
      playerId: toPlayerId,
      field: 'commanderDamage',
      previousValue: fromDamage[partnerIndex],
      extra: {
        'fromId': fromPlayerId,
        'pi': partnerIndex,
        'prevLife': victim.life,
      },
    ));

    fromDamage[partnerIndex] += delta;
    currentDamage[fromPlayerId] = fromDamage;
    final reducesLife = state.commanderDamageReducesLife;
    final newLife = reducesLife ? victim.life - delta : victim.life;
    List<LifeChange> newLog = victim.lifeChangeLog;
    if (reducesLife) {
      newLog = List<LifeChange>.from(victim.lifeChangeLog)
        ..add(LifeChange(delta: -delta, time: DateTime.now()));
      if (newLog.length > 10) newLog.removeAt(0);
    }

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != toPlayerId) return p;
        return p.copyWith(
          life: newLife,
          commanderDamage: currentDamage,
          lifeChangeLog: newLog,
        );
      }).toList(),
    );

    final fromP = _playerById(fromPlayerId);
    final toP = victim;
    _appendGameLog(
      '${fromP?.username ?? '?'} → ${toP.username}: Commander damage +$delta',
    );

    _send(BleMessage.commanderDamage(
      seqNum: _nextSeq(),
      fromPlayerId: fromPlayerId,
      partnerIndex: partnerIndex,
      toPlayerId: toPlayerId,
      amount: delta,
    ));

    _checkLossConditions();
  }

  // ── Proliferate ───────────────────────────────────────────────────────────

  void proliferate(String initiatingPlayerId) {
    if (state.timeoutActive) return;
    state = state.copyWith(
      players: state.players.map((p) {
        if (p.isEliminated) return p;
        final xd = Map<String, int>.from(p.extraDials);
        for (final e in xd.entries.toList()) {
          if (e.value > 0) xd[e.key] = e.value + 1;
        }
        return p.copyWith(
          poison: p.poison > 0 ? p.poison + 1 : p.poison,
          energy: p.energy > 0 ? p.energy + 1 : p.energy,
          experience: p.experience > 0 ? p.experience + 1 : p.experience,
          rad: p.rad > 0 ? p.rad + 1 : p.rad,
          extraDials: xd,
        );
      }).toList(),
    );

    _appendGameLog('Proliferate: all players');

    _send(BleMessage(
      type: BleMessageType.proliferate,
      payload: {'pid': initiatingPlayerId},
      seqNum: _nextSeq(),
    ));

    _checkLossConditions();
  }

  // ── Commander Tax ─────────────────────────────────────────────────────────

  void castCommanderFromZone(String playerId) {
    if (state.timeoutActive) return;
    final player = _playerById(playerId);
    if (player == null) return;

    _pushUndo(UndoAction(
      playerId: playerId,
      field: 'commanderCast',
      previousValue: player.commanderCastCount,
    ));

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != playerId) return p;
        return p.copyWith(commanderCastCount: p.commanderCastCount + 1);
      }).toList(),
    );

    _send(BleMessage(
      type: BleMessageType.commanderCastFromZone,
      payload: {'pid': playerId},
      seqNum: _nextSeq(),
    ));
  }

  // ── Undo ──────────────────────────────────────────────────────────────────

  void undo(String playerId) {
    final player = _playerById(playerId);
    if (player == null || player.undoStack.isEmpty) return;

    final action = player.undoStack.last;
    final newStack =
        List<UndoAction>.from(player.undoStack)..removeLast();

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != playerId) return p;
        var updated = p.copyWith(undoStack: newStack);

        switch (action.field) {
          case 'life':
            updated = updated.copyWith(life: action.previousValue);
          case 'poison':
            updated = updated.copyWith(poison: action.previousValue);
          case 'energy':
            updated = updated.copyWith(energy: action.previousValue);
          case 'experience':
            updated = updated.copyWith(experience: action.previousValue);
          case 'rad':
            updated = updated.copyWith(rad: action.previousValue);
          case 'commanderCast':
            updated = updated.copyWith(commanderCastCount: action.previousValue);
            break;
          case 'commanderDamage':
            final extra = action.extra!;
            final fromId = extra['fromId'] as String;
            final pi = extra['pi'] as int;
            final prevLife = extra['prevLife'] as int;
            final dmg =
                Map<String, List<int>>.from(p.commanderDamage.map(
              (k, v) => MapEntry(k, List<int>.from(v)),
            ));
            final fromDmg = List<int>.from(dmg[fromId] ?? [0, 0]);
            while (fromDmg.length <= pi) {
              fromDmg.add(0);
            }
            fromDmg[pi] = action.previousValue;
            dmg[fromId] = fromDmg;
            updated = updated.copyWith(life: prevLife, commanderDamage: dmg);
            break;
          default:
            final m = Map<String, int>.from(p.extraDials);
            if (action.previousValue <= 0) {
              m.remove(action.field);
            } else {
              m[action.field] = action.previousValue;
            }
            updated = updated.copyWith(extraDials: m);
        }
        return updated;
      }).toList(),
    );

    _send(BleMessage(
      type: BleMessageType.undoAction,
      payload: {
        'pid': playerId,
        'field': action.field,
        'prevValue': action.previousValue,
        if (action.extra != null) 'extra': action.extra,
      },
      seqNum: _nextSeq(),
    ));
  }

  void _pushUndo(UndoAction action) {
    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != action.playerId) return p;
        var stack = List<UndoAction>.from(p.undoStack)..add(action);
        if (stack.length > kUndoStackDepth) stack.removeAt(0);
        return p.copyWith(undoStack: stack);
      }).toList(),
    );
  }

  // ── Variant modes (Planechase, Archenemy, Bounty) ─────────────────────────

  /// Advance to next plane (planeswalk). Caller must ensure deck has cards.
  void advancePlanar(int deckSize) {
    if (!state.planechaseEnabled || deckSize <= 0) return;
    final next = (state.currentPlanarIndex + 1) % deckSize;
    state = state.copyWith(currentPlanarIndex: next);
    _send(BleMessage.variantStateUpdate(
      seqNum: _nextSeq(),
      currentPlanarIndex: next,
    ));
  }

  /// Set current plane by index (e.g. after planar die roll).
  void setPlanarIndex(int index) {
    if (!state.planechaseEnabled) return;
    state = state.copyWith(currentPlanarIndex: index);
    _send(BleMessage.variantStateUpdate(
      seqNum: _nextSeq(),
      currentPlanarIndex: index,
    ));
  }

  /// Advance to next scheme (Archenemy reveals at start of turn).
  void advanceScheme(int deckSize) {
    if (!state.archenemyEnabled || deckSize <= 0) return;
    final next = (state.currentSchemeIndex + 1) % deckSize;
    state = state.copyWith(currentSchemeIndex: next);
    _send(BleMessage.variantStateUpdate(
      seqNum: _nextSeq(),
      currentSchemeIndex: next,
    ));
  }

  /// Advance to next bounty.
  void advanceBounty(int deckSize) {
    if (!state.bountyEnabled || deckSize <= 0) return;
    final next = (state.currentBountyIndex + 1) % deckSize;
    state = state.copyWith(currentBountyIndex: next);
    _send(BleMessage.variantStateUpdate(
      seqNum: _nextSeq(),
      currentBountyIndex: next,
    ));
  }

  // ── Turn & Phase ──────────────────────────────────────────────────────────

  void endTurn() {
    if (state.priorityHeld) return;
    _cancelTurnLimitTimer();

    // Expire end-of-turn alliances
    final expiredIds = state.alliances
        .where((a) =>
            a.duration == AllianceDuration.endOfTurn &&
            a.isExpiredAtTurnEnd(
                state.activePlayerIndex, state.roundNumber))
        .expand((a) => [a.proposerId, a.targetId])
        .toSet();

    var alliances = state.alliances
        .where((a) => !expiredIds.contains(a.proposerId))
        .toList();

    // Find next living player
    var nextIndex = (state.activePlayerIndex + 1) % state.turnOrder.length;
    for (var i = 0; i < state.turnOrder.length; i++) {
      final pId = state.turnOrder[nextIndex % state.turnOrder.length];
      final p = state.playerById(pId);
      if (p != null && !p.isEliminated) break;
      nextIndex++;
    }
    nextIndex = nextIndex % state.turnOrder.length;

    final newRound = nextIndex <= state.activePlayerIndex
        ? state.roundNumber + 1
        : state.roundNumber;

    // Expire end-of-round alliances on round change
    if (newRound > state.roundNumber) {
      alliances = alliances
          .where((a) =>
              !(a.duration == AllianceDuration.endOfRound &&
                  a.isExpiredAtTurnEnd(nextIndex, newRound)))
          .toList();
    }

    // Also sync ally reference on PlayerGameState when alliances expire
    final aliveAllyIds = alliances
        .expand((a) => [a.proposerId, a.targetId])
        .toSet();

    final now = DateTime.now();
    final ending = state.playerById(state.activePlayerId);
    final tn = state.sessionTurnCounter;
    final turnEndEntry = GameLogEntry(
      turnNumber: tn,
      time: now,
      message: '${ending?.username ?? '?'} ends turn',
    );
    var turnLogs = [...state.sessionActionLog, turnEndEntry];
    if (turnLogs.length > _kLogCap) {
      turnLogs = turnLogs.sublist(turnLogs.length - _kLogCap);
    }

    state = state.copyWith(
      activePlayerIndex: nextIndex,
      currentPhase: GamePhase.untap,
      roundNumber: newRound,
      priorityHeld: false,
      priorityHolderId: null,
      alliances: alliances,
      turnStartTime: now,
      sessionTurnCounter: tn + 1,
      sessionActionLog: turnLogs,
      players: state.players.map((p) {
        if (p.allyPlayerId != null &&
            !aliveAllyIds.contains(p.playerId)) {
          return p.copyWith(allyPlayerId: null);
        }
        return p;
      }).toList(),
    );

    _send(BleMessage(
      type: BleMessageType.turnEnd,
      payload: {
        'nextIndex': nextIndex,
        'round': newRound,
        'turnStartTime': now.toIso8601String(),
        'sessionTurnCounter': tn + 1,
        'turnEndLog': turnEndEntry.toJson(),
      },
      seqNum: _nextSeq(),
    ));

    _startTurnLimitTimer();
  }

  void _startTurnLimitTimer() {
    _turnLimitTimer?.cancel();
    final limit = state.turnTimeLimitSeconds;
    if (limit != null && state.isHost && !state.gameOver) {
      _turnLimitTimer = Timer(Duration(seconds: limit), () {
        if (state.priorityHeld || state.timeoutActive) return;
        endTurn();
      });
    }
  }

  void _cancelTurnLimitTimer() {
    _turnLimitTimer?.cancel();
    _turnLimitTimer = null;
  }

  void advancePhase() {
    if (state.priorityHeld || state.timeoutActive) return;
    if (state.currentPhase.isFinalPhase) {
      endTurn();
      return;
    }
    final next = state.currentPhase.next;
    state = state.copyWith(currentPhase: next);
    _send(BleMessage(
      type: BleMessageType.phaseAdvance,
      payload: {'phase': next.name},
      seqNum: _nextSeq(),
    ));
  }

  /// Host-only correction: step the turn phase backward (same sync as advance).
  void previousPhase() {
    if (state.priorityHeld || state.timeoutActive) return;
    final prev = state.currentPhase.previous;
    state = state.copyWith(currentPhase: prev);
    _send(BleMessage(
      type: BleMessageType.phaseAdvance,
      payload: {'phase': prev.name},
      seqNum: _nextSeq(),
    ));
  }

  /// Set the current phase directly (e.g. when active player taps a phase chip).
  /// Only the active player (whose turn it is) can set the phase.
  void setPhase(GamePhase phase) {
    if (state.priorityHeld || state.timeoutActive) return;
    if (state.activePlayerId != state.localPlayerId) return;
    if (phase == state.currentPhase) return;
    state = state.copyWith(currentPhase: phase);
    _send(BleMessage(
      type: BleMessageType.phaseAdvance,
      payload: {'phase': phase.name},
      seqNum: _nextSeq(),
    ));
  }

  void holdPriority(String playerId) {
    state = state.copyWith(
        priorityHeld: true, priorityHolderId: playerId);
    _send(BleMessage(
      type: BleMessageType.priorityHold,
      payload: {'pid': playerId},
      seqNum: _nextSeq(),
    ));
  }

  void releasePriority(String playerId) {
    if (state.priorityHolderId != playerId) return;
    state = state.copyWith(
        priorityHeld: false, priorityHolderId: null);
    _send(BleMessage(
      type: BleMessageType.priorityRelease,
      payload: {'pid': playerId},
      seqNum: _nextSeq(),
    ));
  }

  // ── Timeout ───────────────────────────────────────────────────────────────

  void startTimeout({int? durationSeconds}) {
    _timeoutTimer?.cancel();
    state = state.copyWith(
      timeoutActive: true,
      timeoutStartTime: DateTime.now(),
      timeoutDurationSeconds: durationSeconds,
    );
    if (durationSeconds != null) {
      _timeoutTimer =
          Timer(Duration(seconds: durationSeconds), endTimeout);
    }
    _send(BleMessage(
      type: BleMessageType.timeoutStart,
      payload: {if (durationSeconds != null) 'duration': durationSeconds},
      seqNum: _nextSeq(),
    ));
  }

  void endTimeout() {
    _timeoutTimer?.cancel();
    state = state.copyWith(
      timeoutActive: false,
      timeoutStartTime: null,
      timeoutDurationSeconds: null,
    );
    _send(BleMessage(
      type: BleMessageType.timeoutEnd,
      payload: {},
      seqNum: _nextSeq(),
    ));
  }

  // ── Alliance System ───────────────────────────────────────────────────────

  void proposeAlliance(
      String fromId, String toId, AllianceDuration duration) {
    if (!state.alliancesEnabled) return;
    // One alliance per player
    if (state.alliances.any((a) => a.involves(fromId))) return;
    if (state.pendingProposals.any((p) => p.fromId == fromId)) return;

    final proposal =
        AllianceProposal(fromId: fromId, toId: toId, duration: duration);
    state = state.copyWith(
        pendingProposals: [...state.pendingProposals, proposal]);

    _send(BleMessage(
      type: BleMessageType.alliancePropose,
      payload: {
        'from': fromId,
        'to': toId,
        'duration': duration.name,
      },
      seqNum: _nextSeq(),
      targetPlayerId: toId,
    ));
  }

  void respondToAlliance(String targetId, bool accept) {
    final proposal = state.pendingProposalFor(targetId);
    if (proposal == null) return;

    final newProposals = state.pendingProposals
        .where((p) => p.toId != targetId)
        .toList();

    if (accept) {
      final alliance = Alliance(
        proposerId: proposal.fromId,
        targetId: targetId,
        duration: proposal.duration,
        formedAtRound: state.roundNumber,
        formedAtTurnIndex: state.activePlayerIndex,
      );
      state = state.copyWith(
        alliances: [...state.alliances, alliance],
        pendingProposals: newProposals,
        players: state.players.map((p) {
          if (p.playerId == proposal.fromId) {
            return p.copyWith(allyPlayerId: targetId);
          }
          if (p.playerId == targetId) {
            return p.copyWith(allyPlayerId: proposal.fromId);
          }
          return p;
        }).toList(),
      );
    } else {
      state = state.copyWith(pendingProposals: newProposals);
    }

    _send(BleMessage(
      type: BleMessageType.allianceRespond,
      payload: {
        'from': proposal.fromId,
        'to': targetId,
        'accept': accept,
      },
      seqNum: _nextSeq(),
    ));
  }

  void breakAlliance(String playerId) {
    final alliance = state.allianceFor(playerId);
    if (alliance == null) return;
    _removeAlliance(alliance);
    _send(BleMessage(
      type: BleMessageType.allianceBreak,
      payload: {'pid': playerId},
      seqNum: _nextSeq(),
    ));
  }

  void _removeAlliance(Alliance alliance) {
    state = state.copyWith(
      alliances:
          state.alliances.where((a) => !a.involves(alliance.proposerId)).toList(),
      players: state.players.map((p) {
        if (alliance.involves(p.playerId)) {
          return p.copyWith(allyPlayerId: null);
        }
        return p;
      }).toList(),
    );
  }

  // ── Monarch & Initiative ──────────────────────────────────────────────────

  void setMonarch(String? playerId) {
    state = state.copyWith(monarchPlayerId: playerId);
    _send(BleMessage(
      type: BleMessageType.monarchChange,
      payload: {'pid': playerId ?? ''},
      seqNum: _nextSeq(),
    ));
  }

  void setInitiative(String? playerId) {
    state = state.copyWith(initiativePlayerId: playerId);
    _send(BleMessage(
      type: BleMessageType.initiativeChange,
      payload: {'pid': playerId ?? ''},
      seqNum: _nextSeq(),
    ));
  }

  // ── Day/Night ─────────────────────────────────────────────────────────────

  void setDayNight(DayNightState newState) {
    state = state.copyWith(dayNight: newState);
    _send(BleMessage(
      type: BleMessageType.dayNightChange,
      payload: {'state': newState.name},
      seqNum: _nextSeq(),
    ));
  }

  // ── Teams ────────────────────────────────────────────────────────────────

  void assignTeam(String playerId, int teamIndex) {
    if (!state.isHost && playerId != state.localPlayerId) return;
    state = state.copyWith(
      teamAssignments: {...state.teamAssignments, playerId: teamIndex},
    );
    _send(BleMessage(
      type: BleMessageType.teamAssign,
      payload: {'pid': playerId, 'team': teamIndex},
      seqNum: _nextSeq(),
    ));
  }

  // ── Rematch ───────────────────────────────────────────────────────────────

  void proposeRematch() {
    if (!state.isHost) return;
    _send(BleMessage(
      type: BleMessageType.rematchPropose,
      payload: {},
      seqNum: _nextSeq(),
    ));
  }

  // ── Concede ───────────────────────────────────────────────────────────────

  void concede(String playerId) {
    _eliminatePlayer(playerId, 'concede', null);
    _send(BleMessage(
      type: BleMessageType.concede,
      payload: {'pid': playerId},
      seqNum: _nextSeq(),
    ));
  }

  // ── Loss Condition Checker ────────────────────────────────────────────────

  void _checkLossConditions() {
    for (final player in state.players) {
      if (player.isEliminated) continue;

      if (state.autoKoFromLife && player.life <= 0) {
        _eliminatePlayer(player.playerId, 'life', null);
        continue;
      }

      if (state.autoKoFromPoison && player.poison >= 10) {
        _eliminatePlayer(player.playerId, 'poison', null);
        continue;
      }

      if (state.autoKoFromCommanderDamage) {
        for (final entry in player.commanderDamage.entries) {
          for (int pi = 0; pi < entry.value.length; pi++) {
            if (entry.value[pi] >= 21) {
              _eliminatePlayer(
                  player.playerId, 'commanderDamage', entry.key);
              break;
            }
          }
        }
      }
    }
    _checkGameOver();
  }

  void _eliminatePlayer(
      String playerId, String reason, String? killedBy) {
    // Award commander kill credit for commander damage kills
    if (reason == 'commanderDamage') {
      _ref.read(profileRepositoryProvider).incrementCommanderKills();
      bumpProfileRevisionRef(_ref);
    }

    // Remove from alliances
    final alliance = state.allianceFor(playerId);
    if (alliance != null) _removeAlliance(alliance);

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != playerId) return p;
        return p.copyWith(
          isEliminated: true,
          eliminationReason: reason,
          killedByPlayerId: killedBy,
        );
      }).toList(),
    );

    _send(BleMessage.playerEliminated(
      seqNum: _nextSeq(),
      playerId: playerId,
      reason: reason,
      killedByPlayerId: killedBy,
    ));
  }

  void _checkGameOver() {
    final alive = state.players.where((p) => !p.isEliminated).toList();
    if (alive.length <= 1 && state.players.length > 1) {
      final winner = alive.isEmpty ? null : alive.first;
      state = state.copyWith(
          gameOver: true, winnerPlayerId: winner?.playerId);
    }
  }

  // ── State Snapshot ────────────────────────────────────────────────────────

  /// Build a full snapshot for a reconnecting player or for game start.
  Map<String, dynamic> buildSnapshot() => state.toSnapshotJson();

  void applySnapshot(Map<String, dynamic> snapshot) {
    state = GameState.fromSnapshotJson(
      snapshot,
      isHost: state.isHost,
      localPlayerId: state.localPlayerId,
    );
  }

  // ── BLE inbound ───────────────────────────────────────────────────────────

  void _listenToBle() {
    final service = _ref.read(bleServiceProvider);
    if (service == null) return;
    _messageSub = service.messageStream.listen(_onBleMessage);
  }

  void _onBleMessage(BleMessage msg) {
    switch (msg.type) {
      case BleMessageType.stateDelta:
        _applyStateDelta(msg.payload);
      case BleMessageType.commanderDamage:
        _applyCommanderDamage(msg.payload);
      case BleMessageType.undoAction:
        _applyUndo(msg.payload);
      case BleMessageType.proliferate:
        _applyProliferate();
      case BleMessageType.commanderCastFromZone:
        final pid = msg.payload['pid'] as String? ?? '';
        state = state.copyWith(
          players: state.players.map((p) {
            if (p.playerId != pid) return p;
            return p.copyWith(commanderCastCount: p.commanderCastCount + 1);
          }).toList(),
        );
      case BleMessageType.phaseAdvance:
        final phaseName = msg.payload['phase'] as String? ?? '';
        final phase = GamePhase.values.firstWhere(
          (p) => p.name == phaseName,
          orElse: () => state.currentPhase,
        );
        state = state.copyWith(currentPhase: phase);
      case BleMessageType.turnEnd:
        _applyTurnEnd(msg.payload);
      case BleMessageType.priorityHold:
        final pid = msg.payload['pid'] as String? ?? '';
        state = state.copyWith(priorityHeld: true, priorityHolderId: pid);
      case BleMessageType.priorityRelease:
        state = state.copyWith(priorityHeld: false, priorityHolderId: null);
      case BleMessageType.timeoutStart:
        final dur = (msg.payload['duration'] as num?)?.toInt();
        state = state.copyWith(
          timeoutActive: true,
          timeoutStartTime: DateTime.now(),
          timeoutDurationSeconds: dur,
        );
      case BleMessageType.timeoutEnd:
        state = state.copyWith(
            timeoutActive: false, timeoutStartTime: null, timeoutDurationSeconds: null);
      case BleMessageType.monarchChange:
        final pid = msg.payload['pid'] as String?;
        state = state.copyWith(monarchPlayerId: pid?.isEmpty == true ? null : pid);
      case BleMessageType.initiativeChange:
        final pid = msg.payload['pid'] as String?;
        state = state.copyWith(
            initiativePlayerId: pid?.isEmpty == true ? null : pid);
      case BleMessageType.dayNightChange:
        final dn = DayNightState.values.firstWhere(
          (d) => d.name == msg.payload['state'],
          orElse: () => DayNightState.none,
        );
        state = state.copyWith(dayNight: dn);
      case BleMessageType.alliancePropose:
        _applyAlliancePropose(msg.payload);
      case BleMessageType.allianceRespond:
        _applyAllianceRespond(msg.payload);
      case BleMessageType.allianceBreak:
        final pid = msg.payload['pid'] as String? ?? '';
        final a = state.allianceFor(pid);
        if (a != null) _removeAlliance(a);
      case BleMessageType.concede:
        final pid = msg.payload['pid'] as String? ?? '';
        _eliminatePlayer(pid, 'concede', null);
      case BleMessageType.playerEliminated:
        _applyElimination(msg.payload);
      case BleMessageType.stateSnapshot:
        applySnapshot(msg.payload);
      case BleMessageType.teamAssign:
        final pid = msg.payload['pid'] as String? ?? '';
        final team = (msg.payload['team'] as num?)?.toInt() ?? 0;
        state = state.copyWith(
          teamAssignments: {...state.teamAssignments, pid: team},
        );
      case BleMessageType.variantStateUpdate:
        final planar = (msg.payload['planar'] as num?)?.toInt();
        final scheme = (msg.payload['scheme'] as num?)?.toInt();
        final bounty = (msg.payload['bounty'] as num?)?.toInt();
        state = state.copyWith(
          currentPlanarIndex: planar ?? state.currentPlanarIndex,
          currentSchemeIndex: scheme ?? state.currentSchemeIndex,
          currentBountyIndex: bounty ?? state.currentBountyIndex,
        );
      case BleMessageType.rematchPropose:
        // Clients handle this at the UI layer via stream.
        break;
      case BleMessageType.firstPlayerRollSubmit:
        if (state.isHost) {
          final pid = msg.payload['pid'] as String? ?? '';
          final roll = (msg.payload['roll'] as num?)?.toInt() ?? 0;
          _hostRecordRoll(pid, roll);
        }
        break;
      case BleMessageType.firstPlayerTurnOrder:
        final order = (msg.payload['turnOrder'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];
        if (order.isNotEmpty) {
          state = state.copyWith(
            turnOrder: order,
            activePlayerIndex: 0,
            awaitingFirstPlayerRoll: false,
            firstPlayerRolls: const {},
            turnStartTime: DateTime.now(),
          );
        }
        break;
      default:
        break;
    }

    // Host re-broadcasts client actions to all other clients.
    // Skip firstPlayerRollSubmit (host collects, then broadcasts turn order).
    if (state.isHost && msg.type != BleMessageType.firstPlayerRollSubmit) {
      _ref.read(bleServiceProvider)?.send(msg);
    }
  }

  void _applyStateDelta(Map<String, dynamic> payload) {
    final pid = payload['pid'] as String? ?? '';
    final field = payload['field'] as String? ?? '';
    final newValue = (payload['val'] as num).toInt();

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != pid) return p;
        switch (field) {
          case 'life':
            return p.copyWith(life: newValue);
          case 'poison':
            return p.copyWith(poison: newValue);
          case 'energy':
            return p.copyWith(energy: newValue);
          case 'experience':
            return p.copyWith(experience: newValue);
          case 'rad':
            return p.copyWith(rad: newValue);
          default:
            final m = Map<String, int>.from(p.extraDials);
            if (newValue <= 0) {
              m.remove(field);
            } else {
              m[field] = newValue;
            }
            return p.copyWith(extraDials: m);
        }
      }).toList(),
    );

    final delta = (payload['delta'] as num?)?.toInt() ?? 0;
    final synced = _playerById(pid);
    if (synced != null && delta != 0) {
      if (field == 'life') {
        _appendGameLog(
          '${synced.username}: Life ${delta > 0 ? '+' : ''}$delta',
        );
      } else {
        _appendGameLog(
          '${synced.username}: ${_labelForCounterField(field)} '
          '${delta > 0 ? '+' : ''}$delta',
        );
      }
    }

    _checkLossConditions();
  }

  void _applyCommanderDamage(Map<String, dynamic> payload) {
    final fromId = payload['from'] as String? ?? '';
    final pi = (payload['pi'] as num?)?.toInt() ?? 0;
    final toId = payload['to'] as String? ?? '';
    final amount = (payload['amt'] as num?)?.toInt() ?? 0;

    final victim = state.playerById(toId);
    if (victim == null) return;

    final dmg = Map<String, List<int>>.from(victim.commanderDamage.map(
      (k, v) => MapEntry(k, List<int>.from(v)),
    ));
    final fromDmg = List<int>.from(dmg[fromId] ?? [0, 0]);
    while (fromDmg.length <= pi) {
      fromDmg.add(0);
    }
    fromDmg[pi] += amount;
    dmg[fromId] = fromDmg;

    final reducesLife = state.commanderDamageReducesLife;
    final newLife = reducesLife ? victim.life - amount : victim.life;

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != toId) return p;
        return p.copyWith(
          life: newLife,
          commanderDamage: dmg,
        );
      }).toList(),
    );
    _checkLossConditions();
  }

  void _applyUndo(Map<String, dynamic> payload) {
    final pid = payload['pid'] as String? ?? '';
    final field = payload['field'] as String? ?? '';
    final prevValue = (payload['prevValue'] as num?)?.toInt() ?? 0;
    final extra = payload['extra'] as Map<String, dynamic>?;

    state = state.copyWith(
      players: state.players.map((p) {
        if (p.playerId != pid) return p;
        switch (field) {
          case 'life':
            return p.copyWith(life: prevValue);
          case 'poison':
            return p.copyWith(poison: prevValue);
          case 'energy':
            return p.copyWith(energy: prevValue);
          case 'experience':
            return p.copyWith(experience: prevValue);
          case 'rad':
            return p.copyWith(rad: prevValue);
          case 'commanderCast':
            return p.copyWith(commanderCastCount: prevValue);
          case 'commanderDamage':
            if (extra == null) return p;
            final fromId = extra['fromId'] as String;
            final pi = extra['pi'] as int;
            final prevLife = extra['prevLife'] as int;
            final dmg = Map<String, List<int>>.from(p.commanderDamage.map(
              (k, v) => MapEntry(k, List<int>.from(v)),
            ));
            final fromDmg = List<int>.from(dmg[fromId] ?? [0, 0]);
            while (fromDmg.length <= pi) {
              fromDmg.add(0);
            }
            fromDmg[pi] = prevValue;
            dmg[fromId] = fromDmg;
            return p.copyWith(life: prevLife, commanderDamage: dmg);
          default:
            final m = Map<String, int>.from(p.extraDials);
            if (prevValue <= 0) {
              m.remove(field);
            } else {
              m[field] = prevValue;
            }
            return p.copyWith(extraDials: m);
        }
      }).toList(),
    );
  }

  void _applyProliferate() {
    state = state.copyWith(
      players: state.players.map((p) {
        if (p.isEliminated) return p;
        final xd = Map<String, int>.from(p.extraDials);
        for (final e in xd.entries.toList()) {
          if (e.value > 0) xd[e.key] = e.value + 1;
        }
        return p.copyWith(
          poison: p.poison > 0 ? p.poison + 1 : p.poison,
          energy: p.energy > 0 ? p.energy + 1 : p.energy,
          experience: p.experience > 0 ? p.experience + 1 : p.experience,
          rad: p.rad > 0 ? p.rad + 1 : p.rad,
          extraDials: xd,
        );
      }).toList(),
    );
    _appendGameLog('Proliferate: all players');
    _checkLossConditions();
  }

  void _applyTurnEnd(Map<String, dynamic> payload) {
    final nextIndex = (payload['nextIndex'] as num?)?.toInt() ?? 0;
    final round = (payload['round'] as num?)?.toInt() ?? state.roundNumber;
    final turnStartStr = payload['turnStartTime'] as String?;
    final turnStart = turnStartStr != null
        ? DateTime.tryParse(turnStartStr)
        : DateTime.now();
    final stc = (payload['sessionTurnCounter'] as num?)?.toInt() ??
        state.sessionTurnCounter + 1;
    final logJson = payload['turnEndLog'] as Map<String, dynamic>?;
    var logs = state.sessionActionLog;
    if (logJson != null) {
      logs = [...logs, GameLogEntry.fromJson(logJson)];
      if (logs.length > _kLogCap) {
        logs = logs.sublist(logs.length - _kLogCap);
      }
    }

    state = state.copyWith(
      activePlayerIndex: nextIndex,
      currentPhase: GamePhase.untap,
      roundNumber: round,
      priorityHeld: false,
      priorityHolderId: null,
      turnStartTime: turnStart,
      sessionTurnCounter: stc,
      sessionActionLog: logJson != null ? logs : state.sessionActionLog,
    );
  }

  void _applyElimination(Map<String, dynamic> payload) {
    final pid = payload['pid'] as String? ?? '';
    final reason = payload['reason'] as String? ?? 'unknown';
    final killedBy = payload['killedBy'] as String?;
    _eliminatePlayer(pid, reason, killedBy);
  }

  void _applyAlliancePropose(Map<String, dynamic> payload) {
    final fromId = payload['from'] as String? ?? '';
    final toId = payload['to'] as String? ?? '';
    final duration = AllianceDuration.values.firstWhere(
      (d) => d.name == payload['duration'],
      orElse: () => AllianceDuration.manual,
    );
    final proposal =
        AllianceProposal(fromId: fromId, toId: toId, duration: duration);
    if (!state.pendingProposals.any(
        (p) => p.fromId == fromId && p.toId == toId)) {
      state = state.copyWith(
          pendingProposals: [...state.pendingProposals, proposal]);
    }
  }

  void _applyAllianceRespond(Map<String, dynamic> payload) {
    final fromId = payload['from'] as String? ?? '';
    final toId = payload['to'] as String? ?? '';
    final accept = payload['accept'] as bool? ?? false;
    final newProposals =
        state.pendingProposals.where((p) => p.toId != toId).toList();

    if (accept) {
      final dur = state.pendingProposals
          .where((p) => p.fromId == fromId && p.toId == toId)
          .map((p) => p.duration)
          .firstOrNull ?? AllianceDuration.manual;
      final alliance = Alliance(
        proposerId: fromId,
        targetId: toId,
        duration: dur,
        formedAtRound: state.roundNumber,
        formedAtTurnIndex: state.activePlayerIndex,
      );
      state = state.copyWith(
        alliances: [...state.alliances, alliance],
        pendingProposals: newProposals,
        players: state.players.map((p) {
          if (p.playerId == fromId) return p.copyWith(allyPlayerId: toId);
          if (p.playerId == toId) return p.copyWith(allyPlayerId: fromId);
          return p;
        }).toList(),
      );
    } else {
      state = state.copyWith(pendingProposals: newProposals);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _send(BleMessage msg) {
    _ref.read(bleServiceProvider)?.send(msg);
  }

  int _nextSeq() => _seqNum++;

  PlayerGameState? _playerById(String id) {
    try {
      return state.players.firstWhere((p) => p.playerId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _timeoutTimer?.cancel();
    _turnLimitTimer?.cancel();
    super.dispose();
  }
}
