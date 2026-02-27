import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/game_feedback.dart';

class FeedbackRepository {
  static const _boxName = 'matchFeedback';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<void> saveFeedback(GameFeedback feedback) async {
    await _box.put(feedback.matchId, jsonEncode(feedback.toJson()));
  }

  GameFeedback? getFeedback(String matchId) {
    final json = _box.get(matchId);
    if (json == null) return null;
    try {
      return GameFeedback.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Total likes given across all matches (for profile stats).
  int get totalLikesGiven =>
      _box.values.fold<int>(0, (sum, json) {
        try {
          final f = GameFeedback.fromJson(
              jsonDecode(json) as Map<String, dynamic>);
          return sum + f.likePlayerIds.length;
        } catch (_) {
          return sum;
        }
      });

  /// Total dislikes given across all matches.
  int get totalDislikesGiven =>
      _box.values.fold<int>(0, (sum, json) {
        try {
          final f = GameFeedback.fromJson(
              jsonDecode(json) as Map<String, dynamic>);
          return sum + f.dislikePlayerIds.length;
        } catch (_) {
          return sum;
        }
      });

  /// Count of matches where MVP was voted.
  int get totalMvpVotesGiven =>
      _box.values.fold<int>(0, (sum, json) {
        try {
          final f = GameFeedback.fromJson(
              jsonDecode(json) as Map<String, dynamic>);
          return sum + (f.mvpPlayerId != null ? 1 : 0);
        } catch (_) {
          return sum;
        }
      });

  /// Count of matches where Team Player was voted.
  int get totalTeamPlayerVotesGiven =>
      _box.values.fold<int>(0, (sum, json) {
        try {
          final f = GameFeedback.fromJson(
              jsonDecode(json) as Map<String, dynamic>);
          return sum + (f.teamPlayerId != null ? 1 : 0);
        } catch (_) {
          return sum;
        }
      });
}
