import 'package:flutter/material.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import '../../../ui/tokens/motion_tokens.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../ui/tokens/layout_tokens.dart';
import 'counter_adjust_sheet.dart';

/// A compact row of player-level counters: poison, energy, experience, rad.
/// Each chip shows an icon + count. Tapping opens a +/- sheet.
/// Includes a Proliferate button at the right edge.
class CounterRowWidget extends StatelessWidget {
  final int poison;
  final int energy;
  final int experience;
  final int rad;
  final bool isEliminated;
  final void Function(String field, int delta) onCounterChange;
  final VoidCallback onProliferate;

  const CounterRowWidget({
    super.key,
    required this.poison,
    required this.energy,
    required this.experience,
    required this.rad,
    required this.onCounterChange,
    required this.onProliferate,
    this.isEliminated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutTokens.gr3,
        vertical: LayoutTokens.gr2,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          _CounterChip(
            iconWidget: GameIcon.poison(size: 24, color: AppTheme.success),
            label: 'Poison',
            value: poison,
            accentColor: AppTheme.success,
            dangerAt: 8,
            deathAt: 10,
            isEliminated: isEliminated,
            onTap: () =>
                _showAdjust(context, 'Poison Counters', 'poison', poison),
          ),
          SizedBox(width: LayoutTokens.gr3),
          _CounterChip(
            iconWidget: GameIcon.energy(size: 24, color: AppTheme.accentGold),
            label: 'Energy',
            value: energy,
            accentColor: AppTheme.accentGold,
            isEliminated: isEliminated,
            onTap: () =>
                _showAdjust(context, 'Energy Counters', 'energy', energy),
          ),
          SizedBox(width: LayoutTokens.gr3),
          _CounterChip(
            iconWidget: GameIcon.experience(size: 24, color: const Color(0xFF9C7AFF)),
            label: 'Exp',
            value: experience,
            accentColor: const Color(0xFF9C7AFF),
            isEliminated: isEliminated,
            onTap: () => _showAdjust(
                context, 'Experience Counters', 'experience', experience),
          ),
          SizedBox(width: LayoutTokens.gr3),
          _CounterChip(
            iconWidget: GameIcon.radiation(size: 24, color: const Color(0xFF66FF66)),
            label: 'Rad',
            value: rad,
            accentColor: const Color(0xFF66FF66),
            isEliminated: isEliminated,
            onTap: () =>
                _showAdjust(context, 'Rad Counters', 'rad', rad),
          ),
          SizedBox(width: LayoutTokens.gr3),
          // Proliferate button
          Tooltip(
            message: 'Proliferate',
            child: GestureDetector(
              onTap: isEliminated ? null : onProliferate,
              child: Container(
                width: LayoutTokens.gr6,
                height: LayoutTokens.gr6,
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(LayoutTokens.gr2),
                  border: Border.all(
                    color: isEliminated
                        ? AppTheme.textSecondary.withValues(alpha: OpacityTokens.moderate)
                        : AppTheme.accent.withValues(alpha: 0.6),
                  ),
                ),
                child: Center(
                  child: Text(
                    '+1',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEliminated
                          ? AppTheme.textSecondary
                          : AppTheme.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showAdjust(
    BuildContext context,
    String title,
    String field,
    int current,
  ) {
    if (isEliminated) return;
    showCounterAdjustSheet(
      context,
      title: title,
      current: current,
      onChanged: (delta) => onCounterChange(field, delta),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final Widget? iconWidget;
  final String label;
  final int value;
  final Color accentColor;
  final int? dangerAt;
  final int? deathAt;
  final bool isEliminated;
  final VoidCallback onTap;

  const _CounterChip({
    this.iconWidget,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onTap,
    this.dangerAt,
    this.deathAt,
    this.isEliminated = false,
  });

  Color get _chipColor {
    if (isEliminated) return AppTheme.textSecondary;
    if (deathAt != null && value >= deathAt!) return AppTheme.textSecondary;
    if (dangerAt != null && value >= dangerAt!) return AppTheme.textSecondary;
    return value > 0 ? accentColor : AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.standard,
        padding: EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr2,
          vertical: LayoutTokens.gr2,
        ),
        decoration: BoxDecoration(
          color: _chipColor.withValues(alpha: value > 0 ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(LayoutTokens.gr2),
          border: Border.all(
            color: _chipColor.withValues(alpha: value > 0 ? 0.6 : 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null) iconWidget!,
            const SizedBox(height: LayoutTokens.gr0),
            Text(
              '$value',
              style: TextStyle(
                color: _chipColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
