import 'package:flutter/material.dart';

import '../models/player_slot.dart';
import 'undo_action.dart';

/// One delta entry in a player's life-change history (shown in the UI log).
class LifeChange {
  final int delta;
  final DateTime time;

  const LifeChange({required this.delta, required this.time});

  Map<String, dynamic> toJson() => {
        'delta': delta,
        'time': time.toIso8601String(),
      };

  factory LifeChange.fromJson(Map<String, dynamic> json) => LifeChange(
        delta: (json['delta'] as num).toInt(),
        time: DateTime.parse(json['time'] as String),
      );
}

/// Per-player in-game state. Reconstructed each session; never persisted to Hive.
class PlayerGameState {
  final String playerId;
  final String username;
  final Color playerColor;

  // Commander
  final String? commanderName;
  final String? commanderImageUrl;
  final String? partnerCommanderName;
  final String? partnerCommanderImageUrl;
  final bool hasPartner;

  // Life & counters
  final int life;
  final int poison;
  final int energy;
  final int experience;
  final int rad;

  // commanderDamage[fromPlayerId] = [primaryDamage, partnerDamage]
  final Map<String, List<int>> commanderDamage;

  // Commander tax (# of times cast from command zone)
  final int commanderCastCount;

  // Alliance
  final String? allyPlayerId;

  // Elimination
  final bool isEliminated;
  final String? eliminationReason; // 'life'|'poison'|'commanderDamage'|'concede'|'disconnect'
  final String? killedByPlayerId;

  // Life change log (last 10 entries)
  final List<LifeChange> lifeChangeLog;

  // Undo stack (max kUndoStackDepth entries)
  final List<UndoAction> undoStack;

  const PlayerGameState({
    required this.playerId,
    required this.username,
    required this.playerColor,
    this.commanderName,
    this.commanderImageUrl,
    this.partnerCommanderName,
    this.partnerCommanderImageUrl,
    this.hasPartner = false,
    required this.life,
    this.poison = 0,
    this.energy = 0,
    this.experience = 0,
    this.rad = 0,
    this.commanderDamage = const {},
    this.commanderCastCount = 0,
    this.allyPlayerId,
    this.isEliminated = false,
    this.eliminationReason,
    this.killedByPlayerId,
    this.lifeChangeLog = const [],
    this.undoStack = const [],
  });

  static const _sentinel = Object();

  PlayerGameState copyWith({
    String? commanderName,
    String? commanderImageUrl,
    String? partnerCommanderName,
    String? partnerCommanderImageUrl,
    bool? hasPartner,
    int? life,
    int? poison,
    int? energy,
    int? experience,
    int? rad,
    Map<String, List<int>>? commanderDamage,
    int? commanderCastCount,
    Object? allyPlayerId = _sentinel,
    bool? isEliminated,
    Object? eliminationReason = _sentinel,
    Object? killedByPlayerId = _sentinel,
    List<LifeChange>? lifeChangeLog,
    List<UndoAction>? undoStack,
  }) {
    return PlayerGameState(
      playerId: playerId,
      username: username,
      playerColor: playerColor,
      commanderName: commanderName ?? this.commanderName,
      commanderImageUrl: commanderImageUrl ?? this.commanderImageUrl,
      partnerCommanderName: partnerCommanderName ?? this.partnerCommanderName,
      partnerCommanderImageUrl:
          partnerCommanderImageUrl ?? this.partnerCommanderImageUrl,
      hasPartner: hasPartner ?? this.hasPartner,
      life: life ?? this.life,
      poison: poison ?? this.poison,
      energy: energy ?? this.energy,
      experience: experience ?? this.experience,
      rad: rad ?? this.rad,
      commanderDamage: commanderDamage ?? this.commanderDamage,
      commanderCastCount: commanderCastCount ?? this.commanderCastCount,
      allyPlayerId: identical(allyPlayerId, _sentinel)
          ? this.allyPlayerId
          : allyPlayerId as String?,
      isEliminated: isEliminated ?? this.isEliminated,
      eliminationReason: identical(eliminationReason, _sentinel)
          ? this.eliminationReason
          : eliminationReason as String?,
      killedByPlayerId: identical(killedByPlayerId, _sentinel)
          ? this.killedByPlayerId
          : killedByPlayerId as String?,
      lifeChangeLog: lifeChangeLog ?? this.lifeChangeLog,
      undoStack: undoStack ?? this.undoStack,
    );
  }

  factory PlayerGameState.fromSlot({
    required PlayerSlot slot,
    required int startingLife,
  }) {
    return PlayerGameState(
      playerId: slot.playerId,
      username: slot.username,
      playerColor: slot.playerColor,
      commanderName: slot.commanderName,
      commanderImageUrl: slot.commanderImageUrl,
      partnerCommanderName: slot.partnerCommanderName,
      partnerCommanderImageUrl: slot.partnerCommanderImageUrl,
      hasPartner: slot.hasPartner,
      life: startingLife,
    );
  }

  int commanderDamageFrom(String fromPlayerId, {int partnerIndex = 0}) {
    final damages = commanderDamage[fromPlayerId];
    if (damages == null || damages.length <= partnerIndex) return 0;
    return damages[partnerIndex];
  }

  int get totalCommanderDamageReceived =>
      commanderDamage.values.expand((v) => v).fold(0, (a, b) => a + b);

  bool get isInDanger => life <= 5 || poison >= 8;

  int get commanderTax => commanderCastCount * 2;

  Map<String, dynamic> toJson() => {
        'pid': playerId,
        'username': username,
        'colorValue': playerColor.toARGB32(),
        'commanderName': commanderName,
        'commanderImageUrl': commanderImageUrl,
        'partnerCommanderName': partnerCommanderName,
        'partnerCommanderImageUrl': partnerCommanderImageUrl,
        'hasPartner': hasPartner,
        'life': life,
        'poison': poison,
        'energy': energy,
        'experience': experience,
        'rad': rad,
        'commanderDamage':
            commanderDamage.map((k, v) => MapEntry(k, v.toList())),
        'commanderCastCount': commanderCastCount,
        'allyPlayerId': allyPlayerId,
        'isEliminated': isEliminated,
        'eliminationReason': eliminationReason,
        'killedByPlayerId': killedByPlayerId,
        'lifeChangeLog': lifeChangeLog.map((e) => e.toJson()).toList(),
      };

  factory PlayerGameState.fromJson(Map<String, dynamic> json) {
    return PlayerGameState(
      playerId: json['pid'] as String,
      username: json['username'] as String,
      playerColor: Color((json['colorValue'] as num).toInt()),
      commanderName: json['commanderName'] as String?,
      commanderImageUrl: json['commanderImageUrl'] as String?,
      partnerCommanderName: json['partnerCommanderName'] as String?,
      partnerCommanderImageUrl: json['partnerCommanderImageUrl'] as String?,
      hasPartner: json['hasPartner'] as bool? ?? false,
      life: (json['life'] as num).toInt(),
      poison: (json['poison'] as num?)?.toInt() ?? 0,
      energy: (json['energy'] as num?)?.toInt() ?? 0,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      rad: (json['rad'] as num?)?.toInt() ?? 0,
      commanderDamage:
          (json['commanderDamage'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, List<int>.from(v as List)),
              ) ??
              {},
      commanderCastCount: (json['commanderCastCount'] as num?)?.toInt() ?? 0,
      allyPlayerId: json['allyPlayerId'] as String?,
      isEliminated: json['isEliminated'] as bool? ?? false,
      eliminationReason: json['eliminationReason'] as String?,
      killedByPlayerId: json['killedByPlayerId'] as String?,
      lifeChangeLog: (json['lifeChangeLog'] as List<dynamic>?)
              ?.map((e) => LifeChange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
