enum AllianceDuration { endOfTurn, endOfRound, manual }

enum AllianceDeliveryTiming {
  now,
  delaySeconds,
  endOfProposerTurn,
  startOfNextRound,
}

/// A pending alliance proposal (not yet accepted).
class AllianceProposal {
  final String id;
  final String fromId;
  final String toId;
  final AllianceDuration duration;
  final AllianceDeliveryTiming deliveryTiming;
  final DateTime? deliverAt;
  final int createdAtRound;
  final int createdAtTurnIndex;
  final bool delivered;

  const AllianceProposal({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.duration,
    this.deliveryTiming = AllianceDeliveryTiming.now,
    this.deliverAt,
    this.createdAtRound = 1,
    this.createdAtTurnIndex = 0,
    this.delivered = true,
  });

  bool get isScheduled => !delivered;

  AllianceProposal copyWith({
    bool? delivered,
    DateTime? deliverAt,
  }) =>
      AllianceProposal(
        id: id,
        fromId: fromId,
        toId: toId,
        duration: duration,
        deliveryTiming: deliveryTiming,
        deliverAt: deliverAt ?? this.deliverAt,
        createdAtRound: createdAtRound,
        createdAtTurnIndex: createdAtTurnIndex,
        delivered: delivered ?? this.delivered,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromId': fromId,
        'toId': toId,
        'duration': duration.name,
        'deliveryTiming': deliveryTiming.name,
        if (deliverAt != null) 'deliverAt': deliverAt!.toIso8601String(),
        'createdAtRound': createdAtRound,
        'createdAtTurnIndex': createdAtTurnIndex,
        'delivered': delivered,
      };

  factory AllianceProposal.fromJson(Map<String, dynamic> json) =>
      AllianceProposal(
        id: json['id'] as String? ?? '${json['fromId']}_${json['toId']}',
        fromId: json['fromId'] as String,
        toId: json['toId'] as String,
        duration: AllianceDuration.values.firstWhere(
          (d) => d.name == json['duration'],
          orElse: () => AllianceDuration.manual,
        ),
        deliveryTiming: AllianceDeliveryTiming.values.firstWhere(
          (d) => d.name == json['deliveryTiming'],
          orElse: () => AllianceDeliveryTiming.now,
        ),
        deliverAt: json['deliverAt'] != null
            ? DateTime.tryParse(json['deliverAt'] as String)
            : null,
        createdAtRound: (json['createdAtRound'] as num?)?.toInt() ?? 1,
        createdAtTurnIndex: (json['createdAtTurnIndex'] as num?)?.toInt() ?? 0,
        delivered: json['delivered'] as bool? ?? true,
      );
}

/// An accepted secret alliance between two players.
class Alliance {
  final String id;
  final String proposerId;
  final String targetId;
  final AllianceDuration duration;
  final int formedAtRound;
  final int formedAtTurnIndex;
  final bool isRevealed;

  const Alliance({
    required this.id,
    required this.proposerId,
    required this.targetId,
    required this.duration,
    required this.formedAtRound,
    required this.formedAtTurnIndex,
    this.isRevealed = false,
  });

  bool involves(String playerId) =>
      proposerId == playerId || targetId == playerId;

  String allyOf(String playerId) =>
      playerId == proposerId ? targetId : proposerId;

  Alliance copyWith({bool? isRevealed}) => Alliance(
        id: id,
        proposerId: proposerId,
        targetId: targetId,
        duration: duration,
        formedAtRound: formedAtRound,
        formedAtTurnIndex: formedAtTurnIndex,
        isRevealed: isRevealed ?? this.isRevealed,
      );

  /// Returns true when this alliance should auto-expire at end-of-turn or
  /// end-of-round transitions. Manual alliances never auto-expire.
  bool isExpiredAtTurnEnd(int currentTurnIndex, int currentRound) {
    switch (duration) {
      case AllianceDuration.endOfTurn:
        return currentTurnIndex == formedAtTurnIndex &&
            currentRound == formedAtRound;
      case AllianceDuration.endOfRound:
        return currentRound > formedAtRound;
      case AllianceDuration.manual:
        return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'proposerId': proposerId,
        'targetId': targetId,
        'duration': duration.name,
        'formedAtRound': formedAtRound,
        'formedAtTurnIndex': formedAtTurnIndex,
        'isRevealed': isRevealed,
      };

  factory Alliance.fromJson(Map<String, dynamic> json) => Alliance(
        id: json['id'] as String? ??
            '${json['proposerId']}_${json['targetId']}',
        proposerId: json['proposerId'] as String,
        targetId: json['targetId'] as String,
        duration: AllianceDuration.values.firstWhere(
          (d) => d.name == json['duration'],
          orElse: () => AllianceDuration.manual,
        ),
        formedAtRound: (json['formedAtRound'] as num).toInt(),
        formedAtTurnIndex: (json['formedAtTurnIndex'] as num).toInt(),
        isRevealed: json['isRevealed'] as bool? ?? false,
      );
}

String allianceDurationLabel(AllianceDuration duration) {
  switch (duration) {
    case AllianceDuration.endOfTurn:
      return 'Until end of turn';
    case AllianceDuration.endOfRound:
      return 'Until end of round';
    case AllianceDuration.manual:
      return 'Until broken';
  }
}

String allianceDeliveryLabel(AllianceDeliveryTiming timing, {int? seconds}) {
  switch (timing) {
    case AllianceDeliveryTiming.now:
      return 'Deliver now';
    case AllianceDeliveryTiming.delaySeconds:
      return 'Deliver in ${seconds ?? 30}s';
    case AllianceDeliveryTiming.endOfProposerTurn:
      return 'Deliver at end of your turn';
    case AllianceDeliveryTiming.startOfNextRound:
      return 'Deliver next round';
  }
}
