/// Feedback data without matchId (used when conceding before match is saved).
class PendingFeedbackData {
  final List<String> likePlayerIds;
  final List<String> dislikePlayerIds;
  final String? mvpPlayerId;
  final String? teamPlayerId;

  const PendingFeedbackData({
    this.likePlayerIds = const [],
    this.dislikePlayerIds = const [],
    this.mvpPlayerId,
    this.teamPlayerId,
  });
}

/// Feedback given by a player after a game ends.
class GameFeedback {
  final String matchId;
  final String voterPlayerId;
  final List<String> likePlayerIds;
  final List<String> dislikePlayerIds;
  final String? mvpPlayerId;
  final String? teamPlayerId;

  const GameFeedback({
    required this.matchId,
    required this.voterPlayerId,
    this.likePlayerIds = const [],
    this.dislikePlayerIds = const [],
    this.mvpPlayerId,
    this.teamPlayerId,
  });

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'voterPlayerId': voterPlayerId,
        'likePlayerIds': likePlayerIds,
        'dislikePlayerIds': dislikePlayerIds,
        'mvpPlayerId': mvpPlayerId,
        'teamPlayerId': teamPlayerId,
      };

  factory GameFeedback.fromJson(Map<String, dynamic> json) => GameFeedback(
        matchId: json['matchId'] as String,
        voterPlayerId: json['voterPlayerId'] as String,
        likePlayerIds: (json['likePlayerIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        dislikePlayerIds: (json['dislikePlayerIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        mvpPlayerId: json['mvpPlayerId'] as String?,
        teamPlayerId: json['teamPlayerId'] as String?,
      );
}
