import 'dart:convert';

import 'package:hive/hive.dart';

part 'match_record.g.dart';

/// One player row stored in [MatchRecord.participantsJson].
class MatchParticipantSnapshot {
  final String playerId;
  final String username;
  final String? commanderName;
  final String? commanderImageUrl;
  final int teamIndex;

  const MatchParticipantSnapshot({
    required this.playerId,
    required this.username,
    this.commanderName,
    this.commanderImageUrl,
    this.teamIndex = 0,
  });

  factory MatchParticipantSnapshot.fromJson(Map<String, dynamic> json) =>
      MatchParticipantSnapshot(
        playerId: json['playerId'] as String,
        username: json['username'] as String,
        commanderName: json['commanderName'] as String?,
        commanderImageUrl: json['commanderImageUrl'] as String?,
        teamIndex: (json['teamIndex'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'username': username,
        'commanderName': commanderName,
        if (commanderImageUrl != null) 'commanderImageUrl': commanderImageUrl,
        'teamIndex': teamIndex,
      };
}

@HiveType(typeId: 1)
class MatchRecord extends HiveObject {
  @HiveField(0)
  String matchId;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String commanderName;

  @HiveField(3)
  String? partnerCommanderName;

  @HiveField(4)
  List<String> opponentNames;

  @HiveField(5)
  String result; // 'win' | 'loss' | 'concede'

  @HiveField(6)
  String eliminationReason; // 'life' | 'poison' | 'commanderDamage' | 'deckEmpty' | 'concede' | 'survived'

  @HiveField(7)
  String format; // 'Commander' | 'Standard'

  @HiveField(8)
  int durationMinutes;

  @HiveField(9)
  int startingLifeTotal;

  @HiveField(10)
  int playerCount;

  /// Total match duration (wall clock). Prefer over [durationMinutes] for display.
  @HiveField(11)
  int? durationSeconds;

  /// JSON array of [MatchParticipantSnapshot].
  @HiveField(12)
  String? participantsJson;

  /// Pod / playgroup name at time of match.
  @HiveField(13)
  String? podNameSnapshot;

  /// Location label (e.g. office) at time of match.
  @HiveField(14)
  String? locationSnapshot;

  /// Local player's registered deck id, if they played a saved deck.
  @HiveField(15)
  String? localDeckIdSnapshot;

  MatchRecord({
    required this.matchId,
    required this.date,
    required this.commanderName,
    this.partnerCommanderName,
    required this.opponentNames,
    required this.result,
    required this.eliminationReason,
    required this.format,
    required this.durationMinutes,
    required this.startingLifeTotal,
    required this.playerCount,
    this.durationSeconds,
    this.participantsJson,
    this.podNameSnapshot,
    this.locationSnapshot,
    this.localDeckIdSnapshot,
  });

  List<MatchParticipantSnapshot> get participantSnapshots {
    final raw = participantsJson;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              MatchParticipantSnapshot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Effective duration in seconds (legacy rows use minutes only).
  int get durationSecondsEffective =>
      durationSeconds ?? (durationMinutes * 60).clamp(0, 1 << 30);

  /// Player count for display logic (prefer snapshot list when present).
  int get _effectivePlayerCount {
    final snaps = participantSnapshots;
    if (snaps.isNotEmpty) return snaps.length;
    return playerCount;
  }

  /// Short label for match structure: 1v1, Free for all, 2v2, or a team fallback.
  String get matchTypeLabel {
    final n = _effectivePlayerCount;
    if (n <= 1) return 'Solo';
    if (n == 2) return '1vs1';

    final teams = participantSnapshots.map((p) => p.teamIndex).toList();
    if (teams.isEmpty) {
      return n >= 3 ? 'Free for all' : 'Match';
    }

    if (n == 4 && _isTwoVersusTwo(teams)) {
      return '2vs2';
    }

    if (teams.every((t) => t == 0)) {
      return 'Free for all';
    }

    if (n >= 3) {
      return 'Team game';
    }
    return 'Match';
  }
}

bool _isTwoVersusTwo(List<int> teamIndices) {
  if (teamIndices.length != 4) return false;
  final byTeam = <int, int>{};
  for (final t in teamIndices) {
    if (t <= 0) return false;
    byTeam[t] = (byTeam[t] ?? 0) + 1;
  }
  if (byTeam.length != 2) return false;
  final counts = byTeam.values.toList()..sort();
  return counts[0] == 2 && counts[1] == 2;
}
