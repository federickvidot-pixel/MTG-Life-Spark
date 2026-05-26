import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../ui/tokens/color_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import '../../../ui/tokens/motion_tokens.dart';
import 'package:flutter/services.dart';

import '../../../core/game/commander_identity_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import '../../../ui/tokens/spacing_tokens.dart';
import 'game_modal_chrome.dart';

/// The main life counter — occupies the center of the personal view.
///
/// Displays **only** `life−1`, `life`, `life+1` between the edge controls.
///
/// Interactions:
///   • Horizontal drag on the triplet → ±1 per 36px (4dp-aligned stride)
///   • Tap left / right edge → −1 / +1
///   • Hold left / right → −5 / +5 every 150 ms (after 500 ms threshold)
///   • Double-tap → numeric input dialog
class LifeCounterWidget extends StatefulWidget {
  final int life;
  final Color playerColor;

  /// Optional WUBRG letters for halo / gradient chrome.
  final List<String> commanderColorIdentity;
  final bool isEliminated;
  final void Function(int delta) onLifeChange;
  final VoidCallback? onHaptic;

  const LifeCounterWidget({
    super.key,
    required this.life,
    required this.playerColor,
    this.commanderColorIdentity = const [],
    required this.onLifeChange,
    this.onHaptic,
    this.isEliminated = false,
  });

  @override
  State<LifeCounterWidget> createState() => _LifeCounterWidgetState();
}

class _LifeCounterWidgetState extends State<LifeCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _deltaAnim;
  late Animation<double> _deltaFade;
  late Animation<Offset> _deltaSlide;

  int? _lastDelta;
  Timer? _holdTimer;
  bool _holding = false;

  /// Stride (px) of horizontal drag before committing ±1 life.
  static const double _kDragStride = 36;

  double _wheelDragAccum = 0;

  @override
  void initState() {
    super.initState();
    _deltaAnim = AnimationController(
      vsync: this,
      duration: MotionTokens.hero,
    );
    _deltaFade = CurvedAnimation(parent: _deltaAnim, curve: Curves.easeOut);
    _deltaSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _deltaAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _deltaAnim.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _feedHorizontalDrag(double dx) {
    _wheelDragAccum -= dx;
    while (_wheelDragAccum.abs() >= _kDragStride) {
      _change(_wheelDragAccum > 0 ? 1 : -1);
      _wheelDragAccum += _wheelDragAccum > 0 ? -_kDragStride : _kDragStride;
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────

  void _change(int delta) {
    if (widget.isEliminated) return;
    setState(() => _lastDelta = delta);
    _deltaAnim.forward(from: 0);
    widget.onLifeChange(delta);
    if (widget.onHaptic != null) {
      widget.onHaptic!();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _startHold(int direction) {
    if (widget.isEliminated) return;
    _holding = true;
    _holdTimer = Timer(MotionTokens.hero, () {
      if (!_holding || !mounted) return;
      _change(direction * 5);
      _holdTimer = Timer.periodic(MotionTokens.fast, (_) {
        if (!_holding || !mounted) {
          _holdTimer?.cancel();
          return;
        }
        _change(direction * 5);
      });
    });
  }

  void _stopHold() {
    _holding = false;
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  Future<void> _showNumberPad() async {
    if (widget.isEliminated) return;
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _LifeInputDialog(currentLife: widget.life),
    );
    if (result != null && mounted) {
      final delta = result - widget.life;
      if (delta != 0) _change(delta);
    }
  }

  // ── Colors ─────────────────────────────────────────────────────────────

  Color get _lifeColor {
    if (widget.isEliminated) return AppTheme.textSecondary;
    if (widget.life <= 5) return AppTheme.danger;
    if (widget.life <= 10) return AppTheme.accentGold;
    return AppTheme.textPrimary;
  }

  Color get _deltaColor =>
      (_lastDelta ?? 0) > 0 ? AppTheme.success : AppTheme.textSecondary;

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final halo = CommanderIdentityColors.emphasisBorder(
          widget.commanderColorIdentity,
        );

        return Container(
          decoration: BoxDecoration(
            borderRadius: RadiusTokens.radiusBento,
            gradient: LinearGradient(
              colors: CommanderIdentityColors.gameplayGradient(
                widget.commanderColorIdentity,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: halo.withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: -2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(LayoutTokens.gr0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              RadiusTokens.bento - LayoutTokens.gr0,
            ),
            child: Container(
              color: AppTheme.primary.withValues(alpha: 0.88),
              child: GestureDetector(
                onDoubleTap: widget.isEliminated ? null : _showNumberPad,
                behavior: HitTestBehavior.deferToChild,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wBody = constraints.maxWidth;
                    final hBody = constraints.maxHeight;
                    final tapEdge = math.max(
                      LayoutTokens.minTapTarget,
                      LayoutTokens.gr5 + LayoutTokens.gr0,
                    );

                    if (widget.isEliminated) {
                      return Center(
                        child: Text(
                          '☠',
                          style: TextStyle(
                            fontSize: (hBody * 0.45).clamp(40.0, 96.0),
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }

                    final baseFontSize =
                        (wBody < 200 || hBody < 120)
                            ? 44.0
                            : (wBody < 280 || hBody < 150)
                            ? 56.0
                            : (widget.life.abs() >= 100 ? 72.0 : 80.0);
                    final deltaFontSize = (baseFontSize * 0.27).clamp(
                      18.0,
                      26.0,
                    );

                    final neighborFontSize =
                        (baseFontSize * 0.34).clamp(14.0, 26.0);
                    final neighborColor = AppTheme.textSecondary.withValues(
                      alpha: 0.42,
                    );
                    final gap = LayoutTokens.gr2;

                    final prev = widget.life - 1;
                    final next = widget.life + 1;

                    return Semantics(
                      label: widget.isEliminated
                          ? 'Eliminated at ${widget.life} life'
                          : '${widget.life} life total',
                      value: '${widget.life}',
                      child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          width: tapEdge,
                          height: hBody,
                          child: Semantics(
                            button: true,
                            label: 'Decrease life',
                            enabled: !widget.isEliminated,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _change(-1),
                              onLongPressStart: (_) => _startHold(-1),
                              onLongPressEnd: (_) => _stopHold(),
                              onLongPressCancel: _stopHold,
                              child: const ColoredBox(color: Colors.transparent),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          width: tapEdge,
                          height: hBody,
                          child: Semantics(
                            button: true,
                            label: 'Increase life',
                            enabled: !widget.isEliminated,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _change(1),
                              onLongPressStart: (_) => _startHold(1),
                              onLongPressEnd: (_) => _stopHold(),
                              onLongPressCancel: _stopHold,
                              child: const ColoredBox(color: Colors.transparent),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          width: tapEdge,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IgnorePointer(
                              child: _LifeEdgeStepGlyph(
                                icon: Icons.remove_rounded,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          width: tapEdge,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IgnorePointer(
                              child: _LifeEdgeStepGlyph(
                                icon: Icons.add_rounded,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: tapEdge,
                          right: tapEdge,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (d) =>
                                _feedHorizontalDrag(d.delta.dx),
                            onHorizontalDragEnd: (_) => _wheelDragAccum = 0,
                            onHorizontalDragCancel: () => _wheelDragAccum = 0,
                            behavior: HitTestBehavior.translucent,
                            child: ClipRect(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '$prev',
                                        maxLines: 1,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: neighborFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: neighborColor,
                                          letterSpacing: -0.5,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Expanded(
                                    flex: 2,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${widget.life}',
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: baseFontSize,
                                          fontWeight: FontWeight.w800,
                                          color: _lifeColor,
                                          letterSpacing: -2,
                                          height: 1.0,
                                          shadows: [
                                            Shadow(
                                              color: _lifeColor.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 24,
                                              offset: const Offset(0, LayoutTokens.gr0),
                                            ),
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: LayoutTokens.gr0,
                                              offset: Offset(0, LayoutTokens.gr0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '$next',
                                        maxLines: 1,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: neighborFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: neighborColor,
                                          letterSpacing: -0.5,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: IgnorePointer(
                            child:
                                _lastDelta == null
                                    ? const SizedBox.shrink()
                                    : FadeTransition(
                                      opacity: Tween(
                                        begin: 1.0,
                                        end: 0.0,
                                      ).animate(_deltaFade),
                                      child: SlideTransition(
                                        position: _deltaSlide,
                                        child: Text(
                                          _lastDelta! > 0
                                              ? '+$_lastDelta'
                                              : '$_lastDelta',
                                          style: TextStyle(
                                            fontSize: deltaFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: _deltaColor,
                                          ),
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LifeEdgeStepGlyph extends StatelessWidget {
  final IconData icon;

  const _LifeEdgeStepGlyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: OpacityTokens.soft),
            blurRadius: LayoutTokens.gr0,
            offset: const Offset(0, LayoutTokens.gr0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(LayoutTokens.gr0),
        child: Icon(
          icon,
          size: LayoutTokens.gr5 + LayoutTokens.gr0,
          color: AppTheme.textPrimary.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

// ── Numeric input dialog ───────────────────────────────────────────────────

class _LifeInputDialog extends StatefulWidget {
  final int currentLife;
  const _LifeInputDialog({required this.currentLife});

  @override
  State<_LifeInputDialog> createState() => _LifeInputDialogState();
}

class _LifeInputDialogState extends State<_LifeInputDialog> {
  String _input = '';

  void _press(String digit) {
    if (_input.length >= 4) return;
    setState(() => _input += digit);
  }

  void _delete() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _confirm() {
    final val = int.tryParse(_input);
    Navigator.pop(context, val);
  }

  Widget _key(String label, {VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(LayoutTokens.gr0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
            minimumSize: const Size(0, LayoutTokens.gr6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
          ),
          onPressed: onTap ?? () => _press(label),
          child: Text(
            label,
            style: TextStyle(
              fontSize: LayoutTokens.gr4 - LayoutTokens.gr0 / 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card,
      title: GameDialogTitleRow(
        titleWidget: Text(
          _input.isEmpty ? 'Set Life Total' : _input,
          style: TextStyle(
            color:
                _input.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary,
            fontSize: _input.isEmpty ? LayoutTokens.gr3 : LayoutTokens.gr5,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        onClose: () => Navigator.pop(context),
      ),
      contentPadding: SpacingTokens.horizontalMd.copyWith(top: 0, bottom: 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['⌫', '0', '✓'],
          ])
            Row(
              children:
                  row.map((label) {
                    if (label == '⌫') {
                      return _key(label, onTap: _delete);
                    }
                    if (label == '✓') {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(LayoutTokens.gr0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              minimumSize: const Size(0, LayoutTokens.gr6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  RadiusTokens.sm,
                                ),
                              ),
                            ),
                            onPressed: _input.isNotEmpty ? _confirm : null,
                            child: Icon(
                              Icons.check,
                              color: ColorTokens.onAccent,
                              size: LayoutTokens.gr3,
                            ),
                          ),
                        ),
                      );
                    }
                    return _key(label);
                  }).toList(),
            ),
        ],
      ),
      actions: const [],
    );
  }
}
