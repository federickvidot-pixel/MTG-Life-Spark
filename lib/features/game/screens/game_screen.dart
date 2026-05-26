import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/game/game_log_entry.dart';
import '../../../core/game/game_phase.dart';
import '../../../core/game/commander_identity_colors.dart';
import '../../../core/models/game_feedback.dart';
import '../../../core/persistence/providers.dart';
import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/game_state_notifier.dart';
import '../../../core/game/lobby_state.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_router.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/color_tokens.dart';
import '../../../ui/tokens/motion_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import '../../../shared/widgets/home_nav_bar.dart';
import '../../../core/game/alliance_ui_events.dart';
import '../widgets/alliance_overview_ui.dart';
import '../widgets/commander_damage_panel.dart';
import '../widgets/commander_info_bar.dart';
import '../widgets/variant_card_panel.dart';
import '../widgets/game_hud_header.dart';
import '../widgets/phase_nav_cluster.dart';
import '../widgets/game_modal_chrome.dart';
import '../widgets/political_row_widget.dart';
import '../widgets/game_performance_widgets.dart';
import '../widgets/stack_tracker_tab.dart';
import '../widgets/team_colors.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showOverview = false;
  StreamSubscription<Object?>? _gameOverSub;

  /// Cached so [dispose] never uses `ref` after Riverpod tears down this widget.
  bool _enteredWithHiddenSystemBars = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider).settings;
    _enteredWithHiddenSystemBars = settings.hideSystemBars;
    if (settings.keepDisplayAwake) {
      WakelockPlus.enable();
    }
    if (_enteredWithHiddenSystemBars) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForGameOver();
      final lobby = ref.read(lobbyProvider);
      ref.read(gameProvider.notifier).initFromLobby(lobby);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    if (_enteredWithHiddenSystemBars) {
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
    final localPresent = ref.watch(
      gameProvider.select((g) => g.localPlayer != null),
    );
    if (!localPresent) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final awaitingFirstPlayerRoll = ref.watch(
      gameProvider.select((g) => g.awaitingFirstPlayerRoll),
    );
    if (awaitingFirstPlayerRoll) {
      final game = ref.watch(gameProvider);
      final local = game.localPlayer!;
      return Scaffold(
        backgroundColor: AppTheme.primary,
        body: SafeArea(
          child: _FirstPlayerRollOverlay(
            game: game,
            local: local,
            onRoll:
                (roll) =>
                    ref.read(gameProvider.notifier).submitFirstPlayerRoll(roll),
          ),
        ),
      );
    }

    final gradientChrome = ref.watch(
      gameProvider.select((g) {
        final p = g.localPlayer!;
        return (p.commanderColorIdentity, p.playerColor);
      }),
    );
    final gradientColors = CommanderIdentityColors.gameplayGradient(
      gradientChrome.$1,
      gradientChrome.$2,
    );
    final localPlayerId = ref.read(gameProvider).localPlayerId;
    final timeoutActive = ref.watch(
      gameProvider.select((g) => g.timeoutActive),
    );
    final timeoutStartTime = ref.watch(
      gameProvider.select((g) => g.timeoutStartTime),
    );
    final timeoutDurationSeconds = ref.watch(
      gameProvider.select((g) => g.timeoutDurationSeconds),
    );
    ref.listen<AllianceUiEvent?>(allianceUiEventProvider, (prev, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          handleAllianceUiEvent(context, ref, next);
        });
      }
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (_showOverview)
              PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop) setState(() => _showOverview = false);
                },
                child: Consumer(
                  builder: (context, ref, _) => _OverviewView(
                    game: ref.watch(gameProvider),
                    onClose: () => setState(() => _showOverview = false),
                  ),
                ),
              )
            else
              SafeArea(
                child: _PersonalView(
                  localPlayerId: localPlayerId,
                  onToggleOverview: () => setState(() => _showOverview = true),
                ),
              ),
            if (timeoutActive)
              _TimeoutOverlay(
                startTime: timeoutStartTime,
                durationSeconds: timeoutDurationSeconds,
              ),
          ],
        ),
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
  State<_FirstPlayerRollOverlay> createState() =>
      _FirstPlayerRollOverlayState();
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
      duration: MotionTokens.slow,
    );
    _scaleAnim = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_animController);
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
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
                  borderRadius: RadiusTokens.radiusLg,
                  border: Border.all(
                    color: hasRolled ? AppTheme.accentGold : AppTheme.accent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: OpacityTokens.moderate),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child:
                      hasRolled
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
              borderRadius: RadiusTokens.radiusControlSm,
            ),
            child: Text(
              widget.game.isHost
                  ? '$othersRolled / $totalPlayers players have rolled'
                  : hasRolled
                  ? 'Waiting for others to roll…'
                  : 'Tap the dice above to roll',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4dp spacing: use [LayoutTokens] in this file (no φ-based scaling). ─────

// ── Personal View ──────────────────────────────────────────────────────────

class _PersonalView extends ConsumerStatefulWidget {
  final String localPlayerId;
  final VoidCallback onToggleOverview;

  const _PersonalView({
    required this.localPlayerId,
    required this.onToggleOverview,
  });

  @override
  ConsumerState<_PersonalView> createState() => _PersonalViewState();
}

class _PersonalViewState extends ConsumerState<_PersonalView> {
  /// 0 = Play, 1 = Stack, 2 = History
  int _mainTabIndex = 0;
  @override
  Widget build(BuildContext context) {
    ref.watch(gameProvider.select(gameHudHeaderRebuildFingerprint));
    if (_mainTabIndex == 0) {
      ref.watch(gameProvider.select(playTabRebuildFingerprint));
    } else if (_mainTabIndex == 1) {
      ref.watch(gameProvider.select(stackTabRebuildFingerprint));
    } else {
      ref.watch(gameProvider.select((g) => g.sessionActionLog));
    }

    final game = ref.read(gameProvider);
    final local = game.playerById(widget.localPlayerId);
    if (local == null) return const SizedBox.shrink();

    final notifier = ref.read(gameProvider.notifier);
    final opponents =
        game.players.where((p) => p.playerId != local.playerId).toList();

    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact =
        screenHeight < 704 || screenWidth < GameLayoutBreakpoints.compact;
    final tightVertical =
        screenHeight < GameLayoutBreakpoints.shortViewport;
    final horizontalInset = LayoutTokens.gr3;
    final rawMaxW = min(screenWidth - horizontalInset * 2, 400.0);
    final lifeBandMaxW = rawMaxW - (rawMaxW % 4);
    // 4dp grid: shrink height when vertical space is tight so Play fits without scroll.
    final lifeBandH = tightVertical
        ? (isCompact ? 136.0 : 160.0)
        : (isCompact ? 160.0 : 192.0);

    void adjustLife(int delta) {
      if (delta == 0) return;
      notifier.adjustLife(local.playerId, delta);
    }

    final opponentsWithCommanders = opponents
        .where((o) => !o.isEliminated || o.commanderName != null)
        .toList();
    final lobbyConfig = ref.read(lobbyProvider).config;
    final showCommanderDamage = isCommanderGameSession(
      local: local,
      allPlayers: game.players,
      gameFormat: lobbyConfig.format,
      startingLife: lobbyConfig.startingLife,
    );
    final maxCmdDamage = maxCommanderDamageTrack(
      local,
      opponentsWithCommanders,
    );

    final activeColor =
        game.playerById(game.activePlayerId)?.playerColor ?? AppTheme.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            LayoutTokens.gr3,
            horizontalInset,
            tightVertical ? LayoutTokens.gr1 : LayoutTokens.gr2,
          ),
          child: GameHudHeader(
            tightVertical: tightVertical,
            accentColor: activeColor,
            selectedTabIndex: _mainTabIndex,
            onTabSelected: (index) => setState(() => _mainTabIndex = index),
            commander: CommanderInfoBar(
              player: local,
              onCastCommander:
                  () => notifier.castCommanderFromZone(local.playerId),
              embeddedInCard: true,
              roundNumber: game.roundNumber,
              allyUsername: local.allyPlayerId == null
                  ? null
                  : game.playerById(local.allyPlayerId!)?.username,
              statusTrailing: showCommanderDamage
                  ? CommanderDamageBarButton(
                      totalDamage: local.totalCommanderDamageReceived,
                      maxTrackDamage: maxCmdDamage,
                      enabled: !local.isEliminated,
                      onTap: () => showCommanderDamageSheet(context, ref),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: switch (_mainTabIndex) {
            1 => StackTrackerTab(game: ref.read(gameProvider)),
            2 => _GameHistoryTab(
              entries: ref.watch(
                gameProvider.select((g) => g.sessionActionLog),
              ),
            ),
            _ => LayoutBuilder(
              builder: (context, playViewport) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: playViewport.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: lifeBandMaxW),
                            child: PhaseNavCluster(
                              game: game,
                              accentColor: activeColor,
                              onBack: game.isHost && !game.timeoutActive
                                  ? notifier.previousPhase
                                  : null,
                              onNext: game.isHost && !game.timeoutActive
                                  ? notifier.advancePhase
                                  : null,
                              onPickPhase: game.timeoutActive
                                  ? null
                                  : (game.isHost || game.isLocalPlayersTurn)
                                      ? notifier.setPhase
                                      : null,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: tightVertical
                              ? LayoutTokens.gr1
                              : LayoutTokens.gr2,
                        ),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: lifeBandMaxW,
                              minHeight: lifeBandH,
                            ),
                            child: ScopedLifeCounter(
                              playerId: local.playerId,
                              height: lifeBandH,
                              onLifeChange: adjustLife,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: tightVertical
                              ? LayoutTokens.gr2
                              : LayoutTokens.gr3,
                        ),
                        const VariantCardPanel(),
                        SizedBox(
                          height: tightVertical
                              ? LayoutTokens.gr1
                              : LayoutTokens.gr2,
                        ),
                        if (game.pendingProposalFor(local.playerId) != null)
                          SizedBox(height: LayoutTokens.gr0),
                        if ((game.trackTurnDuration ||
                                game.turnTimeLimitSeconds != null) &&
                            game.turnStartTime != null)
                          _TurnDurationBanner(
                            turnStartTime: game.turnStartTime!,
                            limitSeconds: game.turnTimeLimitSeconds,
                            isActiveTurn: game.isLocalPlayersTurn,
                            activePlayerName:
                                game.playerById(game.activePlayerId)
                                    ?.username ??
                                'Player',
                          ),
                        SizedBox(
                          height: tightVertical
                              ? LayoutTokens.gr2
                              : LayoutTokens.gr3,
                        ),
                        ScopedGameplayDials(
                          playerId: local.playerId,
                          onAdjustCounter: (field, delta) =>
                              notifier.adjustCounter(
                            local.playerId,
                            field,
                            delta,
                          ),
                          onSetCounterAbsolute: (field, v) =>
                              notifier.setGameplayDialAbsolute(
                            local.playerId,
                            field,
                            v,
                          ),
                          onRegisterCustomDial: (key, label) =>
                              notifier.registerCustomGameplayDial(
                            local.playerId,
                            key,
                            label,
                          ),
                          onAddDialToStrip: (field) =>
                              notifier.addGameplayDialToStrip(
                            local.playerId,
                            field,
                          ),
                          onRemoveDialFromStrip: (field) =>
                              notifier.removeGameplayDialFromStrip(
                            local.playerId,
                            field,
                          ),
                        ),
                        SizedBox(height: LayoutTokens.gr2),
                      ],
                    ),
                  ),
                );
              },
            ),
          },
        ),
        _BottomBar(
          game: game,
          local: local,
          onToggleOverview: widget.onToggleOverview,
          compact: tightVertical,
        ),
      ],
    );
  }
}

class _GameHistoryTab extends StatelessWidget {
  final List<GameLogEntry> entries;

  const _GameHistoryTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(LayoutTokens.gr4),
          child: Text(
            'No actions logged yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: OpacityTokens.nearOpaque),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final grouped = <int, List<GameLogEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.turnNumber, () => []).add(e);
    }
    final turns = grouped.keys.toList()..sort();

    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        LayoutTokens.gr3,
        LayoutTokens.gr2,
        LayoutTokens.gr3,
        LayoutTokens.gr4 + bottomSafe,
      ),
      itemCount: turns.length,
      itemBuilder: (context, ti) {
        final turn = turns[ti];
        final rows = grouped[turn]!;
        return Padding(
          padding: EdgeInsets.only(bottom: LayoutTokens.gr3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Turn $turn',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: FontTokens.title,
                ),
              ),
              SizedBox(height: LayoutTokens.gr1),
              ...rows.map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: LayoutTokens.gr1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(e.time),
                        style: TextStyle(
                          fontSize: FontTokens.hudXs,
                          color: AppTheme.textSecondary.withValues(alpha: 0.85),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(width: LayoutTokens.gr2),
                      Expanded(
                        child: Text(
                          e.message,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: FontTokens.hudSm,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }
}

// ── Bottom action bar ──────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final GameState game;
  final PlayerGameState local;
  final VoidCallback onToggleOverview;
  final bool compact;

  const _BottomBar({
    required this.game,
    required this.local,
    required this.onToggleOverview,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final compact = this.compact;
    final iconSize = compact ? 22.0 : 24.0;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          LayoutTokens.gr3,
          compact ? LayoutTokens.gr1 : LayoutTokens.gr2,
          LayoutTokens.gr3,
          LayoutTokens.gr3,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: LayoutTokens.gr2,
            vertical: compact ? LayoutTokens.gr2 : LayoutTokens.gr3,
          ),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: RadiusTokens.radiusMd,
            border: Border.all(color: AppTheme.surface),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: OpacityTokens.faint),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _BarButton(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    iconSize: iconSize,
                    enabled: true,
                    onTap: () => HomeNavBar.promptQuitAndGoHome(context),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _BarButton(
                    icon: Icons.undo,
                    label: 'Undo',
                    iconSize: iconSize,
                    enabled: !local.isEliminated,
                    onTap: () => notifier.undo(local.playerId),
                  ),
                ),
              ),
              if (game.isHost)
                Expanded(
                  child: Center(
                    child: _BarButton(
                      icon:
                          game.timeoutActive ? Icons.play_arrow : Icons.timer,
                      label: game.timeoutActive ? 'Resume' : 'Timeout',
                      iconSize: iconSize,
                      onTap: () {
                        if (game.timeoutActive) {
                          notifier.endTimeout();
                        } else {
                          _showTimeoutPicker(context, notifier);
                        }
                      },
                    ),
                  ),
                ),
              if (game.isHost)
                Expanded(
                  child: Center(
                    child: _BarButton(
                      icon: Icons.skip_next,
                      label: 'End Turn',
                      iconSize: iconSize,
                      enabled:
                          game.isLocalPlayersTurn && !game.timeoutActive,
                      onTap: () => notifier.endTurn(),
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: _BarButton(
                    icon: Icons.grid_view,
                    label: 'Overview',
                    iconSize: iconSize,
                    enabled: true,
                    onTap: onToggleOverview,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _BarButton(
                    icon: Icons.flag_outlined,
                    label: 'Forfeit',
                    iconSize: iconSize,
                    enabled: !local.isEliminated && !game.gameOver,
                    onTap:
                        () => _showConcedeDialog(context, ref, local.playerId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeoutPicker(BuildContext context, GameStateNotifier notifier) {
    showGameBottomSheet<void>(
      context: context,
      builder: (_) => _TimeoutPickerSheet(notifier: notifier),
    );
  }

  void _showConcedeDialog(
    BuildContext context,
    WidgetRef ref,
    String playerId,
  ) {
    final game = ref.read(gameProvider);
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => _ConcedeDialog(
            game: game,
            playerId: playerId,
            onConcede: () {
              ref.read(gameProvider.notifier).concede(playerId);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                final after = ref.read(gameProvider);
                final local = after.localPlayer;
                if (local != null &&
                    local.isEliminated &&
                    !after.gameOver) {
                  context.go(AppRoutes.endGame);
                }
              });
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
    final others =
        game.players
            .where((p) => p.playerId != game.localPlayerId && !p.isEliminated)
            .toList();
    final allPlayers = game.players.where((p) => !p.isEliminated).toList();

    return Consumer(
      builder:
          (context, ref, _) => AlertDialog(
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
                        GameModalChrome.horizontalInset(context),
                        LayoutTokens.gr3,
                        LayoutTokens.gr2,
                        0,
                      ),
                      child: GameDialogTitleRow(
                        title: 'Forfeit?',
                        onClose: () => Navigator.pop(context),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        GameModalChrome.horizontalInset(context),
                        LayoutTokens.gr2,
                        GameModalChrome.horizontalInset(context),
                        0,
                      ),
                      child: const Text(
                        'This will remove you from the game. Rate your opponents before leaving.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: FontTokens.hudSm,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (others.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: GameModalChrome.horizontalInset(context),
                        ),
                        child: const Text(
                          'Rate opponents',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: FontTokens.hudSm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...others.map(
                        (p) => _ConcedePlayerFeedbackRow(
                          player: p,
                          isLiked: _likePlayerIds.contains(p.playerId),
                          isDisliked: _dislikePlayerIds.contains(p.playerId),
                          onLike:
                              () => setState(() {
                                _dislikePlayerIds.remove(p.playerId);
                                _likePlayerIds.add(p.playerId);
                              }),
                          onDislike:
                              () => setState(() {
                                _likePlayerIds.remove(p.playerId);
                                _dislikePlayerIds.add(p.playerId);
                              }),
                        ),
                      ),
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
                        GameModalChrome.horizontalInset(context),
                        0,
                        GameModalChrome.horizontalInset(context),
                        LayoutTokens.gr4,
                      ),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.textSecondary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _submit(ref),
                        child: const Text('Forfeit'),
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
        horizontal: GameModalChrome.horizontalInset(context),
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
                fontSize: FontTokens.hudSm,
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
              backgroundColor:
                  isLiked
                      ? AppTheme.success.withValues(alpha: OpacityTokens.soft)
                      : Colors.transparent,
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
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
              backgroundColor:
                  isDisliked
                      ? AppTheme.accent.withValues(alpha: OpacityTokens.soft)
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
        horizontal: GameModalChrome.horizontalInset(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: FontTokens.hudXs,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButton<String?>(
            value: selectedId,
            isExpanded: true,
            hint: Text(
              hint,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: FontTokens.hudSm,
              ),
            ),
            dropdownColor: AppTheme.card,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: FontTokens.hudSm,
            ),
            underline: const SizedBox.shrink(),
            borderRadius: RadiusTokens.radiusPill,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text(
                  '— None —',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
              ...players.map(
                (p) => DropdownMenuItem<String>(
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
                            fontSize: FontTokens.hudSm,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
  final double iconSize;

  const _BarButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final c =
        enabled
            ? AppTheme.textSecondary
            : AppTheme.textSecondary.withValues(alpha: 0.4);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: RadiusTokens.radiusMd,
        child: Tooltip(
          message: label,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: label,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: LayoutTokens.gr6,
                minHeight: LayoutTokens.gr6,
              ),
              child: Padding(
                padding: const EdgeInsets.all(LayoutTokens.gr2),
                child: Center(
                  child: Icon(icon, size: iconSize, color: c),
                ),
              ),
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
    return GameSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GameSheetHeader(title: 'Start Timeout'),
          SizedBox(height: LayoutTokens.gr3),
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

  const _TimeoutOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.radiusControlSm),
      leading: Icon(icon, color: AppTheme.accentGold),
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      onTap: onTap,
    );
  }
}

// ── Banners ────────────────────────────────────────────────────────────────

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
      final remaining = (widget.durationSeconds! - _elapsed).clamp(0, 9999);
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
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _minimized = false),
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: LayoutTokens.gr3,
                  vertical: LayoutTokens.gr1,
                ),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _minimized = false),
                      borderRadius: RadiusTokens.radiusLg,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: LayoutTokens.gr3,
                          vertical: LayoutTokens.gr1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.95),
                          borderRadius: RadiusTokens.radiusLg,
                          border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 18,
                              color: AppTheme.accentGold,
                            ),
                            SizedBox(width: LayoutTokens.gr1),
                            Text(
                              widget.durationSeconds != null
                                  ? '$_timeStr left — tap to expand'
                                  : '$_timeStr elapsed — tap to expand',
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                borderRadius: RadiusTokens.radiusLg,
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: OpacityTokens.moderate),
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
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
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
                      Icon(Icons.timer, size: 56, color: AppTheme.accentGold),
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
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr2,
        vertical: LayoutTokens.gr1 + 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: OpacityTokens.subtle),
        borderRadius: RadiusTokens.radiusControlSm,
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: OpacityTokens.half)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: AppTheme.accentGold, size: 16),
          SizedBox(width: LayoutTokens.gr1),
          Expanded(
            child: Text(
              'Timeout — $_timeStr',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.accentGold,
                fontSize: FontTokens.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
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
  final String activePlayerName;

  const _TurnDurationBanner({
    required this.turnStartTime,
    this.limitSeconds,
    required this.isActiveTurn,
    required this.activePlayerName,
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
    final remaining =
        hasLimit ? (widget.limitSeconds! - elapsed).clamp(0, 9999) : null;

    final prefix = widget.isActiveTurn
        ? 'Your turn'
        : "${widget.activePlayerName}'s turn";
    String label;
    if (hasLimit && remaining != null) {
      final m = remaining ~/ 60;
      final s = remaining % 60;
      label = '$prefix: $m:${s.toString().padLeft(2, '0')} left';
    } else {
      final m = elapsed ~/ 60;
      final s = elapsed % 60;
      label = '$prefix: $m:${s.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: LayoutTokens.gr0),
      padding: EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr2,
        vertical: LayoutTokens.gr1,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: OpacityTokens.subtle),
        borderRadius: RadiusTokens.radiusControlSm,
        border: Border.all(color: AppTheme.accent.withValues(alpha: OpacityTokens.half)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            color:
                widget.isActiveTurn ? AppTheme.accent : AppTheme.textSecondary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color:
                  widget.isActiveTurn
                      ? AppTheme.accent
                      : AppTheme.textSecondary,
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
    final activePlayer = game.playerById(game.activePlayerId);
    final activeName = activePlayer?.username ?? '—';
    final phaseLabel = game.currentPhase.streamlinedShortLabel;
    final aliveCount = game.activePlayers.length;

    return ColoredBox(
      color: AppTheme.primary,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.primary,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 56,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Round ${game.roundNumber}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: FontTokens.body,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: LayoutTokens.gr0 - 1),
                  Text(
                    '$activeName · $phaseLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: FontTokens.hudXs,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
                onPressed: onClose,
                tooltip: 'Close overview',
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    LayoutTokens.minTapTarget,
                    LayoutTokens.minTapTarget,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(
                    right: LayoutTokens.gr1,
                    top: LayoutTokens.gr1,
                    bottom: LayoutTokens.gr1,
                  ),
                  child: TextButton(
                    onPressed:
                        game.isHost &&
                                game.isLocalPlayersTurn &&
                                !game.timeoutActive
                            ? () => notifier.endTurn()
                            : null,
                    style: TextButton.styleFrom(
                      backgroundColor:
                          AppTheme.accent.withValues(alpha: OpacityTokens.soft),
                      foregroundColor: AppTheme.accent,
                      padding: EdgeInsets.symmetric(
                        horizontal: LayoutTokens.gr2,
                        vertical: LayoutTokens.gr1,
                      ),
                      minimumSize: const Size(0, LayoutTokens.minTapTarget - 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: RadiusTokens.radiusControlSm,
                      ),
                    ),
                    child: const Text(
                      'End turn',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: FontTokens.caption,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  LayoutTokens.gr3,
                  LayoutTokens.gr1,
                  LayoutTokens.gr3,
                  LayoutTokens.gr2,
                ),
                child: PoliticalRowWidget(game: game),
              ),
            ),

            if (game.timeoutActive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    LayoutTokens.gr3,
                    0,
                    LayoutTokens.gr3,
                    LayoutTokens.gr2,
                  ),
                  child: _TimeoutBanner(
                    startTime: game.timeoutStartTime,
                    durationSeconds: game.timeoutDurationSeconds,
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  LayoutTokens.gr3,
                  0,
                  LayoutTokens.gr3,
                  LayoutTokens.gr1,
                ),
                child: Row(
                  children: [
                    Text(
                      'Players',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: FontTokens.caption,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(width: LayoutTokens.gr1),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: LayoutTokens.gr1,
                        vertical: LayoutTokens.gr0 - 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(
                          alpha: OpacityTokens.soft,
                        ),
                        borderRadius: RadiusTokens.radiusControlSm,
                      ),
                      child: Text(
                        '$aliveCount',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: FontTokens.hudXs,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                LayoutTokens.gr3,
                0,
                LayoutTokens.gr3,
                LayoutTokens.gr4,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ...game.players.map(
                    (p) => _OverviewPlayerCard(p: p, game: game),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewLifeBadge extends StatelessWidget {
  const _OverviewLifeBadge({
    required this.life,
    required this.eliminated,
    required this.isActive,
    required this.accent,
  });

  final int life;
  final bool eliminated;
  final bool isActive;
  final Color accent;

  Color get _textColor {
    if (eliminated) return AppTheme.textSecondary;
    if (life <= 5) return AppTheme.danger;
    if (life <= 10) return AppTheme.accentGold;
    return AppTheme.textPrimary;
  }

  Color get _borderColor {
    if (eliminated) {
      return AppTheme.textSecondary.withValues(alpha: OpacityTokens.soft);
    }
    if (isActive) return accent.withValues(alpha: OpacityTokens.moderate);
    return AppTheme.textSecondary.withValues(alpha: OpacityTokens.soft);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
      padding: EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr1 + 2,
        vertical: LayoutTokens.gr0 + 2,
      ),
      decoration: BoxDecoration(
        color: isActive && !eliminated
            ? accent.withValues(alpha: OpacityTokens.subtle)
            : AppTheme.surface.withValues(alpha: OpacityTokens.half),
        borderRadius: RadiusTokens.radiusControlSm,
        border: Border.all(color: _borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        eliminated ? 'OUT' : '$life',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w800,
          fontSize: FontTokens.body,
          height: 1,
        ),
      ),
    );
  }
}

class _OverviewStatusChip extends StatelessWidget {
  const _OverviewStatusChip({
    required this.label,
    required this.isActive,
    required this.accent,
  });

  final String label;
  final bool isActive;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr1,
        vertical: LayoutTokens.gr0 - 1,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? accent.withValues(alpha: OpacityTokens.soft)
            : AppTheme.surface.withValues(alpha: OpacityTokens.half),
        borderRadius: RadiusTokens.radiusControlSm,
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: OpacityTokens.half)
              : AppTheme.textSecondary.withValues(alpha: OpacityTokens.soft),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? accent : AppTheme.textSecondary,
          fontSize: FontTokens.hudXs,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
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
    final local = game.localPlayer;
    final notifier = ref.read(gameProvider.notifier);
    final pendingLabel = pendingAllianceLabel(game, p.playerId);
    final isMonarch = game.isMonarch(p.playerId);
    final hasInit = game.hasInitiative(p.playerId);

    final borderColor = teamIdx > 0 ? teamColor(teamIdx) : p.playerColor;
    var borderColorResolved =
        isActive ? borderColor : borderColor.withValues(alpha: 0.25);
    if (isMonarch || hasInit) {
      borderColorResolved = AppTheme.accentGold.withValues(
        alpha: isActive ? 0.95 : 0.55,
      );
    }

    final statusLabel =
        isActive ? game.currentPhase.shortName : 'Wait';
    final myAlliance =
        local != null ? game.allianceFor(local.playerId) : null;
    final hasAllianceMenu = game.alliancesEnabled &&
        ((!isLocal &&
                myAlliance == null &&
                game.allianceFor(p.playerId) == null) ||
            (myAlliance != null &&
                (isLocal || myAlliance.involves(p.playerId))));
    final showMenu =
        !p.isEliminated && local != null && (isLocal || hasAllianceMenu);

    Widget card = AnimatedContainer(
      duration: MotionTokens.slow,
      margin: EdgeInsets.only(bottom: LayoutTokens.gr2),
      decoration: BoxDecoration(
        color: p.isEliminated
            ? AppTheme.surface.withValues(alpha: OpacityTokens.half)
            : isActive
                ? borderColor.withValues(alpha: OpacityTokens.faint)
                : isLocal
                    ? AppTheme.card.withValues(alpha: OpacityTokens.nearOpaque)
                    : AppTheme.card,
        borderRadius: RadiusTokens.radiusSm,
        border: Border.all(
          color: borderColorResolved,
          width: isActive || isMonarch || hasInit ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: RadiusTokens.radiusSm,
        child: Stack(
          children: [
            if (isActive && !p.isEliminated)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: borderColor,
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isActive && !p.isEliminated
                    ? LayoutTokens.gr1
                    : LayoutTokens.gr2,
                LayoutTokens.gr2,
                LayoutTokens.gr2,
                LayoutTokens.gr2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: p.isEliminated
                            ? AppTheme.textSecondary.withValues(alpha: 0.4)
                            : p.playerColor,
                        child: Text(
                          p.username.isNotEmpty
                              ? p.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: ColorTokens.onAccent,
                            fontSize: FontTokens.sm,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isMonarch)
                        Positioned(
                          right: -2,
                          top: -4,
                          child: Text('👑', style: TextStyle(fontSize: 13)),
                        ),
                      if (hasInit)
                        Positioned(
                          right: -2,
                          bottom: -4,
                          child: Text('⚔️', style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  SizedBox(width: LayoutTokens.gr2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: p.username,
                                style: TextStyle(
                                  color: p.isEliminated
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: FontTokens.hudSm,
                                  height: 1.3,
                                ),
                              ),
                              if (isLocal)
                                TextSpan(
                                  text: ' · you',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: FontTokens.hudXs,
                                    height: 1.3,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: LayoutTokens.gr0 + 1),
                        Wrap(
                          spacing: LayoutTokens.gr0 + 2,
                          runSpacing: LayoutTokens.gr0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OverviewPlayerMarkerBadges(
                              game: game,
                              playerId: p.playerId,
                            ),
                            if (!p.isEliminated)
                              _OverviewStatusChip(
                                label: statusLabel,
                                isActive: isActive,
                                accent: borderColor,
                              ),
                          ],
                        ),
                        if (pendingLabel != null) ...[
                          SizedBox(height: LayoutTokens.gr0 + 1),
                          Text(
                            pendingLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: FontTokens.hudXs,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: LayoutTokens.gr1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OverviewLifeBadge(
                        life: p.life,
                        eliminated: p.isEliminated,
                        isActive: isActive,
                        accent: borderColor,
                      ),
                      if (showMenu)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: LayoutTokens.minTapTarget,
                            minHeight: LayoutTokens.minTapTarget,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'propose':
                                showProposeAllianceSheet(
                                  context: context,
                                  ref: ref,
                                  target: p,
                                );
                              case 'reveal':
                                notifier.revealAlliance(local.playerId);
                              case 'break':
                                notifier.breakAlliance(local.playerId);
                              case 'team':
                                _showTeamSelectorSheet(
                                  context,
                                  ref,
                                  p.playerId,
                                  teamIdx,
                                );
                            }
                          },
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry<String>>[];
                            if (isLocal) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'team',
                                  child: Text('Assign team color'),
                                ),
                              );
                            }
                            if (game.alliancesEnabled &&
                                !isLocal &&
                                game.allianceFor(local.playerId) == null &&
                                game.allianceFor(p.playerId) == null) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'propose',
                                  child: Text('Propose secret alliance'),
                                ),
                              );
                            }
                            final menuAlliance =
                                game.allianceFor(local.playerId);
                            if (game.alliancesEnabled &&
                                menuAlliance != null &&
                                (isLocal ||
                                    menuAlliance.involves(p.playerId)) &&
                                !menuAlliance.isRevealed) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'reveal',
                                  child: Text('Reveal alliance to table'),
                                ),
                              );
                            }
                            if (game.alliancesEnabled &&
                                menuAlliance != null &&
                                (isLocal ||
                                    menuAlliance.involves(p.playerId))) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'break',
                                  child: Text('Break secret alliance'),
                                ),
                              );
                            }
                            return items;
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return card;
  }

  static void _showTeamSelectorSheet(
    BuildContext context,
    WidgetRef ref,
    String playerId,
    int currentTeam,
  ) {
    final notifier = ref.read(gameProvider.notifier);
    showGameBottomSheet<void>(
      context: context,
      builder: (ctx) => GameSheetBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GameSheetHeader(title: 'Assign team'),
            SizedBox(height: LayoutTokens.gr2),
            ...[0, 1, 2, 3, 4].map((idx) {
              final label = idx == 0 ? 'None' : 'Team $idx';
              final color =
                  idx == 0 ? AppTheme.textSecondary : teamColor(idx);
              final isSelected = currentTeam == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: isSelected
                      ? (idx == 0
                          ? AppTheme.textSecondary.withValues(alpha: 0.15)
                          : color.withValues(alpha: 0.15))
                      : Colors.transparent,
                  borderRadius: RadiusTokens.radiusControlSm,
                  child: InkWell(
                    onTap: () {
                      notifier.assignTeam(playerId, idx);
                      Navigator.of(ctx).pop();
                    },
                    borderRadius: RadiusTokens.radiusControlSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
    );
  }
}
