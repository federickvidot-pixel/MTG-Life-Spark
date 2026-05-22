enum AllianceDuration { endOfTurn, endOfRound, manual }

/// A pending alliance proposal (not yet accepted).
class AllianceProposal {
  final String fromId;
  final String toId;
  final AllianceDuration duration;

  const AllianceProposal({
    required this.fromId,
    required this.toId,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'fromId': fromId,
        'toId': toId,
        'duration': duration.name,
      };

  factory AllianceProposal.fromJson(Map<String, dynamic> json) =>
      AllianceProposal(
        fromId: json['fromId'] as String,
        toId: json['toId'] as String,
        duration: AllianceDuration.values.firstWhere(
          (d) => d.name == json['duration'],
          orElse: () => AllianceDuration.manual,
        ),
      );
}

/// An accepted, active secret alliance between two players.
class Alliance {
  final String proposerId;
  final String targetId;
  final AllianceDuration duration;
  final int formedAtRound;
  final int formedAtTurnIndex;

  const Alliance({
    required this.proposerId,
    required this.targetId,
    required this.duration,
    required this.formedAtRound,
    required this.formedAtTurnIndex,
  });

  bool involves(String playerId) =>
      proposerId == playerId || targetId == playerId;

  String allyOf(String playerId) =>
      playerId == proposerId ? targetId : proposerId;

  /// Returns true when this alliance should auto-expire at end-of-turn or
  /// end-of-round transitions. Manual alliances never auto-expire.
  bool isExpiredAtTurnEnd(int currentTurnIndex, int currentRound) {
    switch (duration) {
      case AllianceDuration.endOfTurn:
        return currentTurnIndex == formedAtTurnIndex
            && currentRound == formedAtRound;
      case AllianceDuration.endOfRound:
        return currentRound > formedAtRound;
      case AllianceDuration.manual:
        return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'proposerId': proposerId,
        'targetId': targetId,
        'duration': duration.name,
        'formedAtRound': formedAtRound,
        'formedAtTurnIndex': formedAtTurnIndex,
      };

  factory Alliance.fromJson(Map<String, dynamic> json) => Alliance(
        proposerId: json['proposerId'] as String,
        targetId: json['targetId'] as String,
        duration: AllianceDuration.values.firstWhere(
          (d) => d.name == json['duration'],
          orElse: () => AllianceDuration.manual,
        ),
        formedAtRound: (json['formedAtRound'] as num).toInt(),
        formedAtTurnIndex: (json['formedAtTurnIndex'] as num).toInt(),
      );
}
