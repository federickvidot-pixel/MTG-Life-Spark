import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../ui/tokens/font_tokens.dart';
import 'package:flutter/services.dart';
import '../../../core/game/gameplay_dial_ids.dart';
import '../../../core/game/player_game_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/color_tokens.dart';
import 'game_modal_chrome.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import 'counter_adjust_sheet.dart';

const int _kDialWheelMax = 999;

/// Max counter pills per row on phones (fits ~4 columns with gutters).
const int _kPillsPerRow = 4;

/// Counter dial / action tiles — modest rounding (not stadium pills).
const double _kDialPillCornerRadius = RadiusTokens.controlSm;

/// Corner-badge remove control (~30% outside the pill top-right corner).
const double _kDialRemoveButtonSize = 20;
const double _kDialRemoveBadgeOverlap = 6;

/// Responsive pill geometry — scales down on narrow phones so the strip doesn’t dominate the Play tab.
class _DialMetrics {
  const _DialMetrics({
    required this.pillHeaderHeight,
    required this.stepTapHeight,
    required this.wheelHeight,
    required this.itemExtent,
    required this.leadingSize,
    required this.stepIconSize,
    required this.wheelFontSize,
    required this.addIconSize,
  });

  /// Icon row inside the pill top edge.
  final double pillHeaderHeight;
  final double stepTapHeight;
  final double wheelHeight;
  final double itemExtent;
  final double leadingSize;
  final double stepIconSize;
  final double wheelFontSize;
  final double addIconSize;

  /// Steppers + wheel below the in-pill header.
  double get pillBodyHeight => stepTapHeight + wheelHeight + stepTapHeight;

  /// Full counter tile height (single bordered pill).
  double get tileStackHeight => pillHeaderHeight + pillBodyHeight;

  /// [shortestSide] = `MediaQuery.sizeOf(context).shortestSide`
  factory _DialMetrics.scale(double shortestSide) {
    final t = ((shortestSide - 300) / 180).clamp(0.0, 1.0);
    double lerp(double a, double b) => a + (b - a) * t;
    double r4(double x) => (x / 4).round() * 4.0;
    return _DialMetrics(
      pillHeaderHeight: r4(lerp(32, 36)),
      stepTapHeight: r4(lerp(28, 32)),
      wheelHeight: r4(lerp(48, 64)),
      itemExtent: r4(lerp(18, 22)),
      leadingSize: r4(lerp(16, 20)),
      stepIconSize: r4(lerp(18, 22)),
      wheelFontSize: r4(lerp(12, 15)),
      addIconSize: r4(lerp(22, 26)),
    );
  }
}

/// Modular preset + custom counters with vertical wheel scrolling per dial.
///
/// Only dials listed on [PlayerGameState.visibleGameplayDials] render on the
/// strip; use **Add** to pick core/preset/custom trackers as needed.
class GameplayDialsStripWidget extends StatelessWidget {
  final PlayerGameState Function() getPlayer;
  final bool isEliminated;
  final void Function(String field, int delta) onAdjustCounter;
  final void Function(String field, int absoluteValue) onSetCounterAbsolute;
  final bool Function(String dialKey, String label) onRegisterCustomDial;
  final bool Function(String field) onAddDialToStrip;
  final void Function(String field) onRemoveDialFromStrip;

  const GameplayDialsStripWidget({
    super.key,
    required this.getPlayer,
    required this.isEliminated,
    required this.onAdjustCounter,
    required this.onSetCounterAbsolute,
    required this.onRegisterCustomDial,
    required this.onAddDialToStrip,
    required this.onRemoveDialFromStrip,
  });

  static const Set<String> _coreFields = {
    'poison',
    'energy',
    'experience',
    'rad',
  };

  static IconData _iconForField(String field) {
    return switch (field) {
      'poison' => Icons.coronavirus_outlined,
      'energy' => Icons.bolt_rounded,
      'experience' => Icons.auto_graph_rounded,
      'rad' => Icons.warning_amber_rounded,
      GameplayDialIds.blood => Icons.water_drop_rounded,
      GameplayDialIds.clue => Icons.search_rounded,
      GameplayDialIds.map => Icons.map_rounded,
      GameplayDialIds.treasure => Icons.stars_rounded,
      GameplayDialIds.devotion => Icons.auto_awesome_rounded,
      GameplayDialIds.creatures => Icons.pets_rounded,
      GameplayDialIds.enchantments => Icons.auto_fix_high_rounded,
      GameplayDialIds.artifacts => Icons.handyman_rounded,
      GameplayDialIds.graveyardCreatures => Icons.layers_rounded,
      GameplayDialIds.exile => Icons.output_rounded,
      _ => Icons.tune_rounded,
    };
  }

  static Widget _leadingGlyph(String field, double size) {
    return switch (field) {
      'poison' => GameIcon.poison(size: size, color: AppTheme.success),
      'energy' => GameIcon.energy(size: size, color: AppTheme.accentGold),
      'experience' => GameIcon.experience(
        size: size,
        color: ColorTokens.brandPurple,
      ),
      'rad' => GameIcon.radiation(size: size, color: ColorTokens.success),
      _ => Icon(
        _iconForField(field),
        size: size,
        color: AppTheme.textSecondary.withValues(alpha: 0.95),
      ),
    };
  }

  PlayerGameState get player => getPlayer();

  static void _showStripLimitSnack(BuildContext context, {bool custom = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          custom
              ? 'You can have up to ${GameplayDialIds.maxCustomDials} custom counters '
                  'and ${GameplayDialIds.maxStripDials} counters total on your strip. '
                  'Remove one to add another.'
              : 'Your strip holds up to ${GameplayDialIds.maxStripDials} counters. '
                  'Remove one to add another.',
        ),
      ),
    );
  }

  static String _labelFor(PlayerGameState p, String field) {
    switch (field) {
      case 'poison':
        return 'Poison';
      case 'energy':
        return 'Energy';
      case 'experience':
        return 'Exp';
      case 'rad':
        return 'Rad';
      default:
        return p.customDialLabels[field] ??
            switch (field) {
              GameplayDialIds.blood => 'Blood',
              GameplayDialIds.clue => 'Clue',
              GameplayDialIds.map => 'Map',
              GameplayDialIds.treasure => 'Treasure',
              GameplayDialIds.devotion => 'Devotion',
              GameplayDialIds.creatures => 'Creatures',
              GameplayDialIds.enchantments => 'Enchant',
              GameplayDialIds.artifacts => 'Artifacts',
              GameplayDialIds.graveyardCreatures => 'GY',
              GameplayDialIds.exile => 'Exile',
              _ => field,
            };
    }
  }

  static int _valueOf(PlayerGameState p, String field) => switch (field) {
    'poison' => p.poison,
    'energy' => p.energy,
    'experience' => p.experience,
    'rad' => p.rad,
    _ => p.extraDials[field] ?? 0,
  };

  static bool _fieldKnown(PlayerGameState p, String field) =>
      _coreFields.contains(field) ||
      GameplayDialIds.presets.contains(field) ||
      p.customDialLabels.containsKey(field);

  /// Strip dial tiles shown (same ordering as the strip widget).
  static int orderedStripFieldCount(PlayerGameState p) {
    final seen = <String>{};
    var n = 0;
    for (final f in p.visibleGameplayDials) {
      if (_fieldKnown(p, f) && seen.add(f)) n++;
    }
    return n;
  }

  /// Dial strip is always a single row (max 4 pills + optional Add).
  static int dialStripRowCount() => 1;

  List<String> _orderedStripFields() {
    final seen = <String>{};
    final out = <String>[];
    for (final f in player.visibleGameplayDials) {
      if (_fieldKnown(player, f) && seen.add(f)) {
        out.add(f);
      }
    }
    return out;
  }

  void _showAdjust(
    BuildContext context,
    String field,
    String title,
    int current,
  ) {
    if (isEliminated) return;
    showCounterAdjustSheet(
      context,
      title: title,
      current: current,
      onChanged: (delta) => onAdjustCounter(field, delta),
    );
  }

  Future<void> _promptCustomDial(BuildContext context) async {
    if (isEliminated) return;
    if (!GameplayDialLimits.canAddCustomDial(getPlayer())) {
      _showStripLimitSnack(context, custom: true);
      return;
    }
    final keyCtl = TextEditingController();
    final labelCtl = TextEditingController();
    final ok = await showGameChoiceDialog(
      context: context,
      title: 'Custom dial',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: keyCtl,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Id (letters/numbers)',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(height: LayoutTokens.gr2),
          TextField(
            controller: labelCtl,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Label',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
      primaryLabel: 'Add',
    );
    if (ok == true && context.mounted) {
      final added = onRegisterCustomDial(keyCtl.text, labelCtl.text);
      if (!added && context.mounted) {
        _showStripLimitSnack(context, custom: true);
      }
    }
    keyCtl.dispose();
    labelCtl.dispose();
  }

  Future<void> _showAddChooser(BuildContext context) async {
    if (isEliminated) return;
    if (!GameplayDialLimits.canAddDialToStrip(getPlayer())) {
      _showStripLimitSnack(context);
      return;
    }
    final visible = getPlayer().visibleGameplayDials.toSet();
    final coreOrdered = ['poison', 'energy', 'experience', 'rad'];

    await showGameBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        void pick(String field) {
          final added = onAddDialToStrip(field);
          Navigator.pop(sheetCtx);
          if (!added && context.mounted) {
            _showStripLimitSnack(context);
          }
        }

        final bottomPad = MediaQuery.paddingOf(sheetCtx).bottom;
        Widget section(String title, List<String> ids) {
          final choices = ids
              .where((id) => !visible.contains(id))
              .toList(growable: false);
          if (choices.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  LayoutTokens.gr3,
                  LayoutTokens.gr2,
                  LayoutTokens.gr3,
                  LayoutTokens.gr1,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: FontTokens.hudXs,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.textSecondary.withValues(alpha: 0.75),
                  ),
                ),
              ),
              ...choices.map(
                (id) => ListTile(
                  leading: SizedBox(
                    width: 36,
                    child: Center(child: _leadingGlyph(id, 18)),
                  ),
                  title: Text(
                    _labelFor(player, id),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => pick(id),
                ),
              ),
            ],
          );
        }

        final addableBuiltIn =
            [
              ...coreOrdered,
              ...GameplayDialIds.presets,
            ].where((id) => !visible.contains(id)).length;
        final livePlayer = getPlayer();
        final canAddCustom = GameplayDialLimits.canAddCustomDial(livePlayer);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPad + LayoutTokens.gr2),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GameSheetHandle(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      LayoutTokens.gr3,
                      LayoutTokens.gr3,
                      LayoutTokens.gr3,
                      LayoutTokens.gr1,
                    ),
                    child: Text(
                      'Add counter',
                      style: GameModalChrome.sheetTitleStyle,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: LayoutTokens.gr3),
                    child: Text(
                      'Pick trackers for your strip (max ${GameplayDialIds.maxStripDials}). '
                      'Tap X on a counter to remove it from the strip.',
                      style: TextStyle(
                        fontSize: FontTokens.hudSm,
                        height: 1.35,
                        color: AppTheme.textSecondary.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                  SizedBox(height: LayoutTokens.gr2),
                  section('Common', coreOrdered),
                  section('Tokens & zones', [...GameplayDialIds.presets]),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      LayoutTokens.gr3,
                      LayoutTokens.gr2,
                      LayoutTokens.gr3,
                      0,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: canAddCustom
                          ? () async {
                            Navigator.pop(sheetCtx);
                            await _promptCustomDial(context);
                          }
                          : null,
                      icon: Icon(
                        Icons.edit_note_rounded,
                        color: canAddCustom
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                      label: Text(
                        canAddCustom
                            ? 'Custom dial…'
                            : 'Custom dial (max ${GameplayDialIds.maxCustomDials})',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: canAddCustom
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (!canAddCustom)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        LayoutTokens.gr3,
                        LayoutTokens.gr1,
                        LayoutTokens.gr3,
                        0,
                      ),
                      child: Text(
                        'You already have ${GameplayDialIds.maxCustomDials} custom counters '
                        'or your strip is full (${GameplayDialIds.maxStripDials} max). '
                        'Remove one from your strip before adding another.',
                        style: TextStyle(
                          fontSize: FontTokens.hudSm,
                          height: 1.35,
                          color: AppTheme.textSecondary.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  if (addableBuiltIn == 0)
                    Padding(
                      padding: EdgeInsets.all(LayoutTokens.gr3),
                      child: Text(
                        'Every built-in counter is already on your strip. '
                        'Use Custom dial for anything else.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context, String field) async {
    if (isEliminated) return;
    final label = _labelFor(player, field);
    final ok = await showGameConfirmDialog(
      context: context,
      title: 'Remove $label?',
      message:
          'The counter stays at its current value; it only disappears from your strip.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (ok == true && context.mounted) {
      onRemoveDialFromStrip(field);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = _orderedStripFields();

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(
          MediaQuery.sizeOf(context).shortestSide,
          constraints.maxWidth,
        );
        final metrics = _DialMetrics.scale(shortest);

        final badgePad =
            fields.isNotEmpty && !isEliminated ? _kDialRemoveBadgeOverlap : 0.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            badgePad,
            math.max(badgePad, LayoutTokens.gr1),
            badgePad,
            LayoutTokens.gr0,
          ),
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              final gap = LayoutTokens.gr1;
              final rowContentW = innerConstraints.maxWidth;

              final livePlayer = getPlayer();
              final showAddButton = GameplayDialLimits.showAddCounterTile(
                livePlayer,
                isEliminated: isEliminated,
              );
              final slotCount = fields.length + (showAddButton ? 1 : 0);
              final slots = math.max(1, math.min(slotCount, _kPillsPerRow));
              var pillW = (rowContentW - gap * (slots - 1)) / slots;
              pillW = math.max(pillW, 40.0);

              final rowChildren = <Widget>[
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  SizedBox(
                    width: pillW,
                    height: metrics.tileStackHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: _GameplayDialPill(
                            metrics: metrics,
                            value: _valueOf(livePlayer, fields[i]).clamp(
                              0,
                              9999,
                            ),
                            width: pillW,
                            isEliminated: isEliminated,
                            tooltip:
                                '${_labelFor(livePlayer, fields[i])} — tap to adjust, X to remove',
                            headerLeading: _leadingGlyph(
                              fields[i],
                              metrics.leadingSize,
                            ),
                            onHeaderTap:
                                isEliminated
                                    ? null
                                    : () => _showAdjust(
                                      context,
                                      fields[i],
                                      '${_labelFor(livePlayer, fields[i])} counters',
                                      _valueOf(livePlayer, fields[i]),
                                    ),
                            onHeaderLongPress:
                                isEliminated
                                    ? null
                                    : () => _confirmRemove(context, fields[i]),
                            onStep: (d) => onAdjustCounter(fields[i], d),
                            onSetAbsolute:
                                (v) => onSetCounterAbsolute(
                                  fields[i],
                                  v.clamp(0, 9999),
                                ),
                          ),
                        ),
                        if (!isEliminated)
                          Positioned(
                            top: -_kDialRemoveBadgeOverlap,
                            right: -_kDialRemoveBadgeOverlap,
                            child: _DialStripRemoveButton(
                              onPressed:
                                  () => _confirmRemove(context, fields[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (showAddButton) ...[
                  if (fields.isNotEmpty) SizedBox(width: gap),
                  SizedBox(
                    width: pillW,
                    height: metrics.tileStackHeight,
                    child: _AddCounterPillTile(
                      metrics: metrics,
                      width: pillW,
                      isEliminated: isEliminated,
                      onTap: () => _showAddChooser(context),
                    ),
                  ),
                ],
              ];

              return SizedBox(
                width: rowContentW,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: rowChildren,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AddCounterPillTile extends StatelessWidget {
  final _DialMetrics metrics;
  final double width;
  final bool isEliminated;
  final VoidCallback onTap;

  const _AddCounterPillTile({
    required this.metrics,
    required this.width,
    required this.isEliminated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add counter',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEliminated ? null : onTap,
          borderRadius: BorderRadius.circular(_kDialPillCornerRadius),
          child: Ink(
            width: width,
            height: metrics.tileStackHeight,
            decoration: BoxDecoration(
              color: AppTheme.card.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(_kDialPillCornerRadius),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.45),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                size: metrics.addIconSize,
                color: isEliminated ? AppTheme.textSecondary : AppTheme.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialStripRemoveButton extends StatelessWidget {
  const _DialStripRemoveButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove from strip',
      child: Tooltip(
        message: 'Remove from strip',
        child: SizedBox(
          width: LayoutTokens.minTapTarget,
          height: LayoutTokens.minTapTarget,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topRight,
            children: [
              Material(
                color: AppTheme.card,
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.22),
                shape: CircleBorder(
                  side: BorderSide(
                    color: AppTheme.surface.withValues(alpha: 0.95),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: _kDialRemoveButtonSize,
                    height: _kDialRemoveButtonSize,
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: AppTheme.textSecondary.withValues(alpha: 0.98),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameplayDialPill extends StatefulWidget {
  final _DialMetrics metrics;
  final int value;
  final double width;
  final bool isEliminated;
  final String tooltip;
  final Widget headerLeading;
  final VoidCallback? onHeaderTap;
  final VoidCallback? onHeaderLongPress;
  final void Function(int delta) onStep;
  final void Function(int absolute) onSetAbsolute;

  const _GameplayDialPill({
    required this.metrics,
    required this.value,
    required this.width,
    required this.isEliminated,
    required this.tooltip,
    required this.headerLeading,
    this.onHeaderTap,
    this.onHeaderLongPress,
    required this.onStep,
    required this.onSetAbsolute,
  });

  @override
  State<_GameplayDialPill> createState() => _GameplayDialPillState();
}

class _GameplayDialPillState extends State<_GameplayDialPill> {
  late FixedExtentScrollController _ctrl;
  bool _dragging = false;

  int get _clampedValue => widget.value.clamp(0, _kDialWheelMax);

  int _wheelIndexForValue(int value) => _kDialWheelMax - value;

  int _valueFromWheelIndex(int index) => _kDialWheelMax - index;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(
      initialItem: _wheelIndexForValue(_clampedValue),
    );
  }

  @override
  void didUpdateWidget(covariant _GameplayDialPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.value != widget.value && _ctrl.hasClients) {
      final i = _wheelIndexForValue(_clampedValue);
      if (_ctrl.selectedItem != i) {
        _ctrl.jumpToItem(i);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dim = widget.isEliminated;
    final borderColor = AppTheme.surface.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        enabled: !widget.isEliminated,
        child: Tooltip(
          message: widget.tooltip,
          child: Container(
          width: widget.width,
          height: widget.metrics.tileStackHeight,
          decoration: BoxDecoration(
            color: AppTheme.card.withValues(alpha: dim ? 0.55 : 0.92),
            borderRadius: BorderRadius.circular(_kDialPillCornerRadius),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_kDialPillCornerRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: widget.metrics.pillHeaderHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onHeaderTap,
                    onLongPress: widget.onHeaderLongPress,
                    child: Center(child: widget.headerLeading),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppTheme.textSecondary.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final hStep = widget.metrics.stepTapHeight;
                      final wheelH = math.max(
                        0.0,
                        constraints.maxHeight - 2 * hStep,
                      );

                      return Column(
                        children: [
                          _stepButton(
                            dim: dim,
                            icon: Icons.add_rounded,
                            onTap:
                                widget.isEliminated
                                    ? null
                                    : () {
                                      HapticFeedback.lightImpact();
                                      widget.onStep(1);
                                    },
                          ),
                          SizedBox(
                            height: wheelH,
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                              ),
                              child: IgnorePointer(
                                ignoring: widget.isEliminated,
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (n) {
                                    if (widget.isEliminated) return false;
                                    if (n is ScrollStartNotification) {
                                      _dragging = true;
                                    } else if (n is ScrollEndNotification) {
                                      _dragging = false;
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (!mounted || !_ctrl.hasClients) {
                                          return;
                                        }
                                        final t = _valueFromWheelIndex(
                                          _ctrl.selectedItem,
                                        );
                                        if (t != _clampedValue) {
                                          HapticFeedback.selectionClick();
                                          widget.onSetAbsolute(t);
                                        }
                                      });
                                    }
                                    return false;
                                  },
                                  child: ListWheelScrollView.useDelegate(
                                    controller: _ctrl,
                                    itemExtent: widget.metrics.itemExtent,
                                    physics: const FixedExtentScrollPhysics(),
                                    perspective: 0.003,
                                    diameterRatio: 1.45,
                                    useMagnifier: true,
                                    magnification: 1.14,
                                    overAndUnderCenterOpacity: 0.4,
                                    onSelectedItemChanged: (_) {},
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                      childCount: _kDialWheelMax + 1,
                                      builder: (c, i) {
                                        return Center(
                                          child: Text(
                                            '${_valueFromWheelIndex(i)}',
                                            style: TextStyle(
                                              fontSize:
                                                  widget.metrics.wheelFontSize,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  dim
                                                      ? AppTheme.textSecondary
                                                      : AppTheme.textPrimary
                                                          .withValues(
                                                        alpha: 0.88,
                                                      ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _stepButton(
                            dim: dim,
                            icon: Icons.remove_rounded,
                            onTap:
                                widget.isEliminated
                                    ? null
                                    : () {
                                      HapticFeedback.lightImpact();
                                      widget.onStep(-1);
                                    },
                          ),
                        ],
                      );
                    },
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

  Widget _stepButton({
    required bool dim,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: widget.metrics.stepTapHeight,
          width: double.infinity,
          child: Center(
            child: Icon(
              icon,
              size: widget.metrics.stepIconSize,
              color: dim ? AppTheme.textSecondary : AppTheme.accent,
            ),
          ),
        ),
      ),
    );
  }
}
