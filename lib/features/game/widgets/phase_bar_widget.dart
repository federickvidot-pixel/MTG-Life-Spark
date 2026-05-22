import 'package:flutter/material.dart';
import '../../../ui/tokens/color_tokens.dart';
import '../../../ui/tokens/motion_tokens.dart';

import '../../../core/game/game_phase.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';

class _NoScrollbarScrollBehavior extends ScrollBehavior {
  const _NoScrollbarScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

/// Horizontal scroll carousel for phases. Three items visible; center is active.
/// Scroll to change phase; snaps to center with smooth opacity/scale transitions.
class PhaseBarWidget extends StatefulWidget {
  final GamePhase currentPhase;
  final Color activeColor;
  final bool isHost;
  final VoidCallback? onAdvancePhase;
  final bool canSetPhase;
  final void Function(GamePhase)? onPhaseTap;
  final bool compact;

  const PhaseBarWidget({
    super.key,
    required this.currentPhase,
    required this.activeColor,
    this.isHost = false,
    this.onAdvancePhase,
    this.canSetPhase = false,
    this.onPhaseTap,
    this.compact = false,
  });

  @override
  State<PhaseBarWidget> createState() => _PhaseBarWidgetState();
}

class _PhaseBarWidgetState extends State<PhaseBarWidget> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  bool get _canChangePhase =>
      (widget.isHost && widget.onAdvancePhase != null) ||
      (widget.canSetPhase && widget.onPhaseTap != null);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex(widget.currentPhase.index));
  }

  @override
  void didUpdateWidget(PhaseBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPhase != widget.currentPhase) {
      _scrollToIndex(widget.currentPhase.index);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      setState(() => _scrollOffset = _scrollController.offset);
    }
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final viewportWidth = _scrollController.position.viewportDimension;
    final itemExtent = viewportWidth / 3;
    final targetOffset = index * itemExtent;
    if ((_scrollController.offset - targetOffset).abs() > 1) {
      if (animate) {
        _scrollController.animateTo(
          targetOffset,
          duration: MotionTokens.slow,
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }

  void _onScrollEnd() {
    if (!_scrollController.hasClients) return;
    final viewportWidth = _scrollController.position.viewportDimension;
    final itemExtent = viewportWidth / 3;
    final index = (_scrollController.offset / itemExtent).round().clamp(0, GamePhase.values.length - 1);
    final phase = GamePhase.values[index];

    _scrollController.animateTo(
      index * itemExtent,
      duration: MotionTokens.standard,
      curve: Curves.easeOutCubic,
    );

    if (_canChangePhase && phase != widget.currentPhase && widget.onPhaseTap != null) {
      widget.onPhaseTap!(phase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final itemExtent = viewportWidth / 3;
        final padding = (viewportWidth - itemExtent) / 2;

        return Container(
          height: widget.compact ? 40 : 56,
          color: Colors.transparent,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification) _onScrollEnd();
              return false;
            },
            child: ScrollConfiguration(
              behavior: const _NoScrollbarScrollBehavior(),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: padding),
                itemExtent: itemExtent,
                itemCount: GamePhase.values.length,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              itemBuilder: (context, index) {
                final phase = GamePhase.values[index];
                final effectiveOffset = _scrollController.hasClients
                    ? _scrollOffset
                    : widget.currentPhase.index * itemExtent;
                final distance = (effectiveOffset - index * itemExtent).abs();
                final normalizedDist = (distance / itemExtent).clamp(0.0, 2.0);
                final opacity = (1.0 - normalizedDist * 0.35).clamp(0.35, 1.0);
                final scale = (1.05 - normalizedDist * 0.08).clamp(0.88, 1.05);
                final isCentered = normalizedDist < 0.3;

                return GestureDetector(
                  onTap: () {
                    _scrollToIndex(index, animate: false);
                    if (_canChangePhase && widget.onPhaseTap != null && phase != widget.currentPhase) {
                      widget.onPhaseTap!(phase);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: _PhaseCarouselItem(
                    phase: phase,
                    activeColor: widget.activeColor,
                    opacity: opacity,
                    scale: scale,
                    isCentered: isCentered,
                    compact: widget.compact,
                  ),
                );
              },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhaseCarouselItem extends StatelessWidget {
  final GamePhase phase;
  final Color activeColor;
  final double opacity;
  final double scale;
  final bool isCentered;
  final bool compact;

  const _PhaseCarouselItem({
    required this.phase,
    required this.activeColor,
    required this.opacity,
    required this.scale,
    required this.isCentered,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // 4dp grid — chip padding and type ramp (no golden-ratio scaling).
    final marginH = LayoutTokens.gr0;
    final padH = compact ? LayoutTokens.gr1 : LayoutTokens.gr2;
    final padV = padH;
    final fontSizeInactive = 12.0;
    final fontSizeActive = 16.0;

    return AnimatedOpacity(
      duration: MotionTokens.fast,
      opacity: opacity,
      child: AnimatedScale(
        duration: MotionTokens.fast,
        scale: scale,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: marginH),
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            color: isCentered ? activeColor : AppTheme.card,
            borderRadius: RadiusTokens.radiusPill,
            border: Border.all(
              color: isCentered ? activeColor.withValues(alpha: 0.5) : AppTheme.textSecondary.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: isCentered
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              phase.shortName,
              style: TextStyle(
                color: isCentered ? ColorTokens.onAccent : AppTheme.textSecondary,
                fontSize: isCentered ? fontSizeActive : fontSizeInactive,
                fontWeight: isCentered ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
