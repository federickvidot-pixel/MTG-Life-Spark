import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/game/game_providers.dart';
import '../../core/game/game_state.dart';
import '../../core/game/lobby_state.dart';
import '../../core/game/player_game_state.dart';
import '../../core/game/progression_service.dart';
import '../../core/persistence/providers.dart';
import '../../core/models/game_feedback.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/achievement_definitions.dart';
import '../../shared/utils/app_router.dart';
import '../../shared/utils/wizard_rank_titles.dart';
import '../../ui/tokens/layout_tokens.dart';

class EndGameScreen extends ConsumerStatefulWidget {
  const EndGameScreen({super.key});

  @override
  ConsumerState<EndGameScreen> createState() => _EndGameScreenState();
}

class _EndGameScreenState extends ConsumerState<EndGameScreen> {
  bool _saved = false;
  ProgressResult? _result;
  bool _saving = true;
  bool _feedbackSubmitted = false;
  final Set<String> _likePlayerIds = {};
  final Set<String> _dislikePlayerIds = {};
  String? _mvpPlayerId;
  String? _teamPlayerId;
  String? _underdogPlayerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveMatch());
  }

  Future<void> _saveMatch() async {
    if (_saved) return;
    _saved = true;

    try {
      final game = ref.read(gameProvider);
      final lobby = ref.read(lobbyProvider);
      final service = ref.read(progressionServiceProvider);

      final result = await service.recordMatch(
        finalState: game,
        lobbyState: lobby,
        startTime: game.gameStartTime ?? DateTime.now(),
      );

      // Use pending feedback from concede flow if present
      final pending = ref.read(pendingFeedbackProvider);
      if (pending != null && result.matchId.isNotEmpty) {
        await service.saveFeedback(GameFeedback(
          matchId: result.matchId,
          voterPlayerId: game.localPlayerId,
          likePlayerIds: pending.likePlayerIds,
          dislikePlayerIds: pending.dislikePlayerIds,
          mvpPlayerId: pending.mvpPlayerId,
          teamPlayerId: pending.teamPlayerId,
          underdogPlayerId: pending.underdogPlayerId,
        ));
        ref.read(pendingFeedbackProvider.notifier).state = null;
      }

      bumpProfileRevision(ref);
      bumpDeckListRevision(ref);

      if (mounted) {
        setState(() {
          _result = result;
          _saving = false;
          _feedbackSubmitted = pending != null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final winner = game.winnerPlayerId != null
        ? game.playerById(game.winnerPlayerId!)
        : null;
    final isWinner = winner?.playerId == game.localPlayerId;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: _saving
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accent),
                    SizedBox(height: LayoutTokens.gr3),
                    Text(
                      'Saving match results…',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: LayoutTokens.gr4),

                    // ── Winner spotlight ──────────────────────────────────
                    _WinnerBanner(
                      winner: winner,
                      isLocalWinner: isWinner,
                    ),

                    SizedBox(height: LayoutTokens.gr4),

                    // ── Level-up animation ─────────────────────────────────
                    if (_result != null && _result!.leveledUp)
                      _LevelUpCard(result: _result!),

                    // ── XP earned ─────────────────────────────────────────
                    if (_result != null)
                      _XpCard(
                        result: _result!,
                        isWinner: isWinner,
                      ),

                    // ── New achievements ───────────────────────────────────
                    if (_result != null &&
                        _result!.newAchievementIds.isNotEmpty)
                      _AchievementsCard(ids: _result!.newAchievementIds),

                    SizedBox(height: LayoutTokens.gr2),

                    // ── Post-game feedback (like/dislike, MVP, Team Player) ─
                    if (_result != null && _result!.matchId.isNotEmpty)
                      _FeedbackCard(
                        game: game,
                        feedbackSubmitted: _feedbackSubmitted,
                        likePlayerIds: _likePlayerIds,
                        dislikePlayerIds: _dislikePlayerIds,
                        mvpPlayerId: _mvpPlayerId,
                        teamPlayerId: _teamPlayerId,
                        underdogPlayerId: _underdogPlayerId,
                        onLike: (pid) => setState(() {
                          _dislikePlayerIds.remove(pid);
                          _likePlayerIds.add(pid);
                        }),
                        onDislike: (pid) => setState(() {
                          _likePlayerIds.remove(pid);
                          _dislikePlayerIds.add(pid);
                        }),
                        onMvpChanged: (pid) =>
                            setState(() => _mvpPlayerId = pid),
                        onTeamPlayerChanged: (pid) =>
                            setState(() => _teamPlayerId = pid),
                        onUnderdogChanged: (pid) =>
                            setState(() => _underdogPlayerId = pid),
                        onSubmit: () => _submitFeedback(game),
                      ),

                    SizedBox(height: LayoutTokens.gr2),

                    // ── Final standings ────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: LayoutTokens.gr3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Final Standings',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: LayoutTokens.gr1),
                          ...game.players.map((p) => _FinalPlayerRow(
                                p: p,
                                isWinner: p.playerId == game.winnerPlayerId,
                                isLocal: p.playerId == game.localPlayerId,
                              )),
                        ],
                      ),
                    ),

                    SizedBox(height: LayoutTokens.gr5),

                    // ── Actions ────────────────────────────────────────────
                    _ActionButtons(
                      isHost: game.isHost,
                      onHome: () => context.go(AppRoutes.home),
                      onProfile: () => context.go(AppRoutes.home),
                      onRematch: () => _doRematch(context, ref, game),
                    ),

                    SizedBox(height: LayoutTokens.gr5),
                  ],
                ),
              ),
      ),
    );
  }

  void _doRematch(BuildContext context, WidgetRef ref, GameState game) {
    ref.read(gameProvider.notifier).proposeRematch();
    // Navigate back to lobby — lobby state still has all players
    context.go(AppRoutes.lobby);
  }

  Future<void> _submitFeedback(GameState game) async {
    if (_result == null || _result!.matchId.isEmpty) return;
    final feedback = GameFeedback(
      matchId: _result!.matchId,
      voterPlayerId: game.localPlayerId,
      likePlayerIds: _likePlayerIds.toList(),
      dislikePlayerIds: _dislikePlayerIds.toList(),
      mvpPlayerId: _mvpPlayerId,
      teamPlayerId: _teamPlayerId,
      underdogPlayerId: _underdogPlayerId,
    );
    await ref.read(progressionServiceProvider).saveFeedback(feedback);
    if (mounted) setState(() => _feedbackSubmitted = true);
  }
}

// ── Winner Banner ────────────────────────────────────────────────────────────

class _WinnerBanner extends StatelessWidget {
  final PlayerGameState? winner;
  final bool isLocalWinner;

  const _WinnerBanner({required this.winner, required this.isLocalWinner});

  @override
  Widget build(BuildContext context) {
    if (winner == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Game Over — No Winner',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            isLocalWinner ? '🏆 You Win!' : '🎉 Winner',
            style: const TextStyle(
              color: AppTheme.accentGold,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: LayoutTokens.gr3),

          // Commander art
          if (winner!.commanderImageUrl != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: winner!.playerColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: winner!.playerColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: winner!.commanderImageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => CircleAvatar(
                    backgroundColor: winner!.playerColor,
                    child: Text(
                      winner!.username.isNotEmpty
                          ? winner!.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            )
          else
            CircleAvatar(
              radius: 50,
              backgroundColor: winner!.playerColor,
              child: Text(
                winner!.username.isNotEmpty
                    ? winner!.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            ),

          SizedBox(height: LayoutTokens.gr2),
          Text(
            winner!.username,
            style: TextStyle(
              color: winner!.playerColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (winner!.commanderName != null)
            Text(
              winner!.commanderName!,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

// ── Level Up Card ─────────────────────────────────────────────────────────────

class _LevelUpCard extends StatelessWidget {
  final ProgressResult result;

  const _LevelUpCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(LayoutTokens.gr3, LayoutTokens.gr1, LayoutTokens.gr3, 0),
      padding: EdgeInsets.all(LayoutTokens.gr3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.15),
            AppTheme.accent.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Lottie.asset(
              'assets/animations/level_up.json',
              repeat: true,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.arrow_upward,
                      size: 48, color: AppTheme.accentGold),
            ),
          ),
          SizedBox(width: LayoutTokens.gr3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RANK UP!',
                style: TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Rank ${result.oldLevel} → ${result.newLevel}',
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
              ),
              if (wizardRankTitle(result.oldLevel) !=
                  wizardRankTitle(result.newLevel))
                Text(
                  '${wizardRankTitle(result.oldLevel)} → ${wizardRankTitle(result.newLevel)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── XP Card ──────────────────────────────────────────────────────────────────

class _XpCard extends StatelessWidget {
  final ProgressResult result;
  final bool isWinner;

  const _XpCard({required this.result, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(LayoutTokens.gr3, LayoutTokens.gr1, LayoutTokens.gr3, 0),
      padding: EdgeInsets.all(LayoutTokens.gr3),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: AppTheme.accentGold, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+${result.xpGained} XP',
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isWinner ? 'Win bonus included' : 'Participation XP',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rank ${result.newLevel}',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                wizardRankTitle(result.newLevel),
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Feedback Card ─────────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  final GameState game;
  final bool feedbackSubmitted;
  final Set<String> likePlayerIds;
  final Set<String> dislikePlayerIds;
  final String? mvpPlayerId;
  final String? teamPlayerId;
  final String? underdogPlayerId;
  final void Function(String) onLike;
  final void Function(String) onDislike;
  final void Function(String?) onMvpChanged;
  final void Function(String?) onTeamPlayerChanged;
  final void Function(String?) onUnderdogChanged;
  final VoidCallback onSubmit;

  const _FeedbackCard({
    required this.game,
    required this.feedbackSubmitted,
    required this.likePlayerIds,
    required this.dislikePlayerIds,
    required this.mvpPlayerId,
    required this.teamPlayerId,
    required this.underdogPlayerId,
    required this.onLike,
    required this.onDislike,
    required this.onMvpChanged,
    required this.onTeamPlayerChanged,
    required this.onUnderdogChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final others = game.players
        .where((p) => p.playerId != game.localPlayerId && !p.isEliminated)
        .toList();

    if (feedbackSubmitted) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: LayoutTokens.gr3),
        padding: EdgeInsets.all(LayoutTokens.gr3),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: AppTheme.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Thanks! Your feedback has been recorded.',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate Your Opponents',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: LayoutTokens.gr2),
          if (others.isNotEmpty) ...[
            ...others.map((p) => _PlayerFeedbackRow(
                  player: p,
                  isLiked: likePlayerIds.contains(p.playerId),
                  isDisliked: dislikePlayerIds.contains(p.playerId),
                  onLike: () => onLike(p.playerId),
                  onDislike: () => onDislike(p.playerId),
                )),
            SizedBox(height: LayoutTokens.gr2),
          ],
          // MVP vote
          _VoteDropdown(
            label: 'MVP',
            hint: 'Most Valuable Player',
            players: game.players.where((p) => !p.isEliminated).toList(),
            selectedId: mvpPlayerId,
            onChanged: onMvpChanged,
          ),
          SizedBox(height: LayoutTokens.gr1),
          // Team Player vote
          _VoteDropdown(
            label: 'Team Player',
            hint: 'Best teammate',
            players: game.players.where((p) => !p.isEliminated).toList(),
            selectedId: teamPlayerId,
            onChanged: onTeamPlayerChanged,
          ),
          SizedBox(height: LayoutTokens.gr1),
          _VoteDropdown(
            label: 'Underdog',
            hint: 'Best comeback or underdog performance',
            players: game.players.where((p) => !p.isEliminated).toList(),
            selectedId: underdogPlayerId,
            onChanged: onUnderdogChanged,
          ),
          SizedBox(height: LayoutTokens.gr3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Submit Feedback'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerFeedbackRow extends StatelessWidget {
  final PlayerGameState player;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _PlayerFeedbackRow({
    required this.player,
    required this.isLiked,
    required this.isDisliked,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: player.playerColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.username,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.thumb_up,
              size: 20,
              color: isLiked ? AppTheme.success : AppTheme.textSecondary,
            ),
            onPressed: onLike,
            style: IconButton.styleFrom(
              backgroundColor: isLiked
                  ? AppTheme.success.withValues(alpha: 0.2)
                  : Colors.transparent,
              minimumSize: const Size(36, 36),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.thumb_down,
              size: 20,
              color: isDisliked ? AppTheme.accent : AppTheme.textSecondary,
            ),
            onPressed: onDislike,
            style: IconButton.styleFrom(
              backgroundColor: isDisliked
                  ? AppTheme.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<PlayerGameState> players;
  final String? selectedId;
  final void Function(String?) onChanged;

  const _VoteDropdown({
    required this.label,
    required this.hint,
    required this.players,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: LayoutTokens.gr0),
        DropdownButtonFormField<String>(
          value: selectedId,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                '— None —',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            ...players.map((p) => DropdownMenuItem<String>(
                  value: p.playerId,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: p.playerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: LayoutTokens.gr1),
                      Text(
                        p.username,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Achievements Card ─────────────────────────────────────────────────────────

class _AchievementsCard extends StatelessWidget {
  final List<String> ids;

  const _AchievementsCard({required this.ids});

  @override
  Widget build(BuildContext context) {
    final defs = ids
        .map((id) => AchievementDefinitions.byId(id))
        .whereType<AchievementDef>()
        .toList();

    if (defs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(LayoutTokens.gr3, LayoutTokens.gr1, LayoutTokens.gr3, 0),
      padding: EdgeInsets.all(LayoutTokens.gr2),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏅 New Achievements',
            style: TextStyle(
              color: AppTheme.success,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: LayoutTokens.gr1),
          ...defs.map((def) => Padding(
                padding: EdgeInsets.only(bottom: LayoutTokens.gr0),
                child: Row(
                  children: [
                    Text(def.icon,
                        style: const TextStyle(fontSize: 18)),
                    SizedBox(width: LayoutTokens.gr1),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(def.title,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text(def.description,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Final Player Row ──────────────────────────────────────────────────────────

class _FinalPlayerRow extends StatelessWidget {
  final PlayerGameState p;
  final bool isWinner;
  final bool isLocal;

  const _FinalPlayerRow({
    required this.p,
    required this.isWinner,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: LayoutTokens.gr1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isWinner
            ? AppTheme.accentGold.withValues(alpha: 0.1)
            : AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWinner
              ? AppTheme.accentGold.withValues(alpha: 0.4)
              : AppTheme.surface,
        ),
      ),
      child: Row(
        children: [
          if (isWinner)
            Padding(
              padding: EdgeInsets.only(right: LayoutTokens.gr1),
              child: Text('🏆', style: TextStyle(fontSize: 14)),
            ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: p.playerColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    p.username,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight:
                          isLocal ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLocal)
                  const Text(' (you)',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          if (p.commanderName != null)
            Flexible(
              child: Text(
                p.commanderName!,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            p.isEliminated
                ? _reasonLabel(p.eliminationReason)
                : '${p.life} ❤',
            style: TextStyle(
              color: p.isEliminated ? AppTheme.accent : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _reasonLabel(String? r) {
    switch (r) {
      case 'life':
        return 'Life depleted';
      case 'poison':
        return '10 poison';
      case 'commanderDamage':
        return 'Commander dmg';
      case 'concede':
        return 'Conceded';
      default:
        return 'Eliminated';
    }
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool isHost;
  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onRematch;

  const _ActionButtons({
    required this.isHost,
    required this.onHome,
    required this.onProfile,
    required this.onRematch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (isHost)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Rematch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: onRematch,
              ),
            ),
          if (isHost) SizedBox(height: LayoutTokens.gr2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('View Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: onProfile,
            ),
          ),
          SizedBox(height: LayoutTokens.gr2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.surface),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: onHome,
            ),
          ),
        ],
      ),
    );
  }
}
