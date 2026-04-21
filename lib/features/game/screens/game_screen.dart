import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/game/game_phase.dart';
import '../../../core/models/game_feedback.dart';
import '../../../core/persistence/providers.dart';
import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/game_state_notifier.dart';
import '../../../core/game/lobby_state.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_router.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../shared/widgets/home_nav_bar.dart';
import '../widgets/commander_damage_panel.dart';
import '../widgets/commander_info_bar.dart';
import '../widgets/variant_card_panel.dart';
import '../widgets/counter_row_widget.dart';
import '../widgets/life_counter_widget.dart';
import '../widgets/phase_bar_widget.dart';
import '../widgets/political_row_widget.dart';
import '../widgets/turn_order_widget.dart';
import '../widgets/team_panel_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showOverview = false;
  StreamSubscription<Object?>? _gameOverSub;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider).settings;
    if (settings.keepDisplayAwake) {
      WakelockPlus.enable();
    }
    if (settings.hideSystemBars) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lobby = ref.read(lobbyProvider);
      ref.read(gameProvider.notifier).initFromLobby(lobby);
      _listenForGameOver();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    final settings = ref.read(settingsRepositoryProvider).settings;
    if (settings.hideSystemBars) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _gameOverSub?.cancel();
    super.dispose();
  }

  void _listenForGameOver() {
    _gameOverSub = ref.read(gameProvider.notifier).stream.listen((state) {
      if (state.gameOver && mounted) {
        context.go(AppRoutes.endGame);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final local = game.localPlayer;

    if (local == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (game.awaitingFirstPlayerRoll) {
      return Scaffold(
        backgroundColor: AppTheme.primary,
        body: SafeArea(
          child: _FirstPlayerRollOverlay(
            game: game,
            local: local,
            onRoll: (roll) =>
                ref.read(gameProvider.notifier).submitFirstPlayerRoll(roll),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: local.isEliminated
          ? AppTheme.primary.withValues(alpha: 0.7)
          : AppTheme.primary,
      body: Stack(
        children: [
          if (_showOverview)
            _OverviewView(
              game: game,
              onClose: () => setState(() => _showOverview = false),
            )
          else
            SafeArea(
              child: _PersonalView(
                game: game,
                local: local,
                onToggleOverview: () =>
                    setState(() => _showOverview = true),
              ),
            ),
          if (game.timeoutActive)
            _TimeoutOverlay(
              startTime: game.timeoutStartTime,
              durationSeconds: game.timeoutDurationSeconds,
            ),
        ],
      ),
    );
  }
}

// ── First player roll overlay ───────────────────────────────────────────────

class _FirstPlayerRollOverlay extends StatefulWidget {
  final GameState game;
  final PlayerGameState local;
  final void Function(int roll) onRoll;

  const _FirstPlayerRollOverlay({
    required this.game,
    required this.local,
    required this.onRoll,
  });

  @override
  State<_FirstPlayerRollOverlay> createState() => _FirstPlayerRollOverlayState();
}

class _FirstPlayerRollOverlayState extends State<_FirstPlayerRollOverlay>
    with SingleTickerProviderStateMixin {
  final _rand = Random();
  int? _myRoll;
  bool _rolling = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.2)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _doRoll() {
    if (_myRoll != null || _rolling) return;
    setState(() => _rolling = true);
    final roll = _rand.nextInt(6) + 1;
    widget.onRoll(roll);
    _animController.forward(from: 0);
    setState(() {
      _myRoll = roll;
      _rolling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasRolled = _myRoll != null;
    final othersRolled = widget.game.firstPlayerRolls.length;
    final totalPlayers = widget.game.players.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.casino, size: 48, color: AppTheme.accentGold),
          const SizedBox(height: 16),
          Text(
            'Roll for First Player!',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Highest roll goes first. Tap the dice to roll!',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: hasRolled ? null : _doRoll,
            child: AnimatedBuilder(
              animation: _scaleAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _rolling ? _scaleAnim.value : 1,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasRolled
                        ? AppTheme.accentGold
                        : AppTheme.accent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: hasRolled
                      ? Text(
                          '$_myRoll',
                          style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Icon(
                          Icons.casino_outlined,
                          size: 64,
                          color: AppTheme.accent,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (hasRolled)
            Text(
              'You rolled $_myRoll!',
              style: const TextStyle(
                color: AppTheme.success,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'Tap to roll',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.game.isHost
                  ? '$othersRolled / $totalPlayers players have rolled'
                  : hasRolled
                      ? 'Waiting for others to roll…'
                      : 'Tap the dice above to roll',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Golden ratio spacing (base 4, φ ≈ 1.618) ──────────────────────────────
const _gBase = 4.0;
double _g(num n) => (n * LayoutTokens.goldenRatio).roundToDouble();

// ── Personal View ──────────────────────────────────────────────────────────

class _PersonalView extends ConsumerWidget {
  final GameState game;
  final PlayerGameState local;
  final VoidCallback onToggleOverview;

  const _PersonalView({
    required this.game,
    required this.local,
    required this.onToggleOverview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final opponents = game.players
        .where((p) => p.playerId != local.playerId)
        .toList();

    final activeColor =
        game.playerById(game.activePlayerId)?.playerColor ?? AppTheme.accent;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenHeight < 700 || screenWidth < 360;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical -
              MediaQuery.viewInsetsOf(context).vertical,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
        // ── Commander bar + Cast button (top right) ────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: CommanderInfoBar(
                player: local,
                onCastCommander: () =>
                    notifier.castCommanderFromZone(local.playerId),
                includeCastButton: false,
                roundNumber: game.roundNumber,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: _g(10)),
              child: CastCommanderButton(
                player: local,
                onCastCommander: () =>
                    notifier.castCommanderFromZone(local.playerId),
              ),
            ),
          ],
        ),

        // ── Turn order ────────────────────────────────────────────────────
        TurnOrderWidget(game: game),
        SizedBox(height: _g(_gBase)),

        // ── Phase bar (always visible; tap to set phase when your turn) ──
        PhaseBarWidget(
          currentPhase: game.currentPhase,
          activeColor: activeColor,
          isHost: game.isHost,
          onAdvancePhase: game.isHost ? () => notifier.advancePhase() : null,
          canSetPhase: game.isLocalPlayersTurn,
          onPhaseTap: game.isLocalPlayersTurn
              ? (phase) => notifier.setPhase(phase)
              : null,
        ),
        SizedBox(height: _g(_gBase + 2)),

        // ── Variant decks (Planechase, Archenemy, Bounty) ─────────────────
        const VariantCardPanel(),
        SizedBox(height: _g(_gBase + 2)),

        // ── Life counter (center, takes most space) ────────────────────
        SizedBox(
          height: isCompact ? 140 : 180,
          child: LifeCounterWidget(
            life: local.life,
            playerColor: local.playerColor,
            isEliminated: local.isEliminated,
            onLifeChange: (delta) =>
                notifier.adjustLife(local.playerId, delta),
          ),
        ),
        SizedBox(height: _g(_gBase + 2)),

        // ── Counter row ────────────────────────────────────────────────
        CounterRowWidget(
          poison: local.poison,
          energy: local.energy,
          experience: local.experience,
          rad: local.rad,
          isEliminated: local.isEliminated,
          onCounterChange: (field, delta) =>
              notifier.adjustCounter(local.playerId, field, delta),
          onProliferate: () => notifier.proliferate(local.playerId),
        ),
        SizedBox(height: _g(_gBase + 2)),

        // ── Commander damage panel ─────────────────────────────────────
        CommanderDamagePanel(
          localPlayer: local,
          opponents: opponents,
          onDamageChange: ({
            required String fromPlayerId,
            required int partnerIndex,
            required int delta,
          }) =>
              notifier.applyCommanderDamage(
                fromPlayerId: fromPlayerId,
                partnerIndex: partnerIndex,
                toPlayerId: local.playerId,
                delta: delta,
              ),
        ),

        // ── Alliance indicator ─────────────────────────────────────────
        if (game.pendingProposalFor(local.playerId) != null)
          _AllianceProposalBanner(game: game, local: local),
        if (game.pendingProposalFor(local.playerId) != null)
          SizedBox(height: _g(_gBase)),

        // ── Game state banners ─────────────────────────────────────────
        if (game.monarchPlayerId == local.playerId)
          _GameMarkerBanner(icon: '👑', label: 'You have the Monarch'),
        if (game.initiativePlayerId == local.playerId)
          _GameMarkerBanner(icon: '⚔️', label: 'You have the Initiative'),
        if ((game.trackTurnDuration || game.turnTimeLimitSeconds != null) &&
            game.turnStartTime != null)
          _TurnDurationBanner(
            turnStartTime: game.turnStartTime!,
            limitSeconds: game.turnTimeLimitSeconds,
            isActiveTurn: game.isLocalPlayersTurn,
          ),

        SizedBox(height: _g(_gBase * 2)),

        // ── Bottom action bar ──────────────────────────────────────────
        _BottomBar(
          game: game,
          local: local,
          onToggleOverview: onToggleOverview,
        ),

        SizedBox(height: _g(_gBase + 2)),
          ],
        ),
      ),
    );
  }
}

// ── Bottom action bar ──────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final GameState game;
  final PlayerGameState local;
  final VoidCallback onToggleOverview;

  const _BottomBar({
    required this.game,
    required this.local,
    required this.onToggleOverview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final hasUndo = local.undoStack.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: _g(10), vertical: _g(_gBase + 2)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _g(_gBase + 2), vertical: _g(_gBase + 2)),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(_g(10)),
          border: Border.all(color: AppTheme.surface),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
          // Home (quit with confirmation)
          _BarButton(
            icon: Icons.home_rounded,
            label: 'Home',
            enabled: true,
            onTap: () => HomeNavBar.promptQuitAndGoHome(context),
          ),

          // Undo
          _BarButton(
            icon: Icons.undo,
            label: 'Undo',
            enabled: hasUndo && !local.isEliminated,
            onTap: () => notifier.undo(local.playerId),
          ),

          // Timeout (host only)
          if (game.isHost)
            _BarButton(
              icon: game.timeoutActive ? Icons.play_arrow : Icons.timer,
              label: game.timeoutActive ? 'Resume' : 'Timeout',
              onTap: () {
                if (game.timeoutActive) {
                  notifier.endTimeout();
                } else {
                  _showTimeoutPicker(context, notifier);
                }
              },
            ),

          // End Turn (host controls phase; any player can see it)
          _BarButton(
            icon: Icons.skip_next,
            label: 'End Turn',
            enabled: game.isHost && game.isLocalPlayersTurn && !game.timeoutActive,
            onTap: () => notifier.endTurn(),
          ),

          // Overview (always selectable, including single player)
          _BarButton(
            icon: Icons.grid_view,
            label: 'Overview',
            enabled: true,
            onTap: onToggleOverview,
          ),

          // Concede
          _BarButton(
            icon: Icons.flag_outlined,
            label: 'Concede',
            enabled: !local.isEliminated,
            onTap: () => _showConcedeDialog(context, ref, local.playerId),
          ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeoutPicker(BuildContext context, GameStateNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TimeoutPickerSheet(notifier: notifier),
    );
  }

  void _showConcedeDialog(
      BuildContext context, WidgetRef ref, String playerId) {
    final game = ref.read(gameProvider);
    showDialog<void>(
      context: context,
      builder: (_) => _ConcedeDialog(
        game: game,
        playerId: playerId,
        onConcede: () {
          ref.read(gameProvider.notifier).concede(playerId);
        },
      ),
    );
  }
}

// ── Concede Dialog (with feedback) ───────────────────────────────────────────

class _ConcedeDialog extends StatefulWidget {
  final GameState game;
  final String playerId;
  final VoidCallback onConcede;

  const _ConcedeDialog({
    required this.game,
    required this.playerId,
    required this.onConcede,
  });

  @override
  State<_ConcedeDialog> createState() => _ConcedeDialogState();
}

class _ConcedeDialogState extends State<_ConcedeDialog> {
  final Set<String> _likePlayerIds = {};
  final Set<String> _dislikePlayerIds = {};
  String? _mvpPlayerId;
  String? _teamPlayerId;
  String? _underdogPlayerId;

  void _submit(WidgetRef ref) {
    ref.read(pendingFeedbackProvider.notifier).state = PendingFeedbackData(
      likePlayerIds: _likePlayerIds.toList(),
      dislikePlayerIds: _dislikePlayerIds.toList(),
      mvpPlayerId: _mvpPlayerId,
      teamPlayerId: _teamPlayerId,
      underdogPlayerId: _underdogPlayerId,
    );
    Navigator.pop(context);
    widget.onConcede();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final others = game.players
        .where((p) => p.playerId != game.localPlayerId && !p.isEliminated)
        .toList();
    final allPlayers = game.players.where((p) => !p.isEliminated).toList();

    return Consumer(
      builder: (context, ref, _) => AlertDialog(
        backgroundColor: AppTheme.card,
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.95,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title + X
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
                    20, 8, 0,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Concede?',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.textSecondary,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
                    8,
                    MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
                    0,
                  ),
                  child: const Text(
                    'This will remove you from the game. Rate your opponents before leaving.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                if (others.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
                    ),
                    child: const Text('Rate opponents',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  ...others.map((p) => _ConcedePlayerFeedbackRow(
                        player: p,
                        isLiked: _likePlayerIds.contains(p.playerId),
                        isDisliked: _dislikePlayerIds.contains(p.playerId),
                        onLike: () => setState(() {
                          _dislikePlayerIds.remove(p.playerId);
                          _likePlayerIds.add(p.playerId);
                        }),
                        onDislike: () => setState(() {
                          _likePlayerIds.remove(p.playerId);
                          _dislikePlayerIds.add(p.playerId);
                        }),
                      )),
                  const SizedBox(height: 12),
                ],
                // MVP
                _ConcedeVoteDropdown(
                  label: 'MVP',
                  hint: 'Most Valuable Player',
                  players: allPlayers,
                  selectedId: _mvpPlayerId,
                  onChanged: (id) => setState(() => _mvpPlayerId = id),
                ),
                const SizedBox(height: 8),
                // Team Player
                _ConcedeVoteDropdown(
                  label: 'Team Player',
                  hint: 'Best teammate',
                  players: allPlayers,
                  selectedId: _teamPlayerId,
                  onChanged: (id) => setState(() => _teamPlayerId = id),
                ),
                const SizedBox(height: 8),
                _ConcedeVoteDropdown(
                  label: 'Underdog',
                  hint: 'Best comeback or underdog performance',
                  players: allPlayers,
                  selectedId: _underdogPlayerId,
                  onChanged: (id) => setState(() => _underdogPlayerId = id),
                ),
                const SizedBox(height: 20),
                // Concede button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
                    0,
                    MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
                    24,
                  ),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _submit(ref),
                    child: const Text('Concede'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcedePlayerFeedbackRow extends StatelessWidget {
  final PlayerGameState player;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _ConcedePlayerFeedbackRow({
    required this.player,
    required this.isLiked,
    required this.isDisliked,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
        vertical: 2,
      ),
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
            icon: Icon(Icons.thumb_up, size: 20,
                color: isLiked ? AppTheme.success : AppTheme.textSecondary),
            onPressed: onLike,
            style: IconButton.styleFrom(
              backgroundColor: isLiked
                  ? AppTheme.success.withValues(alpha: 0.2)
                  : Colors.transparent,
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
          ),
          IconButton(
            icon: Icon(Icons.thumb_down, size: 20,
                color: isDisliked ? AppTheme.accent : AppTheme.textSecondary),
            onPressed: onDislike,
            style: IconButton.styleFrom(
              backgroundColor: isDisliked
                  ? AppTheme.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcedeVoteDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<PlayerGameState> players;
  final String? selectedId;
  final void Function(String?) onChanged;

  const _ConcedeVoteDropdown({
    required this.label,
    required this.hint,
    required this.players,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
      ),
      child: Column(
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
          const SizedBox(height: 4),
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
              const DropdownMenuItem<String>(
                value: null,
                child: Text('— None —',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13)),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.username,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _BarButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isVeryNarrow = w < 340;
    final iconOnly = w < 300;
    final iconSize = isVeryNarrow ? 20.0 : 24.0;
    final fontSize = isVeryNarrow ? 9.0 : 11.0;
    final hPad = iconOnly ? 4.0 : (isVeryNarrow ? 6.0 : 10.0);
    final vPad = isVeryNarrow ? 6.0 : 8.0;

    final c = enabled ? AppTheme.textSecondary : AppTheme.textSecondary.withValues(alpha: 0.4);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(_g(_gBase)),
        child: Tooltip(
          message: label,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: c),
                if (!iconOnly) ...[
                  SizedBox(height: isVeryNarrow ? 2 : 4),
                  Text(label, style: TextStyle(color: c, fontSize: fontSize, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Timeout bottom sheet ───────────────────────────────────────────────────

class _TimeoutPickerSheet extends StatelessWidget {
  final GameStateNotifier notifier;
  const _TimeoutPickerSheet({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Start Timeout',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _TimeoutOption(
            label: '2 minutes',
            icon: Icons.timer,
            onTap: () {
              Navigator.pop(context);
              notifier.startTimeout(durationSeconds: 120);
            },
          ),
          const SizedBox(height: 8),
          _TimeoutOption(
            label: '5 minutes',
            icon: Icons.timer,
            onTap: () {
              Navigator.pop(context);
              notifier.startTimeout(durationSeconds: 300);
            },
          ),
          const SizedBox(height: 8),
          _TimeoutOption(
            label: 'No timer (manual)',
            icon: Icons.timer_off,
            onTap: () {
              Navigator.pop(context);
              notifier.startTimeout();
            },
          ),
        ],
      ),
    );
  }
}

class _TimeoutOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeoutOption(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: AppTheme.accentGold),
      title:
          Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      onTap: onTap,
    );
  }
}

// ── Banners ────────────────────────────────────────────────────────────────

class _AllianceProposalBanner extends ConsumerWidget {
  final GameState game;
  final PlayerGameState local;

  const _AllianceProposalBanner({required this.game, required this.local});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposal = game.pendingProposalFor(local.playerId);
    if (proposal == null) return const SizedBox.shrink();

    final from = game.playerById(proposal.fromId);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake, color: AppTheme.accentGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${from?.username ?? proposal.fromId} proposes an alliance!',
                  style: const TextStyle(
                      color: AppTheme.accentGold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 280;
              return Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 12 : 16,
                      ),
                    ),
                    onPressed: () =>
                        ref.read(gameProvider.notifier).respondToAlliance(local.playerId, true),
                    child: const Text('Accept',
                        style: TextStyle(color: AppTheme.success, fontSize: 13)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 12 : 16,
                      ),
                    ),
                    onPressed: () =>
                        ref.read(gameProvider.notifier).respondToAlliance(local.playerId, false),
                    child: const Text('Decline',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GameMarkerBanner extends StatelessWidget {
  final String icon;
  final String label;

  const _GameMarkerBanner({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.accentGold, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Full-screen overlay when timeout is active. Blocks all interaction so
/// players cannot change life or counters. X button minimizes to small timer.
class _TimeoutOverlay extends StatefulWidget {
  final DateTime? startTime;
  final int? durationSeconds;

  const _TimeoutOverlay({this.startTime, this.durationSeconds});

  @override
  State<_TimeoutOverlay> createState() => _TimeoutOverlayState();
}

class _TimeoutOverlayState extends State<_TimeoutOverlay> {
  Timer? _ticker;
  int _elapsed = 0;
  bool _minimized = false;

  @override
  void initState() {
    super.initState();
    if (widget.startTime != null) {
      _elapsed = DateTime.now().difference(widget.startTime!).inSeconds;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed++);
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _timeStr {
    if (widget.durationSeconds != null) {
      final remaining =
          (widget.durationSeconds! - _elapsed).clamp(0, 9999);
      final m = remaining ~/ 60;
      final s = remaining % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_minimized) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 18, color: AppTheme.accentGold),
                    const SizedBox(width: 8),
                    Text(
                      widget.durationSeconds != null
                          ? '$_timeStr left'
                          : _timeStr,
                      style: const TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // Absorb all touches
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => setState(() => _minimized = true),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 56,
                        color: AppTheme.accentGold,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'TIMEOUT',
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.durationSeconds != null
                            ? '$_timeStr remaining'
                            : '$_timeStr elapsed',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Game paused — no life changes',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeoutBanner extends StatefulWidget {
  final DateTime? startTime;
  final int? durationSeconds;

  const _TimeoutBanner({this.startTime, this.durationSeconds});

  @override
  State<_TimeoutBanner> createState() => _TimeoutBannerState();
}

class _TimeoutBannerState extends State<_TimeoutBanner> {
  Timer? _ticker;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    if (widget.startTime != null) {
      _elapsed = DateTime.now().difference(widget.startTime!).inSeconds;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed++);
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _timeStr {
    if (widget.durationSeconds != null) {
      final remaining = (widget.durationSeconds! - _elapsed).clamp(0, 9999);
      final m = remaining ~/ 60;
      final s = remaining % 60;
      return '$m:${s.toString().padLeft(2, '0')} remaining';
    }
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '$m:${s.toString().padLeft(2, '0')} elapsed';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: AppTheme.accentGold, size: 14),
          const SizedBox(width: 6),
          Text(
            'TIMEOUT — $_timeStr',
            style: const TextStyle(
                color: AppTheme.accentGold,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TurnDurationBanner extends StatefulWidget {
  final DateTime turnStartTime;
  final int? limitSeconds;
  final bool isActiveTurn;

  const _TurnDurationBanner({
    required this.turnStartTime,
    this.limitSeconds,
    required this.isActiveTurn,
  });

  @override
  State<_TurnDurationBanner> createState() => _TurnDurationBannerState();
}

class _TurnDurationBannerState extends State<_TurnDurationBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.turnStartTime).inSeconds;
    final hasLimit = widget.limitSeconds != null;
    final remaining = hasLimit
        ? (widget.limitSeconds! - elapsed).clamp(0, 9999)
        : null;

    String label;
    if (hasLimit && remaining != null) {
      final m = remaining ~/ 60;
      final s = remaining % 60;
      label = 'Turn: $m:${s.toString().padLeft(2, '0')} left';
    } else {
      final m = elapsed ~/ 60;
      final s = elapsed % 60;
      label = 'Turn: $m:${s.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            color: widget.isActiveTurn ? AppTheme.accent : AppTheme.textSecondary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: widget.isActiveTurn ? AppTheme.accent : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overview View ─────────────────────────────────────────────────────────

class _OverviewView extends ConsumerWidget {
  final GameState game;
  final VoidCallback onClose;

  const _OverviewView({required this.game, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);

    return SizedBox.expand(
      child: CustomScrollView(
        slivers: [
          // Header: [X] ROUND 1 [End]
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primary,
            toolbarHeight: 48,
            title: Text(
              'ROUND ${game.roundNumber}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 22),
              onPressed: onClose,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                child: TextButton(
                  onPressed: game.isHost &&
                          game.isLocalPlayersTurn &&
                          !game.timeoutActive
                      ? () => notifier.endTurn()
                      : null,
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('End', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          // Monarch / Day-Night row (compact, white borders)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: PoliticalRowWidget(game: game, overviewStyle: true),
            ),
          ),

          // Timeout banner
          if (game.timeoutActive)
            SliverToBoxAdapter(
              child: _TimeoutBanner(
                startTime: game.timeoutStartTime,
                durationSeconds: game.timeoutDurationSeconds,
              ),
            ),

          // Player cards list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...game.players.map((p) => _OverviewPlayerCard(
                      p: p,
                      game: game,
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPlayerCard extends ConsumerWidget {
  final PlayerGameState p;
  final GameState game;

  const _OverviewPlayerCard({required this.p, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = p.playerId == game.activePlayerId;
    final isLocal = p.playerId == game.localPlayerId;
    final teamIdx = game.teamAssignments[p.playerId] ?? 0;

    final borderColor = teamIdx > 0
        ? teamColor(teamIdx)
        : p.playerColor;
    final borderColorResolved =
        isActive ? borderColor : borderColor.withValues(alpha: 0.25);

    final actionLabel = isActive
        ? game.currentPhase.displayName
        : 'Waiting';

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: p.isEliminated
            ? AppTheme.surface.withValues(alpha: 0.5)
            : isLocal
                ? AppTheme.card.withValues(alpha: 0.9)
                : AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColorResolved,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: p.isEliminated
                  ? AppTheme.textSecondary.withValues(alpha: 0.4)
                  : p.playerColor,
              child: Text(
                p.username.isNotEmpty
                    ? p.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Player name
            Expanded(
              child: Text(
                p.username + (isLocal ? ' (you)' : ''),
                style: TextStyle(
                  color: p.isEliminated
                      ? AppTheme.textSecondary
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Action chip (Untap / phase name / Waiting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? borderColor.withValues(alpha: 0.2)
                    : AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? borderColor.withValues(alpha: 0.5)
                      : AppTheme.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                p.isEliminated ? 'OUT' : actionLabel,
                style: TextStyle(
                  color: p.isEliminated
                      ? AppTheme.textSecondary
                      : isActive
                          ? borderColor
                          : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Life total box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                p.isEliminated ? 'OUT' : '${p.life}',
                style: TextStyle(
                  color: p.isEliminated
                      ? AppTheme.textSecondary
                      : p.life <= 10
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isLocal) {
      return GestureDetector(
        onTap: () => _OverviewPlayerCard._showTeamSelectorSheet(
            context, ref, p.playerId, teamIdx),
        child: card,
      );
    }
    return card;
  }

  static void _showTeamSelectorSheet(
      BuildContext context, WidgetRef ref, String playerId, int currentTeam) {
    final notifier = ref.read(gameProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Assign team',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...[0, 1, 2, 3, 4].map((idx) {
                final label =
                    idx == 0 ? 'None' : 'Team $idx';
                final color = idx == 0 ? AppTheme.textSecondary : teamColor(idx);
                final isSelected = currentTeam == idx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: isSelected
                        ? (idx == 0
                            ? AppTheme.textSecondary.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.15))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        notifier.assignTeam(playerId, idx);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            if (idx > 0)
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(width: 12),
                            if (idx > 0) const SizedBox(width: 10),
                            Text(
                              label,
                              style: TextStyle(
                                color: idx == 0
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
