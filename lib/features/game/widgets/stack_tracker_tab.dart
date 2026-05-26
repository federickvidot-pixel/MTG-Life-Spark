import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/game_providers.dart';
import '../../../core/game/game_state.dart';
import '../../../core/game/game_state_notifier.dart';
import '../../../core/game/stack_display.dart';
import '../../../core/game/scryfall_service.dart';
import '../../../core/game/stack_item.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/motion_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import 'game_modal_chrome.dart';
import 'stack_card_picker_dialog.dart';
import 'stack_help_sheet.dart';

/// Stack tracker: beginner-friendly LIFO list with optional by-player view.
class StackTrackerTab extends ConsumerStatefulWidget {
  final GameState game;

  const StackTrackerTab({super.key, required this.game});

  @override
  ConsumerState<StackTrackerTab> createState() => _StackTrackerTabState();
}

class _StackTrackerTabState extends ConsumerState<StackTrackerTab> {
  StackSortMode _sortMode = StackSortMode.stackOrder;
  bool _showCountered = false;
  bool _tipBannerVisible = true;
  final Set<String> _enteredStackIds = {};

  @override
  void initState() {
    super.initState();
    _markStackItemsSeen(widget.game.stackItems);
  }

  @override
  void didUpdateWidget(StackTrackerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldItems = oldWidget.game.stackItems;
    final newItems = widget.game.stackItems;
    if (newItems.isEmpty) {
      _enteredStackIds.clear();
      return;
    }
    final oldIds = oldItems.map((i) => i.id).toSet();
    final newIds = newItems.map((i) => i.id).toSet();
    final addedIds = newIds.difference(oldIds);
    if (addedIds.length > 1) {
      _markStackItemsSeen(newItems);
    }
  }

  void _markStackItemsSeen(List<StackItem> items) {
    _enteredStackIds.addAll(items.map((i) => i.id));
  }

  bool _shouldAnimateEnter(String id) => !_enteredStackIds.contains(id);

  void _markEntered(String id) => _enteredStackIds.add(id);

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final notifier = ref.read(gameProvider.notifier);
    final allItems = game.stackItems;
    final visible = _showCountered
        ? allItems
        : allItems.where((i) => i.showsOnStack).toList();
    final resolvesNext = StackDisplay.resolvesNextItem(allItems);
    final activeRoots = StackDisplay.activeRootsNewestFirst(allItems);

    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final listChildren = _sortMode == StackSortMode.stackOrder
        ? _stackOrderChildren(
            game,
            visible,
            resolvesNext,
            activeRoots,
          )
        : _apnapChildren(game, visible, resolvesNext);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            LayoutTokens.gr3,
            LayoutTokens.gr2,
            LayoutTokens.gr3,
            LayoutTokens.gr0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _sortMode == StackSortMode.stackOrder
                            ? 'Order on stack'
                            : 'By player',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: FontTokens.body,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Add spell or ability',
                      child: IconButton(
                        tooltip: 'Add spell or ability',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.all(LayoutTokens.gr0),
                        constraints: const BoxConstraints(
                          minWidth: LayoutTokens.minTapTarget,
                          minHeight: LayoutTokens.minTapTarget,
                        ),
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.accent,
                        ),
                        onPressed: () =>
                            _showAddDialog(context, parentId: null),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'How the stack works',
                      child: IconButton(
                        tooltip: 'How the stack works',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.all(LayoutTokens.gr0),
                        constraints: const BoxConstraints(
                          minWidth: LayoutTokens.minTapTarget,
                          minHeight: LayoutTokens.minTapTarget,
                        ),
                        icon: Icon(
                          Icons.help_outline_rounded,
                          color: AppTheme.textSecondary.withValues(alpha: 0.9),
                        ),
                        onPressed: () => StackHelpSheet.show(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: LayoutTokens.gr1),
                Wrap(
                  spacing: LayoutTokens.gr1,
                  runSpacing: LayoutTokens.gr0,
                  children: [
                    FilterChip(
                      label: Text('By player'),
                      selected: _sortMode == StackSortMode.apnap,
                      onSelected: (v) => setState(
                        () => _sortMode = v
                            ? StackSortMode.apnap
                            : StackSortMode.stackOrder,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding:
                          EdgeInsets.symmetric(horizontal: LayoutTokens.gr0),
                      shape: RoundedRectangleBorder(
                        borderRadius: RadiusTokens.radiusChip,
                      ),
                    ),
                    FilterChip(
                      label: Text('Resolved / countered'),
                      selected: _showCountered,
                      onSelected: (v) => setState(() => _showCountered = v),
                      visualDensity: VisualDensity.compact,
                      padding:
                          EdgeInsets.symmetric(horizontal: LayoutTokens.gr0),
                      shape: RoundedRectangleBorder(
                        borderRadius: RadiusTokens.radiusChip,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_sortMode == StackSortMode.apnap)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              LayoutTokens.gr3,
              LayoutTokens.gr0,
              LayoutTokens.gr3,
              LayoutTokens.gr1,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Who added what (active player first)',
                style: TextStyle(
                  fontSize: FontTokens.caption,
                  color: AppTheme.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        if (_tipBannerVisible)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: LayoutTokens.gr3),
            sliver: SliverToBoxAdapter(
              child: _TipBanner(
                onHide: () => setState(() => _tipBannerVisible = false),
              ),
            ),
          ),
        if (game.stackItems.isNotEmpty &&
            (game.isHost || game.players.length <= 1))
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: LayoutTokens.gr3),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: LayoutTokens.gr1,
                  runSpacing: LayoutTokens.gr0,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmClearAll(context, notifier),
                      icon: Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text('Clear all'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyStackState(
              onPutOnStack: () => _showAddDialog(context, parentId: null),
              onLoadExample: game.isHost || game.players.length <= 1
                  ? () => notifier.loadExampleStack()
                  : null,
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              LayoutTokens.gr3,
              LayoutTokens.gr0,
              LayoutTokens.gr3,
              LayoutTokens.gr4 + bottomSafe,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(listChildren),
            ),
          ),
      ],
    );
  }

  List<Widget> _stackOrderChildren(
    GameState game,
    List<StackItem> visible,
    StackItem? resolvesNext,
    List<StackItem> activeRoots,
  ) {
    final tree = StackDisplay.stackOrderTree(
      visible,
      includeInactive: _showCountered,
    );
    return [
      for (var i = 0; i < tree.length; i++)
        _StackNodeTile(
          game: game,
          node: tree[i],
          siblingIndex: i,
          siblingCount: tree.length,
          resolvesNextId: resolvesNext?.id,
          activeRoots: activeRoots,
          allItems: game.stackItems,
          shouldAnimateEnter: _shouldAnimateEnter,
          onEnterComplete: _markEntered,
        ),
    ];
  }

  List<Widget> _apnapChildren(
    GameState game,
    List<StackItem> visible,
    StackItem? resolvesNext,
  ) {
    final filteredGame = game.copyWith(stackItems: visible);
    final groups = StackDisplay.apnapGroups(filteredGame);
    return [
      for (final g in groups) ...[
        Padding(
          padding: EdgeInsets.only(
            top: LayoutTokens.gr2,
            bottom: LayoutTokens.gr1,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: game.playerById(g.playerId)?.playerColor ??
                      AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: LayoutTokens.gr2),
              Text(
                g.isActivePlayer
                    ? '${g.username} · Active player'
                    : '${g.username} · Turn order: ${g.turnOrderPosition}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: g.isActivePlayer
                      ? AppTheme.accent
                      : AppTheme.textPrimary,
                  fontSize: FontTokens.hudSm,
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < g.items.length; i++) ...[
          _StackItemEntry(
            game: game,
            item: g.items[i],
            depth: 0,
            siblingIndex: i,
            siblingCount: g.items.length,
            linkToParent: false,
            resolvesNextId: resolvesNext?.id,
            showWaitsHint: false,
            allItems: game.stackItems,
            nestedResponses: _nestedUnder(g.items[i], visible),
            shouldAnimateEnter: _shouldAnimateEnter,
            onEnterComplete: _markEntered,
          ),
        ],
      ],
    ];
  }

  List<StackItem> _nestedUnder(StackItem parent, List<StackItem> visible) {
    return visible
        .where((i) => i.parentId == parent.id)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    GameStateNotifier notifier,
  ) async {
    final ok = await showGameConfirmDialog(
      context: context,
      title: 'Clear stack?',
      message:
          'Remove every spell and ability on the stack. This cannot be undone.',
      confirmLabel: 'Clear all',
      destructive: true,
    );
    if (ok == true) notifier.clearAllStackItems();
  }

  Future<void> _showAddDialog(
    BuildContext context, {
    required String? parentId,
  }) async {
    await openStackAddDialog(context, ref, parentId: parentId);
  }
}

Future<void> openStackAddDialog(
  BuildContext context,
  WidgetRef ref, {
  required String? parentId,
}) async {
  final card = await showStackCardPickerDialog(
    context,
    title: parentId == null ? 'Put on stack' : 'In response to…',
  );
  if (card == null || !context.mounted) return;
  scheduleStackAddItem(ref, context, card: card, parentId: parentId);
}

void scheduleStackAddItem(
  WidgetRef ref,
  BuildContext context, {
  required ScryfallCard card,
  required String? parentId,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ref.read(gameProvider.notifier).addStackItem(
          name: card.name,
          parentId: parentId,
          oracleText: card.oracleText,
          manaCost: card.manaCost,
          imageUrl: card.imageUrl,
          typeLine: card.typeLine,
        );
  });
}

class _TipBanner extends StatelessWidget {
  final VoidCallback onHide;

  const _TipBanner({required this.onHide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: LayoutTokens.gr2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.12),
          borderRadius: RadiusTokens.radiusMd,
        ),
        child: Padding(
          padding: EdgeInsets.all(LayoutTokens.gr2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top spell resolves first. Add newest on top. Search Scryfall when adding cards so names and rules are correct.',
                style: TextStyle(
                  fontSize: FontTokens.caption,
                  height: 1.4,
                  color: AppTheme.textPrimary.withValues(alpha: 0.9),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onHide,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('Hide tip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStackState extends StatelessWidget {
  final VoidCallback onPutOnStack;
  final VoidCallback? onLoadExample;

  const _EmptyStackState({
    required this.onPutOnStack,
    this.onLoadExample,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(LayoutTokens.gr4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: LayoutTokens.gr3),
            Text(
              'Nothing on the stack',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: FontTokens.body,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: LayoutTokens.gr2),
            _emptyBullet('Put spells and abilities here before they resolve.'),
            _emptyBullet('The last one added resolves first.'),
            _emptyBullet('Load the 4-player example to preview a full pod stack.'),
            SizedBox(height: LayoutTokens.gr4),
            FilledButton.icon(
              onPressed: onPutOnStack,
              icon: Icon(Icons.add_rounded),
              label: Text('Add spell'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: RadiusTokens.radiusControlSm,
                ),
              ),
            ),
            if (onLoadExample != null) ...[
              SizedBox(height: LayoutTokens.gr2),
              OutlinedButton.icon(
                onPressed: onLoadExample,
                icon: Icon(Icons.science_outlined),
                label: Text('Load 4-player example'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: RadiusTokens.radiusControlSm,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyBullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: LayoutTokens.gr1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.9),
              fontSize: FontTokens.hudSm,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: FontTokens.hudSm,
                color: AppTheme.textSecondary.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fade + slide when a stack item is newly added.
class _StackAnimatedEnter extends StatefulWidget {
  const _StackAnimatedEnter({
    required this.animate,
    required this.onEnterComplete,
    required this.child,
  });

  final bool animate;
  final VoidCallback onEnterComplete;
  final Widget child;

  @override
  State<_StackAnimatedEnter> createState() => _StackAnimatedEnterState();
}

class _StackAnimatedEnterState extends State<_StackAnimatedEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.standard,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(curve);
    if (widget.animate) {
      widget.onEnterComplete();
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Nested stack row indent — fixed per depth level so deep chains stay readable.
abstract final class _StackNestMetrics {
  static const double indent = LayoutTokens.gr2;
}

class _StackNodeTile extends ConsumerWidget {
  final GameState game;
  final StackDisplayNode node;
  final int siblingIndex;
  final int siblingCount;
  final String? resolvesNextId;
  final List<StackItem> activeRoots;
  final List<StackItem> allItems;
  final bool Function(String id) shouldAnimateEnter;
  final void Function(String id) onEnterComplete;

  const _StackNodeTile({
    required this.game,
    required this.node,
    required this.siblingIndex,
    required this.siblingCount,
    required this.resolvesNextId,
    required this.activeRoots,
    required this.allItems,
    required this.shouldAnimateEnter,
    required this.onEnterComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = this.node;
    final isRoot = node.depth == 0;
    final showWaits = isRoot &&
        node.item.isActive &&
        resolvesNextId != null &&
        node.item.id != resolvesNextId &&
        activeRoots.any((r) => r.id == node.item.id);

    final card = _StackItemCard(
      game: game,
      item: node.item,
      resolvesNextId: resolvesNextId,
      showWaitsHint: showWaits,
      allItems: allItems,
    );

    final cardRow = isRoot
        ? card
        : Padding(
            padding: EdgeInsets.only(
              left: node.depth * _StackNestMetrics.indent,
            ),
            child: card,
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: _StackCardLayout.itemGap),
          child: cardRow,
        ),
        for (var i = 0; i < node.responses.length; i++)
          _StackNodeTile(
            game: game,
            node: node.responses[i],
            siblingIndex: i,
            siblingCount: node.responses.length,
            resolvesNextId: resolvesNextId,
            activeRoots: activeRoots,
            allItems: allItems,
            shouldAnimateEnter: shouldAnimateEnter,
            onEnterComplete: onEnterComplete,
          ),
      ],
    );

    return _StackAnimatedEnter(
      animate: shouldAnimateEnter(node.item.id),
      onEnterComplete: () => onEnterComplete(node.item.id),
      child: content,
    );
  }
}

/// Stack list row: card (+ nested entries for APNAP mode).
class _StackItemEntry extends ConsumerWidget {
  final GameState game;
  final StackItem item;
  final int depth;
  final int siblingIndex;
  final int siblingCount;
  final bool linkToParent;
  final String? resolvesNextId;
  final bool showWaitsHint;
  final List<StackItem> allItems;
  final List<StackItem> nestedResponses;
  final bool Function(String id) shouldAnimateEnter;
  final void Function(String id) onEnterComplete;

  const _StackItemEntry({
    required this.game,
    required this.item,
    required this.depth,
    this.siblingIndex = 0,
    this.siblingCount = 1,
    required this.linkToParent,
    required this.resolvesNextId,
    required this.showWaitsHint,
    required this.allItems,
    this.nestedResponses = const [],
    required this.shouldAnimateEnter,
    required this.onEnterComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = _StackItemCard(
      game: game,
      item: item,
      resolvesNextId: resolvesNextId,
      showWaitsHint: showWaitsHint,
      allItems: allItems,
    );

    final cardRow = !linkToParent
        ? card
        : Padding(
            padding: EdgeInsets.only(
              left: depth * _StackNestMetrics.indent,
            ),
            child: card,
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: _StackCardLayout.itemGap),
          child: cardRow,
        ),
        for (var i = 0; i < nestedResponses.length; i++)
          _StackItemEntry(
            game: game,
            item: nestedResponses[i],
            depth: depth + 1,
            siblingIndex: i,
            siblingCount: nestedResponses.length,
            linkToParent: true,
            resolvesNextId: resolvesNextId,
            showWaitsHint: false,
            allItems: allItems,
            nestedResponses: allItems
                .where(
                  (r) => r.parentId == nestedResponses[i].id,
                )
                .toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
            shouldAnimateEnter: shouldAnimateEnter,
            onEnterComplete: onEnterComplete,
          ),
      ],
    );

    return _StackAnimatedEnter(
      animate: shouldAnimateEnter(item.id),
      onEnterComplete: () => onEnterComplete(item.id),
      child: content,
    );
  }
}

/// Stack action pill dimensions (4dp grid).
abstract final class _StackPillMetrics {
  static const double height = LayoutTokens.minTapTarget;
  static const double gap = LayoutTokens.gr1;
}

/// Stack card spacing (4dp grid).
abstract final class _StackCardLayout {
  static const double paddingH = LayoutTokens.gr3;
  static const double paddingV = LayoutTokens.gr3;
  static const double itemGap = LayoutTokens.gr2;
  static const double groupGap = LayoutTokens.gr1;
  static const double metaGap = LayoutTokens.gr0;
  static const double actionsTopGap = LayoutTokens.gr2;

  /// Align footer actions with text column (player rail + gap).
  static const double actionsInset = LayoutTokens.gr3;
}

class _StackPlayerRail extends StatelessWidget {
  const _StackPlayerRail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: LayoutTokens.gr0),
      child: Container(
        width: LayoutTokens.gr0,
        height: LayoutTokens.gr4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: RadiusTokens.radiusXs,
        ),
      ),
    );
  }
}

class _StackItemCard extends ConsumerWidget {
  final GameState game;
  final StackItem item;
  final String? resolvesNextId;
  final bool showWaitsHint;
  final List<StackItem> allItems;

  const _StackItemCard({
    required this.game,
    required this.item,
    required this.resolvesNextId,
    required this.showWaitsHint,
    required this.allItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final owner = game.playerById(item.playerId);
    final canEdit = notifier.canEditStackItem(item);
    final canStatus = notifier.canChangeStackItemStatus(item);
    final isLocal = item.playerId == game.localPlayerId;
    final isFizzled = item.status == StackItemStatus.fizzled;
    final isResolved = item.status == StackItemStatus.resolved;
    final isResolvesNext = item.isActive && item.id == resolvesNextId;
    final parentName = StackDisplay.parentNameFor(item, allItems);

    final targetInvalid =
        StackDisplay.hasInvalidStackTarget(item, allItems);
    final showFizzleToggle = canStatus &&
        (isFizzled ||
            (item.isActive && (targetInvalid || item.parentId != null)));
    final statusLabel = switch (item.status) {
      StackItemStatus.resolved => 'Resolved',
      StackItemStatus.countered => 'Countered',
      StackItemStatus.fizzled => 'Fizzled',
      StackItemStatus.active => null,
    };
    final statusColor = switch (item.status) {
      StackItemStatus.resolved => AppTheme.success,
      StackItemStatus.countered => AppTheme.danger,
      StackItemStatus.fizzled => AppTheme.dangerAmber,
      StackItemStatus.active => null,
    };

    final borderColor = isResolvesNext
        ? AppTheme.accent
        : AppTheme.textSecondary.withValues(alpha: 0.14);
    final showActions = showFizzleToggle || (item.isActive && canStatus);

    final actions = showActions
        ? _StackItemActions(
            notifier: notifier,
            itemId: item.id,
            isFizzled: isFizzled,
            showResolveRespond: item.isActive && canStatus,
            showFizzleToggle: showFizzleToggle,
            onRespond: () => openStackAddDialog(
              context,
              ref,
              parentId: item.id,
            ),
          )
        : null;

    return Material(
      color: isFizzled
          ? AppTheme.card.withValues(alpha: 0.72)
          : isResolved
              ? AppTheme.success.withValues(alpha: 0.14)
              : AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: RadiusTokens.radiusMd,
        side: BorderSide(
          color: isFizzled
              ? AppTheme.dangerAmber.withValues(alpha: 0.35)
              : isResolved
                  ? AppTheme.success.withValues(alpha: 0.55)
                  : borderColor,
          width: isResolvesNext ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: RadiusTokens.radiusMd,
        onTap: item.isActive || isFizzled || isResolved
            ? () => _openItemMenu(context, ref, item)
            : null,
        onLongPress: canEdit ? () => _renameItem(context, ref, item) : null,
        child: Opacity(
          opacity: isFizzled ? 0.62 : isResolved ? 0.92 : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _StackCardLayout.paddingH,
              vertical: _StackCardLayout.paddingV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isResolvesNext) ...[
                  _ResolvesNextBadge(),
                  SizedBox(height: _StackCardLayout.groupGap),
                ],
                _buildCardBody(
                  context,
                  ownerColor: owner?.playerColor ?? AppTheme.textSecondary,
                  isFizzled: isFizzled,
                  isResolved: isResolved,
                  parentName: parentName,
                  ownerLabel:
                      '${owner?.username ?? item.playerId}${isLocal ? ' (you)' : ''}',
                  showWaitsHint: showWaitsHint,
                  targetInvalid: targetInvalid,
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  actions: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody(
    BuildContext context, {
    required Color ownerColor,
    required bool isFizzled,
    required bool isResolved,
    required String? parentName,
    required String ownerLabel,
    required bool showWaitsHint,
    required bool targetInvalid,
    required String? statusLabel,
    required Color? statusColor,
    required Widget? actions,
  }) {
    final info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StackPlayerRail(color: ownerColor),
        SizedBox(width: LayoutTokens.gr2),
        Expanded(
          child: _StackCardInfo(
            item: item,
            isFizzled: isFizzled,
            isResolved: isResolved,
            parentName: parentName,
            ownerLabel: ownerLabel,
            showWaitsHint: showWaitsHint,
            targetInvalid: targetInvalid,
            statusLabel: statusLabel,
            statusColor: statusColor,
            onShowRules: item.oracleText != null &&
                    item.oracleText!.trim().isNotEmpty
                ? () => _showOracleText(context, item)
                : null,
          ),
        ),
      ],
    );

    if (actions == null) return info;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        info,
        SizedBox(height: _StackCardLayout.actionsTopGap),
        Padding(
          padding: EdgeInsets.only(left: _StackCardLayout.actionsInset),
          child: actions,
        ),
      ],
    );
  }

  Future<void> _openItemMenu(
    BuildContext context,
    WidgetRef ref,
    StackItem item,
  ) async {
    final notifier = ref.read(gameProvider.notifier);
    final action = await showGameBottomSheet<String>(
      context: context,
      builder: (ctx) => GameSheetBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameSheetHandle(),
            SizedBox(height: LayoutTokens.gr1),
            if (item.isActive)
              ListTile(
                leading: Icon(Icons.reply_rounded),
                title: Text('In response to…'),
                onTap: () => Navigator.pop(ctx, 'respond'),
              ),
            if (notifier.canChangeStackItemStatus(item) &&
                (item.isActive || item.status == StackItemStatus.fizzled))
              ListTile(
                leading: Icon(
                  Icons.not_interested_rounded,
                  color: AppTheme.dangerAmber,
                ),
                title: Text(
                  item.status == StackItemStatus.fizzled
                      ? 'Undo fizzle'
                      : 'Fizzle',
                ),
                subtitle: Text(
                  item.status == StackItemStatus.fizzled
                      ? 'Put this spell back on the stack as active'
                      : 'Target illegal or spell left the stack (rules counter)',
                ),
                onTap: () => Navigator.pop(ctx, 'toggle_fizzle'),
              ),
            if (item.isActive && notifier.canChangeStackItemStatus(item))
              ListTile(
                leading: Icon(Icons.block_rounded),
                title: Text('Mark countered'),
                onTap: () => Navigator.pop(ctx, 'countered'),
              ),
            if (notifier.canEditStackItem(item))
              ListTile(
                leading: Icon(Icons.edit_rounded),
                title: Text('Rename'),
                onTap: () => Navigator.pop(ctx, 'rename'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'respond') {
      await openStackAddDialog(context, ref, parentId: item.id);
    } else if (action == 'toggle_fizzle') {
      notifier.setStackItemStatus(
        item.id,
        item.status == StackItemStatus.fizzled
            ? StackItemStatus.active
            : StackItemStatus.fizzled,
      );
    } else if (action == 'countered') {
      notifier.setStackItemStatus(item.id, StackItemStatus.countered);
    } else if (action == 'rename') {
      _renameItem(context, ref, item);
    }
  }

  Future<void> _renameItem(
    BuildContext context,
    WidgetRef ref,
    StackItem item,
  ) async {
    final card = await showStackCardPickerDialog(
      context,
      title: 'Rename',
      initialQuery: item.name,
    );
    if (card == null || !context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ref.read(gameProvider.notifier).renameStackItem(
            item.id,
            card.name,
            oracleText: card.oracleText,
            manaCost: card.manaCost,
            imageUrl: card.imageUrl,
            typeLine: card.typeLine,
          );
    });
  }

  void _showOracleText(BuildContext context, StackItem item) {
    final text = item.oracleText?.trim();
    if (text == null || text.isEmpty) return;
    showGameBottomSheet<void>(
      context: context,
      builder: (ctx) => GameSheetBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: FontTokens.headline,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (item.typeLine != null && item.typeLine!.isNotEmpty) ...[
                SizedBox(height: LayoutTokens.gr1),
                Text(
                  item.typeLine!,
                  style: TextStyle(
                    fontSize: FontTokens.hudSm,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
              SizedBox(height: LayoutTokens.gr2),
              Text(
                text,
                style: TextStyle(
                  fontSize: FontTokens.hudSm,
                  height: 1.45,
                  color: AppTheme.textPrimary.withValues(alpha: 0.92),
                ),
              ),
            ],
        ),
      ),
    );
  }
}

class _ResolvesNextBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: LayoutTokens.gr2,
            vertical: LayoutTokens.gr0,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.25),
            borderRadius: RadiusTokens.radiusControlSm,
          ),
          child: Text(
            'Resolves next',
            style: TextStyle(
              fontSize: FontTokens.hudXs,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
            ),
          ),
        ),
        SizedBox(width: LayoutTokens.gr1),
        Text(
          '#1',
          style: TextStyle(
            fontSize: FontTokens.hudXs,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _StackCardInfo extends StatelessWidget {
  const _StackCardInfo({
    required this.item,
    required this.isFizzled,
    required this.isResolved,
    required this.parentName,
    required this.ownerLabel,
    required this.showWaitsHint,
    required this.targetInvalid,
    required this.statusLabel,
    required this.statusColor,
    required this.onShowRules,
  });

  final StackItem item;
  final bool isFizzled;
  final bool isResolved;
  final String? parentName;
  final String ownerLabel;
  final bool showWaitsHint;
  final bool targetInvalid;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onShowRules;

  @override
  Widget build(BuildContext context) {
    final metaLines = <Widget>[
      if (showWaitsHint)
        Text(
          'Resolves after items above',
          style: TextStyle(
            fontSize: FontTokens.hudXs,
            height: 1.35,
            color: AppTheme.textSecondary.withValues(alpha: 0.75),
          ),
        ),
      if (targetInvalid && item.isActive)
        Text(
          'Target is no longer on the stack',
          style: TextStyle(
            fontSize: FontTokens.hudXs,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppTheme.dangerAmber,
          ),
        ),
      if (statusLabel != null && statusColor != null)
        Text(
          statusLabel!,
          style: TextStyle(
            fontSize: FontTokens.hudXs,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: FontTokens.body,
                  height: 1.3,
                  color: AppTheme.textPrimary,
                  decoration: (isFizzled || isResolved)
                      ? null
                      : (item.isActive
                          ? null
                          : TextDecoration.lineThrough),
                ),
              ),
            ),
            if (onShowRules != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: LayoutTokens.gr3,
                  minHeight: LayoutTokens.gr3,
                ),
                tooltip: 'Card rules',
                icon: Icon(
                  Icons.menu_book_outlined,
                  size: LayoutTokens.gr3,
                  color: AppTheme.textSecondary.withValues(alpha: 0.9),
                ),
                onPressed: onShowRules,
              ),
          ],
        ),
        if (item.typeLabel != null) ...[
          SizedBox(height: _StackCardLayout.groupGap),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: LayoutTokens.gr1,
                vertical: LayoutTokens.gr0,
              ),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.12),
                borderRadius: RadiusTokens.radiusControlSm,
              ),
              child: Text(
                item.typeLabel!,
                style: TextStyle(
                  fontSize: FontTokens.hudXs,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        ],
        if (parentName != null) ...[
          SizedBox(height: _StackCardLayout.groupGap),
          Text(
            'In response to $parentName',
            style: TextStyle(
              fontSize: FontTokens.caption,
              height: 1.35,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ],
        SizedBox(height: _StackCardLayout.groupGap),
        Text(
          ownerLabel,
          style: TextStyle(
            fontSize: FontTokens.caption,
            height: 1.35,
            color: AppTheme.textSecondary.withValues(alpha: 0.85),
          ),
        ),
        if (metaLines.isNotEmpty) ...[
          SizedBox(height: _StackCardLayout.groupGap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < metaLines.length; i++) ...[
                if (i > 0) SizedBox(height: _StackCardLayout.metaGap),
                metaLines[i],
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _StackPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color foreground;
  final Color? background;
  final Color? border;
  final bool filled;

  const _StackPillButton({
    required this.label,
    required this.onPressed,
    required this.foreground,
    this.background,
    this.border,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: _StackPillMetrics.height,
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.standard,
          foregroundColor: foreground,
          backgroundColor: filled
              ? background
              : background?.withValues(alpha: 0.18),
          padding: EdgeInsets.symmetric(
            horizontal: LayoutTokens.gr2,
            vertical: LayoutTokens.gr1,
          ),
          minimumSize: Size(0, _StackPillMetrics.height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: RadiusTokens.radiusControlSm,
            side: border != null
                ? BorderSide(color: border!, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: FontTokens.caption,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
    ),
    );
  }
}

class _StackItemActions extends StatelessWidget {
  final GameStateNotifier notifier;
  final String itemId;
  final bool isFizzled;
  final bool showResolveRespond;
  final bool showFizzleToggle;
  final VoidCallback onRespond;

  const _StackItemActions({
    required this.notifier,
    required this.itemId,
    required this.isFizzled,
    required this.showResolveRespond,
    required this.showFizzleToggle,
    required this.onRespond,
  });

  void _toggleFizzle() {
    notifier.setStackItemStatus(
      itemId,
      isFizzled ? StackItemStatus.active : StackItemStatus.fizzled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      if (showResolveRespond) ...[
        Expanded(
          child: _StackPillButton(
            label: 'Resolve',
            onPressed: () => notifier.setStackItemStatus(
              itemId,
              StackItemStatus.resolved,
            ),
            foreground: AppTheme.success,
            background: AppTheme.success,
          ),
        ),
        SizedBox(width: _StackPillMetrics.gap),
        Expanded(
          child: _StackPillButton(
            label: 'Respond',
            onPressed: onRespond,
            foreground: AppTheme.accent,
            background: AppTheme.accent,
            border: AppTheme.accent.withValues(alpha: 0.55),
          ),
        ),
      ],
      if (showFizzleToggle) ...[
        if (showResolveRespond) SizedBox(width: _StackPillMetrics.gap),
        Expanded(
          child: _StackPillButton(
            label: isFizzled ? 'Fizzled' : 'Fizzle',
            onPressed: _toggleFizzle,
            foreground: AppTheme.dangerAmber,
            background: AppTheme.dangerAmber,
            filled: isFizzled,
          ),
        ),
      ],
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: slots,
    );
  }
}
